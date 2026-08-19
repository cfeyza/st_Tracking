import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../models/parent.dart';
import '../../services/api_client.dart';
import '../../services/parent_service.dart';
import '../../theme/app_theme.dart';

class ParentProfileScreen extends StatefulWidget {
  const ParentProfileScreen({super.key});

  @override
  State<ParentProfileScreen> createState() => _ParentProfileScreenState();
}

class _ParentProfileScreenState extends State<ParentProfileScreen> {
  late Future<ParentProfile> _future;

  @override
  void initState() {
    super.initState();
    _future = ParentService.getMe();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(title: Text(l10n.profile)),
      body: FutureBuilder<ParentProfile>(
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
          final parent = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileHeader(
                  name: '${parent.name} ${parent.surname}',
                  role: l10n.parent,
                ),
                Padding(
                  padding: AppInsets.page(context),
                  child: Card(
                    shape: AppCard.shape(cs),
                    child: Column(
                      children: [
                        _InfoTile(icon: Icons.person_outline, label: l10n.name, value: parent.name),
                        _Divider(),
                        _InfoTile(icon: Icons.badge_outlined, label: l10n.surname, value: parent.surname),
                        _Divider(),
                        _InfoTile(icon: Icons.email_outlined, label: l10n.email, value: parent.email),
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

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
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
