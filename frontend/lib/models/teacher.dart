class TeacherProfile {
  final int id;
  final String teacherCode;
  final String name;
  final String surname;
  final String email;

  TeacherProfile({
    required this.id,
    required this.teacherCode,
    required this.name,
    required this.surname,
    required this.email,
  });

  factory TeacherProfile.fromJson(Map<String, dynamic> json) {
    return TeacherProfile(
      id: json['id'] as int,
      teacherCode: json['teacher_code'] as String,
      name: json['name'] as String,
      surname: json['surname'] as String,
      email: json['email'] as String,
    );
  }
}

class TeacherDashboard {
  final int classroomCount;
  final int studentCount;

  TeacherDashboard({required this.classroomCount, required this.studentCount});

  factory TeacherDashboard.fromJson(Map<String, dynamic> json) {
    return TeacherDashboard(
      classroomCount: json['classroom_count'] as int,
      studentCount: json['student_count'] as int,
    );
  }
}

class StudentListItem {
  final int id;
  final String name;
  final String surname;
  final int schoolId;
  final String studentCode;
  final List<String> classrooms;
  final bool isRegistered;

  StudentListItem({
    required this.id,
    required this.name,
    required this.surname,
    required this.schoolId,
    required this.studentCode,
    required this.classrooms,
    required this.isRegistered,
  });

  factory StudentListItem.fromJson(Map<String, dynamic> json) {
    return StudentListItem(
      id: json['id'] as int,
      name: json['name'] as String,
      surname: json['surname'] as String,
      schoolId: json['school_id'] as int,
      studentCode: json['student_code'] as String,
      classrooms: (json['classrooms'] as List).cast<String>(),
      isRegistered: json['is_registered'] as bool,
    );
  }
}
