import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../models/parent.dart';
import '../../services/api_client.dart';
import '../../services/parent_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/profile_widgets.dart';

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

    return Scaffold(
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
          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: const ContentShapesPainter())),
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfileHeader(
                      name: '${parent.name} ${parent.surname}',
                      role: l10n.parent,
                    ),
                    Padding(
                      padding: AppInsets.page(context),
                      child: ProfileInfoCard(
                        children: [
                          ProfileInfoTile(
                            icon: Icons.person_outline_rounded,
                            label: l10n.name,
                            value: parent.name,
                          ),
                          ProfileInfoTile(
                            icon: Icons.badge_outlined,
                            label: l10n.surname,
                            value: parent.surname,
                          ),
                          ProfileInfoTile(
                            icon: Icons.email_outlined,
                            label: l10n.email,
                            value: parent.email,
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
