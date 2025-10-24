import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qadaa_prayer_tracker/core/services/auth_exceptions.dart';
import 'package:qadaa_prayer_tracker/core/services/auth_flow_result.dart';
import 'package:qadaa_prayer_tracker/core/services/auth_service.dart';
import 'package:qadaa_prayer_tracker/Views/Dashboard/home_dashboard.dart';
import 'package:qadaa_prayer_tracker/Views/qadaa_missed.dart';
import 'package:qadaa_prayer_tracker/l10n/app_localizations.dart';
import 'package:qadaa_prayer_tracker/views/registration/sign_up_screen.dart';

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
      final result = await _authService.determinePostSignIn(user);
      if (!mounted) return;
      _handleAuthResult(result);
    } on AuthCancelledException {
      // User aborted the Google flow.
    } on FirebaseAuthException catch (e) {
      debugPrint('Google sign-in Firebase error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.googleSignInFailed)),
      );
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.googleSignInFailed)),
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
      final result = await _authService.determinePostSignIn(user);
      if (!mounted) return;
      _handleAuthResult(result);
    } on AuthCancelledException {
      // User aborted the Apple flow.
    } on FirebaseAuthException catch (e) {
      debugPrint('Apple sign-in Firebase error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.loginFailed)),
      );
    } catch (e) {
      debugPrint('Apple sign-in error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.loginFailed)),
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
        SnackBar(content: Text(loc.loginFailed)),
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

  // ✅ Reset Password
  Future<void> _resetPassword() async {
    final loc = AppLocalizations.of(context)!;
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.resetPasswordTitle),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            cursorColor: const Color(0xFF2563EB),
            decoration: InputDecoration(
              labelText: loc.emailLabel,
              border: const OutlineInputBorder(),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel,
                  style: const TextStyle(color: Color(0xFF2563EB))),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.enterEmailWarning)),
                  );
                  return;
                }
                try {
                  await _authService.sendPasswordReset(email);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.resetEmailSent)),
                  );
                } on FirebaseAuthException catch (e) {
                  String msg = loc.resetFailed;
                  if (e.code == 'user-not-found') msg = loc.emailNotFound;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(msg)));
                } catch (e) {
                  debugPrint('Reset password error: $e');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.resetFailed)),
                  );
                }
              },
              child: Text(loc.send,
                  style: const TextStyle(color: Color(0xFF2563EB))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    const themeColor = Color(0xFF2563EB);
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    );

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
                  constraints: const BoxConstraints(maxWidth: 420),
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
                          loc.signInWelcome,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc.signInTagline,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 15,
                            height: 1.5,
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
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Color(0xFFDC2626)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Color(0xFFB91C1C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        TextField(
                          controller: _emailOrPhoneController,
                          cursorColor: themeColor,
                          decoration: InputDecoration(
                            labelText: loc.emailLabel,
                            prefixIcon: const Icon(
                              Icons.mail_outline_rounded,
                              color: Color(0xFF475569),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FBFF),
                            enabledBorder: inputBorder,
                            focusedBorder: inputBorder.copyWith(
                              borderSide: const BorderSide(
                                color: themeColor,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          cursorColor: themeColor,
                          decoration: InputDecoration(
                            labelText: loc.passwordLabel,
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: Color(0xFF475569),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: const Color(0xFF475569),
                              ),
                              onPressed: () => setState(() {
                                _obscurePassword = !_obscurePassword;
                              }),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FBFF),
                            enabledBorder: inputBorder,
                            focusedBorder: inputBorder.copyWith(
                              borderSide: const BorderSide(
                                color: themeColor,
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
                              foregroundColor: themeColor,
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
                              backgroundColor: themeColor,
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
                                  side: const BorderSide(
                                    color: Color(0xFFE2E8F0),
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
                                        color: Color(0xFF0F172A),
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
                                  side: const BorderSide(
                                    color: Color(0xFFE2E8F0),
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
                                        color: Color(0xFF0F172A),
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
                                color: themeColor.withValues(alpha: 0.35),
                              ),
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              loc.continueAsGuest,
                              style: const TextStyle(
                                color: themeColor,
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
                              loc.noAccount,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignUpScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                loc.signUp,
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

  Widget _buildSectionDivider(String label) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFE2E8F0),
          ),
        ),
      ],
    );
  }
}
