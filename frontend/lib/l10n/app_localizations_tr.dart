// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Öğrenci Takip Uygulaması';

  @override
  String get logIn => 'Giriş yap';

  @override
  String get logOut => 'Çıkış yap';

  @override
  String get register => 'Kayıt ol';

  @override
  String get cancel => 'İptal';

  @override
  String get add => 'Ekle';

  @override
  String get ok => 'Tamam';

  @override
  String get post => 'Gönder';

  @override
  String get delete => 'Sil';

  @override
  String get remove => 'Kaldır';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get name => 'Ad';

  @override
  String get surname => 'Soyad';

  @override
  String get schoolId => 'Okul No';

  @override
  String get teacherCode => 'Öğretmen kodu';

  @override
  String get studentCode => 'Öğrenci kodu';

  @override
  String get classroom => 'Sınıf';

  @override
  String get student => 'Öğrenci';

  @override
  String get teacher => 'Öğretmen';

  @override
  String get parent => 'Veli';

  @override
  String get date => 'Tarih';

  @override
  String get subject => 'Ders';

  @override
  String get grade => 'Not';

  @override
  String get status => 'Durum';

  @override
  String get registered => 'Kayıtlı';

  @override
  String get pending => 'Beklemede';

  @override
  String get ascending => 'Artan';

  @override
  String get descending => 'Azalan';

  @override
  String get announcements => 'Duyurular';

  @override
  String get classrooms => 'Sınıflar';

  @override
  String get students => 'Öğrenciler';

  @override
  String get grades => 'Notlar';

  @override
  String get profile => 'Profil';

  @override
  String get emailRequired => 'E-posta zorunludur';

  @override
  String get passwordRequired => 'Şifre zorunludur';

  @override
  String get nameRequired => 'Ad zorunludur';

  @override
  String get surnameRequired => 'Soyad zorunludur';

  @override
  String get schoolIdRequired => 'Okul No zorunludur';

  @override
  String get schoolIdMustBeNumber => 'Okul No sayı olmalıdır';

  @override
  String get passwordMinLength => 'Şifre en az 8 karakter olmalıdır';

  @override
  String get schoolIdHelperText =>
      'Öğretmeniniz sizi sınıf listesiyle eşleştirmek için bunu kullanır';

  @override
  String get iAmA => 'Ben bir';

  @override
  String get dontHaveAccount => 'Hesabınız yok mu? Kayıt olun';

  @override
  String get alreadyHaveAccount => 'Zaten hesabınız var mı? Giriş yapın';

  @override
  String get registrationSuccess =>
      'Kayıt başarılı! Hesabınızı doğrulamak için e-postanızı kontrol edin, ardından giriş yapın.';

  @override
  String copiedToClipboard(String label) {
    return '$label panoya kopyalandı';
  }

  @override
  String pageXofY(int page, int totalPages) {
    return '$page/$totalPages sayfa';
  }

  @override
  String get myGrades => 'Notlarım';

  @override
  String get myStudents => 'Öğrencilerim';

  @override
  String get myClassrooms => 'Sınıflarım';

  @override
  String gradesWithStudent(String studentName) {
    return 'Notlar — $studentName';
  }

  @override
  String myStudentsWithClassroom(String classroomName) {
    return 'Öğrencilerim — $classroomName';
  }

  @override
  String get addTeacherCode => 'Öğretmen kodu ekle';

  @override
  String get addStudentCode => 'Öğrenci kodu ekle';

  @override
  String get addClassroom => 'Sınıf ekle';

  @override
  String get addGrades => 'Not ekle';

  @override
  String get addGrade => 'Not ekle';

  @override
  String get addToRoster => 'Listeye ekle';

  @override
  String get createClassroom => 'Sınıf oluştur';

  @override
  String get newClassroom => 'Yeni sınıf';

  @override
  String get existingClassroom => 'Mevcut sınıf';

  @override
  String get noAnnouncementsYet => 'Henüz duyuru yok.';

  @override
  String get noGradesYet => 'Henüz not yok.';

  @override
  String get noGradesFound => 'Not bulunamadı.';

  @override
  String get noStudentsFound => 'Öğrenci bulunamadı.';

  @override
  String get noClassroomsYet =>
      'Henüz sınıf yok. Eklemek için + düğmesine dokunun.';

  @override
  String get noStudentsLinked =>
      'Henüz öğrenci bağlanmadı. Eklemek için + düğmesine dokunun.';

  @override
  String get noExistingClassrooms =>
      'Henüz sınıfınız yok. Bunun yerine yeni bir tane oluşturun.';

  @override
  String get newAnnouncement => 'Yeni duyuru';

  @override
  String get announcementText => 'Duyuru metni';

  @override
  String get targetClassrooms => 'Hedef sınıf(lar)';

  @override
  String get enterTextAndPickClassroom =>
      'Metin girin ve en az bir sınıf seçin.';

  @override
  String get addClassroomFirst => 'Duyuru göndermeden önce bir sınıf ekleyin.';

  @override
  String parentAnnouncementMeta(
    String studentName,
    String teacherName,
    String classrooms,
  ) {
    return '$studentName için · $teacherName · $classrooms';
  }

  @override
  String get deleteClassroomTooltip => 'Sınıfı sil';

  @override
  String get deleteClassroomTitle => 'Sınıf silinsin mi?';

  @override
  String deleteClassroomConfirm(String name) {
    return 'Bu işlem \'$name\' sınıfını siler. O sınıftaki öğrenciler öğrenci listenizden de kaldırılır; kayıtları silinmez.';
  }

  @override
  String deletedClassroom(String name) {
    return '\'$name\' silindi.';
  }

  @override
  String studentCount(int count) {
    return '$count öğrenci';
  }

  @override
  String get classroomNameLabel => 'Sınıf adı (örn. 5A)';

  @override
  String get addStudentsHelper =>
      'Bu sınıfa ad, soyad ve okul numarasıyla öğrenci ekleyin. Sonradan doğru sınıfa yerleştirmenize gerek yok — zaten bu sınıfa ekliyorsunuz.';

  @override
  String get pdfImportHelper =>
      'Ya da doğrudan e-Okul sınıf listesi PDF\'inden bir veya daha fazla sınıf içe aktarın — sınıf ve şube dosyadan okunur, bu nedenle yukarıdaki alanlar kullanılmaz.';

  @override
  String get importing => 'İçe aktarılıyor…';

  @override
  String get importFromPdf => 'PDF\'den içe aktar';

  @override
  String get importSummary => 'İçe aktarma özeti';

  @override
  String get noClassroomsInPdf => 'Bu PDF\'den hiçbir sınıf okunamadı.';

  @override
  String get importNew => 'yeni';

  @override
  String get importExisting => 'mevcut';

  @override
  String importStudentsAdded(int count) {
    return '$count öğrenci eklendi';
  }

  @override
  String importSkipped(int count) {
    return ', $count atlandı (zaten listede)';
  }

  @override
  String get importIssues => 'Sorunlar:';

  @override
  String get chooseClassroom => 'Bir sınıf seçin.';

  @override
  String get rosterUpdated => 'Liste güncellendi.';

  @override
  String get classroomNameRequired => 'Sınıf adı zorunludur.';

  @override
  String classroomAlreadyExists(String name) {
    return '\'$name\' adında bir sınıf zaten var. Bunun yerine mevcut sınıflar listesinden seçin.';
  }

  @override
  String get classroomCreated => 'Sınıf oluşturuldu.';

  @override
  String get filterAllStudents => 'Filtre: tüm öğrenciler';

  @override
  String get allStudents => 'Tüm öğrenciler';

  @override
  String get filterAllClassrooms => 'Filtre: tüm sınıflar';

  @override
  String get allClassrooms => 'Tüm sınıflar';

  @override
  String get filterByTeacher => 'Öğretmene göre filtrele';

  @override
  String get allTeachers => 'Tüm öğretmenler';

  @override
  String sortBy(String value) {
    return 'Sıralama: $value';
  }

  @override
  String get removeStudentTooltip => 'Öğrenciyi kaldır';

  @override
  String get removeStudentTitle => 'Öğrenci kaldırılsın mı?';

  @override
  String removeStudentConfirm(String studentName) {
    return '$studentName tüm sınıflarınızdan ve listenizden kaldırılacak. Kayıtları ve not geçmişi saklanır; onlara bağlı diğer öğretmen veya veliler etkilenmez.';
  }

  @override
  String removedStudent(String studentName) {
    return '$studentName kaldırıldı.';
  }

  @override
  String get classroomsColumn => 'Sınıf(lar)';

  @override
  String get enterTeacherCodeInstruction =>
      'Öğretmeninizin verdiği kodu girin. Bunun çalışması için zaten o öğretmenin sınıf listesinde (ad, soyad ve okul numaranızla eşleştirilen) olmanız gerekir.';

  @override
  String get teacherCodeLabel => 'Öğretmen kodu';

  @override
  String linkedToTeacher(String teacherName) {
    return '$teacherName ile bağlantı kuruldu';
  }

  @override
  String get nowLinkedToTeacher => 'Bu öğretmene başarıyla bağlandınız.';

  @override
  String addedToClassrooms(String classrooms) {
    return 'Şu sınıflara eklendiniz: $classrooms';
  }

  @override
  String get enterChildStudentCode =>
      'Çocuğunuzun öğrenci kodunu girin (profil sayfasında bulunur).';

  @override
  String get studentCodeLabel => 'Öğrenci kodu';

  @override
  String get studentLinked => 'Öğrenci bağlandı.';

  @override
  String schoolIdValue(String id) {
    return 'Okul No: $id';
  }

  @override
  String get fillInAllRosterFields =>
      'Her liste satırı için ad, soyad ve okul numarasını doldurun (veya kaldırın).';

  @override
  String get schoolIdMustBeNumberRoster => 'Okul No sayı olmalıdır.';

  @override
  String get studentsSection => 'Öğrenciler';

  @override
  String get addRow => 'Satır ekle';

  @override
  String get enterManually => 'Manüel gir';

  @override
  String get pickClassroomAndStudentGradeHint =>
      'Sınıf ve öğrenci seçin, ardından notu girin.';

  @override
  String get scanOpticForm => 'Optik form tara';

  @override
  String get readExamSheet => 'Sınav kağıdı oku';

  @override
  String get selectClassroomFirst => 'Önce bir sınıf seçin';

  @override
  String get subjectLabel => 'Ders (örn. Matematik)';

  @override
  String get gradeValueLabel => 'Not (örn. 85 veya A-)';

  @override
  String get pickClassroomAndStudentGradeError =>
      'Sınıf ve öğrenci seçin, ders ve notu girin.';

  @override
  String get gradeAdded => 'Not eklendi.';

  @override
  String get comingSoon => 'Çok yakında';

  @override
  String get deleteAnnouncementTooltip => 'Duyuruyu sil';

  @override
  String get deleteAnnouncementTitle => 'Duyuru silinsin mi?';

  @override
  String get deleteAnnouncementConfirm => 'Bu duyuru kalıcı olarak silinecek.';

  @override
  String get deletedAnnouncement => 'Duyuru silindi.';

  @override
  String studentsListPartial(int fetched, int total) {
    return '$total öğrencinin yalnızca $fetched tanesi yüklenebildi — bazıları listede görünmeyebilir.';
  }

  @override
  String classroomsListPartial(int fetched, int total) {
    return '$total sınıfın yalnızca $fetched tanesi yüklenebildi — bazıları listede görünmeyebilir.';
  }

  @override
  String get markAsRead => 'Oku ve Onayla';

  @override
  String get acknowledged => 'Okundu';

  @override
  String get viewReaders => 'Okuyanları gör';

  @override
  String get announcementReaders => 'Okuma durumu';

  @override
  String studentsWhoRead(int count) {
    return 'Okuyanlar ($count)';
  }

  @override
  String studentsWhoHaventRead(int count) {
    return 'Okumayanlar ($count)';
  }
}
