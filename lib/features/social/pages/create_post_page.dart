import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/core/services/permission_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flow/core/services/text_to_image_service.dart';
import 'package:flow/features/social/pages/setup_social_profile_page.dart';
import 'dart:io';

class CreatePostPage extends StatefulWidget {
  final String? mealId; // If sharing a meal
  final String? workoutId; // If sharing a workout
  
  const CreatePostPage({super.key, this.mealId, this.workoutId});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _captionController = TextEditingController();
  String? _imageUrl;
  File? _imageFile;
  bool _isLoading = false;
  String _loadingMessage = 'Creating post...';
  String _postType = 'text'; // 'text', 'image', 'meal', 'workout'
  bool _showEmojiPicker = false;
  Color _selectedBackgroundColor = TextToImageService.backgroundColors[0];

  @override
  void initState() {
    super.initState();
    _checkUsername();
    if (widget.mealId != null) {
      _postType = 'meal';
      _captionController.text = 'Just logged my meal! 🍽️';
    } else if (widget.workoutId != null) {
      _postType = 'workout';
      _captionController.text = 'Crushed my workout! 💪';
    }
  }

  Future<void> _checkUsername() async {
    final hasUsername = await _supabaseService.hasUsername();
    if (!hasUsername && mounted) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SetupSocialProfilePage(),
          fullscreenDialog: true,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final hasPermission = await PermissionService.requestPhotosPermission();
      
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.photoPermissionRequired)),
          );
        }
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          _imageFile = File(image.path);
          _postType = 'image';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString()))),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final hasPermission = await PermissionService.requestCameraPermission();
      
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.cameraPermissionRequired)),
          );
        }
        return;
      }

      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        setState(() {
          _imageFile = File(photo.path);
          _postType = 'image';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString()))),
        );
      }
    }
  }

  Future<void> _createPost() async {
    if (_captionController.text.trim().isEmpty && _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseAddCaptionOrImage)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = AppLocalizations.of(context)!.preparingPost;
    });

    try {
      String? imageUrl;
      
      if (_imageFile != null) {
        setState(() => _loadingMessage = AppLocalizations.of(context)!.uploadingImage);
        imageUrl = await _supabaseService.uploadPostImage(_imageFile);
        
        if (imageUrl == null) {
          throw Exception('Upload failed. Please check your internet and try again.');
        }
      }

      setState(() => _loadingMessage = AppLocalizations.of(context)!.finalizingPost);
      await _supabaseService.createPost(
        _captionController.text.trim(),
        imageUrl: imageUrl,
        postType: _postType,
        mealId: widget.mealId,
        workoutId: widget.workoutId,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.postCreated)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.createPost, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createPost,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(AppLocalizations.of(context)!.post, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        _loadingMessage, 
                        style: const TextStyle(
                          color: AppColors.primary, 
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Post Type Indicator
            if (_postType != 'text')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getPostTypeColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getPostTypeIcon(), size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      _getPostTypeLabel(),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Caption Input
            TextField(
              controller: _captionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.whatsOnYourMind,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions_outlined),
                  onPressed: () {
                    setState(() => _showEmojiPicker = !_showEmojiPicker);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Background Color Selector (for text posts)
            if (_imageFile == null && widget.mealId == null && widget.workoutId == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.backgroundColor, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: TextToImageService.backgroundColors.length,
                        itemBuilder: (context, index) {
                        final color = TextToImageService.backgroundColors[index];
                        final isSelected = color == _selectedBackgroundColor;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedBackgroundColor = color),
                          child: Container(
                            width: 50,
                            height: 50,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Emoji Picker
            if (_showEmojiPicker)
              SizedBox(
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    _captionController.text += emoji.emoji;
                  },
                  config: const Config(
                    height: 256,
                    checkPlatformCompatibility: true,
                    emojiViewConfig: EmojiViewConfig(
                      emojiSizeMax: 28,
                    ),
                  ),
                ),
              ),

            // Image Preview
            if (_imageFile != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _imageFile!,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () => setState(() {
                        _imageFile = null;
                        _postType = 'text';
                      }),
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),

            // Add Photo Buttons
            if (_imageFile == null && widget.mealId == null && widget.workoutId == null)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: Text(AppLocalizations.of(context)!.gallery),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(AppLocalizations.of(context)!.camera),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Color _getPostTypeColor() {
    switch (_postType) {
      case 'meal':
        return Colors.orange;
      case 'workout':
        return Colors.blue;
      case 'image':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getPostTypeIcon() {
    switch (_postType) {
      case 'meal':
        return Icons.restaurant;
      case 'workout':
        return Icons.fitness_center;
      case 'image':
        return Icons.image;
      default:
        return Icons.text_fields;
    }
  }

  String _getPostTypeLabel() {
    switch (_postType) {
      case 'meal':
        return 'Meal Post';
      case 'workout':
        return 'Workout Post';
      case 'image':
        return 'Photo Post';
      default:
        return 'Text Post';
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }
}
