import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qadaa_prayer_tracker/core/app_colors.dart';
import 'package:qadaa_prayer_tracker/core/services/auth_exceptions.dart';
import 'package:qadaa_prayer_tracker/core/services/auth_flow_result.dart';
import 'package:qadaa_prayer_tracker/core/services/auth_service.dart';
import 'package:qadaa_prayer_tracker/Views/Dashboard/home_dashboard.dart';
import 'package:qadaa_prayer_tracker/Views/qadaa_missed.dart';
import 'package:qadaa_prayer_tracker/l10n/app_localizations.dart';
import 'package:qadaa_prayer_tracker/views/registration/sign_up_screen.dart';
import 'package:qadaa_prayer_tracker/core/animations/slide_page_route.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  final AuthService _authService = AuthService();

  Future<void> _signIn() async {
    final loc = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.signInWithEmail(
        email: _emailOrPhoneController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (user == null) {
        setState(() => _errorMessage = loc.loginFailed);
        return;
      }

      final result = await _authService.determinePostSignIn(user);
      if (!mounted) return;
      _handleAuthResult(result);
    } on FirebaseAuthException catch (e) {
      String errorMessage = loc.loginFailed;
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        errorMessage = loc.invalidCredentials;
      } else if (e.code == 'invalid-email') {
        errorMessage = loc.invalidEmail;
      } else if (e.code == 'user-disabled') {
        errorMessage = loc.accountDisabled;
      }

      setState(() => _errorMessage = errorMessage);
    } catch (e) {
      debugPrint('Email sign-in error: $e');
      setState(() => _errorMessage = loc.loginFailed);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    final loc = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.signInWithGoogle();
      if (!mounted) return;
      
      final result = await _authService.determinePostSignIn(user);
      if (!mounted) return;
      _handleAuthResult(result);
    } on AuthCancelledException {
      // User aborted the Google flow - just reset loading state
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Google sign-in Firebase error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppColors.styledSnackBar(loc.googleSignInFailed),
      );
    } catch (e, stackTrace) {
      debugPrint('Google sign-in error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppColors.styledSnackBar(loc.googleSignInFailed),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithApple() async {
    final loc = AppLocalizations.of(context)!;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.signInWithApple();
      if (!mounted) return;
      
      final result = await _authService.determinePostSignIn(user);
      if (!mounted) return;
      _handleAuthResult(result);
    } on AuthCancelledException {
      // User aborted the Apple flow - just reset loading state
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Apple sign-in Firebase error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppColors.styledSnackBar(loc.appleSignInFailed),
      );
    } catch (e, stackTrace) {
      debugPrint('Apple sign-in error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppColors.styledSnackBar(loc.appleSignInFailed),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _continueAsGuest() async {
    final loc = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final localeCode = Localizations.localeOf(context).languageCode;
      final result = await _authService.continueAsGuest(localeCode);
      if (!mounted) return;
      _handleAuthResult(result);
    } catch (e) {
      debugPrint('Guest sign-in error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppColors.styledSnackBar(loc.loginFailed),
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

  // ✅ Reset Password
  Future<void> _resetPassword() async {
    final loc = AppLocalizations.of(context)!;
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            loc.resetPasswordTitle,
            style: const TextStyle(color: AppColors.text),
          ),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              labelText: loc.emailLabel,
              labelStyle: const TextStyle(color: AppColors.text),
              filled: true,
              fillColor: AppColors.accent.withValues(alpha: 0.1),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: AppColors.secondary.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel,
                  style: const TextStyle(color: AppColors.primary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    AppColors.styledSnackBar(loc.enterEmailWarning),
                  );
                  return;
                }
                try {
                  await _authService.sendPasswordReset(email);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    AppColors.styledSnackBar(loc.resetEmailSent),
                  );
                } on FirebaseAuthException catch (e) {
                  String msg = loc.resetFailed;
                  if (e.code == 'user-not-found') msg = loc.emailNotFound;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(AppColors.styledSnackBar(msg));
                } catch (e) {
                  debugPrint('Reset password error: $e');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    AppColors.styledSnackBar(loc.resetFailed),
                  );
                }
              },
              child: Text(loc.send,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: AppColors.secondary.withValues(alpha: 0.3)),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
          children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        Center(
                          child: Image.asset(
                            'assets/icons/Itmam_logo.png',
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 1),
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
                            loc.signInTagline,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.error_outline,
                                    color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: AppColors.text,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        TextField(
                          controller: _emailOrPhoneController,
                          cursorColor: AppColors.primary,
                          decoration: InputDecoration(
                            labelText: loc.emailLabel,
                            labelStyle: const TextStyle(color: AppColors.text),
                            prefixIcon: const Icon(
                              Icons.mail_outline_rounded,
                              color: AppColors.text,
                            ),
                            filled: true,
                            fillColor: AppColors.accent.withValues(alpha: 0.1),
                            enabledBorder: inputBorder,
                            focusedBorder: inputBorder.copyWith(
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          cursorColor: AppColors.primary,
                          decoration: InputDecoration(
                            labelText: loc.passwordLabel,
                            labelStyle: const TextStyle(color: AppColors.text),
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.text,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.text,
                              ),
                              onPressed: () => setState(() {
                                _obscurePassword = !_obscurePassword;
                              }),
                            ),
                            filled: true,
                            fillColor: AppColors.accent.withValues(alpha: 0.1),
                            enabledBorder: inputBorder,
                            focusedBorder: inputBorder.copyWith(
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _resetPassword,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                            ),
                            child: Text(
                              loc.forgotPassword,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 18),
                              shape: const StadiumBorder(),
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              loc.signIn,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildSectionDivider(loc.orContinueWith),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _signInWithGoogle,
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(
                                    color: AppColors.primary.withValues(alpha: 0.5),
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      "assets/icons/google.svg",
                                      height: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      loc.google,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.text,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : _signInWithApple,
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(
                                    color: AppColors.primary.withValues(alpha: 0.5),
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SvgPicture.asset(
                                      "assets/icons/apple.svg",
                                      height: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      loc.apple,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.text,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _continueAsGuest,
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.5),
                              ),
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              loc.continueAsGuest,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              loc.noAccount,
                              style: const TextStyle(
                                color: AppColors.text,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  SlidePageRoute(
                                    page: const SignUpScreen(),
                                    direction: SlideDirection.rightToLeft,
                                  ),
                                );
                              },
                              child: Text(
                                loc.signUp,
                                style: const TextStyle(
                                  color: AppColors.primary,
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

  Widget _buildSectionDivider(String label) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
                                    color: AppColors.secondary.withValues(alpha: 0.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
                                    color: AppColors.secondary.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}
