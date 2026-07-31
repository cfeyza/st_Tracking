class Grade {
  final int id;
  final String subject;
  final String value;
  final DateTime createdAt;
  final String teacherName;
  final String? classroomName;
  final String? studentName;

  Grade({
    required this.id,
    required this.subject,
    required this.value,
    required this.createdAt,
    required this.teacherName,
    this.classroomName,
    this.studentName,
  });

  factory Grade.fromJson(Map<String, dynamic> json) {
    return Grade(
      id: json['id'] as int,
      subject: json['subject'] as String,
      value: json['value'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      teacherName: json['teacher_name'] as String,
      classroomName: json['classroom_name'] as String?,
      studentName: json['student_name'] as String?,
    );
  }
}
