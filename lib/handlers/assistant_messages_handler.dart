import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../constants/jwt_secret.dart';
import '../prompt/prompt_text.dart';

int? getUserIdFromToken(Request request) {
  final authHeader = request.headers['Authorization'];
  if (authHeader == null || !authHeader.startsWith('Bearer ')) return null;

  final token = authHeader.substring(7);
  try {
    final jwt = JWT.verify(token, SecretKey(jwtSecret));
    return jwt.payload['user_id'] as int?;
  } catch (_) {
    return null;
  }
}

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

    return Response.ok(jsonEncode(messages),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(
        body: jsonEncode({'error': 'Database error: $e'}));
  }
}

Future<Response> postMessageHandler(Request request, Connection db) async {
  try {
    final userId = getUserIdFromToken(request);
    if (userId == null) {
      return Response(401, body: jsonEncode({'error': 'Unauthorized'}));
    }

    final body = await request.readAsString();
    final data = jsonDecode(body);
    final role = data['role'];
    final message = data['message'];
    final createdAt = data['created_at'];

    if (role == null || message == null) {
      return Response(400, body: jsonEncode({'error': 'Missing required fields'}));
    }

    if (role == 'user') {
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
            'error': 'Вы достигли лимита запросов. Попробуйте снова через 14 дней.'
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }
    }

    final now = DateTime.now();

    if (role == 'user') {
      await db.execute(Sql.named('''
        INSERT INTO assistant_messages (user_id, role, message, created_at)
        VALUES (@user_id, 'user', @message, @created_at)
      '''), parameters: {
        'user_id': userId,
        'message': message,
        'created_at': now,
      });

      final deepseekKey = Platform.environment['DEEPSEEK_API_KEY'];
      print('🔐 DEEPSEEK_API_KEY = $deepseekKey');

      if (deepseekKey == null) {
        return Response.internalServerError(
            body: jsonEncode({'error': 'Missing DeepSeek API key'}));
      }

      final uri = Uri.parse('https://api.deepseek.com/v1/chat/completions');
      final payload = {
        'model': 'deepseek-chat',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': message}
        ],
      };

      print('📤 payload = ${jsonEncode(payload)}');
      print('🧠 systemPrompt = $systemPrompt');

      final aiResp = await http.post(uri,
          headers: {
            'Authorization': 'Bearer $deepseekKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload));

      print('📥 Response status: ${aiResp.statusCode}');
      print('📥 Response body: ${aiResp.body}');

      if (aiResp.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(aiResp.bodyBytes));
        final assistantReply = decoded['choices'][0]['message']['content'];

        await db.execute(Sql.named('''
          INSERT INTO assistant_messages (user_id, role, message, created_at)
          VALUES (@user_id, 'assistant', @message, @created_at)
        '''), parameters: {
          'user_id': userId,
          'message': assistantReply,
          'created_at': now,
        });

        return Response.ok(
            jsonEncode({'assistant_reply': assistantReply}),
            headers: {'Content-Type': 'application/json'});
      } else {
        return Response.internalServerError(
            body: jsonEncode({'error': 'AI request failed'}));
      }
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

    return Response(201,
        body: jsonEncode(newMessage),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    print('❌ Ошибка в postMessageHandler: $e');
    return Response.internalServerError(
        body: jsonEncode({'error': 'Internal error: $e'}));
  }
}

Router assistantMessagesHandler(Connection db) {
  final router = Router();
  router.get('/messages', (req) => getMessagesHandler(req, db));
  router.post('/messages', (req) => postMessageHandler(req, db));
  return router;
}