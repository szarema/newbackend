class ValidationResult {
  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.assembledData,
  });

  final bool isValid;
  final Map<String, String> errors;
  final Map<String, dynamic> assembledData;
}
