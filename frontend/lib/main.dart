import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'locale_notifier.dart';
import 'navigation.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/parent/parent_add_student_code_screen.dart';
import 'screens/parent/parent_home_screen.dart';
import 'screens/parent/parent_profile_screen.dart';
import 'screens/parent/parent_student_grades_screen.dart';
import 'screens/parent/parent_students_screen.dart';
import 'screens/student/student_add_teacher_code_screen.dart';
import 'screens/student/student_grades_screen.dart';
import 'screens/student/student_home_screen.dart';
import 'screens/student/student_profile_screen.dart';
import 'screens/teacher/teacher_add_classroom_screen.dart';
import 'screens/teacher/teacher_add_grade_options_screen.dart';
import 'screens/teacher/teacher_add_grade_screen.dart';
import 'screens/teacher/teacher_classrooms_screen.dart';
import 'screens/teacher/teacher_grades_screen.dart';
import 'screens/teacher/teacher_home_screen.dart';
import 'screens/teacher/teacher_profile_screen.dart';
import 'screens/teacher/teacher_students_screen.dart';
import 'services/fcm_service.dart';
import 'services/session.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Runs in a separate isolate spawned fresh when the app is backgrounded or
  // killed, so Firebase must be initialized again here.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await Session.load();
  await loadSavedLocale();

  if (!kIsWeb) {
    try {
      await FcmService.init();
    } catch (e, stackTrace) {
      debugPrint('FCM init failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }


  runApp(const StudentTrackingApp());
}

class StudentTrackingApp extends StatelessWidget {
  const StudentTrackingApp({super.key});

  static Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        if (!Session.isLoggedIn) {
          return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
        return switch (Session.role) {
          'teacher' => MaterialPageRoute(builder: (_) => const TeacherHomeScreen()),
          'student' => MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
          'parent' => MaterialPageRoute(builder: (_) => const ParentHomeScreen()),
          _ => MaterialPageRoute(builder: (_) => const LoginScreen()),
        };
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case '/teacher/home':
        return MaterialPageRoute(builder: (_) => const TeacherHomeScreen());
      case '/teacher/profile':
        return MaterialPageRoute(builder: (_) => const TeacherProfileScreen());
      case '/teacher/classrooms':
        return MaterialPageRoute(builder: (_) => const TeacherClassroomsScreen());
      case '/teacher/add-classroom':
        return MaterialPageRoute(builder: (_) => const TeacherAddClassroomScreen());
      case '/teacher/students':
        final args = settings.arguments as Map?;
        return MaterialPageRoute(
          builder: (_) => TeacherStudentsScreen(
            initialClassroomId: args?['classroomId'] as int?,
            initialClassroomName: args?['classroomName'] as String?,
          ),
        );
      case '/teacher/add-grade-options':
        return MaterialPageRoute(builder: (_) => const TeacherAddGradeOptionsScreen());
      case '/teacher/add-grade':
        return MaterialPageRoute(builder: (_) => const TeacherAddGradeScreen());
      case '/teacher/grades':
        final args = settings.arguments as Map?;
        return MaterialPageRoute(
          builder: (_) => TeacherGradesScreen(
            initialStudentId: args?['studentId'] as int?,
            initialStudentName: args?['studentName'] as String?,
          ),
        );

      case '/student/home':
        return MaterialPageRoute(builder: (_) => const StudentHomeScreen());
      case '/student/profile':
        return MaterialPageRoute(builder: (_) => const StudentProfileScreen());
      case '/student/add-teacher-code':
        return MaterialPageRoute(builder: (_) => const StudentAddTeacherCodeScreen());
      case '/student/grades':
        return MaterialPageRoute(builder: (_) => const StudentGradesScreen());

      case '/parent/home':
        return MaterialPageRoute(builder: (_) => const ParentHomeScreen());
      case '/parent/profile':
        return MaterialPageRoute(builder: (_) => const ParentProfileScreen());
      case '/parent/add-student-code':
        return MaterialPageRoute(builder: (_) => const ParentAddStudentCodeScreen());
      case '/parent/students':
        return MaterialPageRoute(builder: (_) => const ParentStudentsScreen());
      case '/parent/student-grades':
        final args = settings.arguments as Map?;
        return MaterialPageRoute(
          builder: (_) => ParentStudentGradesScreen(
            studentId: args?['studentId'] as int? ?? 0,
            studentName: args?['studentName'] as String? ?? '',
          ),
        );

      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'Student Tracking App',
          navigatorKey: navigatorKey,
          locale: locale,
          theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo), useMaterial3: true),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('tr'),
          ],
          initialRoute: '/',
          onGenerateRoute: _onGenerateRoute,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
