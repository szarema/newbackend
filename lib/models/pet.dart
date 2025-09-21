class Pet {
  const Pet({
    required this.id,
    required this.userId,
    required this.name,
    required this.breed,
    required this.gender,
    required this.age,
    required this.weight,
  });

  final int id;
  final int userId;
  final String name;
  final String? breed;
  final String? gender;
  final int? age;
  final int? weight;

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'],
      userId: map['user_id'],
      name: map['name'],
      breed: map['breed'],
      gender: map['gender'],
      age: map['age'],
      weight: map['weight'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'breed': breed,
      'gender': gender,
      'age': age,
      'weight': weight,
    };
  }
}
