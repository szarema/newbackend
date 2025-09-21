import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import '../utils/utils.dart';

Router notesHandler(Connection db) {
  final router = Router();

  // Получение всех заметок по pet_id
  router.get('/', (Request request) async {
    try {
      final petId = request.url.queryParameters['pet_id'];
      final validatedId = NotesValidators.validatePetId(petId);

      if (validatedId == null) {
        return ApiResponse.badRequest('Некорректный pet_id');
      }

      final result = await db.execute(
        Sql.named(
          'SELECT * FROM notes WHERE pet_id = @id ORDER BY event_date DESC',
        ),
        parameters: {'id': validatedId},
      );

      final preparedData =
          result.map((row) {
            final map = row.toColumnMap();
            _convertDateTime(map, 'event_date');
            return map;
          }).toList();

      return ApiResponse.ok(jsonEncode(preparedData));
    } catch (e) {
      return ApiResponse.serverError(e);
    }
  });

  // Создание заметки
  router.post('/', (Request request) async {
    try {
      final petId = request.url.queryParameters['pet_id'];
      final validatedPetId = NotesValidators.validatePetId(petId);

      if (validatedPetId == null) {
        return ApiResponse.badRequest('Некорректный pet_id');
      }

      final data = await Parser.parseRequestData(request);
      if (data is! Map<String, dynamic>) return data;

      final validation = NotesValidators.validateNoteData(data);
      if (!validation.isValid) {
        return ApiResponse.badRequest(validation.errors.values.join(', '));
      }

      final petExists = await NotesValidators.petExists(validatedPetId, db);

      if (!petExists) {
        return ApiResponse.notFound('Питомец не найден');
      }

      final result = await db.execute(
        Sql.named('''
        INSERT INTO notes (pet_id, text, event_date)
        VALUES (@pet_id, @text,  @event_date)
        RETURNING *
      '''),
        parameters: {'pet_id': validatedPetId, ...validation.assembledData},
      );

      final preparedData = result.map((row) {
        final map = row.toColumnMap();
        _convertDateTime(map, 'event_date');
        return map;
      }).toList();

      return ApiResponse.ok(preparedData.first); // ✅ без jsonEncode
    } catch (e) {
      return ApiResponse.serverError(e);
    }
  });

  // Обновление заметки
  router.patch('/', (Request request) async {
    try {
      final id = request.url.queryParameters['id'];
      final validatedId = NotesValidators.validatePetId(id);

      if (validatedId == null) {
        return ApiResponse.badRequest('Некорректный id');
      }

      final data = await Parser.parseRequestData(request);
      if (data is! Map<String, dynamic>) return data;

      final validation = NotesValidators.validateNoteData(data);
      if (!validation.isValid) {
        return ApiResponse.badRequest(validation.errors.values.join(', '));
      }

      final result = await db.execute(
        Sql.named('''
          UPDATE notes SET
            text = @text,            
            event_date = @event_date
          WHERE id = @id
          RETURNING *
        '''),
        parameters: {...validation.assembledData, 'id': validatedId},
      );

      if (result.isEmpty) {
        return ApiResponse.notFound('Заметка не найдена');
      }

      final preparedData =
          result.map((row) {
            final map = row.toColumnMap();
            _convertDateTime(map, 'event_date');
            return map;
          }).toList();

      return ApiResponse.ok(jsonEncode(preparedData.first));
    } catch (e) {
      return ApiResponse.serverError(e);
    }
  });

  // Удаление заметки
  router.delete('/', (Request request) async {
    try {
      final id = request.url.queryParameters['id'];
      final validatedId = NotesValidators.validatePetId(id);

      if (validatedId == null) {
        return ApiResponse.badRequest('Некорректный id');
      }

      final result = await db.execute(
        Sql.named('DELETE FROM notes WHERE id = @id RETURNING id'),
        parameters: {'id': validatedId},
      );

      if (result.isEmpty) {
        return ApiResponse.notFound('Заметка не найдена');
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

void _convertDateTime(Map<String, dynamic> map, String key) {
  if (map[key] is DateTime) {
    map[key] = (map[key] as DateTime).toIso8601String();
  }
}
