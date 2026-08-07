import '../config.dart';
import '../models/announcement.dart';
import '../models/grade.dart';
import '../models/paginated.dart';
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

  static Future<List<TeacherFilterItem>> listAnnouncementTeachers() async {
    final json = await ApiClient.get('/student/announcement-teachers');
    return (json as List).map((e) => TeacherFilterItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Paginated<Announcement>> listAnnouncements({
    int page = 1,
    int pageSize = kDefaultPageSize,
    int? teacherId,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (teacherId != null) params['teacher_id'] = teacherId.toString();
    final query = Uri(queryParameters: params).query;
    final json = await ApiClient.get('/student/announcements?$query');
    return Paginated.fromJson(json as Map<String, dynamic>, Announcement.fromJson);
  }

  static Future<List<TeacherFilterItem>> listGradeTeachers() async {
    final json = await ApiClient.get('/student/grade-teachers');
    return (json as List).map((e) => TeacherFilterItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Paginated<Grade>> listGrades({
    int page = 1,
    int pageSize = kDefaultPageSize,
    int? teacherId,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (teacherId != null) params['teacher_id'] = teacherId.toString();
    final query = Uri(queryParameters: params).query;
    final json = await ApiClient.get('/student/grades?$query');
    return Paginated.fromJson(json as Map<String, dynamic>, Grade.fromJson);
  }
}
