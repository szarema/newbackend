import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';

import '../utils/utils.dart';

Router medicalRecordsHandler(Connection db) {
  final router = Router();

  // Получение записи мед. книжки относительно питомца
  router.get('/', (Request request) async {
    try {
      final petId = request.url.queryParameters['pet_id'];
      final validatedPetId = MedicalRecordsValidators.validatePetId(petId);

      if (validatedPetId == null) {
        return ApiResponse.badRequest('Некорректный pet_id');
      }

      final result = await db.execute(
        Sql.named('SELECT * FROM medical_records WHERE pet_id = @id'),
        parameters: {'id': validatedPetId},
      );

      if (result.isEmpty) {
        return ApiResponse.ok(null);
      }

      return ApiResponse.ok(jsonEncode(result.first.toColumnMap()));
    } catch (e) {
      return ApiResponse.serverError(e);
    }
  });

  // Создание записи мед. книжки
  router.post('/', (Request request) async {
    try {
      final petId = request.url.queryParameters['pet_id'];
      final validatedPetId = HealthNotesValidators.validateId(petId);

      if (validatedPetId == null) {
        return ApiResponse.badRequest('Некорректный pet_id');
      }

      final data = await Parser.parseRequestData(request);
      if (data is! Map<String, dynamic>) return data;

      final validation = MedicalRecordsValidators.validateCreateData(data);
      if (!validation.isValid) {
        return ApiResponse.badRequest(validation.errors.values.join(', '));
      }

      final result = await db.execute(
        Sql.named('''
          INSERT INTO medical_records 
          (pet_id, has_chip, chip_location, has_vaccines, anti_parasite, reproduction_info)
          VALUES 
          (@pet_id, @has_chip, @chip_location, @has_vaccines, @anti_parasite, @reproduction_info)
          RETURNING *
        '''),
        parameters: {'pet_id': validatedPetId, ...validation.assembledData},
      );

      return ApiResponse.ok(jsonEncode(result.first.toColumnMap()));
    } catch (e) {
      if (e.toString().contains('23505')) {
        return ApiResponse.serverError(
          'Для этого питомца уже существует медицинская запись',
        );
      }

      return ApiResponse.serverError(e);
    }
  });

  // Обновление записи мед. книжки
  router.patch('/', (Request request) async {
    try {
      final id = request.url.queryParameters['id'];
      final validatedId = MedicalRecordsValidators.validatePetId(id);

      if (validatedId == null) {
        return ApiResponse.badRequest('Некорректный id');
      }

      final data = await Parser.parseRequestData(request);
      if (data is! Map<String, dynamic>) return data;

      final validation = MedicalRecordsValidators.validateUpdateData(data);
      if (!validation.isValid) {
        return ApiResponse.badRequest(validation.errors.values.join(', '));
      }

      if (validation.assembledData.isEmpty) {
        return ApiResponse.badRequest('Нет данных для обновления');
      }

      final result = await db.execute(
        Sql.named('''
          UPDATE medical_records SET
            ${validation.assembledData.keys.map((k) => '$k = @$k').join(', ')}
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
      return ApiResponse.serverError(e);
    }
  });

  // Удаление записи
  router.delete('/', (Request request) async {
    try {
      final id = request.url.queryParameters['id'];
      final validatedId = MedicalRecordsValidators.validatePetId(id);

      if (validatedId == null) {
        return ApiResponse.badRequest('Некорректный id');
      }

      final result = await db.execute(
        Sql.named('DELETE FROM medical_records WHERE id = @id RETURNING id'),
        parameters: {'id': validatedId},
      );

      if (result.isEmpty) {
        return ApiResponse.notFound('Запись не найдена');
      }

      return ApiResponse.ok(
        jsonEncode({'status': 'deleted', 'id': validatedId}),
      );
    } catch (e) {
      return ApiResponse.serverError(e);
    }
  });

  return router;
}
