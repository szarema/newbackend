import 'validation_result.dart';

class PetValidators {
  static const minAge = 0;
  static const maxAge = 100;
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
    _validateAge(data, errors);
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

  static void _validateAge(Map data, Map<String, String> errors) {
    if (!data.containsKey('age')) return;

    final age = _parseNumber(data['age']);
    if (age == null) {
      errors['age'] = 'Некорректный формат возраста';
      return;
    }

    if (age < minAge || age > maxAge) {
      errors['age'] = 'Возраст должен быть между $minAge и $maxAge';
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

  static Map<String, dynamic> _assembleData(Map data) {
    return {
      'name': data['name']?.toString().trim(),
      'breed': data['breed']?.toString().trim(),
      'gender': data['gender']?.toString().toLowerCase().trim(),
      'age': _parseNumber(data['age']),
      'weight': _parseNumber(data['weight']),
    };
  }
}
