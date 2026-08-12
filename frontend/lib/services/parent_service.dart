import '../config.dart';
import '../models/announcement.dart';
import '../models/grade.dart';
import '../models/paginated.dart';
import '../models/parent.dart';
import '../models/student.dart';
import 'api_client.dart';

class ParentService {
  static Future<ParentProfile> getMe() async {
    final json = await ApiClient.get('/parent/me');
    return ParentProfile.fromJson(json as Map<String, dynamic>);
  }

  static Future<void> addStudentCode(String code) async {
    await ApiClient.post('/parent/student-code', body: {'code': code});
  }

  static Future<List<ParentStudentListItem>> listStudents() async {
    final json = await ApiClient.get('/parent/students');
    return (json as List).map((e) => ParentStudentListItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Paginated<Announcement>> listAnnouncements({
    int page = 1,
    int pageSize = kDefaultPageSize,
    int? studentId,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (studentId != null) params['student_id'] = studentId.toString();
    final query = Uri(queryParameters: params).query;
    final json = await ApiClient.get('/parent/announcements?$query');
    return Paginated.fromJson(json as Map<String, dynamic>, Announcement.fromJson);
  }

  static Future<List<TeacherFilterItem>> listStudentGradeTeachers(int studentId) async {
    final json = await ApiClient.get('/parent/students/$studentId/grade-teachers');
    return (json as List).map((e) => TeacherFilterItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Paginated<Grade>> listStudentGrades(
    int studentId, {
    int page = 1,
    int pageSize = kDefaultPageSize,
    int? teacherId,
    String sortBy = 'date',
    String order = 'desc',
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
      'sort_by': sortBy,
      'order': order,
    };
    if (teacherId != null) params['teacher_id'] = teacherId.toString();
    final query = Uri(queryParameters: params).query;
    final json = await ApiClient.get('/parent/students/$studentId/grades?$query');
    return Paginated.fromJson(json as Map<String, dynamic>, Grade.fromJson);
  }
}
