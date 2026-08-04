class ParentProfile {
  final String name;
  final String surname;
  final String email;

  ParentProfile({required this.name, required this.surname, required this.email});

  factory ParentProfile.fromJson(Map<String, dynamic> json) {
    return ParentProfile(
      name: json['name'] as String,
      surname: json['surname'] as String,
      email: json['email'] as String,
    );
  }
}

class ParentStudentListItem {
  final int id;
  final String name;
  final String surname;
  final int schoolId;

  ParentStudentListItem({
    required this.id,
    required this.name,
    required this.surname,
    required this.schoolId,
  });

  factory ParentStudentListItem.fromJson(Map<String, dynamic> json) {
    return ParentStudentListItem(
      id: json['id'] as int,
      name: json['name'] as String,
      surname: json['surname'] as String,
      schoolId: json['school_id'] as int,
    );
  }
}
