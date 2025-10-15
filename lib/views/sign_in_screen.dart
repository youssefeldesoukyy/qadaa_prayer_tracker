import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';
import 'package:qadaa_prayer_tracker/Views/Dashboard/home_dashboard.dart';
import 'package:qadaa_prayer_tracker/l10n/app_localizations.dart';
import 'package:qadaa_prayer_tracker/Views/qadaa_missed.dart';
import 'package:qadaa_prayer_tracker/Views/sign_up_screen.dart';

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

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _signIn() async {
    final loc = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailOrPhoneController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) {
        setState(() => _errorMessage = loc.loginFailed);
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('Users').doc(user.uid).get();

      if (!doc.exists) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const QadaaMissed()),
          );
        }
        return;
      }

      final data = doc.data() ?? {};
      final prayerPlan = data['prayerPlan'] as Map<String, dynamic>?;

      // if no prayer plan → go to setup
      if (prayerPlan == null || prayerPlan['missedPrayers'] == null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const QadaaMissed()),
          );
        }
        return;
      }

      // ✅ Parse missedPrayers to DailyTotals
      final missedPrayers = Map<String, dynamic>.from(
        prayerPlan['missedPrayers'] ?? {},
      );
      final totals = DailyTotals.fromMap(missedPrayers);

      // ✅ Parse perDay (dailyPlan) safely
      final dailyPlanRaw =
          prayerPlan['dailyPlan'] as Map<String, dynamic>? ?? {};
      final perDay = dailyPlanRaw.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      );

      // ✅ Navigate to HomeDashboard with loaded data
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeDashboard(
              initial: totals,
              perDay: perDay,
            ),
          ),
        );
      }
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
    } catch (_) {
      setState(() => _errorMessage = loc.loginFailed);
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
              labelStyle: const TextStyle(color: Colors.black54),
              floatingLabelStyle: const TextStyle(color: Color(0xFF2563EB)),
              border: const OutlineInputBorder(),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF2563EB), width: 2),
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                loc.cancel,
                style: const TextStyle(color: Color(0xFF2563EB)),
              ),
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
                  await FirebaseAuth.instance
                      .sendPasswordResetEmail(email: email);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.resetEmailSent)),
                    );
                  }
                } on FirebaseAuthException catch (e) {
                  String msg = loc.resetFailed;
                  if (e.code == 'user-not-found') msg = loc.emailNotFound;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(msg)));
                }
              },
              child: Text(
                loc.send,
                style: const TextStyle(color: Color(0xFF2563EB)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  loc.appTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.signInSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 32),

                // Email or phone
                TextField(
                  controller: _emailOrPhoneController, // or your controller
                  cursorColor: const Color(0xFF2563EB), // 🟦 cursor color
                  decoration: InputDecoration(
                    labelText: loc.emailLabel,
                    labelStyle: const TextStyle(color: Colors.black54), // default label color
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    prefixIcon: const Icon(Icons.person_outline),
                    // 🟦 make label turn blue when focused
                    floatingLabelStyle: const TextStyle(color: Color(0xFF2563EB)),
                  ),
                ),


                const SizedBox(height: 16),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  cursorColor: const Color(0xFF2563EB),
                  decoration: InputDecoration(
                    labelText: loc.passwordLabel,
                    labelStyle: const TextStyle(color: Colors.black54),
                    floatingLabelStyle: const TextStyle(color: Color(0xFF2563EB)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Error Message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                // Sign In button
                ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          loc.signIn,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),

                const SizedBox(height: 16),

                // Forgot password
                TextButton(
                  onPressed: () {
                    _resetPassword();
                  },
                  child: Text(
                    loc.forgotPassword,
                    style: const TextStyle(color: Color(0xFF2563EB)),
                  ),
                ),

                // Don’t have an account? Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      loc.noAccount,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 15,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignUpScreen()),
                        );
                      },
                      child: Text(
                        loc.signUp,
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
    );
  }
}
