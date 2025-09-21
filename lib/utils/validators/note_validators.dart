import 'package:postgres/postgres.dart';

import 'validation_result.dart';

class NotesValidators {
  static const maxTextLength = 2000;
  static const minTextLength = 1;
  static final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$'); //2025-01-19

  static ValidationResult validateNoteData(Map<String, dynamic> data) {
    final errors = <String, String>{};
    final assembledData = <String, dynamic>{};

    // Валидация текста
    final text = data['text']?.toString().trim();
    if (text == null || text.isEmpty) {
      errors['text'] = 'Текст заметки обязателен';
    } else if (text.length < minTextLength) {
      errors['text'] = 'Минимальная длина текста - $minTextLength символов';
    } else if (text.length > maxTextLength) {
      errors['text'] = 'Максимальная длина текста - $maxTextLength символов';
    } else {
      assembledData['text'] = text;
    }

    if (!data.containsKey('event_date')) {
      errors['event_date'] = 'Дата обязательна';
    } else {
      final eventDate = _parseDate(data['event_date']);
      if (eventDate == null) {
        errors['event_date'] =
            'Некорректный формат даты (ожидается ГГГГ-ММ-ДД)';
      } else {
        assembledData['event_date'] = eventDate;
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      assembledData: assembledData,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final strValue = value.toString();
    if (!dateRegex.hasMatch(strValue)) return null;
    try {
      final date = DateTime.parse(strValue);
      return DateTime.utc(date.year, date.month, date.day);
    } catch (_) {
      return null;
    }
  }

  static int? validatePetId(dynamic petId) {
    if (petId == null) return null;
    if (petId is int) return petId > 0 ? petId : null;
    final parsed = int.tryParse(petId.toString());
    return parsed != null && parsed > 0 ? parsed : null;
  }

  static Future<bool> petExists(int petId, Connection db) async {
    final result = await db.execute(
      Sql.named('SELECT 1 FROM pets WHERE id = @id'),
      parameters: {'id': petId},
    );
    return result.isNotEmpty;
  }
}
