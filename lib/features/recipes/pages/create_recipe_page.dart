import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class CreateRecipePage extends StatefulWidget {
  const CreateRecipePage({super.key});

  @override
  State<CreateRecipePage> createState() => _CreateRecipePageState();
}

class _CreateRecipePageState extends State<CreateRecipePage> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _imagePicker = ImagePicker();
  
  // Basic info
  final _titleEnController = TextEditingController();
  final _titleDeController = TextEditingController();
  final _descriptionEnController = TextEditingController();
  final _descriptionDeController = TextEditingController();
  
  // Time and servings
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _servingsController = TextEditingController(text: '1');
  
  // Selection fields
  String? _selectedMealType;
  String? _selectedDietType;
  String? _selectedCuisine;
  
  // Ingredients and instructions
  List<Map<String, dynamic>> _ingredients = [];
  List<String> _instructionsEn = [];
  List<String> _instructionsDe = [];
  
  // Image
  File? _selectedImage;
  bool _isUploading = false;
  bool _isSaving = false;
  
  // Tags
  List<String> _selectedTags = [];
  final List<String> _availableTags = [
    'high-protein', 'low-carb', 'quick', 'budget-friendly', 'healthy',
    'vegetarian', 'vegan', 'gluten-free', 'keto', 'paleo', 'comfort-food',
    'classic', 'authentic', 'dinner', 'breakfast', 'lunch', 'snack'
  ];
  
  // Nutrition fields (per serving)
  final Map<String, TextEditingController> _nutritionControllers = {};
  
  @override
  void initState() {
    super.initState();
    _initializeNutritionControllers();
  }
  
  void _initializeNutritionControllers() {
    final nutritionFields = [
      'calories', 'protein', 'carbs', 'fat', 'fiber', 'sugar', 'saturated_fat',
      'omega3', 'omega6', 'vitamin_a', 'vitamin_c', 'vitamin_d', 'vitamin_e', 'vitamin_k',
      'vitamin_b1_thiamine', 'vitamin_b2_riboflavin', 'vitamin_b3_niacin',
      'vitamin_b5_pantothenic_acid', 'vitamin_b6', 'vitamin_b7_biotin',
      'vitamin_b9_folate', 'vitamin_b12',
      'calcium', 'iron', 'magnesium', 'phosphorus', 'potassium', 'sodium',
      'zinc', 'copper', 'manganese', 'selenium', 'chromium', 'molybdenum', 'iodine',
      'water', 'caffeine', 'creatine', 'taurine', 'beta_alanine', 'l_carnitine',
      'glutamine', 'bcaa', 'leucine', 'isoleucine', 'valine', 'lysine',
      'methionine', 'phenylalanine', 'threonine', 'tryptophan', 'histidine',
      'arginine', 'tyrosine', 'cysteine', 'alanine', 'aspartic_acid',
      'glutamic_acid', 'serine', 'proline', 'glycine',
    ];
    
    for (var field in nutritionFields) {
      _nutritionControllers[field] = TextEditingController(text: '0');
    }
  }
  
  @override
  void dispose() {
    _titleEnController.dispose();
    _titleDeController.dispose();
    _descriptionEnController.dispose();
    _descriptionDeController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    for (var controller in _nutritionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }
  
  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseUploadImage),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseAddIngredient),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_instructionsEn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseAddInstruction),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isSaving = true);
    
    try {
      // Upload image first
      final imageUrl = await _supabaseService.uploadRecipeImage(_selectedImage!);
      if (imageUrl == null) {
        throw Exception('Failed to upload image');
      }
      
      // Prepare nutrition data
      final nutritionData = <String, dynamic>{};
      for (var entry in _nutritionControllers.entries) {
        final value = double.tryParse(entry.value.text) ?? 0.0;
        nutritionData[entry.key] = value;
      }
      
      // Calculate total time
      final prepTime = int.tryParse(_prepTimeController.text) ?? 0;
      final cookTime = int.tryParse(_cookTimeController.text) ?? 0;
      final totalTime = prepTime + cookTime;
      
      // Save recipe
      final recipeId = await _supabaseService.createRecipe(
        titleEn: _titleEnController.text.trim(),
        titleDe: _titleDeController.text.trim(),
        descriptionEn: _descriptionEnController.text.trim(),
        descriptionDe: _descriptionDeController.text.trim(),
        prepTimeMinutes: prepTime,
        cookTimeMinutes: cookTime,
        totalTimeMinutes: totalTime,
        servings: int.tryParse(_servingsController.text) ?? 1,
        recommendedMealType: _selectedMealType,
        dietType: _selectedDietType,
        cuisineType: _selectedCuisine,
        ingredients: _ingredients,
        instructionsEn: _instructionsEn,
        instructionsDe: _instructionsDe,
        imageUrl: imageUrl,
        nutritionData: nutritionData,
        tags: _selectedTags,
      );
      
      final l10n = AppLocalizations.of(context)!;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.recipeCreatedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate refresh needed
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorGeneric(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.createRecipe),
        backgroundColor: AppColors.primary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image upload
            _buildImageUpload(),
            const SizedBox(height: 24),
            
            // Basic info
            _buildSectionTitle(l10n.basicInformation),
            _buildTextField(_titleEnController, l10n.titleEnglish, Icons.title, required: true),
            _buildTextField(_titleDeController, 'Title (German)', Icons.title),
            _buildTextField(_descriptionEnController, 'Description (English)', Icons.description, maxLines: 3),
            _buildTextField(_descriptionDeController, 'Description (German)', Icons.description, maxLines: 3),
            
            const SizedBox(height: 24),
            
            // Time and servings
            _buildSectionTitle('Time & Servings'),
            Row(
              children: [
                Expanded(child: _buildTextField(_prepTimeController, l10n.prepTimeMin, Icons.timer, keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(_cookTimeController, l10n.cookTimeMin, Icons.timer, keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(_servingsController, 'Servings', Icons.people, keyboardType: TextInputType.number)),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Meal type, diet, cuisine
            _buildSectionTitle('Category'),
            _buildDropdown(l10n.mealType, _selectedMealType, ['BREAKFAST', 'LUNCH', 'DINNER', 'SNACK'], (value) {
              setState(() => _selectedMealType = value);
            }),
            _buildDropdown(l10n.dietType, _selectedDietType, ['none', 'vegetarian', 'vegan', 'pescetarian', 'keto', 'paleo', 'gluten-free'], (value) {
              setState(() => _selectedDietType = value);
            }),
            _buildDropdown('Cuisine', _selectedCuisine, ['Italian', 'French', 'Spanish', 'Greek', 'German', 'British', 'Mediterranean', 'European'], (value) {
              setState(() => _selectedCuisine = value);
            }),
            
            const SizedBox(height: 24),
            
            // Ingredients
            _buildSectionTitle('Ingredients'),
            ..._ingredients.asMap().entries.map((entry) => _buildIngredientItem(entry.key, entry.value)),
            ElevatedButton.icon(
              onPressed: _addIngredient,
              icon: const Icon(Icons.add),
              label: Text(l10n.addIngredient),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                foregroundColor: AppColors.primary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Instructions
            _buildSectionTitle('Instructions'),
            ..._instructionsEn.asMap().entries.map((entry) => _buildInstructionItem(entry.key, entry.value)),
            ElevatedButton.icon(
              onPressed: _addInstruction,
              icon: const Icon(Icons.add),
              label: Text(l10n.addInstruction),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.1),
                foregroundColor: AppColors.primary,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Tags
            _buildSectionTitle('Tags'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Nutrition (collapsible)
            _buildNutritionSection(),
            
            const SizedBox(height: 32),
            
            // Save button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveRecipe,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n.createRecipe, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImageUpload() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Tap to upload image (Required)',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
  
  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: AppColors.card,
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'This field is required';
                }
                return null;
              }
            : null,
      ),
    );
  }
  
  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: AppColors.card,
        ),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
      ),
    );
  }
  
  Widget _buildIngredientItem(int index, Map<String, dynamic> ingredient) {
    final l10n = AppLocalizations.of(context)!;
    final nameEnController = TextEditingController(text: ingredient['name_en'] ?? '');
    final nameDeController = TextEditingController(text: ingredient['name_de'] ?? '');
    final amountController = TextEditingController(text: ingredient['amount']?.toString() ?? '');
    final unitController = TextEditingController(text: ingredient['unit'] ?? 'g');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(l10n.ingredient(index + 1), style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() => _ingredients.removeAt(index));
                  },
                ),
              ],
            ),
            _buildTextField(nameEnController, 'Name (EN)', Icons.label, required: true),
            _buildTextField(nameDeController, 'Name (DE)', Icons.label),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(amountController, 'Amount', Icons.numbers, keyboardType: TextInputType.number),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(unitController, 'Unit', Icons.scale, required: true),
                ),
              ],
            ),
            // Update ingredient on change
            Builder(
              builder: (context) {
                nameEnController.addListener(() {
                  _ingredients[index]['name_en'] = nameEnController.text;
                });
                nameDeController.addListener(() {
                  _ingredients[index]['name_de'] = nameDeController.text;
                });
                amountController.addListener(() {
                  _ingredients[index]['amount'] = double.tryParse(amountController.text) ?? 0;
                });
                unitController.addListener(() {
                  _ingredients[index]['unit'] = unitController.text;
                });
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInstructionItem(int index, String instruction) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: instruction);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: l10n.instructionStep(index + 1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
                onChanged: (value) {
                  _instructionsEn[index] = value;
                  if (_instructionsDe.length > index) {
                    _instructionsDe[index] = value; // Auto-fill German if not set
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  _instructionsEn.removeAt(index);
                  if (_instructionsDe.length > index) {
                    _instructionsDe.removeAt(index);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _addIngredient() {
    setState(() {
      _ingredients.add({
        'name_en': '',
        'name_de': '',
        'amount': 0.0,
        'unit': 'g',
      });
    });
  }
  
  void _addInstruction() {
    setState(() {
      _instructionsEn.add('');
      _instructionsDe.add('');
    });
  }
  
  Widget _buildNutritionSection() {
    final l10n = AppLocalizations.of(context)!;
    return ExpansionTile(
      title: Text(l10n.nutritionalInformationPerServing),
      initiallyExpanded: false,
      children: [
        // Macros
        _buildNutritionField('calories', 'Calories (kcal)', 'kcal'),
        _buildNutritionField('protein', 'Protein (g)', 'g'),
        _buildNutritionField('carbs', 'Carbohydrates (g)', 'g'),
        _buildNutritionField('fat', 'Fat (g)', 'g'),
        _buildNutritionField('fiber', 'Fiber (g)', 'g'),
        _buildNutritionField('sugar', 'Sugar (g)', 'g'),
        _buildNutritionField('saturated_fat', 'Saturated Fat (g)', 'g'),
        
        const Divider(),
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Text(l10n.vitamins, style: const TextStyle(fontWeight: FontWeight.bold));
          },
        ),
        _buildNutritionField('vitamin_a', 'Vitamin A (μg)', 'μg'),
        _buildNutritionField('vitamin_c', 'Vitamin C (mg)', 'mg'),
        _buildNutritionField('vitamin_d', 'Vitamin D (μg)', 'μg'),
        _buildNutritionField('vitamin_e', 'Vitamin E (mg)', 'mg'),
        _buildNutritionField('vitamin_k', 'Vitamin K (μg)', 'μg'),
        _buildNutritionField('vitamin_b1_thiamine', 'Vitamin B1 (mg)', 'mg'),
        _buildNutritionField('vitamin_b2_riboflavin', 'Vitamin B2 (mg)', 'mg'),
        _buildNutritionField('vitamin_b3_niacin', 'Vitamin B3 (mg)', 'mg'),
        _buildNutritionField('vitamin_b5_pantothenic_acid', 'Vitamin B5 (mg)', 'mg'),
        _buildNutritionField('vitamin_b6', 'Vitamin B6 (mg)', 'mg'),
        _buildNutritionField('vitamin_b7_biotin', 'Vitamin B7 (μg)', 'μg'),
        _buildNutritionField('vitamin_b9_folate', 'Vitamin B9 (μg)', 'μg'),
        _buildNutritionField('vitamin_b12', 'Vitamin B12 (μg)', 'μg'),
        
        const Divider(),
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            return Text(l10n.minerals, style: const TextStyle(fontWeight: FontWeight.bold));
          },
        ),
        _buildNutritionField('calcium', 'Calcium (mg)', 'mg'),
        _buildNutritionField('iron', 'Iron (mg)', 'mg'),
        _buildNutritionField('magnesium', 'Magnesium (mg)', 'mg'),
        _buildNutritionField('phosphorus', 'Phosphorus (mg)', 'mg'),
        _buildNutritionField('potassium', 'Potassium (mg)', 'mg'),
        _buildNutritionField('sodium', 'Sodium (mg)', 'mg'),
        _buildNutritionField('zinc', 'Zinc (mg)', 'mg'),
      ],
    );
  }
  
  Widget _buildNutritionField(String key, String label, String unit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: _nutritionControllers[key],
        decoration: InputDecoration(
          labelText: '$label ($unit)',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: AppColors.card,
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }
}

