import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/services/replicate_service.dart';
import 'package:flow/core/services/permission_service.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flow/features/meal_tracking/pages/food_detail_page.dart';
import 'package:flow/features/meal_tracking/pages/food_recognition_result_page.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:flow/services/open_food_facts_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io';

class FoodSearchPage extends StatefulWidget {
  final String mealType;
  const FoodSearchPage({super.key, required this.mealType});
  @override
  State<FoodSearchPage> createState() => _FoodSearchPageState();
}

class _FoodSearchPageState extends State<FoodSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();
  final ReplicateService _replicateService = ReplicateService();
  final OpenFoodFactsService _openFoodFactsService = OpenFoodFactsService();
  final ImagePicker _imagePicker = ImagePicker();
  final stt.SpeechToText _speech = stt.SpeechToText();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _recentFoods = [];
  bool _isLoading = false;
  bool _isRecognizing = false;
  bool _isListening = false;
  bool _isScanning = false;
  String _searchFilter = 'all'; // 'all', 'general', 'custom'
  bool _isCreatingFood = false;
  String? _creatingFoodName;

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final recents = await _supabaseService.getRecentFoods();
    if (mounted) setState(() => _recentFoods = recents);
  }
  void _onSearch(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final results = await _supabaseService.searchFoodWithFilter(query, filter: _searchFilter);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AppLocalizations.of(context)!.addTo} ${widget.mealType}',
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchFoodHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Filter chips
          _buildFilterChips(),
          // Alternative methods - only show when search is empty
          if (_searchController.text.isEmpty)
            _buildAlternativeMethods(),
          // Content
          Expanded(
            child: _isLoading || _isRecognizing || _isCreatingFood
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty && _searchController.text.isNotEmpty && !_isCreatingFood
                    ? _buildEmptyStateWithAICard()
                    : _searchController.text.isEmpty 
                        ? _buildRecentHistory() 
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _searchResults.length + (_shouldShowAICard() ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Show AI card at the end if no results
                              if (_shouldShowAICard() && index == _searchResults.length) {
                                return _buildAICreateCard(_searchController.text);
                              }
                              final food = _searchResults[index];
                              // Show loader if this is the food being created
                              if (_isCreatingFood && _creatingFoodName == food['name']) {
                                return _buildCreatingLoader();
                              }
                              return FadeInUp(
                                duration: Duration(milliseconds: 200 + (index * 50)),
                                child: _buildFoodTile(food),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeMethods() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          bottom: BorderSide(color: AppColors.background, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMethodButton(
            icon: Icons.camera_alt,
            label: AppLocalizations.of(context)!.camera,
            color: AppColors.primary,
            onTap: _openCamera,
          ),
          _buildMethodButton(
            icon: Icons.qr_code_scanner,
            label: AppLocalizations.of(context)!.barcode,
            color: Colors.orange,
            onTap: _openBarcodeScanner,
          ),
          _buildMethodButton(
            icon: Icons.mic,
            label: AppLocalizations.of(context)!.voice,
            color: Colors.purple,
            onTap: _openVoiceRecorder,
          ),
        ],
      ),
    );
  }

  Widget _buildMethodButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openCamera() async {
    try {
      // Check camera permission
      final hasPermission = await PermissionService.requestCameraPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.cameraPermissionRequired)),
          );
        }
        return;
      }

      // Pick image from camera
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isRecognizing = true);

      if (mounted) {
        setState(() => _isRecognizing = false);
        
        // Navigate to recognition result page (it will handle recognition)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodRecognitionResultPage(
              imageFile: File(image.path),
              mealType: widget.mealType,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error recognizing food: $e');
      if (mounted) {
        setState(() => _isRecognizing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString()))),
        );
      }
    }
  }

  Future<void> _openBarcodeScanner() async {
    // Check camera permission
    final hasPermission = await PermissionService.requestCameraPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.cameraPermissionRequired)),
        );
      }
      return;
    }

    setState(() => _isScanning = true);

    // Navigate to barcode scanner
    if (mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const _BarcodeScannerPage(),
        ),
      );

      setState(() => _isScanning = false);

      if (result != null && result is String) {
        // Barcode scanned, fetch product from Open Food Facts
        await _processBarcode(result);
      }
    }
  }

  Future<void> _processBarcode(String barcode) async {
    setState(() => _isRecognizing = true);

    try {
      final product = await _openFoodFactsService.getProductByBarcode(barcode);

      if (product == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.productNotFound),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        setState(() => _isRecognizing = false);
        return;
      }

      // Navigate to recognition result page
      if (mounted) {
        setState(() => _isRecognizing = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodRecognitionResultPage(
              imageFile: File(''), // No image for barcode
              mealType: widget.mealType,
              recognizedFoods: [product],
            ),
          ),
        );
      }
    } catch (e) {
      print('Error processing barcode: $e');
      if (mounted) {
        setState(() => _isRecognizing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString()))),
        );
      }
    }
  }

  Future<void> _openVoiceRecorder() async {
    // Check microphone permission
    final hasPermission = await PermissionService.requestMicrophonePermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.microphonePermissionRequired)),
        );
      }
      return;
    }

    // Initialize speech to text
    bool available = await _speech.initialize(
      onError: (error) {
        print('Speech recognition error: $error');
        if (mounted) {
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
              AppLocalizations.of(context)!.speechRecognitionError(error.errorMsg))),
          );
        }
      },
      onStatus: (status) {
        print('Speech recognition status: $status');
        if (status == 'done' || status == 'notListening') {
          if (mounted) {
            setState(() => _isListening = false);
          }
        }
      },
    );

    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.speechRecognitionNotAvailable)),
        );
      }
      return;
    }

    setState(() => _isListening = true);

    // Show listening dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _VoiceListeningDialog(
          onStop: () {
            _speech.stop();
            setState(() => _isListening = false);
            Navigator.pop(context);
          },
        ),
      );
    }

    // Detect system language for speech recognition
    final locale = Localizations.localeOf(context);
    final localeId = locale.languageCode == 'de' ? 'de_DE' : 'en_US';
    
    // Start listening
    await _speech.listen(
      onResult: (result) async {
        if (result.finalResult) {
          final transcription = result.recognizedWords;
          print('Transcription: $transcription');

          if (transcription.isNotEmpty) {
            _speech.stop();
            if (mounted) {
              Navigator.pop(context); // Close listening dialog
              setState(() => _isListening = false);
            }
            await _processVoiceTranscription(transcription);
          }
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: localeId, // Dynamic based on device language
    );
  }

  Future<void> _processVoiceTranscription(String transcription) async {
    setState(() => _isRecognizing = true);

    try {
      // Use Gemini to extract food information from transcription
      // Detect system language
      final locale = Localizations.localeOf(context);
      final language = locale.languageCode == 'de' ? 'de' : 'en';
      
      final foodsList = await _replicateService.recognizeFoodFromVoice(
        transcription,
        language: language,
      );

      if (foodsList.isEmpty) {
        if (mounted) {
          setState(() => _isRecognizing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noFoodItemsDetected),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Navigate to recognition result page
      if (mounted) {
        setState(() => _isRecognizing = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodRecognitionResultPage(
              imageFile: File(''), // No image for voice
              mealType: widget.mealType,
              recognizedFoods: foodsList,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error processing voice transcription: $e');
      if (mounted) {
        setState(() => _isRecognizing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString()))),
        );
      }
    }
  }

  bool _shouldShowAICard() {
    return _searchResults.isEmpty && 
           _searchController.text.isNotEmpty && 
           _searchFilter != 'custom' &&
           !_isCreatingFood;
  }

  Widget _buildFilterChips() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(
            label: l10n.allFoods,
            isSelected: _searchFilter == 'all',
            onTap: () {
              setState(() => _searchFilter = 'all');
              if (_searchController.text.length >= 2) {
                _onSearch(_searchController.text);
              }
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: l10n.generalFoods,
            isSelected: _searchFilter == 'general',
            onTap: () {
              setState(() => _searchFilter = 'general');
              if (_searchController.text.length >= 2) {
                _onSearch(_searchController.text);
              }
            },
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: l10n.myFoods,
            isSelected: _searchFilter == 'custom',
            onTap: () {
              setState(() => _searchFilter = 'custom');
              if (_searchController.text.length >= 2) {
                _onSearch(_searchController.text);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateWithAICard() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAICreateCard(_searchController.text),
      ],
    );
  }

  Widget _buildAICreateCard(String foodName) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: const Color(0xFFC8E6C9), // Light green
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.shade300, width: 1.5),
      ),
      child: InkWell(
        onTap: () => _createFoodWithAI(foodName),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade400,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          l10n.createWithAI,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"$foodName"',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green.shade800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreatingLoader() {
    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.creatingFoodWithAI,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createFoodWithAI(String foodName) async {
    if (foodName.trim().isEmpty) return;

    setState(() {
      _isCreatingFood = true;
      _creatingFoodName = foodName;
    });

    try {
      // Detect system language
      final locale = Localizations.localeOf(context);
      final language = locale.languageCode == 'de' ? 'de' : 'en';

      // Generate food details with AI
      final aiFoodData = await _replicateService.generateFoodDetailsFromName(
        foodName,
        language: language,
      );

      // Create custom food in database
      final createdFood = await _supabaseService.createCustomFoodWithAI(
        foodName,
        aiFoodData,
        language: language,
      );

      if (mounted) {
        setState(() {
          _isCreatingFood = false;
          _creatingFoodName = null;
          // Add to search results
          _searchResults.insert(0, createdFood);
        });

        // Navigate to food detail page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FoodDetailPage(
              food: createdFood,
              mealType: widget.mealType,
            ),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.foodCreatedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error creating food with AI: $e');
      if (mounted) {
        setState(() {
          _isCreatingFood = false;
          _creatingFoodName = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 80,
            color: AppColors.textSecondary.withAlpha(51),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? AppLocalizations.of(context)!.searchYourMeal
                : AppLocalizations.of(context)!.noResultsFound,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodTile(Map<String, dynamic> food) {
    final isCustom = food['is_custom'] == true;
    return Card(
      color: AppColors.card,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: isCustom
            ? Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.restaurant,
                  color: Colors.green,
                  size: 20,
                ),
              )
            : null,
        title: Row(
          children: [
            Expanded(
              child: Text(
                food['name'] ?? food['german_name'] ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            if (isCustom)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  AppLocalizations.of(context)!.myFood,
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${food['calories']} kcal • ${food['protein']}g P • ${food['carbs']}g C • ${food['fat']}g F',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FoodDetailPage(food: food, mealType: widget.mealType),
            ),
          );
        },
      ),
    );
  }
  Widget _buildRecentHistory() {
    if (_recentFoods.isEmpty) return _buildEmptyState();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            AppLocalizations.of(context)!.recentFoods ?? 'Recently Eaten',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recentFoods.length,
            itemBuilder: (context, index) {
              return _buildFoodTile(_recentFoods[index]);
            },
          ),
        ),
      ],
    );
  }
}

// Barcode Scanner Page
class _BarcodeScannerPage extends StatefulWidget {
  const _BarcodeScannerPage();

  @override
  State<_BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    formats: [BarcodeFormat.ean13, BarcodeFormat.ean8],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.scanBarcode),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final barcode = barcodes.first;
                if (barcode.rawValue != null) {
                  _controller.stop();
                  Navigator.pop(context, barcode.rawValue);
                }
              }
            },
          ),
          // Overlay with scanning guide
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 60),
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AppLocalizations.of(context)!.positionBarcode,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Voice Listening Dialog
class _VoiceListeningDialog extends StatelessWidget {
  final VoidCallback onStop;

  const _VoiceListeningDialog({required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mic,
              size: 64,
              color: Colors.purple,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.listening,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.speakFoodItems,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onStop,
              icon: const Icon(Icons.stop),
              label: Text(AppLocalizations.of(context)!.stopListening),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
