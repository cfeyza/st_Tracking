import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../locale_notifier.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class DrawerAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  DrawerAction({required this.icon, required this.label, required this.onTap});
}

/// Shared left drawer: a tappable profile header up top, a caller-supplied
/// list of action buttons, and a logout item that always sits at the bottom.
class AppDrawer extends StatelessWidget {
  final VoidCallback onProfileTap;
  final List<DrawerAction> actions;

  const AppDrawer({super.key, required this.onProfileTap, required this.actions});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Drawer(
      width: 240,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              onProfileTap();
            },
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.drawerGradient,
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 24,
                20,
                24,
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.45),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(Icons.person_rounded, size: 28, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.profile,
                          style: textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              'View profile',
                              style: textTheme.labelSmall?.copyWith(
                                color: Colors.white.withOpacity(0.75),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: Colors.white.withOpacity(0.75),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          for (final action in actions)
            ListTile(
              leading: Icon(action.icon),
              title: Text(action.label),
              onTap: () {
                Navigator.of(context).pop();
                action.onTap();
              },
            ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 4),
          ValueListenableBuilder<Locale>(
            valueListenable: localeNotifier,
            builder: (context, locale, _) => ListTile(
              leading: const Icon(Icons.language),
              title: Text(locale.languageCode == 'tr' ? 'Türkçe' : 'English'),
              onTap: toggleLocale,
            ),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: colorScheme.error),
            title: Text(l10n.logOut, style: TextStyle(color: colorScheme.error)),
            onTap: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}
