class ClassroomOut {
  final int id;
  final String name;
  final int studentCount;
  final DateTime createdAt;

  ClassroomOut({
    required this.id,
    required this.name,
    required this.studentCount,
    required this.createdAt,
  });

  factory ClassroomOut.fromJson(Map<String, dynamic> json) {
    return ClassroomOut(
      id: json['id'] as int,
      name: json['name'] as String,
      studentCount: json['student_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class RosterStudentIn {
  final String name;
  final String surname;
  final String schoolId;

  RosterStudentIn({required this.name, required this.surname, required this.schoolId});

  Map<String, dynamic> toJson() => {
        'name': name,
        'surname': surname,
        'school_id': schoolId,
      };
}
