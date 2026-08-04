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
  final int schoolId;

  RosterStudentIn({required this.name, required this.surname, required this.schoolId});

  Map<String, dynamic> toJson() => {
        'name': name,
        'surname': surname,
        'school_id': schoolId,
      };
}

class PdfImportClassroomResult {
  final int classroomId;
  final String classroomName;
  final bool createdClassroom;
  final int studentsAdded;
  final List<String> skipped;

  PdfImportClassroomResult({
    required this.classroomId,
    required this.classroomName,
    required this.createdClassroom,
    required this.studentsAdded,
    required this.skipped,
  });

  factory PdfImportClassroomResult.fromJson(Map<String, dynamic> json) {
    return PdfImportClassroomResult(
      classroomId: json['classroom_id'] as int,
      classroomName: json['classroom_name'] as String,
      createdClassroom: json['created_classroom'] as bool,
      studentsAdded: json['students_added'] as int,
      skipped: (json['skipped'] as List).map((e) => e as String).toList(),
    );
  }
}

class PdfImportResult {
  final List<PdfImportClassroomResult> classrooms;
  final List<String> errors;

  PdfImportResult({required this.classrooms, required this.errors});

  factory PdfImportResult.fromJson(Map<String, dynamic> json) {
    return PdfImportResult(
      classrooms: (json['classrooms'] as List)
          .map((e) => PdfImportClassroomResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      errors: (json['errors'] as List).map((e) => e as String).toList(),
    );
  }
}
