import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/core/theme/app_spacing.dart';
import 'package:flow/core/widgets/flow_widgets.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/core/widgets/main_navigation.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:flow/features/onboarding/pages/auth_page.dart';
import 'package:flow/features/onboarding/pages/onboarding_page.dart';

class ConfirmEmailPage extends StatefulWidget {
  final String email;
  final String password;

  const ConfirmEmailPage({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<ConfirmEmailPage> createState() => _ConfirmEmailPageState();
}

class _ConfirmEmailPageState extends State<ConfirmEmailPage> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isChecking = false;

  void _checkConfirmation() async {
    setState(() => _isChecking = true);

    try {
      // Instead of refreshSession (which needs a session), we try to signIn.
      // If the email is confirmed, signIn will succeed.
      // If not, Supabase will throw an error 'Email not confirmed'.
      final response = await _supabaseService.signIn(
        widget.email,
        widget.password,
      );

      if (response.user != null && response.user!.emailConfirmedAt != null) {
        // Success! Ensure profile exists with metadata (it will recover from auth metadata)
        try {
          await _supabaseService.ensureProfileExists();

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const MainNavigationContainer(),
              ),
              (route) => false,
            );
          }
        } catch (profileError) {
          // If profile creation fails due to missing onboarding data, redirect to onboarding
          String errorMsg = profileError.toString();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                duration: const Duration(seconds: 5),
              ),
            );
            
            // Sign out and redirect to onboarding
            await _supabaseService.signOut();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const OnboardingPage(),
              ),
              (route) => false,
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.verificationPending),
            ),
          );
        }
      }
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('Email not confirmed')) {
        if (mounted) msg = AppLocalizations.of(context)!.verificationPending;
      } else if (msg.contains('Invalid login credentials')) {
        // This might happen if they change password or something, but shouldn't here
        msg = 'Something is wrong with the credentials. Try signing in again.';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInDown(
                child: Container(
                  padding: AppSpacing.paddingPage,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xxxl + 8),
              FadeInUp(
                child: Text(
                  AppLocalizations.of(context)!.verifyAccount,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Builder(
                  builder: (context) {
                    final sentLink = AppLocalizations.of(context)!.sentLink;
                    final dot = sentLink.indexOf('.');
                    final firstPart = dot >= 0 ? sentLink.substring(0, dot + 1) : '';
                    final rest = dot >= 0 ? sentLink.substring(dot + 1).trim() : sentLink;
                    final message = firstPart.isEmpty
                        ? '${widget.email}\n$sentLink'
                        : '$firstPart\n${widget.email}. $rest';
                    return Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.touchTarget + 12),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: FlowButton(
                  text: AppLocalizations.of(context)!.iveConfirmed,
                  isLoading: _isChecking,
                  onPressed: _checkConfirmation,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuthPage(isSignUp: false),
                      ),
                      (route) => false,
                    );
                  },
                  child: Text(
                    AppLocalizations.of(context)!.backToLogin,
                    style: const TextStyle(color: AppColors.textSecondary),
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
