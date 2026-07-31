import '../models/announcement.dart';
import '../models/grade.dart';
import '../models/student.dart';
import 'api_client.dart';

class StudentService {
  static Future<StudentProfile> getMe() async {
    final json = await ApiClient.get('/student/me');
    return StudentProfile.fromJson(json as Map<String, dynamic>);
  }

  static Future<TeacherCodeResponse> addTeacherCode(String code) async {
    final json = await ApiClient.post('/student/teacher-code', body: {'code': code});
    return TeacherCodeResponse.fromJson(json as Map<String, dynamic>);
  }

  static Future<List<Announcement>> listAnnouncements() async {
    final json = await ApiClient.get('/student/announcements');
    return (json as List).map((e) => Announcement.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<Grade>> listGrades() async {
    final json = await ApiClient.get('/student/grades');
    return (json as List).map((e) => Grade.fromJson(e as Map<String, dynamic>)).toList();
  }
}
