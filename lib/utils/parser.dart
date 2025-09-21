import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'api_response.dart';

class Parser {
  static Future<dynamic> parseRequestData(Request request) async {
    try {
      return jsonDecode(await request.readAsString());
    } catch (e) {
      return ApiResponse.badRequest('Некорректный JSON формат');
    }
  }
}
