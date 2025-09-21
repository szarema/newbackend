import 'validation_result.dart';

class MedicalRecordsValidators {
  static const maxChipLocationLength = 100;
  static const maxReproductionInfoLength = 500;
  static const maxYesNoLength = 50;
  static const maxAntiParasiteLength = 200;

  static ValidationResult validateCreateData(Map<String, dynamic> data) {
    final errors = <String, String>{};
    final assembledData = <String, dynamic>{};

    // Опциональные поля
    _validateField('has_chip', data, errors, assembledData, maxYesNoLength);
    _validateChipLocation(data, errors, assembledData);
    _validateField('has_vaccines', data, errors, assembledData, maxYesNoLength);
    _validateAntiParasite(data, errors, assembledData);
    _validateReproductionInfo(data, errors, assembledData);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      assembledData: assembledData,
    );
  }

  static ValidationResult validateUpdateData(Map<String, dynamic> data) {
    final errors = <String, String>{};
    final assembledData = <String, dynamic>{};

    _validateField('has_chip', data, errors, assembledData, maxYesNoLength);
    _validateChipLocation(data, errors, assembledData);
    _validateField('has_vaccines', data, errors, assembledData, maxYesNoLength);
    _validateAntiParasite(data, errors, assembledData);
    _validateReproductionInfo(data, errors, assembledData);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      assembledData: assembledData,
    );
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

  static void _validateChipLocation(
    Map data,
    Map<String, String> errors,
    Map<String, dynamic> assembledData,
  ) {
    if (!data.containsKey('chip_location')) {
      assembledData['chip_location'] = null;
      return;
    }

    final value = data['chip_location']?.toString().trim();
    if (value != null && value.isNotEmpty) {
      if (value.length > maxChipLocationLength) {
        errors['chip_location'] =
            'Максимальная длина - $maxChipLocationLength символов';
        return;
      }

      assembledData['chip_location'] = value;
    }
  }

  static void _validateAntiParasite(
    Map data,
    Map<String, String> errors,
    Map<String, dynamic> assembledData,
  ) {
    if (!data.containsKey('anti_parasite')) {
      assembledData['anti_parasite'] = null;
      return;
    }

    final value = data['anti_parasite']?.toString().trim();
    if (value != null && value.isNotEmpty) {
      if (value.length > maxAntiParasiteLength) {
        errors['anti_parasite'] =
            'Максимальная длина - $maxAntiParasiteLength символов';
        return;
      }

      assembledData['anti_parasite'] = value;
    }
  }

  static void _validateReproductionInfo(
    Map data,
    Map<String, String> errors,
    Map<String, dynamic> assembledData,
  ) {
    if (!data.containsKey('reproduction_info')) {
      assembledData['reproduction_info'] = null;
      return;
    }

    final value = data['reproduction_info']?.toString().trim();
    if (value != null && value.isNotEmpty) {
      if (value.length > maxReproductionInfoLength) {
        errors['reproduction_info'] =
            'Максимальная длина - $maxReproductionInfoLength символов';
        return;
      }

      assembledData['reproduction_info'] = value;
    }
  }

  static int? validatePetId(dynamic petId) {
    if (petId == null) return null;
    if (petId is int) return petId > 0 ? petId : null;
    final parsed = int.tryParse(petId.toString());
    return parsed != null && parsed > 0 ? parsed : null;
  }
}
