import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';

import '../utils/utils.dart';

Router healthNotesHandler(Connection db) {
  final router = Router();

  // Получение записи Ухода по здоровью относительно питомца
  router.get('/', (Request request) async {
    try {
      final petId = request.url.queryParameters['pet_id'];
      final validatedPetId = HealthNotesValidators.validateId(petId);

      if (validatedPetId == null) {
        return ApiResponse.badRequest('Некорректный pet_id');
      }

      final result = await db.execute(
        Sql.named('SELECT * FROM health_notes WHERE pet_id = @id'),
        parameters: {'id': validatedPetId},
      );

      if (result.isEmpty) {
        return Response(204); // No Content
        //return ApiResponse.ok(null);
      }

      final record = result.first.toColumnMap();

      // Проверка: если запись пуста (например, содержит только id/pet_id), считаем её невалидной
      if (record['id'] == null) {
        return ApiResponse.ok(null);
      }

      return ApiResponse.ok(jsonEncode(record));
    } catch (e) {
      return ApiResponse.internalServerError(e);
    }
  });

  // Создание записи Ухода по здоровью
  router.post('/', (Request request) async {
    try {
      final petId = request.url.queryParameters['pet_id'];
      final validatedPetId = HealthNotesValidators.validateId(petId);

      if (validatedPetId == null) {
        return ApiResponse.badRequest('Некорректный pet_id');
      }

      final data = await Parser.parseRequestData(request);
      if (data is! Map<String, dynamic>) return data;

      final validation = HealthNotesValidators.validateCreateData(data);
      if (!validation.isValid) {
        return ApiResponse.badRequest(validation.errors.values.join(', '));
      }

      if (validation.assembledData.isEmpty) {
        return ApiResponse.badRequest('Нет данных для создания');
      }

      final result = await db.execute(
        Sql.named('''
        INSERT INTO health_notes
        (pet_id, clinic, doctor, grooming_salon, diet)
        VALUES (@pet_id, @clinic, @doctor, @grooming_salon, @diet)
        RETURNING *
        '''),
        parameters: {'pet_id': validatedPetId, ...validation.assembledData},
      );

      return ApiResponse.ok(jsonEncode(result.first.toColumnMap()));
    } catch (e) {
      if (e.toString().contains('23505')) {
        return ApiResponse.serverError(
          'Для этого питомца уже существует запись Ухода по здоровью',
        );
      }

      return ApiResponse.internalServerError(e);
    }
  });

  // Обновление записи Ухода по здоровью
  router.patch('/', (Request request) async {
    try {
      final id = request.url.queryParameters['id'];
      final validatedId = HealthNotesValidators.validateId(id);

      if (validatedId == null) {
        return ApiResponse.badRequest('Некорректный id');
      }

      final data = await Parser.parseRequestData(request);
      if (data is! Map<String, dynamic>) return data;

      final validation = HealthNotesValidators.validateUpdateData(data);
      if (!validation.isValid) {
        return ApiResponse.badRequest(validation.errors.values.join(', '));
      }

      if (validation.assembledData.isEmpty) {
        return ApiResponse.badRequest('Нет данных для обновления');
      }

      final result = await db.execute(
        Sql.named('''
        UPDATE health_notes SET
          clinic = @clinic,
          doctor = @doctor,
          grooming_salon = @grooming_salon,
          diet = @diet
        WHERE id = @id
        RETURNING *
        '''),
        parameters: {...validation.assembledData, 'id': validatedId},
      );

      if (result.isEmpty) {
        return ApiResponse.notFound('Запись не найдена');
      }

      return ApiResponse.ok(jsonEncode(result.first.toColumnMap()));
    } catch (e) {
      return ApiResponse.internalServerError(e);
    }
  });

  // Удаление Ухода по здоровью
  router.delete('/', (Request request) async {
    try {
      final id = request.url.queryParameters['id'];
      final validatedId = HealthNotesValidators.validateId(id);

      if (validatedId == null) {
        return ApiResponse.badRequest('Некорректный pet_id');
      }

      final result = await db.execute(
        Sql.named('DELETE FROM health_notes WHERE id = @id RETURNING id'),
        parameters: {'id': validatedId},
      );

      if (result.isEmpty) {
        return ApiResponse.notFound('Запись не найдена');
      }

      return ApiResponse.ok(jsonEncode({'status': 'deleted'}));
    } catch (e) {
      return ApiResponse.internalServerError(e);
    }
  });

  return router;
}
