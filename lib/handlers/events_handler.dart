import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';

import '../utils/utils.dart';
import '../utils/validators/event_validators.dart';

Router eventsHandler(Connection db) {
  final router = Router();

  /// CREATE EVENT
  router.post('/', (Request request) async {
    print('🔥 POST /events CALLED');
    print('Query params: ${request.url.queryParameters}');
    try {
      final userId = request.context['user_id'] as int;
      // pet_id из query
      final petIdStr = request.url.queryParameters['pet_id'];
      final petId = int.tryParse(petIdStr ?? '');

      if (petId == null) {
        return ApiResponse.badRequest('Некорректный pet_id');
      }

      final data = await Parser.parseRequestData(request);
      print('📦 BODY DATA: $data');
      if (data is! Map<String, dynamic>) return data;

      // Валидация
      final validation = EventValidators.validateCreate(data);
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
            repeat
          )
          VALUES (
            @user_id,
            @pet_id,
            @title,
            @type,
            @event_datetime,
            @reminder,
            @repeat
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
      print('❌ ERROR INSERT EVENT: $e');
      return ApiResponse.internalServerError(e);
    }
  });

  return router;
}