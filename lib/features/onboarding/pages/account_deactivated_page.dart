import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/core/theme/app_spacing.dart';
import 'package:flow/core/widgets/flow_widgets.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/features/onboarding/pages/auth_page.dart';
import 'package:flow/l10n/app_localizations.dart';

/// Shown when account was deactivated because email was not confirmed in time.
class AccountDeactivatedPage extends StatelessWidget {
  const AccountDeactivatedPage({super.key});

  Future<void> _resendConfirmation(BuildContext context) async {
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null || email.isEmpty) return;
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.confirmationEmailSent)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString()))),
        );
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await SupabaseService().signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage(isSignUp: false)),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.paddingPage,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mark_email_unread_rounded, size: 80, color: AppColors.warning),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                l10n.accountPaused,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.accountPausedMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              FlowButton(
                text: l10n.resendConfirmationEmail,
                onPressed: () => _resendConfirmation(context),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () => _signOut(context),
                child: Text(
                  l10n.logout,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
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
