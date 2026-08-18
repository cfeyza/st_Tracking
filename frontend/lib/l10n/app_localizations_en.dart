// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Student Tracking App';

  @override
  String get logIn => 'Log in';

  @override
  String get logOut => 'Log out';

  @override
  String get register => 'Register';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get ok => 'OK';

  @override
  String get post => 'Post';

  @override
  String get delete => 'Delete';

  @override
  String get remove => 'Remove';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get name => 'Name';

  @override
  String get surname => 'Surname';

  @override
  String get schoolId => 'School ID';

  @override
  String get teacherCode => 'Teacher code';

  @override
  String get studentCode => 'Student code';

  @override
  String get classroom => 'Classroom';

  @override
  String get student => 'Student';

  @override
  String get teacher => 'Teacher';

  @override
  String get parent => 'Parent';

  @override
  String get date => 'Date';

  @override
  String get subject => 'Subject';

  @override
  String get grade => 'Grade';

  @override
  String get status => 'Status';

  @override
  String get registered => 'Registered';

  @override
  String get pending => 'Pending';

  @override
  String get ascending => 'Ascending';

  @override
  String get descending => 'Descending';

  @override
  String get announcements => 'Announcements';

  @override
  String get classrooms => 'Classrooms';

  @override
  String get students => 'Students';

  @override
  String get grades => 'Grades';

  @override
  String get profile => 'Profile';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get surnameRequired => 'Surname is required';

  @override
  String get schoolIdRequired => 'School ID is required';

  @override
  String get schoolIdMustBeNumber => 'School ID must be a number';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters';

  @override
  String get schoolIdHelperText =>
      'Your teacher uses this to match you to their class roster';

  @override
  String get iAmA => 'I am a';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Register';

  @override
  String get alreadyHaveAccount => 'Already have an account? Log in';

  @override
  String get registrationSuccess =>
      'Registration successful! Check your email to verify your account, then log in.';

  @override
  String copiedToClipboard(String label) {
    return '$label copied to clipboard';
  }

  @override
  String pageXofY(int page, int totalPages) {
    return 'Page $page of $totalPages';
  }

  @override
  String get myGrades => 'My grades';

  @override
  String get myStudents => 'My students';

  @override
  String get myClassrooms => 'My classrooms';

  @override
  String gradesWithStudent(String studentName) {
    return 'Grades — $studentName';
  }

  @override
  String myStudentsWithClassroom(String classroomName) {
    return 'My students — $classroomName';
  }

  @override
  String get addTeacherCode => 'Add teacher code';

  @override
  String get addStudentCode => 'Add student code';

  @override
  String get addClassroom => 'Add classroom';

  @override
  String get addGrades => 'Add grades';

  @override
  String get addGrade => 'Add grade';

  @override
  String get addToRoster => 'Add to roster';

  @override
  String get createClassroom => 'Create classroom';

  @override
  String get newClassroom => 'New classroom';

  @override
  String get existingClassroom => 'Existing classroom';

  @override
  String get noAnnouncementsYet => 'No announcements yet.';

  @override
  String get noGradesYet => 'No grades yet.';

  @override
  String get noGradesFound => 'No grades found.';

  @override
  String get noStudentsFound => 'No students found.';

  @override
  String get noClassroomsYet => 'No classrooms yet. Tap + to add one.';

  @override
  String get noStudentsLinked => 'No students linked yet. Tap + to add one.';

  @override
  String get noExistingClassrooms =>
      'You have no classrooms yet. Create a new one instead.';

  @override
  String get newAnnouncement => 'New announcement';

  @override
  String get announcementText => 'Announcement text';

  @override
  String get targetClassrooms => 'Target classroom(s)';

  @override
  String get enterTextAndPickClassroom =>
      'Enter text and pick at least one classroom.';

  @override
  String get addClassroomFirst =>
      'Add a classroom first before posting an announcement.';

  @override
  String parentAnnouncementMeta(
    String studentName,
    String teacherName,
    String classrooms,
  ) {
    return 'For $studentName · $teacherName · $classrooms';
  }

  @override
  String get deleteClassroomTooltip => 'Delete classroom';

  @override
  String get deleteClassroomTitle => 'Delete classroom?';

  @override
  String deleteClassroomConfirm(String name) {
    return 'This removes \'$name\'. Students who are in that classroom will also be removed from your student list; their records aren\'t deleted.';
  }

  @override
  String deletedClassroom(String name) {
    return 'Deleted \'$name\'.';
  }

  @override
  String studentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students',
      one: '1 student',
    );
    return '$_temp0';
  }

  @override
  String get classroomNameLabel => 'Classroom name (e.g. 5A)';

  @override
  String get addStudentsHelper =>
      'Add students to this classroom by name, surname, and school ID. You never need to place them into the right classroom afterward — this is it.';

  @override
  String get pdfImportHelper =>
      'Or import one or more classrooms straight from an e-Okul class-list PDF — the classroom and section are read from the file, so the fields above aren\'t used for this.';

  @override
  String get importing => 'Importing…';

  @override
  String get importFromPdf => 'Import from PDF';

  @override
  String get importSummary => 'Import summary';

  @override
  String get noClassroomsInPdf => 'No classrooms could be read from this PDF.';

  @override
  String get importNew => 'new';

  @override
  String get importExisting => 'existing';

  @override
  String importStudentsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count students added',
      one: '1 student added',
    );
    return '$_temp0';
  }

  @override
  String importSkipped(int count) {
    return ', $count skipped (already in your roster)';
  }

  @override
  String get importIssues => 'Issues:';

  @override
  String get chooseClassroom => 'Choose a classroom.';

  @override
  String get rosterUpdated => 'Roster updated.';

  @override
  String get classroomNameRequired => 'Classroom name is required.';

  @override
  String classroomAlreadyExists(String name) {
    return 'A classroom named \'$name\' already exists. Pick it from the existing classrooms list instead.';
  }

  @override
  String get classroomCreated => 'Classroom created.';

  @override
  String get filterAllStudents => 'Filter: all students';

  @override
  String get allStudents => 'All students';

  @override
  String get filterAllClassrooms => 'Filter: all classrooms';

  @override
  String get allClassrooms => 'All classrooms';

  @override
  String get filterByTeacher => 'Filter by teacher';

  @override
  String get allTeachers => 'All teachers';

  @override
  String sortBy(String value) {
    return 'Sort: $value';
  }

  @override
  String get removeStudentTooltip => 'Remove student';

  @override
  String get removeStudentTitle => 'Remove student?';

  @override
  String removeStudentConfirm(String studentName) {
    return '$studentName will be removed from all of your classrooms and your roster. Their record and grade history are kept, and other teachers or parents linked to them are unaffected.';
  }

  @override
  String removedStudent(String studentName) {
    return 'Removed $studentName.';
  }

  @override
  String get classroomsColumn => 'Classroom(s)';

  @override
  String get enterTeacherCodeInstruction =>
      'Enter the code your teacher gave you. You must already be on that teacher\'s classroom roster (matched by your name, surname, and school ID) for this to work.';

  @override
  String get teacherCodeLabel => 'Teacher code';

  @override
  String linkedToTeacher(String teacherName) {
    return 'Linked to $teacherName';
  }

  @override
  String get nowLinkedToTeacher => 'You\'re now linked to this teacher.';

  @override
  String addedToClassrooms(String classrooms) {
    return 'You\'ve been added to: $classrooms';
  }

  @override
  String get enterChildStudentCode =>
      'Enter your child\'s student code (found on their profile page).';

  @override
  String get studentCodeLabel => 'Student code';

  @override
  String get studentLinked => 'Student linked.';

  @override
  String schoolIdValue(String id) {
    return 'School ID: $id';
  }

  @override
  String get fillInAllRosterFields =>
      'Fill in name, surname, and school ID for every roster row (or remove it).';

  @override
  String get schoolIdMustBeNumberRoster => 'School ID must be a number.';

  @override
  String get studentsSection => 'Students';

  @override
  String get addRow => 'Add row';

  @override
  String get enterManually => 'Enter manually';

  @override
  String get pickClassroomAndStudentGradeHint =>
      'Pick a classroom and student, then type in the grade.';

  @override
  String get scanOpticForm => 'Scan optic form';

  @override
  String get readExamSheet => 'Read exam sheet';

  @override
  String get selectClassroomFirst => 'Select a classroom first';

  @override
  String get subjectLabel => 'Subject (e.g. Math)';

  @override
  String get gradeValueLabel => 'Grade (e.g. 85 or A-)';

  @override
  String get pickClassroomAndStudentGradeError =>
      'Pick a classroom and student, and fill in subject and grade.';

  @override
  String get gradeAdded => 'Grade added.';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get deleteAnnouncementTooltip => 'Delete announcement';

  @override
  String get deleteAnnouncementTitle => 'Delete announcement?';

  @override
  String get deleteAnnouncementConfirm =>
      'This announcement will be permanently deleted.';

  @override
  String get deletedAnnouncement => 'Announcement deleted.';

  @override
  String studentsListPartial(int fetched, int total) {
    return 'Could only load $fetched of $total students — some may be missing from the list.';
  }

  @override
  String classroomsListPartial(int fetched, int total) {
    return 'Could only load $fetched of $total classrooms — some may be missing from the list.';
  }

  @override
  String get markAsRead => 'Read & Acknowledge';

  @override
  String get acknowledged => 'Acknowledged';

  @override
  String get viewReaders => 'View readers';

  @override
  String get announcementReaders => 'Readers';

  @override
  String studentsWhoRead(int count) {
    return 'Have read ($count)';
  }

  @override
  String studentsWhoHaventRead(int count) {
    return 'Have not read ($count)';
  }
}
