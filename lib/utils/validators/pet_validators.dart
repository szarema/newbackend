import 'validation_result.dart';

class PetValidators {
  static const minWeight = 1;
  static const maxWeight = 999;
  static const maxBreedLength = 100;
  static final allowedGenders = {'самец', 'самка'};

  static ValidationResult validatePetData(Map<String, dynamic> data) {
    final errors = <String, String>{};

    if (data['name']?.toString().trim().isEmpty ?? true) {
      errors['name'] = 'Имя обязательно для заполнения';
    }

    _validateGender(data, errors);
    _validateBirthDate(data, errors); //  новая проверка
    _validateWeight(data, errors);
    _validateBreed(data, errors);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      assembledData: _assembleData(data),
    );
  }

  static void _validateGender(Map data, Map<String, String> errors) {
    if (!data.containsKey('gender')) return;

    final gender = data['gender']?.toString().toLowerCase().trim();
    if (gender != null && gender.isNotEmpty) {
      if (!allowedGenders.contains(gender)) {
        errors['gender'] =
        'Неверно указан гендер. Допустимые значения: ${allowedGenders.join(', ')}';
      }
    }
  }

  ///  Новая проверка birth_date
  static void _validateBirthDate(Map data, Map<String, String> errors) {
    if (!data.containsKey('birth_date')) return;

    final birthDateStr = data['birth_date']?.toString().trim();
    if (birthDateStr == null || birthDateStr.isEmpty) {
      errors['birth_date'] = 'Дата рождения обязательна';
      return;
    }

    // Проверим формат YYYY-MM-DD
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!regex.hasMatch(birthDateStr)) {
      errors['birth_date'] =
      'Неверный формат даты рождения. Используйте YYYY-MM-DD';
    }
  }

  static void _validateWeight(Map data, Map<String, String> errors) {
    if (!data.containsKey('weight')) return;

    final weight = _parseNumber(data['weight']);
    if (weight == null) {
      errors['weight'] = 'Некорректный формат веса';
      return;
    }

    final value = weight.toInt();
    if (value < minWeight || value > maxWeight) {
      errors['weight'] = 'Вес должен быть между $minWeight и $maxWeight кг';
    }
  }

  static void _validateBreed(Map data, Map<String, String> errors) {
    if (!data.containsKey('breed')) return;

    final breed = data['breed']?.toString().trim();
    if (breed != null && breed.isNotEmpty) {
      if (breed.length > maxBreedLength) {
        errors['breed'] =
        'Максимальная длина породы - $maxBreedLength символов';
      }
    }
  }

  static num? _parseNumber(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;

    final valueStr = value.toString();
    return int.tryParse(valueStr);
  }

  ///  Сбор данных
  static Map<String, dynamic> _assembleData(Map data) {
    return {
      'name': data['name']?.toString().trim(),
      'breed': data['breed']?.toString().trim(),
      'gender': data['gender']?.toString().toLowerCase().trim(),
      'birth_date': data['birth_date']?.toString().trim(), //
      'weight': _parseNumber(data['weight']),
    };
  }
}
