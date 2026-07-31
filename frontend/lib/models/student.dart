class StudentProfile {
  final int id;
  final String studentCode;
  final String name;
  final String surname;
  final String schoolId;
  final String email;

  StudentProfile({
    required this.id,
    required this.studentCode,
    required this.name,
    required this.surname,
    required this.schoolId,
    required this.email,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] as int,
      studentCode: json['student_code'] as String,
      name: json['name'] as String,
      surname: json['surname'] as String,
      schoolId: json['school_id'] as String,
      email: json['email'] as String,
    );
  }
}

class TeacherCodeResponse {
  final String teacherName;
  final List<String> classrooms;

  TeacherCodeResponse({required this.teacherName, required this.classrooms});

  factory TeacherCodeResponse.fromJson(Map<String, dynamic> json) {
    return TeacherCodeResponse(
      teacherName: json['teacher_name'] as String,
      classrooms: (json['classrooms'] as List).cast<String>(),
    );
  }
}
