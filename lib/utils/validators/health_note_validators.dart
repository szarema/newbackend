import 'validation_result.dart';

class HealthNotesValidators {
  static const maxClinicLength = 100;
  static const maxDoctorLength = 50;
  static const maxGroomingSalonLength = 100;
  static const maxDietLength = 500;

  static ValidationResult validateCreateData(Map<String, dynamic> data) {
    final errors = <String, String>{};
    final assembledData = <String, dynamic>{};

    // Опциональные поля
    _validateField('clinic', data, errors, assembledData, maxClinicLength);
    _validateField('doctor', data, errors, assembledData, maxDoctorLength);
    _validateField(
      'grooming_salon',
      data,
      errors,
      assembledData,
      maxGroomingSalonLength,
    );
    _validateField('diet', data, errors, assembledData, maxDietLength);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      assembledData: assembledData,
    );
  }

  static ValidationResult validateUpdateData(Map<String, dynamic> data) {
    final errors = <String, String>{};
    final assembledData = <String, dynamic>{};

    _validateField('clinic', data, errors, assembledData, maxClinicLength);
    _validateField('doctor', data, errors, assembledData, maxDoctorLength);
    _validateField(
      'grooming_salon',
      data,
      errors,
      assembledData,
      maxGroomingSalonLength,
    );
    _validateField('diet', data, errors, assembledData, maxDietLength);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      assembledData: assembledData,
    );
  }

  static int? validateId(dynamic id) {
    if (id == null) return null;
    if (id is int) return id;
    return int.tryParse(id.toString());
  }

  static void _validateField(
    String field,
    Map data,
    Map<String, String> errors,
    Map<String, dynamic> assembledData,
    int maxLength,
  ) {
    if (!data.containsKey(field)) {
      assembledData[field] = null;
      return;
    }

    final value = data[field]?.toString().trim();
    if (value != null && value.isNotEmpty) {
      if (value.length > maxLength) {
        errors[field] = '$field: максимальная длина - $maxLength символов';
        return;
      }

      assembledData[field] = value;
      return;
    }

    errors[field] = '$field не может быть пустым';
  }
}
