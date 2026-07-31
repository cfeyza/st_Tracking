import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class DrawerAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  DrawerAction({required this.icon, required this.label, required this.onTap});
}

/// Shared left drawer: a tappable profile picture up top, a caller-supplied
/// list of action buttons, and a logout item that always sits at the bottom.
class AppDrawer extends StatelessWidget {
  final VoidCallback onProfileTap;
  final List<DrawerAction> actions;

  const AppDrawer({super.key, required this.onProfileTap, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          GestureDetector(
            onTap: onProfileTap,
            child: DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.grey),
                ),
              ),
            ),
          ),
          for (final action in actions)
            ListTile(
              leading: Icon(action.icon),
              title: Text(action.label),
              onTap: action.onTap,
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
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
