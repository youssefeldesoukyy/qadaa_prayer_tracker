import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qadaa_prayer_tracker/core/app_colors.dart';
import 'package:qadaa_prayer_tracker/core/services/auth_flow_result.dart';
import 'package:qadaa_prayer_tracker/core/services/auth_service.dart';
import 'package:qadaa_prayer_tracker/Views/Dashboard/home_dashboard.dart';
import 'package:qadaa_prayer_tracker/Views/qadaa_missed.dart';
import 'package:qadaa_prayer_tracker/l10n/app_localizations.dart';
import 'package:qadaa_prayer_tracker/core/animations/slide_page_route.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
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
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validation checks
    if (firstName.isEmpty ||
        lastName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppColors.styledSnackBar(loc.fillAllFields),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppColors.styledSnackBar(loc.passwordsDoNotMatch),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _authService.signUp(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        AppColors.styledSnackBar(loc.accountCreated),
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
        AppColors.styledSnackBar(error),
      );
    } catch (e) {
      debugPrint('Sign-up error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        AppColors.styledSnackBar(loc.somethingWentWrong),
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
          SlidePageRoute(
            page: const QadaaMissed(),
            direction: SlideDirection.rightToLeft,
          ),
        );
        break;
      case AuthTarget.homeDashboard:
        final totals = result.totals;
        if (totals == null) {
          Navigator.pushReplacement(
            context,
            SlidePageRoute(
              page: const QadaaMissed(),
              direction: SlideDirection.rightToLeft,
            ),
          );
          return;
        }
        Navigator.pushReplacement(
          context,
          SlidePageRoute(
            page: HomeDashboard(
              initial: totals,
              perDay: result.perDay,
            ),
            direction: SlideDirection.rightToLeft,
          ),
        );
        break;
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: AppColors.secondary.withValues(alpha: 0.3),
      ),
    );

    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: AppColors.text),
      floatingLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
      prefixIcon: Icon(icon, color: AppColors.text),
      filled: true,
      fillColor: AppColors.accent.withValues(alpha: 0.1),
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(12, 0, 12, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.text),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(height: 0),
                        // Logo
                        Center(
                          child: Image.asset(
                            'assets/icons/Itmam_logo.png',
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 0),
                        Center(
                          child: Text(
                            loc.appTitle,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            loc.signUpTagline,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _firstNameController,
                                cursorColor: AppColors.primary,
                                decoration: _inputDecoration(
                                        loc.firstName, Icons.person_outline_rounded)
                                    .copyWith(
                                  labelText: null,
                                  hintText: loc.firstName,
                                  hintStyle: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _lastNameController,
                                cursorColor: AppColors.primary,
                                decoration: _inputDecoration(
                                        loc.lastName, Icons.person_outline_rounded)
                                    .copyWith(
                                  labelText: null,
                                  hintText: loc.lastName,
                                  hintStyle: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.text,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          cursorColor: AppColors.primary,
                          decoration: _inputDecoration(
                              loc.emailLabel, Icons.mail_outline_rounded),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          cursorColor: AppColors.primary,
                          decoration: _inputDecoration(
                              loc.passwordLabel, Icons.lock_outline_rounded)
                              .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.text,
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
                          cursorColor: AppColors.primary,
                          decoration: _inputDecoration(
                              loc.confirmPassword, Icons.lock_outline_rounded)
                              .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.text,
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
                              backgroundColor: AppColors.primary,
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
                        // const SizedBox(height: 12),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: [
                        //     Text(
                        //       loc.alreadyHaveAccount,
                        //       style: const TextStyle(
                        //         color: AppColors.text,
                        //       ),
                        //     ),
                        //     TextButton(
                        //       onPressed: () => Navigator.pop(context),
                        //       child: Text(
                        //         loc.signIn,
                        //         style: const TextStyle(
                        //           color: AppColors.primary,
                        //           fontWeight: FontWeight.w700,
                        //         ),
                        //       ),
                        //     ),
                        //   ],
                        // ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: AppColors.text.withValues(alpha: 0.5),
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
