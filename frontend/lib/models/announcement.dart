/// Unified announcement model. `teacherName` is null on the teacher's own
/// list (it's implicitly them); `studentName` is only present on the
/// parent's feed, where announcements from several children are mixed
/// together.
class Announcement {
  final int id;
  final String text;
  final DateTime createdAt;
  final List<String> classrooms;
  final String? teacherName;
  final String? studentName;

  Announcement({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.classrooms,
    this.teacherName,
    this.studentName,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as int,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      classrooms: (json['classrooms'] as List).cast<String>(),
      teacherName: json['teacher_name'] as String?,
      studentName: json['student_name'] as String?,
    );
  }
}
