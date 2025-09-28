import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shelf_multipart/multipart.dart';

import '../utils/utils.dart';

Router petsHandler(Connection db) {
  final router = Router();

  // Получение всех питомцев пользователя
  router.get('/', (Request request) async {
    try {
      final userId = request.context['user_id'] as int;

      final result = await db.execute(
        Sql.named('SELECT * FROM pets WHERE user_id = @userId'),
        parameters: {'userId': userId},
      );

      return ApiResponse.ok(
        result.map((r) => r.toColumnMap()).toList(),
      );
    } catch (e) {
      return ApiResponse.internalServerError(e);
    }
  });

  // Создание питомца
  router.post('/', (Request request) async {
    final userId = request.context['user_id'] as int;

    final data = await Parser.parseRequestData(request);
    if (data is! Map<String, dynamic>) return data;

    final validation = PetValidators.validatePetData(data);
    if (!validation.isValid) {
      return ApiResponse.badRequest(validation.errors.values.join(', '));
    }

    final result = await db.execute(
      Sql.named('''
        INSERT INTO pets (user_id, name, breed, gender, birth_date, weight)
        VALUES (@userId, @name, @breed, @gender, @birth_date, @weight)
        RETURNING *
      '''),
      parameters: {'userId': userId, ...validation.assembledData},
    );

    return ApiResponse.ok(result.first.toColumnMap());
  });

  // Обновление питомца
  router.patch('/', (Request request) async {
    final userId = request.context['user_id'] as int;
    final petId = await _validatePetId(request);
    if (petId is! int) return petId;

    final data = await Parser.parseRequestData(request);
    if (data is! Map<String, dynamic>) return data;

    final validation = PetValidators.validatePetData(data);
    if (!validation.isValid) {
      return ApiResponse.badRequest(validation.errors.values.join(', '));
    }

    final assembledData = validation.assembledData;
    final fields = <String>[];
    final parameters = <String, dynamic>{'id': petId, 'user_id': userId};

    for (final field in ['name', 'breed', 'gender', 'birth_date', 'weight']) {
      if (assembledData.containsKey(field)) {
        fields.add('$field = @$field');
        parameters[field] = assembledData[field];
      }
    }

    if (fields.isEmpty) {
      return ApiResponse.badRequest('Нет данных для обновления');
    }

    final result = await db.execute(
      Sql.named('''
        UPDATE pets 
        SET ${fields.join(', ')}
        WHERE id = @id AND user_id = @user_id
        RETURNING *
      '''),
      parameters: parameters,
    );

    if (result.isEmpty) {
      return ApiResponse.notFound('Питомец не найден или не принадлежит вам');
    }

    return ApiResponse.ok(result.first.toColumnMap());
  });

  // Удаление питомца
  router.delete('/', (Request request) async {
    final userId = request.context['user_id'] as int;
    final petId = await _validatePetId(request);
    if (petId is! int) return petId;

    try {
      final result = await db.execute(
        Sql.named('''
          DELETE FROM pets 
          WHERE id = @id AND user_id = @user_id 
          RETURNING id
        '''),
        parameters: {'id': petId, 'user_id': userId},
      );

      if (result.isEmpty) {
        return ApiResponse.notFound('Питомец не найден');
      }

      return ApiResponse.ok({
        'status': 'deleted',
        'id': petId,
        'message': 'Питомец удален',
      });
    } catch (e) {
      return ApiResponse.internalServerError(e);
    }
  });

  // Загрузка фото питомца
  router.post('/with-photo', (Request request) async {
    try {
      final userId = request.context['user_id'] as int;

      final contentType = request.headers['Content-Type'];
      if (contentType == null || !contentType.contains('multipart/form-data')) {
        return ApiResponse.badRequest('Неверный Content-Type');
      }

      final boundary = contentType.split('boundary=').last;
      final transformer = MimeMultipartTransformer(boundary);
      final bodyStream = request.read();
      final parts = await transformer.bind(bodyStream).toList();

      String? fileName;
      List<int>? fileBytes;
      String? name;
      String? breed;
      String? gender;
      DateTime? birthDate;
      int? weight;

      for (final part in parts) {
        final headers = part.headers;
        final contentDisposition = headers['content-disposition'];

        if (contentDisposition != null) {
          if (contentDisposition.contains('name="photo"')) {
            final match = RegExp(r'filename="(.+)"').firstMatch(contentDisposition);
            if (match != null) {
              fileName = match.group(1);
              fileBytes = await part.toList().then((chunks) => chunks.expand((x) => x).toList());
            }
          } else if (contentDisposition.contains('name="name"')) {
            name = await utf8.decoder.bind(part).join();
          } else if (contentDisposition.contains('name="breed"')) {
            breed = await utf8.decoder.bind(part).join();
          } else if (contentDisposition.contains('name="gender"')) {
            gender = await utf8.decoder.bind(part).join();
          } else if (contentDisposition.contains('name="birth_date"')) {
            final birthStr = await utf8.decoder.bind(part).join();
            birthDate = DateTime.tryParse(birthStr);
          } else if (contentDisposition.contains('name="weight"')) {
            weight = int.tryParse(await utf8.decoder.bind(part).join());
          }
        }
      }

      if (name == null || gender == null || birthDate == null || weight == null) {
        return ApiResponse.badRequest('Обязательные поля отсутствуют');
      }

      String? photoUrl;
      if (fileName != null && fileBytes != null) {
        final file = File('uploads/$fileName');
        await file.writeAsBytes(fileBytes);
        photoUrl = '/uploads/$fileName';
      }

      final result = await db.execute(
        Sql.named('''
        INSERT INTO pets (user_id, name, breed, gender, birth_date, weight, photo_url)
        VALUES (@userId, @name, @breed, @gender, @birth_date, @weight, @photo_url)
        RETURNING *
      '''),
        parameters: {
          'userId': userId,
          'name': name,
          'breed': breed,
          'gender': gender,
          'birth_date': birthDate,
          'weight': weight,
          'photo_url': photoUrl,
        },
      );

      return ApiResponse.ok(result.first.toColumnMap());
    } catch (e) {
      return ApiResponse.internalServerError(e);
    }
  });

  return router;
}

dynamic _validatePetId(Request request) {
  final petIdStr = request.url.queryParameters['pet_id'];
  final petId = int.tryParse(petIdStr ?? '');
  return petId != null && petId > 0
      ? petId
      : ApiResponse.badRequest('Некорректный pet_id');
}