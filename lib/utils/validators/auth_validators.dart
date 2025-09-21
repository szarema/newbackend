import 'package:bcrypt/bcrypt.dart';

import 'validation_result.dart';

class AuthValidators {
  static const minPasswordLength = 8;
  static const maxPasswordLength = 64;
  static const maxEmailLength = 128;
  static final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static ValidationResult validateRegistrationData(Map<String, dynamic> data) {
    final errors = <String, String>{};
    final assembledData = <String, dynamic>{};

    // Email validation
    final email = data['email']?.toString().trim().toLowerCase();
    if (email == null || email.isEmpty) {
      errors['email'] = 'Email обязателен';
    } else if (!emailRegex.hasMatch(email)) {
      errors['email'] = 'Некорректный формат email';
    } else if (email.length > maxEmailLength) {
      errors['email'] = 'Email слишком длинный';
    } else {
      assembledData['email'] = email;
    }

    // Password validation
    final password = data['password']?.toString();
    if (password == null || password.isEmpty) {
      errors['password'] = 'Пароль обязателен';
    } else if (password.length < minPasswordLength) {
      errors['password'] =
          'Минимальная длина пароля - $minPasswordLength символов';
    } else if (password.length > maxPasswordLength) {
      errors['password'] =
          'Максимальная длина пароля - $maxPasswordLength символов';
    } else {
      assembledData['password'] = password;
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      assembledData: assembledData,
    );
  }

  static ValidationResult validateLoginData(Map<String, dynamic> data) {
    final errors = <String, String>{};
    final assembledData = <String, dynamic>{};

    final email = data['email']?.toString().trim().toLowerCase();
    if (email == null || email.isEmpty) {
      errors['email'] = 'Email обязателен';
    } else {
      assembledData['email'] = email;
    }

    final password = data['password']?.toString();
    if (password == null || password.isEmpty) {
      errors['password'] = 'Пароль обязателен';
    } else {
      assembledData['password'] = password;
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      assembledData: assembledData,
    );
  }

  static String hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  static bool verifyPassword(String password, String hash) {
    return BCrypt.checkpw(password, hash);
  }
}
