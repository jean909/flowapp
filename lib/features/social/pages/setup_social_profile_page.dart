import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:flow/services/supabase_service.dart';
import 'dart:async';

class SetupSocialProfilePage extends StatefulWidget {
  const SetupSocialProfilePage({super.key});

  @override
  State<SetupSocialProfilePage> createState() => _SetupSocialProfilePageState();
}

class _SetupSocialProfilePageState extends State<SetupSocialProfilePage> with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  
  bool _isLoading = false;
  bool _checkingUsername = false;
  bool? _usernameAvailable;
  String? _usernameError;
  Timer? _debounce;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
    _usernameController.addListener(_onUsernameChanged);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  Future<void> _loadCurrentProfile() async {
    final userId = _supabaseService.getCurrentUserId();
    if (userId != null) {
      final profile = await _supabaseService.getProfileById(userId);
      if (profile != null && mounted) {
        setState(() {
          _displayNameController.text = profile['full_name'] ?? '';
        });
      }
    }
  }

  void _onUsernameChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    final username = _usernameController.text.trim();
    
    if (username.isEmpty) {
      setState(() {
        _usernameError = null;
        _usernameAvailable = null;
      });
      return;
    }

    if (!RegExp(r'^[a-z0-9_]{3,30}$').hasMatch(username)) {
      setState(() {
        _usernameError = AppLocalizations.of(context)!.usernameFormatError;
        _usernameAvailable = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        _checkingUsername = true;
        _usernameError = null;
      });

      try {
        final available = await _supabaseService.isUsernameAvailable(username);
        if (mounted) {
          setState(() {
            _usernameAvailable = available;
            _checkingUsername = false;
            if (!available) {
              _usernameError = AppLocalizations.of(context)!.usernameAlreadyTaken;
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _checkingUsername = false;
            _usernameError = AppLocalizations.of(context)!.errorCheckingUsername;
          });
        }
      }
    });
  }

  Future<void> _completeSetup() async {
    final username = _usernameController.text.trim();
    final displayName = _displayNameController.text.trim();
    final bio = _bioController.text.trim();

    final l10n = AppLocalizations.of(context)!;
    if (username.isEmpty || displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.usernameAndDisplayNameRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_usernameAvailable != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseChooseAvailableUsername),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _supabaseService.setupSocialProfile(
        username: username,
        displayName: displayName,
        bio: bio.isNotEmpty ? bio : null,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _goBack() {
    Navigator.pop(context, 'skip');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: _goBack,
        ),
        title: null,
        actions: [
          TextButton(
            onPressed: _goBack,
            child: Text(
              AppLocalizations.of(context)!.skip,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.1),
                Colors.white,
                AppColors.primary.withOpacity(0.05),
              ],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_add_rounded,
                              size: 60,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            AppLocalizations.of(context)!.welcomeToSocial,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context)!.createUniqueProfile,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Username Field
                    _buildLabel(AppLocalizations.of(context)!.usernameLabel, required: true),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 16, right: 8),
                            child: Text(
                              '@',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(minWidth: 0),
                          hintText: AppLocalizations.of(context)!.usernameHint,
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          errorText: _usernameError,
                          errorStyle: const TextStyle(fontSize: 12),
                          suffixIcon: _checkingUsername
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : _usernameAvailable == true
                                  ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28)
                                  : _usernameAvailable == false
                                      ? const Icon(Icons.cancel_rounded, color: Colors.red, size: 28)
                                      : null,
                        ),
                        style: const TextStyle(fontSize: 16),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        enableSuggestions: false,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        AppLocalizations.of(context)!.usernameRules,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Display Name Field
                    _buildLabel(AppLocalizations.of(context)!.displayNameLabel, required: true),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _displayNameController,
                      hintText: AppLocalizations.of(context)!.yourNameHint,
                      icon: Icons.badge_rounded,
                    ),
                    const SizedBox(height: 24),

                    // Bio Field
                    _buildLabel(AppLocalizations.of(context)!.bioLabel, required: false),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _bioController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.tellUsAboutYourselfHint,
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(20),
                        ),
                        style: const TextStyle(fontSize: 16),
                        maxLines: 4,
                        maxLength: 150,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Complete Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _completeSetup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.completeSetup,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 24),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildLabel(String text, {required bool required}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.primary),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        style: const TextStyle(fontSize: 16),
        textInputAction: TextInputAction.next,
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
