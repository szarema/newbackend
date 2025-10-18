import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';

Future<Response> getMessagesHandler(Request request, Connection db) async {
  try {
    final result = await db.execute(
      Sql.named('SELECT * FROM assistant_messages ORDER BY created_at DESC'),
    );

    final messages = result.map((row) {
      return {
        'id': row[0],
        'user_id': row[1],
        'role': row[2],
        'message': row[3],
        'created_at': (row[4] as DateTime?).toString(),
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

Future<Response> postMessageHandler(Request request, Connection db) async {
  try {
    final body = await request.readAsString();
    final data = jsonDecode(body);

    if (!data.containsKey('user_id') ||
        !data.containsKey('role') ||
        !data.containsKey('message')) {
      return Response(400, body: 'Missing required fields');
    }

    final userId = data['user_id'];
    final role = data['role'];
    final message = data['message'];

    // final result = await db.execute(Sql.named('''
    //   SELECT COUNT(*) FROM assistant_messages
    //   WHERE user_id = @user_id AND created_at > NOW() - INTERVAL '14 days'
    // '''), parameters: {'user_id': userId});


    // Подсчет только user‑сообщений за последние 14 дней
    final result = await db.execute(Sql.named('''
      SELECT COUNT(*) FROM assistant_messages
      WHERE user_id = @user_id
      AND role = 'user'
      AND created_at > NOW() - INTERVAL '14 days'
    '''), parameters: {'user_id': userId});


    final count = result.first[0] as int;

    if (count >= 5) {
      return Response(
        429,
        body: jsonEncode({
          'error':
          'Вы достигли лимита запросов. Следующие сообщения будут доступны через 14 дней с момента первого израсходованного запроса.'
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final createdAt = data['created_at'];

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
      'created_at': (inserted[1] as DateTime).toString(),
    };

    return Response(201, body: jsonEncode(newMessage), headers: {
      'Content-Type': 'application/json',
    });
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'Database error: $e'}),
    );
  }
}

Router assistantMessagesHandler(Connection db) {
  final router = Router();

  // router.get('/', (Request req) => getMessagesHandler(req, db));
  // router.post('/', (Request req) => postMessageHandler(req, db));

  // router.get('/messages', getMessagesHandler);
  // router.post('/messages', postMessageHandler);

  router.get('/messages', (Request req) => getMessagesHandler(req, db));
  router.post('/messages', (Request req) => postMessageHandler(req, db));

  return router;
}