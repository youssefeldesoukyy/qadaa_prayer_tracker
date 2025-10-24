import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qadaa_prayer_tracker/core/services/auth_flow_result.dart';
import 'package:qadaa_prayer_tracker/core/services/auth_service.dart';
import 'package:qadaa_prayer_tracker/Views/Dashboard/home_dashboard.dart';
import 'package:qadaa_prayer_tracker/Views/qadaa_missed.dart';
import 'package:qadaa_prayer_tracker/l10n/app_localizations.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _signUpUser() async {
    final loc = AppLocalizations.of(context)!;

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validation checks
    if (firstName.isEmpty ||
        lastName.isEmpty ||
        phone.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.fillAllFields)),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.passwordsDoNotMatch)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.signUp(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phone,
        email: email,
        password: password,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.accountCreated)),
      );

      _handleAuthResult(result);
    } on FirebaseAuthException catch (e) {
      String error = loc.somethingWentWrong;

      if (e.code == 'email-already-in-use') {
        error = loc.emailInUse;
      } else if (e.code == 'weak-password') {
        error = loc.weakPassword;
      } else if (e.code == 'invalid-email') {
        error = loc.invalidEmail;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } catch (e) {
      debugPrint('Sign-up error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.somethingWentWrong)),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleAuthResult(AuthFlowResult result) {
    if (!mounted) return;

    switch (result.target) {
      case AuthTarget.qadaaSetup:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const QadaaMissed()),
        );
        break;
      case AuthTarget.homeDashboard:
        final totals = result.totals;
        if (totals == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const QadaaMissed()),
          );
          return;
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeDashboard(
              initial: totals,
              perDay: result.perDay,
            ),
          ),
        );
        break;
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    const themeColor = Color(0xFF2563EB);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    );

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
      floatingLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: themeColor,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF475569)),
      filled: true,
      fillColor: const Color(0xFFF8FBFF),
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: themeColor, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    const themeColor = Color(0xFF2563EB);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/sign_in_background.jpg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 40,
                          offset: const Offset(0, 18),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.signUpWelcome,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc.signUpTagline,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _firstNameController,
                                cursorColor: themeColor,
                                decoration: _inputDecoration(
                                    loc.firstName, Icons.person_outline_rounded),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextField(
                                controller: _lastNameController,
                                cursorColor: themeColor,
                                decoration: _inputDecoration(
                                    loc.lastName, Icons.person_outline_rounded),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          cursorColor: themeColor,
                          decoration: _inputDecoration(
                              loc.phoneNumber, Icons.call_outlined),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          cursorColor: themeColor,
                          decoration: _inputDecoration(
                              loc.emailLabel, Icons.mail_outline_rounded),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          cursorColor: themeColor,
                          decoration: _inputDecoration(
                              loc.passwordLabel, Icons.lock_outline_rounded)
                              .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF475569),
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          cursorColor: themeColor,
                          decoration: _inputDecoration(
                              loc.confirmPassword, Icons.lock_outline_rounded)
                              .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF475569),
                              ),
                              onPressed: () => setState(() =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signUpUser,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: const StadiumBorder(),
                              backgroundColor: themeColor,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              loc.signUp,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              loc.alreadyHaveAccount,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                loc.signIn,
                                style: const TextStyle(
                                  color: themeColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
