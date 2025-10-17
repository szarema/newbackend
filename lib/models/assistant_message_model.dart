class AssistantMessageModel {
  final int id;
  final int userId;
  final String role; // 'user' или 'assistant'
  final String message;
  final DateTime createdAt;

  AssistantMessageModel({
    required this.id,
    required this.userId,
    required this.role,
    required this.message,
    required this.createdAt,
  });

  factory AssistantMessageModel.fromJson(Map<String, dynamic> json) {
    return AssistantMessageModel(
      id: json['id'],
      userId: json['user_id'],
      role: json['role'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'role': role,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }
}