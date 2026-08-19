import 'package:flutter/material.dart';
import 'package:student_tracking_app/l10n/app_localizations.dart';

import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/language_button.dart';
import '../../widgets/teal_input_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _role = 'student';
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _schoolIdController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _schoolIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.register(
        role: _role,
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        schoolId: _role == 'student' ? int.parse(_schoolIdController.text.trim()) : null,
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.registrationSuccess),
          duration: const Duration(seconds: 6),
        ),
      );
      _formKey.currentState!.reset();
      _nameController.clear();
      _surnameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _schoolIdController.clear();
      setState(() => _role = 'student');
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AuthBackground(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Compact gradient header ──────────────────────────────
              SizedBox(
                height: (mq.size.height * 0.22).clamp(140.0, 200.0),
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
                          const Icon(
                            Icons.person_add_alt_1_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            l10n.register,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
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
                      const Text(
                        'Create account',
                        style: TextStyle(
                          color: AppColors.deepTeal,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Role selector
                      DropdownButtonFormField<String>(
                        value: _role,
                        style: const TextStyle(color: Color(0xFF006064), fontSize: 15),
                        dropdownColor: Colors.white,
                        decoration: InputDecoration(
                          labelText: l10n.iAmA,
                          labelStyle: const TextStyle(color: Color(0xFF0097A7)),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF00ACC1), Color(0xFF26C6DA)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                              child: const Icon(Icons.badge_outlined,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF0FDFE),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Color(0xFFB2EBF2), width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Color(0xFF00BCD4), width: 2),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        items: [
                          DropdownMenuItem(
                              value: 'teacher', child: Text(l10n.teacher)),
                          DropdownMenuItem(
                              value: 'student', child: Text(l10n.student)),
                          DropdownMenuItem(
                              value: 'parent', child: Text(l10n.parent)),
                        ],
                        onChanged: (value) => setState(() => _role = value!),
                      ),
                      const SizedBox(height: 16),

                      TealInputField(
                        controller: _nameController,
                        label: l10n.name,
                        icon: Icons.person_outline_rounded,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l10n.nameRequired : null,
                      ),
                      const SizedBox(height: 16),

                      TealInputField(
                        controller: _surnameController,
                        label: l10n.surname,
                        icon: Icons.person_outline_rounded,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? l10n.surnameRequired
                                : null,
                      ),

                      if (_role == 'student') ...[
                        const SizedBox(height: 16),
                        TealInputField(
                          controller: _schoolIdController,
                          label: l10n.schoolId,
                          icon: Icons.domain_rounded,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (_role != 'student') return null;
                            final trimmed = v?.trim() ?? '';
                            if (trimmed.isEmpty) return l10n.schoolIdRequired;
                            if (int.tryParse(trimmed) == null) {
                              return l10n.schoolIdMustBeNumber;
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),

                      TealInputField(
                        controller: _emailController,
                        label: l10n.email,
                        icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? l10n.emailRequired : null,
                      ),
                      const SizedBox(height: 16),

                      TealInputField(
                        controller: _passwordController,
                        label: l10n.password,
                        icon: Icons.lock_outline_rounded,
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return l10n.passwordRequired;
                          if (v.length < 8) return l10n.passwordMinLength;
                          return null;
                        },
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
                            : Text(l10n.register),
                      ),
                      const SizedBox(height: 14),

                      TextButton(
                        onPressed: () => Navigator.of(context)
                            .pushNamedAndRemoveUntil('/login', (route) => false),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryCyan,
                        ),
                        child: Text(l10n.alreadyHaveAccount),
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
