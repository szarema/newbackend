class EventValidators {
  static ValidationResult validateCreate(Map<String, dynamic> data) {
    final errors = <String, String>{};
    final assembled = <String, dynamic>{};

    // title
    if (data['title'] == null || data['title'].toString().trim().isEmpty) {
      errors['title'] = 'Название обязательно';
    } else {
      assembled['title'] = data['title'].toString().trim();
    }

    // type
    if (data['type'] == null) {
      errors['type'] = 'Тип обязателен';
    } else {
      assembled['type'] = data['type'];
    }

    // event_datetime
    if (data['event_datetime'] == null) {
      errors['event_datetime'] = 'Дата и время обязательны';
    } else {
      final dt = DateTime.tryParse(data['event_datetime']);
      if (dt == null) {
        errors['event_datetime'] = 'Некорректная дата';
      } else {
        assembled['event_datetime'] = dt.toIso8601String();
      }
    }

    // reminder
    if (data['reminder'] == null) {
      errors['reminder'] = 'Напоминание обязательно';
    } else {
      assembled['reminder'] = data['reminder'];
    }

    // repeat
    if (data['repeat'] == null) {
      errors['repeat'] = 'Повторение обязательно';
    } else {
      assembled['repeat'] = data['repeat'];
    }

    return ValidationResult(errors, assembled);
  }
}

/// 🔹 Вспомогательный класс
class ValidationResult {
  final Map<String, String> errors;
  final Map<String, dynamic> assembledData;

  ValidationResult(this.errors, this.assembledData);

  bool get isValid => errors.isEmpty;
}