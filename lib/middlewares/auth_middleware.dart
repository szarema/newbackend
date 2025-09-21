import 'dart:convert';

import 'package:backend/constants/jwt_secret.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';

Future<int?> _getUserIdFromRequest(Request request) async {
  final authHeader = request.headers['authorization'];
  if (authHeader == null || !authHeader.startsWith('Bearer ')) return null;

  final token = authHeader.split(' ').last;
  try {
    final jwt = JWT.verify(token, SecretKey(jwtSecret));
    return jwt.payload['user_id'] as int?;
  } catch (_) {
    return null;
  }
}

Middleware checkAuth() {
  return (Handler innerHandler) {
    return (Request request) async {
      final userId = await _getUserIdFromRequest(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Токен отсутствует или он некорректный'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
      // Добавим user_id в запрос для дальнейшего использования
      return innerHandler(request.change(context: {'user_id': userId}));
    };
  };
}

Middleware authGuard() => (Handler innerHandler) {
  return (Request request) {
    final userId = request.context['user_id'] as int?;
    return userId != null
        ? innerHandler(request)
        : Response.forbidden(
          jsonEncode({'error': 'Требуется авторизация'}),
          headers: {'Content-Type': 'application/json'},
        );
  };
};
