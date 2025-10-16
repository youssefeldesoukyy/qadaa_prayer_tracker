import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qadaa_prayer_tracker/models/daily_totals.dart';
import 'package:qadaa_prayer_tracker/Views/Dashboard/home_dashboard.dart';
import 'package:qadaa_prayer_tracker/l10n/app_localizations.dart';
import 'package:qadaa_prayer_tracker/Views/qadaa_missed.dart';
import 'package:qadaa_prayer_tracker/Views/sign_up_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  // ✅ Normal Email/Password Sign In
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

      await _navigateAfterSignIn(userCredential.user);
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

  // ✅ Google Sign-In
  Future<void> _signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      await googleSignIn.signOut(); // force re-pick each time

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return;

      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('Users').doc(user.uid);
      final doc = await userRef.get();

      if (!doc.exists) {
        // Create minimal new user record
        final displayName = user.displayName ?? '';
        final parts = displayName.split(' ');
        final firstName = parts.isNotEmpty ? parts.first : '';
        final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

        await userRef.set({
          'id': user.uid,
          'email': user.email,
          'firstName': firstName,
          'lastName': lastName,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const QadaaMissed()),
          );
        }
        return;
      }

      // Existing user → go to HomeDashboard
      await _navigateAfterSignIn(user);
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google Sign-In failed")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ Apple Sign-In (iOS only)
  Future<void> _signInWithApple() async {
    try {
      setState(() => _isLoading = true);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      await _navigateAfterSignIn(userCredential.user);
    } catch (e) {
      debugPrint('Apple sign-in error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Apple Sign-In failed")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ Guest Sign-In (local only)
  Future<void> _continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isGuest', true);
    final currentLang = Localizations.localeOf(context).languageCode;
    await prefs.setString('language_code', currentLang);

    final isFirstTime = prefs.getBool('isGuestFirstTime') ?? true;

    if (isFirstTime) {
      // 🆕 First-time guest
      await prefs.setBool('isGuestFirstTime', true);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const QadaaMissed()),
        );
      }
      return;
    }

    // 🟢 Returning guest
    final totalsData = prefs.getString('guestTotals');
    final perDayData = prefs.getString('guestPerDay');

    if (totalsData != null) {
      final totals = DailyTotals.fromJson(jsonDecode(totalsData));
      final perDay = perDayData != null
          ? Map<String, int>.from(jsonDecode(perDayData))
          : null;

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeDashboard(initial: totals, perDay: perDay),
          ),
        );
      }
    } else {
      // Fallback: go to setup again
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const QadaaMissed()),
        );
      }
    }
  }

  // ✅ Shared function for navigating after Firebase login
  Future<void> _navigateAfterSignIn(User? user) async {
    if (user == null) return;
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

    if (prayerPlan == null || prayerPlan['missedPrayers'] == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const QadaaMissed()),
        );
      }
      return;
    }

    final missedPrayers =
        Map<String, dynamic>.from(prayerPlan['missedPrayers'] ?? {});
    final totals = DailyTotals.fromMap(missedPrayers);

    final dailyPlanRaw = prayerPlan['dailyPlan'] as Map<String, dynamic>? ?? {};
    final perDay =
        dailyPlanRaw.map((key, value) => MapEntry(key, (value as num).toInt()));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeDashboard(initial: totals, perDay: perDay),
        ),
      );
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
              child: Text(loc.send,
                  style: const TextStyle(color: Color(0xFF2563EB))),
            ),
          ],
        );
      },
    );
  }

  // ✅ UI
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
                //Email & Password fields
                TextField(
                  controller: _emailOrPhoneController,
                  cursorColor: const Color(0xFF2563EB),
                  decoration: InputDecoration(
                    labelText: loc.emailLabel,
                    labelStyle: const TextStyle(color: Colors.black54),
                    floatingLabelStyle:
                        const TextStyle(color: Color(0xFF2563EB)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF2563EB), width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  cursorColor: const Color(0xFF2563EB),
                  decoration: InputDecoration(
                    labelText: loc.passwordLabel,
                    labelStyle: const TextStyle(color: Colors.black54),
                    floatingLabelStyle:
                        const TextStyle(color: Color(0xFF2563EB)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0xFF2563EB), width: 2),
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
                      : Text(loc.signIn,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 20),
                // 🔹 New Social Buttons
// 🔹 Social Sign-In Row (Google + Apple)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        icon: SvgPicture.asset(
                          "assets/icons/google.svg",
                          height: 24,
                        ),
                        label: const Text(
                          "Google",
                          style: TextStyle(color: Colors.black54),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _signInWithApple,
                        icon: SvgPicture.asset(
                          "assets/icons/apple.svg",
                          height: 24,
                        ),
                        label: const Text(
                          "Apple",
                          style: TextStyle(color: Colors.black54),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _isLoading ? null : _continueAsGuest,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Continue as Guest",
                    style: TextStyle(color: Color(0xFF2563EB)),
                  ),
                ),

                const SizedBox(height: 20),
                TextButton(
                  onPressed: _resetPassword,
                  child: Text(loc.forgotPassword,
                      style: const TextStyle(color: Color(0xFF2563EB))),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      loc.noAccount,
                      style: const TextStyle(color: Colors.black54),
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
