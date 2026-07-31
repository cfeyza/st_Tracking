import '../models/announcement.dart';
import '../models/parent.dart';
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

  static Future<List<Announcement>> listAnnouncements() async {
    final json = await ApiClient.get('/parent/announcements');
    return (json as List).map((e) => Announcement.fromJson(e as Map<String, dynamic>)).toList();
  }
}
