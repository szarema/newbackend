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

  final message = {
    'id': assistantMessages.length + 1,
    'user_id': data['user_id'],
    'role': data['role'],
    'message': data['message'],
    'created_at': DateTime.now().toIso8601String(),
  };

  assistantMessages.add(message);

  return Response(201, body: jsonEncode(message), headers: {
    'Content-Type': 'application/json',
  });
}

/// <------ ДОБАВЬ ЭТУ ФУНКЦИЮ --------->

Router assistantMessagesHandler(Connection db) {
  final router = Router();

  router.get('/', getMessagesHandler);
  router.post('/', postMessageHandler);

  return router;
}