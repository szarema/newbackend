import 'validation_result.dart';

class EventValidators {
  static ValidationResult validateCreateEvent(Map<String, dynamic> data) {
    final errors = <String, String>{};
    final assembled = <String, dynamic>{};

    // title (обязательное)
    final title = data['title'];
    if (title == null || title.toString().trim().isEmpty) {
      errors['title'] = 'Название события обязательно';
    } else {
      assembled['title'] = title.toString().trim();
    }

    // type (обязательное)
    final type = data['type'];
    if (type == null || type.toString().isEmpty) {
      errors['type'] = 'Тип события обязателен';
    } else {
      assembled['type'] = type;
    }

    // event_datetime (обязательное)
    final eventDateTime = data['event_datetime'];
    if (eventDateTime == null) {
      errors['event_datetime'] = 'Дата и время обязательны';
    } else {
      assembled['event_datetime'] = eventDateTime;
    }

    // reminder (обязательное)
    final reminder = data['reminder'];
    if (reminder == null) {
      errors['reminder'] = 'Напоминание обязательно';
    } else {
      assembled['reminder'] = reminder;
    }

    // repeat_type (обязательное)
    final repeatType = data['repeat_type'];
    if (repeatType == null) {
      errors['repeat_type'] = 'Тип повтора обязателен';
    } else {
      assembled['repeat_type'] = repeatType;
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      assembledData: assembled,
    );
  }
}