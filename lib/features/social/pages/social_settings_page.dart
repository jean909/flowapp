import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/l10n/app_localizations.dart';

class SocialSettingsPage extends StatefulWidget {
  const SocialSettingsPage({super.key});

  @override
  State<SocialSettingsPage> createState() => _SocialSettingsPageState();
}

class _SocialSettingsPageState extends State<SocialSettingsPage> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isPublic = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final profile = await _supabaseService.getProfile();
      if (mounted) {
        setState(() {
          _isPublic = profile?['is_public'] ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingSettings(e.toString()))),
        );
      }
    }
  }

  Future<void> _updatePublicProfile(bool value) async {
    try {
      await _supabaseService.updateProfile({'is_public': value});
      if (mounted) {
        setState(() => _isPublic = value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value 
              ? AppLocalizations.of(context)!.profileNowPublic 
              : AppLocalizations.of(context)!.profileNowPrivate),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorUpdatingSettings(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Privacy Section
                Text(
                  'Privacy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.publicProfile),
                    subtitle: Text(
                      _isPublic
                          ? 'Anyone can see your profile and posts'
                          : 'Only people you follow can see your profile',
                    ),
                    value: _isPublic,
                    onChanged: _updatePublicProfile,
                    secondary: Icon(
                      _isPublic ? Icons.public : Icons.lock,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Account Section
                Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(AppLocalizations.of(context)!.aboutSocial),
                    subtitle: Text(AppLocalizations.of(context)!.manageSocialProfileSettings),
                    onTap: () {
                      // Could add more settings here
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

