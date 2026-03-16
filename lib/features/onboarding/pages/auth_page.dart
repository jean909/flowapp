import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flow/features/onboarding/pages/confirm_email_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/flow_widgets.dart';
import '../../../services/supabase_service.dart';
import '../../../core/widgets/main_navigation.dart';
import 'package:flow/features/onboarding/models/onboarding_data.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:flow/features/onboarding/pages/forgot_password_page.dart';
import 'package:flow/features/onboarding/pages/onboarding_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthPage extends StatefulWidget {
  final bool isSignUp;
  final OnboardingData? onboardingData;

  const AuthPage({super.key, this.isSignUp = true, this.onboardingData});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  late bool _isSignUp;

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  bool _isValidEmail(String value) => _emailRegex.hasMatch(value);

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.isSignUp;
  }

  void _handleAuth() async {
    if (_isSignUp && widget.onboardingData == null) {
      // If Sign Up is pressed without onboarding data, navigate to onboarding
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingPage()),
      );
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseFillFields)),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.invalidEmail)),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.passwordMinLength)),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        // Validate that all required onboarding data is present
        if (widget.onboardingData == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.pleaseFillFields)),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        final data = widget.onboardingData!;
        final missingFields = <String>[];
        
        if (data.gender == null || data.gender!.isEmpty) missingFields.add('gender');
        if (data.goal == null || data.goal!.isEmpty) missingFields.add('goal');
        if (data.age == null) missingFields.add('age');
        if (data.currentWeight == null) missingFields.add('current_weight');
        if (data.height == null) missingFields.add('height');
        if (data.activityLevel == null || data.activityLevel!.isEmpty) missingFields.add('activity_level');

        if (missingFields.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.missingRequiredDataOnboarding(missingFields.join(", "))),
                duration: const Duration(seconds: 5),
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OnboardingPage()),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        // Save onboarding data locally as backup before signUp
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('pending_onboarding_data', jsonEncode(data.toJson()));
        await prefs.setString('pending_user_email', email);

        final response = await _supabaseService.signUp(
          email,
          password,
          data: data.toJson(),
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.welcomeFamily)),
        );

        // If email confirmation is disabled, Supabase may return a session immediately
        if (response.session != null) {
          try {
            await _supabaseService.ensureProfileExists();
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainNavigationContainer()),
                (route) => false,
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString()))),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConfirmEmailPage(
                    email: email,
                    password: password,
                  ),
                ),
              );
            }
          }
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmEmailPage(
                email: email,
                password: password,
              ),
            ),
          );
        }
      } else {
        await _supabaseService.signIn(email, password);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationContainer()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        final l10n = AppLocalizations.of(context)!;
        
        if (e is AuthException) {
          if (e.message.contains('Invalid login credentials')) {
            errorMsg = l10n.invalidCredentials;
          } else if (e.message.contains('Email not confirmed')) {
            errorMsg = l10n.verificationPending;
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorGeneric(errorMsg))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/login_bg.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.white70, BlendMode.lighten),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: AppSpacing.paddingPage,
                child: FadeInUp(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(230),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                          child: Image.asset(
                            'assets/images/flow_banner.png',
                            width: double.infinity,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: AppSpacing.sm),
                          child: Column(
                            children: [
                              Text(
                                _isSignUp
                                    ? AppLocalizations.of(context)!.createAccount
                                    : AppLocalizations.of(context)!.welcomeBack,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxxl),
                              TextField(
                                controller: _emailController,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: AppLocalizations.of(context)!.email,
                                  filled: true,
                                  fillColor: AppColors.background,
                                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: AppLocalizations.of(context)!.password,
                                  filled: true,
                                  fillColor: AppColors.background,
                                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxxl),
                                FlowButton(
                                  text: _isSignUp
                                      ? AppLocalizations.of(context)!.signUp
                                      : AppLocalizations.of(context)!.signIn,
                                  isLoading: _isLoading,
                                  onPressed: _handleAuth,
                                ),
                                if (!_isSignUp)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                                        );
                                      },
                                      child: Text(
                                        AppLocalizations.of(context)!.forgotPassword,
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                              const SizedBox(height: AppSpacing.xxl),
                              TextButton(
                                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                                child: Text(
                                  _isSignUp
                                      ? AppLocalizations.of(context)!.alreadyHaveAccount
                                      : AppLocalizations.of(context)!.needAccount,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
