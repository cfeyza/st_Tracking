import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Student Tracking App'**
  String get appTitle;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get logIn;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @surname.
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get surname;

  /// No description provided for @schoolId.
  ///
  /// In en, this message translates to:
  /// **'School ID'**
  String get schoolId;

  /// No description provided for @teacherCode.
  ///
  /// In en, this message translates to:
  /// **'Teacher code'**
  String get teacherCode;

  /// No description provided for @studentCode.
  ///
  /// In en, this message translates to:
  /// **'Student code'**
  String get studentCode;

  /// No description provided for @classroom.
  ///
  /// In en, this message translates to:
  /// **'Classroom'**
  String get classroom;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @teacher.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacher;

  /// No description provided for @parent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get parent;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @grade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get grade;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @registered.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get registered;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @ascending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// No description provided for @descending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @classrooms.
  ///
  /// In en, this message translates to:
  /// **'Classrooms'**
  String get classrooms;

  /// No description provided for @students.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get students;

  /// No description provided for @grades.
  ///
  /// In en, this message translates to:
  /// **'Grades'**
  String get grades;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @surnameRequired.
  ///
  /// In en, this message translates to:
  /// **'Surname is required'**
  String get surnameRequired;

  /// No description provided for @schoolIdRequired.
  ///
  /// In en, this message translates to:
  /// **'School ID is required'**
  String get schoolIdRequired;

  /// No description provided for @schoolIdMustBeNumber.
  ///
  /// In en, this message translates to:
  /// **'School ID must be a number'**
  String get schoolIdMustBeNumber;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength;

  /// No description provided for @schoolIdHelperText.
  ///
  /// In en, this message translates to:
  /// **'Your teacher uses this to match you to their class roster'**
  String get schoolIdHelperText;

  /// No description provided for @iAmA.
  ///
  /// In en, this message translates to:
  /// **'I am a'**
  String get iAmA;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get alreadyHaveAccount;

  /// No description provided for @registrationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Check your email to verify your account, then log in.'**
  String get registrationSuccess;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'{label} copied to clipboard'**
  String copiedToClipboard(String label);

  /// No description provided for @pageXofY.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {totalPages}'**
  String pageXofY(int page, int totalPages);

  /// No description provided for @myGrades.
  ///
  /// In en, this message translates to:
  /// **'My grades'**
  String get myGrades;

  /// No description provided for @myStudents.
  ///
  /// In en, this message translates to:
  /// **'My students'**
  String get myStudents;

  /// No description provided for @myClassrooms.
  ///
  /// In en, this message translates to:
  /// **'My classrooms'**
  String get myClassrooms;

  /// No description provided for @gradesWithStudent.
  ///
  /// In en, this message translates to:
  /// **'Grades — {studentName}'**
  String gradesWithStudent(String studentName);

  /// No description provided for @myStudentsWithClassroom.
  ///
  /// In en, this message translates to:
  /// **'My students — {classroomName}'**
  String myStudentsWithClassroom(String classroomName);

  /// No description provided for @addTeacherCode.
  ///
  /// In en, this message translates to:
  /// **'Add teacher code'**
  String get addTeacherCode;

  /// No description provided for @addStudentCode.
  ///
  /// In en, this message translates to:
  /// **'Add student code'**
  String get addStudentCode;

  /// No description provided for @addClassroom.
  ///
  /// In en, this message translates to:
  /// **'Add classroom'**
  String get addClassroom;

  /// No description provided for @addGrades.
  ///
  /// In en, this message translates to:
  /// **'Add grades'**
  String get addGrades;

  /// No description provided for @addGrade.
  ///
  /// In en, this message translates to:
  /// **'Add grade'**
  String get addGrade;

  /// No description provided for @addToRoster.
  ///
  /// In en, this message translates to:
  /// **'Add to roster'**
  String get addToRoster;

  /// No description provided for @createClassroom.
  ///
  /// In en, this message translates to:
  /// **'Create classroom'**
  String get createClassroom;

  /// No description provided for @newClassroom.
  ///
  /// In en, this message translates to:
  /// **'New classroom'**
  String get newClassroom;

  /// No description provided for @existingClassroom.
  ///
  /// In en, this message translates to:
  /// **'Existing classroom'**
  String get existingClassroom;

  /// No description provided for @noAnnouncementsYet.
  ///
  /// In en, this message translates to:
  /// **'No announcements yet.'**
  String get noAnnouncementsYet;

  /// No description provided for @noGradesYet.
  ///
  /// In en, this message translates to:
  /// **'No grades yet.'**
  String get noGradesYet;

  /// No description provided for @noGradesFound.
  ///
  /// In en, this message translates to:
  /// **'No grades found.'**
  String get noGradesFound;

  /// No description provided for @noStudentsFound.
  ///
  /// In en, this message translates to:
  /// **'No students found.'**
  String get noStudentsFound;

  /// No description provided for @noClassroomsYet.
  ///
  /// In en, this message translates to:
  /// **'No classrooms yet. Tap + to add one.'**
  String get noClassroomsYet;

  /// No description provided for @noStudentsLinked.
  ///
  /// In en, this message translates to:
  /// **'No students linked yet. Tap + to add one.'**
  String get noStudentsLinked;

  /// No description provided for @noExistingClassrooms.
  ///
  /// In en, this message translates to:
  /// **'You have no classrooms yet. Create a new one instead.'**
  String get noExistingClassrooms;

  /// No description provided for @newAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'New announcement'**
  String get newAnnouncement;

  /// No description provided for @announcementText.
  ///
  /// In en, this message translates to:
  /// **'Announcement text'**
  String get announcementText;

  /// No description provided for @targetClassrooms.
  ///
  /// In en, this message translates to:
  /// **'Target classroom(s)'**
  String get targetClassrooms;

  /// No description provided for @enterTextAndPickClassroom.
  ///
  /// In en, this message translates to:
  /// **'Enter text and pick at least one classroom.'**
  String get enterTextAndPickClassroom;

  /// No description provided for @addClassroomFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a classroom first before posting an announcement.'**
  String get addClassroomFirst;

  /// No description provided for @parentAnnouncementMeta.
  ///
  /// In en, this message translates to:
  /// **'For {studentName} · {teacherName} · {classrooms}'**
  String parentAnnouncementMeta(
    String studentName,
    String teacherName,
    String classrooms,
  );

  /// No description provided for @deleteClassroomTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete classroom'**
  String get deleteClassroomTooltip;

  /// No description provided for @deleteClassroomTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete classroom?'**
  String get deleteClassroomTitle;

  /// No description provided for @deleteClassroomConfirm.
  ///
  /// In en, this message translates to:
  /// **'This removes \'{name}\'. Students who are in that classroom will also be removed from your student list; their records aren\'t deleted.'**
  String deleteClassroomConfirm(String name);

  /// No description provided for @deletedClassroom.
  ///
  /// In en, this message translates to:
  /// **'Deleted \'{name}\'.'**
  String deletedClassroom(String name);

  /// No description provided for @studentCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 student} other{{count} students}}'**
  String studentCount(int count);

  /// No description provided for @classroomNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Classroom name (e.g. 5A)'**
  String get classroomNameLabel;

  /// No description provided for @addStudentsHelper.
  ///
  /// In en, this message translates to:
  /// **'Add students to this classroom by name, surname, and school ID. You never need to place them into the right classroom afterward — this is it.'**
  String get addStudentsHelper;

  /// No description provided for @pdfImportHelper.
  ///
  /// In en, this message translates to:
  /// **'Or import one or more classrooms straight from an e-Okul class-list PDF — the classroom and section are read from the file, so the fields above aren\'t used for this.'**
  String get pdfImportHelper;

  /// No description provided for @importing.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get importing;

  /// No description provided for @importFromPdf.
  ///
  /// In en, this message translates to:
  /// **'Import from PDF'**
  String get importFromPdf;

  /// No description provided for @importSummary.
  ///
  /// In en, this message translates to:
  /// **'Import summary'**
  String get importSummary;

  /// No description provided for @noClassroomsInPdf.
  ///
  /// In en, this message translates to:
  /// **'No classrooms could be read from this PDF.'**
  String get noClassroomsInPdf;

  /// No description provided for @importNew.
  ///
  /// In en, this message translates to:
  /// **'new'**
  String get importNew;

  /// No description provided for @importExisting.
  ///
  /// In en, this message translates to:
  /// **'existing'**
  String get importExisting;

  /// No description provided for @importStudentsAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 student added} other{{count} students added}}'**
  String importStudentsAdded(int count);

  /// No description provided for @importSkipped.
  ///
  /// In en, this message translates to:
  /// **', {count} skipped (already in your roster)'**
  String importSkipped(int count);

  /// No description provided for @importIssues.
  ///
  /// In en, this message translates to:
  /// **'Issues:'**
  String get importIssues;

  /// No description provided for @chooseClassroom.
  ///
  /// In en, this message translates to:
  /// **'Choose a classroom.'**
  String get chooseClassroom;

  /// No description provided for @rosterUpdated.
  ///
  /// In en, this message translates to:
  /// **'Roster updated.'**
  String get rosterUpdated;

  /// No description provided for @classroomNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Classroom name is required.'**
  String get classroomNameRequired;

  /// No description provided for @classroomAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'A classroom named \'{name}\' already exists. Pick it from the existing classrooms list instead.'**
  String classroomAlreadyExists(String name);

  /// No description provided for @classroomCreated.
  ///
  /// In en, this message translates to:
  /// **'Classroom created.'**
  String get classroomCreated;

  /// No description provided for @filterAllStudents.
  ///
  /// In en, this message translates to:
  /// **'Filter: all students'**
  String get filterAllStudents;

  /// No description provided for @allStudents.
  ///
  /// In en, this message translates to:
  /// **'All students'**
  String get allStudents;

  /// No description provided for @filterAllClassrooms.
  ///
  /// In en, this message translates to:
  /// **'Filter: all classrooms'**
  String get filterAllClassrooms;

  /// No description provided for @allClassrooms.
  ///
  /// In en, this message translates to:
  /// **'All classrooms'**
  String get allClassrooms;

  /// No description provided for @filterByTeacher.
  ///
  /// In en, this message translates to:
  /// **'Filter by teacher'**
  String get filterByTeacher;

  /// No description provided for @allTeachers.
  ///
  /// In en, this message translates to:
  /// **'All teachers'**
  String get allTeachers;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort: {value}'**
  String sortBy(String value);

  /// No description provided for @removeStudentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove student'**
  String get removeStudentTooltip;

  /// No description provided for @removeStudentTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove student?'**
  String get removeStudentTitle;

  /// No description provided for @removeStudentConfirm.
  ///
  /// In en, this message translates to:
  /// **'{studentName} will be removed from all of your classrooms and your roster. Their record and grade history are kept, and other teachers or parents linked to them are unaffected.'**
  String removeStudentConfirm(String studentName);

  /// No description provided for @removedStudent.
  ///
  /// In en, this message translates to:
  /// **'Removed {studentName}.'**
  String removedStudent(String studentName);

  /// No description provided for @classroomsColumn.
  ///
  /// In en, this message translates to:
  /// **'Classroom(s)'**
  String get classroomsColumn;

  /// No description provided for @enterTeacherCodeInstruction.
  ///
  /// In en, this message translates to:
  /// **'Enter the code your teacher gave you. You must already be on that teacher\'s classroom roster (matched by your name, surname, and school ID) for this to work.'**
  String get enterTeacherCodeInstruction;

  /// No description provided for @teacherCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Teacher code'**
  String get teacherCodeLabel;

  /// No description provided for @linkedToTeacher.
  ///
  /// In en, this message translates to:
  /// **'Linked to {teacherName}'**
  String linkedToTeacher(String teacherName);

  /// No description provided for @nowLinkedToTeacher.
  ///
  /// In en, this message translates to:
  /// **'You\'re now linked to this teacher.'**
  String get nowLinkedToTeacher;

  /// No description provided for @addedToClassrooms.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been added to: {classrooms}'**
  String addedToClassrooms(String classrooms);

  /// No description provided for @enterChildStudentCode.
  ///
  /// In en, this message translates to:
  /// **'Enter your child\'s student code (found on their profile page).'**
  String get enterChildStudentCode;

  /// No description provided for @studentCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Student code'**
  String get studentCodeLabel;

  /// No description provided for @studentLinked.
  ///
  /// In en, this message translates to:
  /// **'Student linked.'**
  String get studentLinked;

  /// No description provided for @schoolIdValue.
  ///
  /// In en, this message translates to:
  /// **'School ID: {id}'**
  String schoolIdValue(String id);

  /// No description provided for @fillInAllRosterFields.
  ///
  /// In en, this message translates to:
  /// **'Fill in name, surname, and school ID for every roster row (or remove it).'**
  String get fillInAllRosterFields;

  /// No description provided for @schoolIdMustBeNumberRoster.
  ///
  /// In en, this message translates to:
  /// **'School ID must be a number.'**
  String get schoolIdMustBeNumberRoster;

  /// No description provided for @studentsSection.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get studentsSection;

  /// No description provided for @addRow.
  ///
  /// In en, this message translates to:
  /// **'Add row'**
  String get addRow;

  /// No description provided for @enterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get enterManually;

  /// No description provided for @pickClassroomAndStudentGradeHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a classroom and student, then type in the grade.'**
  String get pickClassroomAndStudentGradeHint;

  /// No description provided for @scanOpticForm.
  ///
  /// In en, this message translates to:
  /// **'Scan optic form'**
  String get scanOpticForm;

  /// No description provided for @readExamSheet.
  ///
  /// In en, this message translates to:
  /// **'Read exam sheet'**
  String get readExamSheet;

  /// No description provided for @selectClassroomFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a classroom first'**
  String get selectClassroomFirst;

  /// No description provided for @subjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject (e.g. Math)'**
  String get subjectLabel;

  /// No description provided for @gradeValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Grade (e.g. 85 or A-)'**
  String get gradeValueLabel;

  /// No description provided for @pickClassroomAndStudentGradeError.
  ///
  /// In en, this message translates to:
  /// **'Pick a classroom and student, and fill in subject and grade.'**
  String get pickClassroomAndStudentGradeError;

  /// No description provided for @gradeAdded.
  ///
  /// In en, this message translates to:
  /// **'Grade added.'**
  String get gradeAdded;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @deleteAnnouncementTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete announcement'**
  String get deleteAnnouncementTooltip;

  /// No description provided for @deleteAnnouncementTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete announcement?'**
  String get deleteAnnouncementTitle;

  /// No description provided for @deleteAnnouncementConfirm.
  ///
  /// In en, this message translates to:
  /// **'This announcement will be permanently deleted.'**
  String get deleteAnnouncementConfirm;

  /// No description provided for @deletedAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'Announcement deleted.'**
  String get deletedAnnouncement;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
