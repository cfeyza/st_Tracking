import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../models/student.dart';
import '../../services/api_client.dart';
import '../../services/student_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile_widgets.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  late Future<StudentProfile> _future;

  @override
  void initState() {
    super.initState();
    _future = StudentService.getMe();
  }

  void _copy(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).copiedToClipboard(label))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: FutureBuilder<StudentProfile>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${(snapshot.error as ApiException?)?.message ?? snapshot.error}',
              ),
            );
          }
          final student = snapshot.data!;
          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: const ContentShapesPainter())),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfileHeader(
                      name: '${student.name} ${student.surname}',
                      role: l10n.student,
                    ),
                    Padding(
                      padding: AppInsets.page(context),
                      child: ProfileInfoCard(
                        children: [
                          ProfileInfoTile(
                            icon: Icons.qr_code_rounded,
                            label: l10n.studentCode,
                            value: student.studentCode,
                            onTap: () => _copy(context, l10n.studentCode, student.studentCode),
                            trailing: Icon(Icons.copy_rounded,
                                size: 18, color: AppColors.primaryCyan),
                          ),
                          ProfileInfoTile(
                            icon: Icons.person_outline_rounded,
                            label: l10n.name,
                            value: student.name,
                          ),
                          ProfileInfoTile(
                            icon: Icons.badge_outlined,
                            label: l10n.surname,
                            value: student.surname,
                          ),
                          ProfileInfoTile(
                            icon: Icons.tag_rounded,
                            label: l10n.schoolId,
                            value: student.schoolId.toString(),
                          ),
                          ProfileInfoTile(
                            icon: Icons.email_outlined,
                            label: l10n.email,
                            value: student.email,
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
