import 'dart:convert';
import 'package:shelf/shelf.dart';

class ApiResponse {
  static const headers = {'Content-Type': 'application/json'};

  static Response ok(Object? body) {
    final jsonBody = body is String
        ? body
        : jsonEncode(_serializeData(body ?? {})); // 👈 добавили сериализацию
    return Response.ok(jsonBody, headers: headers);
  }

  static Response badRequest(String message) => Response.badRequest(
    body: jsonEncode({'error': message}),
    headers: headers,
  );

  static Response serverError(dynamic e) => Response.internalServerError(
    body: jsonEncode({'error': e.toString()}),
    headers: headers,
  );

  static Response notFound(String message) =>
      Response.notFound(jsonEncode({'error': message}), headers: headers);

  static Response unauthorized(String message) =>
      Response.unauthorized(jsonEncode({'error': message}), headers: headers);

  static Response forbidden(String message) =>
      Response.forbidden(jsonEncode({'error': message}), headers: headers);

  static Response internalServerError(dynamic e) =>
      Response.internalServerError(
        body: jsonEncode({
          'error': 'Внутренняя ошибка сервера: ${e.toString()}',
        }),
        headers: headers,
      );

  /// 🔥 сериализация DateTime
  static dynamic _serializeData(dynamic data) {
    if (data is DateTime) {
      return data.toIso8601String();
    } else if (data is List) {
      return data.map(_serializeData).toList();
    } else if (data is Map) {
      return data.map((k, v) => MapEntry(k, _serializeData(v)));
    } else {
      return data;
    }
  }
}
