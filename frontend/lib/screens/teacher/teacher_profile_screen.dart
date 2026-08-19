import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../models/teacher.dart';
import '../../services/api_client.dart';
import '../../services/teacher_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile_widgets.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  late Future<TeacherProfile> _future;

  @override
  void initState() {
    super.initState();
    _future = TeacherService.getMe();
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
      body: FutureBuilder<TeacherProfile>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error is ApiException
                  ? (snapshot.error as ApiException).message
                  : snapshot.error.toString()),
            );
          }
          final teacher = snapshot.data!;
          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: const ContentShapesPainter())),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfileHeader(
                      name: '${teacher.name} ${teacher.surname}',
                      role: l10n.teacher,
                    ),
                    Padding(
                      padding: AppInsets.page(context),
                      child: ProfileInfoCard(
                        children: [
                          ProfileInfoTile(
                            icon: Icons.qr_code_rounded,
                            label: l10n.teacherCode,
                            value: teacher.teacherCode,
                            onTap: () => _copy(context, l10n.teacherCode, teacher.teacherCode),
                            trailing: Icon(Icons.copy_rounded,
                                size: 18, color: AppColors.primaryCyan),
                          ),
                          ProfileInfoTile(
                            icon: Icons.person_outline_rounded,
                            label: l10n.name,
                            value: teacher.name,
                          ),
                          ProfileInfoTile(
                            icon: Icons.badge_outlined,
                            label: l10n.surname,
                            value: teacher.surname,
                          ),
                          ProfileInfoTile(
                            icon: Icons.email_outlined,
                            label: l10n.email,
                            value: teacher.email,
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
