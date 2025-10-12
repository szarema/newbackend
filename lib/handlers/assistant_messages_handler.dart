import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';

final assistantMessages = <Map<String, dynamic>>[];

Future<Response> getMessagesHandler(Request request) async {
  return Response.ok(jsonEncode(assistantMessages), headers: {
    'Content-Type': 'application/json',
  });
}

Future<Response> postMessageHandler(Request request) async {
  final body = await request.readAsString();
  final data = jsonDecode(body);

  if (!data.containsKey('user_id') || !data.containsKey('role') || !data.containsKey('message')) {
    return Response(400, body: 'Missing required fields');
  }

  final userId = data['user_id'];

  // 🔍 Фильтр сообщения за последние 14 дней
  final now = DateTime.now();
  final fourteenDaysAgo = now.subtract(const Duration(days: 14));

  final recentMessages = assistantMessages.where((msg) {
    return msg['user_id'] == userId &&
        DateTime.parse(msg['created_at']).isAfter(fourteenDaysAgo);
  }).toList();

  if (recentMessages.length >= 20) {
    return Response(
      429,
      body: jsonEncode({
        'error': 'Вы достигли лимита запросов. Следующие 20 сообщений будут доступны через 14 дней с момента первого израсходованного запроса.'
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  final message = {
    'id': assistantMessages.length + 1,
    'user_id': userId,
    'role': data['role'],
    'message': data['message'],
    'created_at': now.toIso8601String(),
  };

  assistantMessages.add(message);

  return Response(201, body: jsonEncode(message), headers: {
    'Content-Type': 'application/json',
  });
}

Router assistantMessagesHandler(Connection db) {
  final router = Router();

  router.get('/', getMessagesHandler);
  router.post('/', postMessageHandler);

  return router;
}