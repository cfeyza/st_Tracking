import '../config.dart';
import '../models/announcement.dart';
import '../models/announcement_readers.dart';
import '../models/classroom.dart';
import '../models/grade.dart';
import '../models/paginated.dart';
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

  static Future<Paginated<ClassroomOut>> listClassrooms({int page = 1, int pageSize = kDefaultPageSize}) async {
    final json = await ApiClient.get('/teacher/classrooms?page=$page&page_size=$pageSize');
    return Paginated.fromJson(json as Map<String, dynamic>, ClassroomOut.fromJson);
  }

  static Future<({List<ClassroomOut> items, int total})> listAllClassrooms() async {
    final first = await listClassrooms(page: 1, pageSize: 100);
    if (first.totalPages <= 1) {
      assert(first.items.length == first.total,
          'listAllClassrooms: single page but item count ${first.items.length} != server total ${first.total}');
      return (items: first.items, total: first.total);
    }
    final rest = await Future.wait([
      for (int p = 2; p <= first.totalPages; p++) listClassrooms(page: p, pageSize: 100),
    ]);
    final items = [...first.items, for (final page in rest) ...page.items];
    assert(items.length == first.total,
        'listAllClassrooms: fetched ${items.length} across all pages but server reported ${first.total}');
    return (items: items, total: first.total);
  }

  static Future<void> deleteClassroom(int classroomId) async {
    await ApiClient.delete('/teacher/classrooms/$classroomId');
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

  static Future<PdfImportResult> importClassroomsPdf(List<int> bytes, String filename) async {
    final json = await ApiClient.postMultipart(
      '/teacher/classrooms/import/pdf',
      fieldName: 'file',
      bytes: bytes,
      filename: filename,
    );
    return PdfImportResult.fromJson(json as Map<String, dynamic>);
  }

  static Future<Paginated<StudentListItem>> listStudents({
    int? classroomId,
    String sortBy = 'classroom',
    String order = 'asc',
    int page = 1,
    int pageSize = kDefaultPageSize,
  }) async {
    final params = <String, String>{
      'sort_by': sortBy,
      'order': order,
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (classroomId != null) params['classroom_id'] = classroomId.toString();
    final query = Uri(queryParameters: params).query;
    final json = await ApiClient.get('/teacher/students?$query');
    return Paginated.fromJson(json as Map<String, dynamic>, StudentListItem.fromJson);
  }

  static Future<void> deleteStudent(int studentId) async {
    await ApiClient.delete('/teacher/students/$studentId');
  }

  static Future<({List<StudentListItem> items, int total})> listAllStudents() async {
    final first = await listStudents(page: 1, pageSize: 100);
    if (first.totalPages <= 1) {
      assert(first.items.length == first.total,
          'listAllStudents: single page but item count ${first.items.length} != server total ${first.total}');
      return (items: first.items, total: first.total);
    }
    final rest = await Future.wait([
      for (int p = 2; p <= first.totalPages; p++) listStudents(page: p, pageSize: 100),
    ]);
    final items = [...first.items, for (final page in rest) ...page.items];
    assert(items.length == first.total,
        'listAllStudents: fetched ${items.length} across all pages but server reported ${first.total}');
    return (items: items, total: first.total);
  }

  static Future<Paginated<Announcement>> listAnnouncements({int page = 1, int pageSize = kDefaultPageSize}) async {
    final json = await ApiClient.get('/teacher/announcements?page=$page&page_size=$pageSize');
    return Paginated.fromJson(json as Map<String, dynamic>, Announcement.fromJson);
  }

  static Future<Announcement> createAnnouncement(String text, List<int> classroomIds) async {
    final json = await ApiClient.post('/teacher/announcements', body: {
      'text': text,
      'classroom_ids': classroomIds,
    });
    return Announcement.fromJson(json as Map<String, dynamic>);
  }

  static Future<void> deleteAnnouncement(int announcementId) async {
    await ApiClient.delete('/teacher/announcements/$announcementId');
  }

  static Future<List<StudentReaderInfo>> _fetchAllReaderPages(String base, String filter) async {
    final items = <StudentReaderInfo>[];
    int page = 1;
    int totalPages = 1;
    do {
      final json = await ApiClient.get('$base?filter=$filter&page=$page&page_size=100') as Map<String, dynamic>;
      items.addAll((json['items'] as List).map((e) => StudentReaderInfo.fromJson(e as Map<String, dynamic>)));
      totalPages = json['total_pages'] as int;
      page++;
    } while (page <= totalPages);
    return items;
  }

  static Future<AnnouncementReaders> getAnnouncementReaders(int announcementId) async {
    final base = '/teacher/announcements/$announcementId/readers';
    final results = await Future.wait([
      _fetchAllReaderPages(base, 'readers'),
      _fetchAllReaderPages(base, 'non_readers'),
    ]);
    return AnnouncementReaders(
      announcementId: announcementId,
      readers: results[0],
      nonReaders: results[1],
    );
  }

  static Future<Paginated<Grade>> listGrades({
    int? studentId,
    int? classroomId,
    String sortBy = 'date',
    String order = 'desc',
    int page = 1,
    int pageSize = kDefaultPageSize,
  }) async {
    final params = <String, String>{
      'sort_by': sortBy,
      'order': order,
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (studentId != null) params['student_id'] = studentId.toString();
    if (classroomId != null) params['classroom_id'] = classroomId.toString();
    final query = Uri(queryParameters: params).query;
    final json = await ApiClient.get('/teacher/grades?$query');
    return Paginated.fromJson(json as Map<String, dynamic>, Grade.fromJson);
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
