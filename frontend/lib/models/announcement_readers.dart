class StudentReaderInfo {
  final int id;
  final String name;
  final String surname;
  final DateTime? readAt;

  StudentReaderInfo({
    required this.id,
    required this.name,
    required this.surname,
    this.readAt,
  });

  factory StudentReaderInfo.fromJson(Map<String, dynamic> json) {
    return StudentReaderInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      surname: json['surname'] as String,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
    );
  }
}

class AnnouncementReaders {
  final int announcementId;
  final List<StudentReaderInfo> readers;
  final List<StudentReaderInfo> nonReaders;

  AnnouncementReaders({
    required this.announcementId,
    required this.readers,
    required this.nonReaders,
  });

  factory AnnouncementReaders.fromJson(Map<String, dynamic> json) {
    return AnnouncementReaders(
      announcementId: json['announcement_id'] as int,
      readers: (json['readers'] as List)
          .map((e) => StudentReaderInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      nonReaders: (json['non_readers'] as List)
          .map((e) => StudentReaderInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
