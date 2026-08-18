import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../models/student.dart';
import '../../services/api_client.dart';
import '../../services/student_service.dart';
import '../../theme/app_theme.dart';

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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(title: Text(l10n.profile), backgroundColor: cs.surface),
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
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileHeader(
                  name: '${student.name} ${student.surname}',
                  role: l10n.student,
                ),
                Padding(
                  padding: AppInsets.page(context),
                  child: Card(
                    shape: AppCard.shape(cs),
                    child: Column(
                      children: [
                        _InfoTile(
                          icon: Icons.qr_code,
                          label: l10n.studentCode,
                          value: student.studentCode,
                          trailing: const Icon(Icons.copy, size: 18),
                          onTap: () => _copy(context, l10n.studentCode, student.studentCode),
                        ),
                        _Divider(),
                        _InfoTile(icon: Icons.person_outline, label: l10n.name, value: student.name),
                        _Divider(),
                        _InfoTile(icon: Icons.badge_outlined, label: l10n.surname, value: student.surname),
                        _Divider(),
                        _InfoTile(
                          icon: Icons.tag,
                          label: l10n.schoolId,
                          value: student.schoolId.toString(),
                        ),
                        _Divider(),
                        _InfoTile(icon: Icons.email_outlined, label: l10n.email, value: student.email),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String role;

  const _ProfileHeader({required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isMobile = Bp.isMobile(context);
    final avatarRadius = isMobile ? 36.0 : 44.0;

    return Container(
      color: cs.primaryContainer,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 24 : 36,
        horizontal: 24,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: cs.onPrimaryContainer.withAlpha(26),
            child: Icon(Icons.person, size: avatarRadius, color: cs.onPrimaryContainer),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: (isMobile ? tt.titleLarge : tt.headlineSmall)
                ?.copyWith(color: cs.onPrimaryContainer),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            role,
            style: tt.bodyMedium?.copyWith(color: cs.onPrimaryContainer.withAlpha(178)),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
