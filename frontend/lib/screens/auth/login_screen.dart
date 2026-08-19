import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/language_button.dart';
import '../../widgets/teal_input_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final response = await AuthService.login(_emailController.text.trim(), _passwordController.text);
      if (!mounted) return;
      final homeRoute = switch (response.role) {
        'teacher' => '/teacher/home',
        'student' => '/student/home',
        'parent' => '/parent/home',
        _ => '/login',
      };
      Navigator.of(context).pushNamedAndRemoveUntil(homeRoute, (route) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mq = MediaQuery.of(context);
    final headerH = (mq.size.height * 0.40).clamp(200.0, 320.0);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AuthBackground(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Gradient header area ─────────────────────────────────
              SizedBox(
                height: headerH,
                child: SafeArea(
                  bottom: false,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 4,
                        right: 8,
                        child: const LanguageButton(),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.45),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.school_rounded,
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            l10n.appTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── White form card ──────────────────────────────────────
              Container(
                constraints: const BoxConstraints(minHeight: 380),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 24,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(28, 36, 28, mq.padding.bottom + 36),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.welcomeBack,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.deepTeal,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.logIn,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.deepTeal.withOpacity(0.55),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),
                      TealInputField(
                        controller: _emailController,
                        label: l10n.email,
                        icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? l10n.emailRequired : null,
                      ),
                      const SizedBox(height: 16),
                      TealInputField(
                        controller: _passwordController,
                        label: l10n.password,
                        icon: Icons.lock_outline_rounded,
                        obscureText: true,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? l10n.passwordRequired : null,
                      ),
                      const SizedBox(height: 30),
                      FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(l10n.logIn),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/register'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryCyan,
                        ),
                        child: Text(l10n.dontHaveAccount),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
