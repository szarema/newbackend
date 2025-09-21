import 'dart:convert';

import 'package:backend/constants/jwt_secret.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';

import '../utils/utils.dart';

Router authHandler(Connection db) {
  final router = Router();

  // Регистрация
  router.post('/register', (Request request) async {
    try {
      final data = await Parser.parseRequestData(request);
      if (data is! Map<String, dynamic>) return data;

      final validation = AuthValidators.validateRegistrationData(data);
      if (!validation.isValid) {
        return ApiResponse.badRequest(validation.errors.values.join(', '));
      }

      final assembledData = validation.assembledData;
      final hash = AuthValidators.hashPassword(assembledData['password']);

      final result = await db.execute(
        Sql.named('''
            INSERT INTO users (email, password_hash)
            VALUES (@email, @password)
            RETURNING *
          '''),
        parameters: {'email': assembledData['email'], 'password': hash},
      );

      final user = result.first;
      final userId = user[0] as int;

      final jwt = JWT({'user_id': userId});
      final token = jwt.sign(SecretKey(jwtSecret));

      return ApiResponse.ok(jsonEncode({'token': token}));
    } catch (e) {
      if (e.toString().contains('23505')) {
        return ApiResponse.serverError(
          'Пользователь с таким e-mail уже существует',
        );
      }

      return ApiResponse.internalServerError(e);
    }
  });

  // Авторизация
  router.post('/login', (Request request) async {
    try {
      final data = await Parser.parseRequestData(request);
      if (data is! Map<String, dynamic>) return data;

      final validation = AuthValidators.validateLoginData(data);
      if (!validation.isValid) {
        return ApiResponse.badRequest(validation.errors.values.join(', '));
      }

      final assembledData = validation.assembledData;
      final result = await db.execute(
        Sql.named('''
          SELECT id, password_hash FROM users
          WHERE email = @email
        '''),
        parameters: {'email': assembledData['email']},
      );

      if (result.isEmpty) {
        return ApiResponse.unauthorized('Неверные учетные данные');
      }

      final user = result.first;
      final userId = user[0] as int;
      final storedHash = user[1] as String;

      if (!AuthValidators.verifyPassword(
        assembledData['password'],
        storedHash,
      )) {
        return ApiResponse.unauthorized('Неверные учетные данные');
      }

      final jwt = JWT({'user_id': userId});
      final token = jwt.sign(SecretKey(jwtSecret));

      return ApiResponse.ok(jsonEncode({'token': token}));
    } catch (e) {
      return ApiResponse.serverError(e);
    }
  });






  // Сброс пароля
  router.post('/reset-password', (Request request) async {
    try {
      final data = await Parser.parseRequestData(request);
      if (data is! Map<String, dynamic>) return data;

      final email = data['email']?.toString().trim();
      final newPassword = data['newPassword']?.toString();

      if (email == null || email.isEmpty) {
        return ApiResponse.badRequest('Email обязателен');
      }

      if (newPassword == null || newPassword.isEmpty) {
        return ApiResponse.badRequest('Новый пароль обязателен');
      }

      // Проверка, существует ли пользователь с таким email
      final result = await db.execute(
        Sql.named('SELECT id FROM users WHERE email = @e'),
        parameters: {'e': email},
      );

      if (result.isEmpty) {
        return ApiResponse.notFound('Пользователь с таким email не найден');
      }

      // Хэширование нового пароля и обновление в базе
      final newHash = AuthValidators.hashPassword(newPassword);
      await db.execute(
        Sql.named('''
        UPDATE users SET password_hash = @p WHERE email = @e
      '''),
        parameters: {'e': email, 'p': newHash},
      );

      return ApiResponse.ok(jsonEncode({'message': 'Пароль обновлён'}));
    } catch (e) {
      return ApiResponse.internalServerError(e);
    }
  });



  return router;
}
