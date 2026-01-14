import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';

import '../utils/utils.dart';
import '../utils/validators/event_validators.dart';

Router eventsHandler(Connection db) {
  final router = Router();

  /// Создание события
  router.post('/', (Request request) async {
    try {
      final userId = request.context['user_id'] as int;

      final data = await Parser.parseRequestData(request);
      if (data is! Map<String, dynamic>) return data;

      final petId = data['pet_id'];
      if (petId == null) {
        return ApiResponse.badRequest('pet_id обязателен');
      }

      final validation = EventValidators.validateCreateEvent(data);
      if (!validation.isValid) {
        return ApiResponse.badRequest(
          validation.errors.values.join(', '),
        );
      }

      final result = await db.execute(
        Sql.named('''
          INSERT INTO events (
            user_id,
            pet_id,
            title,
            type,
            event_datetime,
            reminder,
            repeat_type
          )
          VALUES (
            @user_id,
            @pet_id,
            @title,
            @type,
            @event_datetime,
            @reminder,
            @repeat_type
          )
          RETURNING *
        '''),
        parameters: {
          'user_id': userId,
          'pet_id': petId,
          ...validation.assembledData,
        },
      );

      return ApiResponse.ok(result.first.toColumnMap());
    } catch (e) {
      return ApiResponse.internalServerError(e);
    }
  });

  return router;
}