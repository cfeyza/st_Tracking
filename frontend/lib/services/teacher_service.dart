import '../models/announcement.dart';
import '../models/classroom.dart';
import '../models/grade.dart';
import '../models/teacher.dart';
import 'api_client.dart';

class TeacherService {
  static Future<TeacherProfile> getMe() async {
    final json = await ApiClient.get('/teacher/me');
    return TeacherProfile.fromJson(json as Map<String, dynamic>);
  }

  static Future<TeacherDashboard> getDashboard() async {
    final json = await ApiClient.get('/teacher/dashboard');
    return TeacherDashboard.fromJson(json as Map<String, dynamic>);
  }

  static Future<List<ClassroomOut>> listClassrooms() async {
    final json = await ApiClient.get('/teacher/classrooms');
    return (json as List).map((e) => ClassroomOut.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<ClassroomOut> createClassroom(String name, List<RosterStudentIn> students) async {
    final json = await ApiClient.post('/teacher/classrooms', body: {
      'name': name,
      'students': students.map((s) => s.toJson()).toList(),
    });
    return ClassroomOut.fromJson(json as Map<String, dynamic>);
  }

  static Future<List<StudentListItem>> addToRoster(int classroomId, List<RosterStudentIn> students) async {
    final json = await ApiClient.post('/teacher/classrooms/$classroomId/roster', body: {
      'students': students.map((s) => s.toJson()).toList(),
    });
    return (json as List).map((e) => StudentListItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> removeStudentFromClassroom(int classroomId, int studentId) async {
    await ApiClient.delete('/teacher/classrooms/$classroomId/students/$studentId');
  }

  static Future<List<StudentListItem>> listStudents({
    int? classroomId,
    String sortBy = 'surname',
    String order = 'asc',
  }) async {
    final params = <String, String>{'sort_by': sortBy, 'order': order};
    if (classroomId != null) params['classroom_id'] = classroomId.toString();
    final query = Uri(queryParameters: params).query;
    final json = await ApiClient.get('/teacher/students?$query');
    return (json as List).map((e) => StudentListItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Announcement>> listAnnouncements() async {
    final json = await ApiClient.get('/teacher/announcements');
    return (json as List).map((e) => Announcement.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Announcement> createAnnouncement(String text, List<int> classroomIds) async {
    final json = await ApiClient.post('/teacher/announcements', body: {
      'text': text,
      'classroom_ids': classroomIds,
    });
    return Announcement.fromJson(json as Map<String, dynamic>);
  }

  static Future<List<Grade>> listGrades({int? studentId}) async {
    final path = studentId == null ? '/teacher/grades' : '/teacher/grades?student_id=$studentId';
    final json = await ApiClient.get(path);
    return (json as List).map((e) => Grade.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Grade> addGrade({
    required int studentId,
    int? classroomId,
    required String subject,
    required String value,
  }) async {
    final json = await ApiClient.post('/teacher/grades', body: {
      'student_id': studentId,
      'classroom_id': ?classroomId,
      'subject': subject,
      'value': value,
    });
    return Grade.fromJson(json as Map<String, dynamic>);
  }
}
