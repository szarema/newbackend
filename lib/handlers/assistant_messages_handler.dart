import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../constants/jwt_secret.dart';

/// Извлекаем user_id из JWT токена
int? getUserIdFromToken(Request request) {
  final authHeader = request.headers['Authorization'];
  if (authHeader == null || !authHeader.startsWith('Bearer ')) return null;

  final token = authHeader.substring(7);
  try {
    final jwt = JWT.verify(token, SecretKey(jwtSecret));
    return jwt.payload['user_id'] as int?;
  } catch (e) {
    return null;
  }
}

/// Получение сообщений только текущего пользователя
Future<Response> getMessagesHandler(Request request, Connection db) async {
  try {
    final userId = getUserIdFromToken(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}));
    }

    final result = await db.execute(Sql.named('''
      SELECT * FROM assistant_messages
      WHERE user_id = @user_id
      ORDER BY created_at DESC
    '''), parameters: {'user_id': userId});

    final messages = result.map((row) {
      return {
        'id': row[0],
        'user_id': row[1],
        'role': row[2],
        'message': row[3],
        'created_at': (row[4] as DateTime?)?.toIso8601String(),
      };
    }).toList();

    return Response.ok(jsonEncode(messages), headers: {
      'Content-Type': 'application/json',
    });
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'Database error: $e'}),
    );
  }
}

/// Сохранение сообщений с проверкой лимитов
Future<Response> postMessageHandler(Request request, Connection db) async {
  try {
    final userId = getUserIdFromToken(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}));
    }

    final body = await request.readAsString();
    final data = jsonDecode(body);

    if (!data.containsKey('role') || !data.containsKey('message')) {
      return Response(400, body: 'Missing required fields');
    }

    final role = data['role'];
    final message = data['message'];
    final createdAt = data['created_at'];

    // Подсчёт только USER-сообщений за последние 14 дней
    final result = await db.execute(Sql.named('''
      SELECT COUNT(*) FROM assistant_messages
      WHERE user_id = @user_id
        AND role = 'user'
        AND created_at > NOW() - INTERVAL '14 days'
    '''), parameters: {'user_id': userId});

    final count = result.first[0] as int;

    // Ограничиваем только user-сообщения, ассистент всегда может сохраняться
    if (role == 'user' && count >= 5) {
      return Response(
        429,
        body: jsonEncode({
          'error':
          'Вы достигли лимита запросов. Следующие сообщения будут доступны через 14 дней с момента первого израсходованного запроса.'
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final insertResult = await db.execute(Sql.named('''
      INSERT INTO assistant_messages (user_id, role, message, created_at)
      VALUES (@user_id, @role, @message, @created_at)
      RETURNING id, created_at
    '''), parameters: {
      'user_id': userId,
      'role': role,
      'message': message,
      'created_at': DateTime.parse(createdAt),
    });

    final inserted = insertResult.first;

    final newMessage = {
      'id': inserted[0],
      'user_id': userId,
      'role': role,
      'message': message,
      'created_at': (inserted[1] as DateTime).toIso8601String(),
    };

    return Response(201, body: jsonEncode(newMessage), headers: {
      'Content-Type': 'application/json',
    });
  } catch (e) {
    print(' Ошибка в postMessageHandler: $e');
    return Response.internalServerError(
      body: jsonEncode({'error': 'Database error: $e'}),
    );
  }
}

Router assistantMessagesHandler(Connection db) {
  final router = Router();

  router.get('/messages', (Request req) => getMessagesHandler(req, db));
  router.post('/messages', (Request req) => postMessageHandler(req, db));

  return router;
}