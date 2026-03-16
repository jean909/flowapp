import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';

class ReplicateService {
  // Set at build: flutter run --dart-define=REPLICATE_API_TOKEN=your_token
  static String get _apiToken => const String.fromEnvironment(
    'REPLICATE_API_TOKEN',
    defaultValue: '',
  );
  static const String _baseUrl = 'https://api.replicate.com/v1';
  static const String _model = 'google/gemini-3-pro';

  Future<String> generateAdvice({
    required String prompt,
    String? systemInstruction,
    double temperature = 1.0,
    int maxOutputTokens = 1000,
    bool dynamicThinking = false,
  }) async {
    try {
      // First, get the model version
      final modelUrl = Uri.parse('$_baseUrl/models/$_model');
      final modelResponse = await http.get(
        modelUrl,
        headers: {
          'Authorization': 'Token $_apiToken',
          'Content-Type': 'application/json',
        },
      );

      if (modelResponse.statusCode != 200) {
        throw Exception('Failed to get model: ${modelResponse.statusCode}');
      }

      final modelData = jsonDecode(modelResponse.body);
      final latestVersion = modelData['latest_version'] as Map<String, dynamic>?;
      final versionId = latestVersion?['id'] as String?;

      if (versionId == null) {
        throw Exception('No version found for model');
      }

      // Create prediction
      final url = Uri.parse('$_baseUrl/predictions');

      final inputMap = <String, dynamic>{
        'prompt': prompt,
        'temperature': temperature,
        'max_output_tokens': maxOutputTokens,
        'dynamic_thinking': dynamicThinking,
        'top_p': 0.95,
      };
      
      if (systemInstruction != null) {
        inputMap['system_instruction'] = systemInstruction;
      }

      final body = {
        'version': versionId,
        'input': inputMap,
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 201) {
        print('Replicate API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create prediction: ${response.statusCode}');
      }

      final predictionData = jsonDecode(response.body);
      final predictionId = predictionData['id'] as String;

      // Poll for completion
      return await _pollForResult(predictionId);
    } catch (e) {
      print('Error generating advice: $e');
      rethrow;
    }
  }

  Future<String> _pollForResult(String predictionId) async {
    final maxAttempts = 30;
    final delay = Duration(seconds: 2);

    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(delay);

      final url = Uri.parse('$_baseUrl/predictions/$predictionId');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Token $_apiToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get prediction status: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final status = data['status'] as String;

      if (status == 'succeeded') {
        final output = data['output'];
        
        // Handle different output formats
        if (output is List) {
          // If output is a list, concatenate all strings
          if (output.isNotEmpty) {
            final result = output.map((e) {
              if (e is String) return e;
              return e.toString();
            }).join('');
            print('Replicate output (list): ${result.length} chars, ${output.length} fragments');
            
            // Check if last fragment appears truncated (doesn't end with } or complete sentence)
            if (output.isNotEmpty) {
              final lastFragment = output.last.toString();
              final lastFragmentTrimmed = lastFragment.trim();
              if (!lastFragmentTrimmed.endsWith('}') && 
                  !lastFragmentTrimmed.endsWith('}"') &&
                  !lastFragmentTrimmed.endsWith('}\n') &&
                  !lastFragmentTrimmed.endsWith('}\r\n')) {
                print('[Replicate] WARNING: Last fragment may be truncated');
                print('[Replicate] Last fragment (last 100 chars): ${lastFragment.length > 100 ? lastFragment.substring(lastFragment.length - 100) : lastFragment}');
              }
            }
            
            return result;
          }
        } else if (output is String) {
          // If output is already a string
          print('Replicate output (string): ${output.length} chars');
          return output;
        }
        
        print('Replicate output type: ${output.runtimeType}, value: $output');
        throw Exception('Empty or invalid output from model');
      } else if (status == 'failed' || status == 'canceled') {
        final error = data['error'] as String? ?? 'Unknown error';
        throw Exception('Prediction failed: $error');
      }
      // Continue polling if status is 'starting' or 'processing'
    }

    throw Exception('Prediction timeout after ${maxAttempts * delay.inSeconds} seconds');
  }

  // Generate Advanced Analytics Insights
  Future<Map<String, dynamic>> generateAnalyticsInsights({
    required Map<String, dynamic> userData,
    required String reportType, // 'daily', 'weekly', 'monthly'
  }) async {
    try {
      final systemInstruction = '''You are an expert health and fitness AI analyst. Your task is to analyze user data and provide personalized insights and recommendations.

Return ONLY a valid JSON object with this exact structure:
{
  "summary": "A brief 2-3 sentence summary of the user's overall health and fitness status",
  "insights": {
    "nutrition": "Detailed analysis of nutrition patterns, macro balance, meal timing, etc.",
    "exercise": "Analysis of workout frequency, intensity, progress, and patterns",
    "hydration": "Analysis of water intake patterns",
    "sleep": "Analysis of sleep patterns (if available)",
    "mood": "Analysis of mood patterns (if available)",
    "overall": "Overall health and fitness assessment"
  },
  "recommendations": [
    {
      "category": "nutrition|exercise|hydration|sleep|lifestyle",
      "priority": "high|medium|low",
      "title": "Short recommendation title",
      "description": "Detailed recommendation explanation",
      "actionable": "Specific actionable steps"
    }
  ],
  "trends": {
    "calories": "trending_up|trending_down|stable",
    "protein": "trending_up|trending_down|stable",
    "exercise_frequency": "trending_up|trending_down|stable",
    "water_intake": "trending_up|trending_down|stable"
  },
  "achievements": [
    "Achievement 1 description",
    "Achievement 2 description"
  ],
  "concerns": [
    "Concern 1 description",
    "Concern 2 description"
  ]
}

Be specific, actionable, and encouraging. Focus on what the user is doing well and provide constructive suggestions for improvement.''';

      final prompt = '''Analyze the following user data and generate personalized insights and recommendations:

User Profile:
- Gender: ${userData['gender'] ?? 'Not specified'}
- Age: ${userData['age'] ?? 'Not specified'}
- Goal: ${userData['goal'] ?? 'Not specified'}
- Current Weight: ${userData['current_weight'] ?? 'Not specified'} kg
- Target Weight: ${userData['target_weight'] ?? 'Not specified'} kg
- Activity Level: ${userData['activity_level'] ?? 'Not specified'}

Nutrition Data (${reportType}):
${userData['nutrition'] ?? 'No nutrition data available'}

Exercise Data (${reportType}):
${userData['exercise'] ?? 'No exercise data available'}

Water Intake (${reportType}):
${userData['water'] ?? 'No water data available'}

Sleep Data (${reportType}):
${userData['sleep'] ?? 'No sleep data available'}

Mood Data (${reportType}):
${userData['mood'] ?? 'No mood data available'}

Generate comprehensive insights and actionable recommendations based on this data.''';

      final response = await generateAdvice(
        prompt: prompt,
        systemInstruction: systemInstruction,
        temperature: 0.7,
        maxOutputTokens: 3000,
      );

      // Parse JSON response
      try {
        // Remove markdown code blocks if present
        String cleanedResponse = response.trim();
        if (cleanedResponse.startsWith('```json')) {
          cleanedResponse = cleanedResponse.substring(7);
        }
        if (cleanedResponse.startsWith('```')) {
          cleanedResponse = cleanedResponse.substring(3);
        }
        if (cleanedResponse.endsWith('```')) {
          cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
        }
        cleanedResponse = cleanedResponse.trim();

        final jsonData = jsonDecode(cleanedResponse) as Map<String, dynamic>;
        return jsonData;
      } catch (e) {
        print('Error parsing AI response: $e');
        print('Response was: $response');
        // Return fallback structure
        return {
          'summary': 'Analysis completed. Please review your data trends.',
          'insights': {
            'overall': 'Continue tracking your progress for better insights.',
          },
          'recommendations': [],
          'trends': {},
          'achievements': [],
          'concerns': [],
        };
      }
    } catch (e) {
      print('Error generating analytics insights: $e');
      rethrow;
    }
  }

  // Upload image to Supabase Storage and get public URL
  Future<String?> _uploadImageToSupabase(File imageFile) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Read and compress image
      final imageBytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);
      
      if (decodedImage == null) {
        throw Exception('Failed to decode image');
      }
      
      // Resize if too large (max 1024px on longest side)
      img.Image? processedImage = decodedImage;
      if (decodedImage.width > 1024 || decodedImage.height > 1024) {
        final ratio = decodedImage.width > decodedImage.height 
            ? 1024 / decodedImage.width 
            : 1024 / decodedImage.height;
        processedImage = img.copyResize(
          decodedImage,
          width: (decodedImage.width * ratio).toInt(),
          height: (decodedImage.height * ratio).toInt(),
        );
      }
      
      // Encode to JPEG with quality 85
      final jpegBytes = img.encodeJpg(processedImage, quality: 85);
      
      // Create temporary file in system temp directory
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/food_recognition_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(jpegBytes);
      
      // Generate unique filename
      final fileName = 'food_recognition_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = '$userId/$fileName';
      
      // Upload to Supabase Storage
      await supabase.storage
          .from('food_images')
          .upload(
            storagePath,
            tempFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );
      
      // Get public URL
      final imageUrl = supabase.storage
          .from('food_images')
          .getPublicUrl(storagePath);
      
      // Clean up temp file
      try {
        await tempFile.delete();
      } catch (e) {
        print('Error deleting temp file: $e');
      }
      
      return imageUrl;
    } catch (e) {
      print('Error uploading image to Supabase: $e');
      // If bucket doesn't exist, we'll need to create it manually in Supabase Dashboard
      // For now, return null and handle error
      rethrow;
    }
  }

  // Recognize food from image using Gemini Vision
  // Returns a List of food items (can be 1 or more)
  // language: 'de' for German, 'en' for English (default)
  Future<List<Map<String, dynamic>>> recognizeFoodFromImage(
    File imageFile, {
    String language = 'en',
  }) async {
    try {
      // Upload image to Supabase Storage first
      final imageUrl = await _uploadImageToSupabase(imageFile);
      if (imageUrl == null) {
        throw Exception('Failed to upload image to storage');
      }
      
      print('Image uploaded to: $imageUrl');
      
      // Get model version
      final modelUrl = Uri.parse('$_baseUrl/models/$_model');
      final modelResponse = await http.get(
        modelUrl,
        headers: {
          'Authorization': 'Token $_apiToken',
          'Content-Type': 'application/json',
        },
      );

      if (modelResponse.statusCode != 200) {
        throw Exception('Failed to get model: ${modelResponse.statusCode}');
      }

      final modelData = jsonDecode(modelResponse.body);
      final latestVersion = modelData['latest_version'] as Map<String, dynamic>?;
      final versionId = latestVersion?['id'] as String?;

      if (versionId == null) {
        throw Exception('No version found for model');
      }

      // Enhanced system instruction for better food recognition - DETECT ALL ITEMS
      // Language-aware prompts
      final isGerman = language == 'de';
      
      final systemInstruction = isGerman
          ? '''Du bist ein Experte für Ernährung und Lebensmittelerkennung. Deine Aufgabe ist es, Lebensmittelbilder zu analysieren und vollständige Nährwertinformationen für ALLE sichtbaren Lebensmittel im Bild zu extrahieren.

WICHTIGE REGELN:
1. Identifiziere ALLE Lebensmittel/Getränke im Bild - sei gründlich und erkenne jedes einzelne Element
2. Sei bei jedem Element spezifisch (z.B. "Gegrillte Hähnchenbrust" nicht nur "Hähnchen", "Orangensaft" nicht nur "Saft")
3. Generiere Namen basierend auf dem, was du siehst - durchsuche KEINE Datenbanken, nutze dein Wissen
4. Bei Getränken identifiziere die Art (Wasser, Saft, Limonade, Kaffee, Tee, etc.)
5. Schätze Nährwerte basierend auf Standard-Lebensmittelzusammensetzungsdaten
6. Für Portionsgröße schätze das tatsächliche Gewicht/Volumen im Bild für JEDES Element
7. Gib NUR ein gültiges JSON-Array zurück, keine Erklärungen, kein Markdown, keine Code-Blöcke

Gib ein JSON-ARRAY mit dieser EXAKTEN Struktur zurück (ein Objekt pro Lebensmittel):
[
  {
    "name": "spezifischer Lebensmittelname auf Englisch (z.B. 'Grilled Chicken Breast', 'Apple', 'Orange Juice')",
    "german_name": "spezifischer Lebensmittelname auf Deutsch (z.B. 'Gegrillte Hähnchenbrust', 'Apfel', 'Orangensaft')",
    "calories": Zahl (Kalorien pro 100g oder 100ml),
    "protein": Zahl (Gramm pro 100g/100ml),
    "carbs": Zahl (Gramm pro 100g/100ml),
    "fat": Zahl (Gramm pro 100g/100ml),
    "fiber": Zahl (Gramm pro 100g/100ml, 0 wenn nicht zutreffend),
    "sugar": Zahl (Gramm pro 100g/100ml, 0 wenn nicht zutreffend),
    "sodium": Zahl (Milligramm pro 100g/100ml, 0 wenn nicht zutreffend),
    "water": Zahl (Gramm pro 100g, für Flüssigkeiten 95-100, für Feststoffe basierend auf Lebensmitteltyp schätzen),
    "caffeine": Zahl (Milligramm pro 100g/100ml, 0 wenn nicht zutreffend, für Kaffee/Tee schätzen),
    "estimated_weight": Zahl (geschätztes Gewicht in Gramm oder ml im Bild für DIESES spezifische Element),
    "unit": "g" für Feststoffe, "ml" für Flüssigkeiten/Getränke
  },
  {
    // Zweites Element falls vorhanden...
  }
]

KRITISCH: Du MUSST ALLE Lebensmittel im Bild erkennen. Wenn du einen Apfel, eine Orange und Cola siehst, gib ein Array mit 3 Objekten zurück. Wenn du nur ein Element siehst, gib ein Array mit 1 Objekt zurück. Gib immer ein Array zurück, niemals ein einzelnes Objekt.

Sei genau und spezifisch. Wenn du ein Getränk siehst, setze unit auf "ml". Wenn du feste Nahrung siehst, setze unit auf "g".'''
          : '''You are an expert nutritionist and food recognition specialist. Your task is to analyze food images and extract complete nutritional information for ALL food items visible in the image.

IMPORTANT RULES:
1. Identify ALL foods/drinks visible in the image - be thorough and detect every single item
2. For each item, be specific (e.g., "Grilled Chicken Breast" not just "Chicken", "Orange Juice" not just "Juice")
3. Generate names based on what you see - DO NOT search databases, use your knowledge
4. For drinks/beverages, identify the type (water, juice, soda, coffee, tea, etc.)
5. Estimate nutritional values based on standard food composition data
6. For portion size, estimate the actual weight/volume visible in the image for EACH item
7. Return ONLY valid JSON array, no explanations, no markdown, no code blocks

Return a JSON ARRAY with this EXACT structure (one object per food item):
[
  {
    "name": "specific food name in English (e.g., 'Grilled Chicken Breast', 'Apple', 'Orange Juice')",
    "german_name": "specific food name in German (e.g., 'Gegrilltes Hähnchenbrust', 'Apfel', 'Orangensaft')",
    "calories": number (calories per 100g or 100ml),
    "protein": number (grams per 100g/100ml),
    "carbs": number (grams per 100g/100ml),
    "fat": number (grams per 100g/100ml),
    "fiber": number (grams per 100g/100ml, 0 if not applicable),
    "sugar": number (grams per 100g/100ml, 0 if not applicable),
    "sodium": number (milligrams per 100g/100ml, 0 if not applicable),
    "water": number (grams per 100g, for liquids use 95-100, for solids estimate based on food type),
    "caffeine": number (milligrams per 100g/100ml, 0 if not applicable, estimate for coffee/tea),
    "estimated_weight": number (estimated weight in grams or ml visible in the image for THIS specific item),
    "unit": "g" for solids, "ml" for liquids/drinks
  },
  {
    // Second item if present...
  }
]

CRITICAL: You MUST detect ALL food items in the image. If you see an apple, orange, and cola, return an array with 3 objects. If you see only one item, return an array with 1 object. Always return an array, never a single object.

Be accurate and specific. If you see a drink, set unit to "ml". If you see solid food, set unit to "g".''';

      // Detailed prompt for food recognition - DETECT ALL ITEMS
      final prompt = isGerman
          ? '''Untersuche dieses Lebensmittelbild sorgfältig und identifiziere ALLE sichtbaren Lebensmittel- und Getränkeartikel:

Für JEDES Element, das du siehst:
1. Welches Lebensmittel oder Getränk ist es (sei spezifisch - inkludiere Zubereitungsmethode, Art, Marke falls sichtbar)
2. Die Portionsgröße im Bild für DIESES spezifische Element (schätze Gewicht in Gramm oder Volumen in ml)
3. Vollständige Nährwertinformationen pro 100g oder 100ml basierend auf Standard-Lebensmittelzusammensetzung

Für Getränke:
- Identifiziere die Art (Wasser, Saft, Limonade, Kaffee, Tee, Energydrink, etc.)
- Schätze Kalorien, Kohlenhydrate, Zucker, Koffein (falls zutreffend)
- Setze unit auf "ml" und Wassergehalt auf 95-100

Für feste Lebensmittel:
- Identifiziere das spezifische Lebensmittel und die Zubereitungsmethode
- Schätze alle Makronährstoffe (Protein, Kohlenhydrate, Fett)
- Schätze Ballaststoffe, Zucker, Natrium falls sichtbar oder typisch für dieses Lebensmittel
- Setze unit auf "g" und schätze Wassergehalt (Obst/Gemüse ~85%, gekochte Lebensmittel ~60-70%, trockene Lebensmittel ~10-20%)

WICHTIG: Gib ein JSON-ARRAY mit einem Objekt für JEDES Lebensmittel/Getränk zurück, das du siehst. Wenn du mehrere Elemente siehst (z.B. Apfel, Orange, Cola), gib ein Array mit 3 Objekten zurück. Verpasse keine Elemente.'''
          : '''Carefully examine this food image and identify ALL food and drink items visible:

For EACH item you see:
1. What food or drink is it (be specific - include cooking method, type, brand if visible)
2. The portion size visible in the image for THIS specific item (estimate weight in grams or volume in ml)
3. Complete nutritional information per 100g or 100ml based on standard food composition

For drinks/beverages:
- Identify the type (water, juice, soda, coffee, tea, energy drink, etc.)
- Estimate calories, carbs, sugar, caffeine (if applicable)
- Set unit to "ml" and water content to 95-100

For solid foods:
- Identify the specific food item and preparation method
- Estimate all macronutrients (protein, carbs, fat)
- Estimate fiber, sugar, sodium if visible or typical for that food
- Set unit to "g" and estimate water content (fruits/vegetables ~85%, cooked foods ~60-70%, dry foods ~10-20%)

IMPORTANT: Return a JSON ARRAY with one object for EACH food/drink item you see. If you see multiple items (e.g., apple, orange, cola), return an array with 3 objects. Do not miss any items.''';
      
      // Create prediction with image - Gemini Flash 2.5 accepts images via images array
      final url = Uri.parse('$_baseUrl/predictions');
      
      // Gemini Flash 2.5 through Replicate accepts images via 'images' array (array of URIs)
      final inputMap = <String, dynamic>{
        'prompt': prompt,
        'system_instruction': systemInstruction,
        'temperature': 0.3, // Slightly higher for more creative recognition
        'max_output_tokens': 4000, // Increased for Gemini 3.0 Pro and multiple items
        'top_p': 0.95,
        'images': [imageUrl], // Array of image URIs from Supabase Storage
      };

      final body = {
        'version': versionId,
        'input': inputMap,
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 201) {
        print('Replicate API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create prediction: ${response.statusCode}');
      }

      final predictionData = jsonDecode(response.body);
      final predictionId = predictionData['id'] as String;

      // Poll for completion
      final result = await _pollForResult(predictionId);
      
      // Parse JSON response - now returns array of foods
      try {
        // Clean up response - remove markdown code blocks if present
        String cleanedResult = result.trim();
        if (cleanedResult.startsWith('```json')) {
          cleanedResult = cleanedResult.substring(7);
        }
        if (cleanedResult.startsWith('```')) {
          cleanedResult = cleanedResult.substring(3);
        }
        if (cleanedResult.endsWith('```')) {
          cleanedResult = cleanedResult.substring(0, cleanedResult.length - 3);
        }
        cleanedResult = cleanedResult.trim();
        
        final parsedData = jsonDecode(cleanedResult);
        
        // Handle both array and single object (for backward compatibility)
        List<Map<String, dynamic>> foodsList;
        
        if (parsedData is List) {
          foodsList = List<Map<String, dynamic>>.from(parsedData);
        } else if (parsedData is Map) {
          // Single object - convert to array
          foodsList = [Map<String, dynamic>.from(parsedData)];
        } else {
          throw Exception('Unexpected response format');
        }
        
        // Validate and normalize each food item
        return foodsList.map((foodData) {
          return {
            'name': foodData['name'] ?? 'Unknown Food',
            'german_name': foodData['german_name'] ?? foodData['name'] ?? 'Unknown Food',
            'calories': (foodData['calories'] as num?)?.toDouble() ?? 0.0,
            'protein': (foodData['protein'] as num?)?.toDouble() ?? 0.0,
            'carbs': (foodData['carbs'] as num?)?.toDouble() ?? 0.0,
            'fat': (foodData['fat'] as num?)?.toDouble() ?? 0.0,
            'fiber': (foodData['fiber'] as num?)?.toDouble() ?? 0.0,
            'sugar': (foodData['sugar'] as num?)?.toDouble() ?? 0.0,
            'sodium': (foodData['sodium'] as num?)?.toDouble() ?? 0.0,
            'water': (foodData['water'] as num?)?.toDouble() ?? 0.0,
            'caffeine': (foodData['caffeine'] as num?)?.toDouble() ?? 0.0,
            'estimated_weight': (foodData['estimated_weight'] as num?)?.toDouble() ?? 100.0,
            'unit': foodData['unit'] ?? 'g',
          };
        }).toList();
      } catch (e) {
        print('Error parsing food data: $e');
        print('Raw response: $result');
        throw Exception('Failed to parse food recognition result: $e');
      }
    } catch (e) {
      print('Error recognizing food from image: $e');
      rethrow;
    }
  }

  // Recognize food from voice transcription using Gemini
  // language: 'de' for German, 'en' for English (default)
  Future<List<Map<String, dynamic>>> recognizeFoodFromVoice(
    String transcription, {
    String language = 'en',
  }) async {
    try {
      // Get model version
      final modelUrl = Uri.parse('$_baseUrl/models/$_model');
      final modelResponse = await http.get(
        modelUrl,
        headers: {
          'Authorization': 'Token $_apiToken',
          'Content-Type': 'application/json',
        },
      );

      if (modelResponse.statusCode != 200) {
        throw Exception('Failed to get model: ${modelResponse.statusCode}');
      }

      final modelData = jsonDecode(modelResponse.body);
      final latestVersion = modelData['latest_version'] as Map<String, dynamic>?;
      final versionId = latestVersion?['id'] as String?;

      if (versionId == null) {
        throw Exception('No version found for model');
      }

      // System instruction for voice transcription - Language-aware
      final isGerman = language == 'de';
      
      final systemInstruction = isGerman
          ? '''Du bist ein Experte für Ernährung. Deine Aufgabe ist es, Lebensmittelinformationen aus Sprachtranskriptionen zu extrahieren.

WICHTIGE REGELN:
1. Identifiziere ALLE Lebensmittel/Getränke, die in der Transkription erwähnt werden
2. Sei spezifisch mit Namen (z.B. "Gegrillte Hähnchenbrust" nicht nur "Hähnchen")
3. Schätze Nährwerte basierend auf Standard-Lebensmittelzusammensetzungsdaten
4. Schätze Portionsgrößen falls erwähnt, sonst verwende typische Portionsgrößen
5. Gib NUR ein gültiges JSON-Array zurück, keine Erklärungen, kein Markdown, keine Code-Blöcke

Gib ein JSON-ARRAY mit dieser EXAKTEN Struktur zurück (ein Objekt pro Lebensmittel):
[
  {
    "name": "spezifischer Lebensmittelname auf Englisch",
    "german_name": "spezifischer Lebensmittelname auf Deutsch",
    "calories": Zahl (Kalorien pro 100g oder 100ml),
    "protein": Zahl (Gramm pro 100g/100ml),
    "carbs": Zahl (Gramm pro 100g/100ml),
    "fat": Zahl (Gramm pro 100g/100ml),
    "fiber": Zahl (Gramm pro 100g/100ml, 0 wenn nicht zutreffend),
    "sugar": Zahl (Gramm pro 100g/100ml, 0 wenn nicht zutreffend),
    "sodium": Zahl (Milligramm pro 100g/100ml, 0 wenn nicht zutreffend),
    "water": Zahl (Gramm pro 100g, für Flüssigkeiten 95-100),
    "caffeine": Zahl (Milligramm pro 100g/100ml, 0 wenn nicht zutreffend),
    "estimated_weight": Zahl (geschätztes Gewicht in Gramm oder ml - verwende erwähnte Portion oder typische Portionsgröße),
    "unit": "g" für Feststoffe, "ml" für Flüssigkeiten/Getränke
  }
]

KRITISCH: Erkenne ALLE erwähnten Lebensmittel. Wenn der Benutzer "Apfel, Orange und Cola" sagt, gib ein Array mit 3 Objekten zurück. Gib immer ein Array zurück.'''
          : '''You are an expert nutritionist. Your task is to extract food information from voice transcriptions.

IMPORTANT RULES:
1. Identify ALL foods/drinks mentioned in the transcription
2. Be specific with names (e.g., "Grilled Chicken Breast" not just "Chicken")
3. Estimate nutritional values based on standard food composition data
4. Estimate portion sizes if mentioned, otherwise use typical serving sizes
5. Return ONLY valid JSON array, no explanations, no markdown, no code blocks

Return a JSON ARRAY with this EXACT structure (one object per food item):
[
  {
    "name": "specific food name in English",
    "german_name": "specific food name in German",
    "calories": number (calories per 100g or 100ml),
    "protein": number (grams per 100g/100ml),
    "carbs": number (grams per 100g/100ml),
    "fat": number (grams per 100g/100ml),
    "fiber": number (grams per 100g/100ml, 0 if not applicable),
    "sugar": number (grams per 100g/100ml, 0 if not applicable),
    "sodium": number (milligrams per 100g/100ml, 0 if not applicable),
    "water": number (grams per 100g, for liquids use 95-100),
    "caffeine": number (milligrams per 100g/100ml, 0 if not applicable),
    "estimated_weight": number (estimated weight in grams or ml - use mentioned portion or typical serving),
    "unit": "g" for solids, "ml" for liquids/drinks
  }
]

CRITICAL: Detect ALL food items mentioned. If user says "apple, orange, and cola", return an array with 3 objects. Always return an array.''';

      final prompt = isGerman
          ? '''Analysiere diese Sprachtranskription und extrahiere ALLE erwähnten Lebensmittel:

"$transcription"

Für jedes erwähnte Lebensmittel/Getränk:
1. Identifiziere das spezifische Element (sei spezifisch mit Namen und Zubereitungsmethoden)
2. Schätze Nährwertinformationen pro 100g/100ml
3. Schätze Portionsgröße falls erwähnt, sonst verwende typische Portionsgröße
4. Setze unit korrekt (g für Feststoffe, ml für Flüssigkeiten)

Gib ein JSON-Array mit einem Objekt für jedes erkannte Lebensmittel zurück.'''
          : '''Analyze this voice transcription and extract ALL food items mentioned:

"$transcription"

For each food/drink mentioned:
1. Identify the specific item (be specific with names and preparation methods)
2. Estimate nutritional information per 100g/100ml
3. Estimate portion size if mentioned, otherwise use typical serving size
4. Set unit correctly (g for solids, ml for liquids)

Return a JSON array with one object for each food item detected.''';

      final url = Uri.parse('$_baseUrl/predictions');
      
      final inputMap = <String, dynamic>{
        'prompt': prompt,
        'system_instruction': systemInstruction,
        'temperature': 0.3,
        'max_output_tokens': 4000, // Increased for Gemini 3.0 Pro
        'top_p': 0.95,
      };

      final body = {
        'version': versionId,
        'input': inputMap,
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 201) {
        print('Replicate API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create prediction: ${response.statusCode}');
      }

      final predictionData = jsonDecode(response.body);
      final predictionId = predictionData['id'] as String;

      // Poll for completion
      final result = await _pollForResult(predictionId);
      
      // Parse JSON response - same logic as image recognition
      try {
        String cleanedResult = result.trim();
        if (cleanedResult.startsWith('```json')) {
          cleanedResult = cleanedResult.substring(7);
        }
        if (cleanedResult.startsWith('```')) {
          cleanedResult = cleanedResult.substring(3);
        }
        if (cleanedResult.endsWith('```')) {
          cleanedResult = cleanedResult.substring(0, cleanedResult.length - 3);
        }
        cleanedResult = cleanedResult.trim();
        
        final parsedData = jsonDecode(cleanedResult);
        
        List<Map<String, dynamic>> foodsList;
        
        if (parsedData is List) {
          foodsList = List<Map<String, dynamic>>.from(parsedData);
        } else if (parsedData is Map) {
          foodsList = [Map<String, dynamic>.from(parsedData)];
        } else {
          throw Exception('Unexpected response format');
        }
        
        return foodsList.map((foodData) {
          return {
            'name': foodData['name'] ?? 'Unknown Food',
            'german_name': foodData['german_name'] ?? foodData['name'] ?? 'Unknown Food',
            'calories': (foodData['calories'] as num?)?.toDouble() ?? 0.0,
            'protein': (foodData['protein'] as num?)?.toDouble() ?? 0.0,
            'carbs': (foodData['carbs'] as num?)?.toDouble() ?? 0.0,
            'fat': (foodData['fat'] as num?)?.toDouble() ?? 0.0,
            'fiber': (foodData['fiber'] as num?)?.toDouble() ?? 0.0,
            'sugar': (foodData['sugar'] as num?)?.toDouble() ?? 0.0,
            'sodium': (foodData['sodium'] as num?)?.toDouble() ?? 0.0,
            'water': (foodData['water'] as num?)?.toDouble() ?? 0.0,
            'caffeine': (foodData['caffeine'] as num?)?.toDouble() ?? 0.0,
            'estimated_weight': (foodData['estimated_weight'] as num?)?.toDouble() ?? 100.0,
            'unit': foodData['unit'] ?? 'g',
          };
        }).toList();
      } catch (e) {
        print('Error parsing voice food data: $e');
        print('Raw response: $result');
        throw Exception('Failed to parse voice recognition result: $e');
      }
    } catch (e) {
      print('Error recognizing food from voice: $e');
      rethrow;
    }
  }

  // Generate complete food details from food name using AI
  // language: 'de' for German, 'en' for English (default)
  Future<Map<String, dynamic>> generateFoodDetailsFromName(
    String foodName, {
    String language = 'en',
  }) async {
    try {
      // Get model version
      final modelUrl = Uri.parse('$_baseUrl/models/$_model');
      final modelResponse = await http.get(
        modelUrl,
        headers: {
          'Authorization': 'Token $_apiToken',
          'Content-Type': 'application/json',
        },
      );

      if (modelResponse.statusCode != 200) {
        throw Exception('Failed to get model: ${modelResponse.statusCode}');
      }

      final modelData = jsonDecode(modelResponse.body);
      final latestVersion = modelData['latest_version'] as Map<String, dynamic>?;
      final versionId = latestVersion?['id'] as String?;

      if (versionId == null) {
        throw Exception('No version found for model');
      }

      // System instruction for food details generation - Language-aware
      final isGerman = language == 'de';
      
      final systemInstruction = isGerman
          ? '''Du bist ein Experte für Ernährung und Lebensmittelzusammensetzung. Deine Aufgabe ist es, vollständige Nährwertinformationen für ein Lebensmittel basierend auf seinem Namen zu generieren.

WICHTIGE REGELN:
1. Generiere ALLE Nährwertinformationen für das genannte Lebensmittel
2. Verwende Standard-Lebensmittelzusammensetzungsdaten
3. Sei präzise und realistisch mit den Werten
4. Gib NUR ein gültiges JSON-Objekt zurück, keine Erklärungen, kein Markdown, keine Code-Blöcke
5. Alle Werte sind pro 100g oder 100ml (je nach Lebensmitteltyp)

Gib ein JSON-OBJEKT mit dieser EXAKTEN Struktur zurück:
{
  "name": "Lebensmittelname auf Englisch",
  "german_name": "Lebensmittelname auf Deutsch",
  "calories": Zahl (Kalorien pro 100g/100ml),
  "protein": Zahl (Gramm pro 100g/100ml),
  "carbs": Zahl (Gramm pro 100g/100ml),
  "fat": Zahl (Gramm pro 100g/100ml),
  "fiber": Zahl (Gramm pro 100g/100ml, 0 wenn nicht zutreffend),
  "sugar": Zahl (Gramm pro 100g/100ml, 0 wenn nicht zutreffend),
  "saturated_fat": Zahl (Gramm pro 100g/100ml, 0 wenn nicht zutreffend),
  "omega3": Zahl (Gramm pro 100g/100ml, 0 wenn nicht zutreffend),
  "omega6": Zahl (Gramm pro 100g/100ml, 0 wenn nicht zutreffend),
  "vitamin_a": Zahl (mcg pro 100g/100ml, 0 wenn nicht zutreffend),
  "vitamin_c": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "vitamin_d": Zahl (mcg pro 100g/100ml, 0 wenn nicht zutreffend),
  "vitamin_e": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "vitamin_k": Zahl (mcg pro 100g/100ml, 0 wenn nicht zutreffend),
  "vitamin_b1_thiamine": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "vitamin_b2_riboflavin": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "vitamin_b3_niacin": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "vitamin_b5_pantothenic_acid": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "vitamin_b6": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "vitamin_b7_biotin": Zahl (mcg pro 100g/100ml, 0 wenn nicht zutreffend),
  "vitamin_b9_folate": Zahl (mcg pro 100g/100ml, 0 wenn nicht zutreffend),
  "vitamin_b12": Zahl (mcg pro 100g/100ml, 0 wenn nicht zutreffend),
  "calcium": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "iron": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "magnesium": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "phosphorus": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "potassium": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "sodium": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "zinc": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "copper": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "manganese": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "selenium": Zahl (mcg pro 100g/100ml, 0 wenn nicht zutreffend),
  "choline": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "lycopene": Zahl (mcg pro 100g/100ml, 0 wenn nicht zutreffend),
  "lutein_zeaxanthin": Zahl (mcg pro 100g/100ml, 0 wenn nicht zutreffend),
  "beta_carotene": Zahl (mcg pro 100g/100ml, 0 wenn nicht zutreffend),
  "alpha_carotene": Zahl (mcg pro 100g/100ml, 0 wenn nicht zutreffend),
  "water": Zahl (Gramm pro 100g, für Flüssigkeiten 95-100, für Feststoffe basierend auf Typ),
  "caffeine": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "tryptophan": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "threonine": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "isoleucine": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "leucine": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "lysine": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "methionine": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "phenylalanine": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "valine": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend),
  "histidine": Zahl (mg pro 100g/100ml, 0 wenn nicht zutreffend)
}

Sei präzise und realistisch. Verwende dein Wissen über Lebensmittelzusammensetzung.'''
          : '''You are an expert nutritionist and food composition specialist. Your task is to generate complete nutritional information for a food item based on its name.

IMPORTANT RULES:
1. Generate ALL nutritional information for the mentioned food
2. Use standard food composition data
3. Be precise and realistic with values
4. Return ONLY a valid JSON object, no explanations, no markdown, no code blocks
5. All values are per 100g or 100ml (depending on food type)

Return a JSON OBJECT with this EXACT structure:
{
  "name": "Food name in English",
  "german_name": "Food name in German",
  "calories": number (calories per 100g/100ml),
  "protein": number (grams per 100g/100ml),
  "carbs": number (grams per 100g/100ml),
  "fat": number (grams per 100g/100ml),
  "fiber": number (grams per 100g/100ml, 0 if not applicable),
  "sugar": number (grams per 100g/100ml, 0 if not applicable),
  "saturated_fat": number (grams per 100g/100ml, 0 if not applicable),
  "omega3": number (grams per 100g/100ml, 0 if not applicable),
  "omega6": number (grams per 100g/100ml, 0 if not applicable),
  "vitamin_a": number (mcg per 100g/100ml, 0 if not applicable),
  "vitamin_c": number (mg per 100g/100ml, 0 if not applicable),
  "vitamin_d": number (mcg per 100g/100ml, 0 if not applicable),
  "vitamin_e": number (mg per 100g/100ml, 0 if not applicable),
  "vitamin_k": number (mcg per 100g/100ml, 0 if not applicable),
  "vitamin_b1_thiamine": number (mg per 100g/100ml, 0 if not applicable),
  "vitamin_b2_riboflavin": number (mg per 100g/100ml, 0 if not applicable),
  "vitamin_b3_niacin": number (mg per 100g/100ml, 0 if not applicable),
  "vitamin_b5_pantothenic_acid": number (mg per 100g/100ml, 0 if not applicable),
  "vitamin_b6": number (mg per 100g/100ml, 0 if not applicable),
  "vitamin_b7_biotin": number (mcg per 100g/100ml, 0 if not applicable),
  "vitamin_b9_folate": number (mcg per 100g/100ml, 0 if not applicable),
  "vitamin_b12": number (mcg per 100g/100ml, 0 if not applicable),
  "calcium": number (mg per 100g/100ml, 0 if not applicable),
  "iron": number (mg per 100g/100ml, 0 if not applicable),
  "magnesium": number (mg per 100g/100ml, 0 if not applicable),
  "phosphorus": number (mg per 100g/100ml, 0 if not applicable),
  "potassium": number (mg per 100g/100ml, 0 if not applicable),
  "sodium": number (mg per 100g/100ml, 0 if not applicable),
  "zinc": number (mg per 100g/100ml, 0 if not applicable),
  "copper": number (mg per 100g/100ml, 0 if not applicable),
  "manganese": number (mg per 100g/100ml, 0 if not applicable),
  "selenium": number (mcg per 100g/100ml, 0 if not applicable),
  "choline": number (mg per 100g/100ml, 0 if not applicable),
  "lycopene": number (mcg per 100g/100ml, 0 if not applicable),
  "lutein_zeaxanthin": number (mcg per 100g/100ml, 0 if not applicable),
  "beta_carotene": number (mcg per 100g/100ml, 0 if not applicable),
  "alpha_carotene": number (mcg per 100g/100ml, 0 if not applicable),
  "water": number (grams per 100g, for liquids use 95-100, for solids estimate based on type),
  "caffeine": number (mg per 100g/100ml, 0 if not applicable),
  "tryptophan": number (mg per 100g/100ml, 0 if not applicable),
  "threonine": number (mg per 100g/100ml, 0 if not applicable),
  "isoleucine": number (mg per 100g/100ml, 0 if not applicable),
  "leucine": number (mg per 100g/100ml, 0 if not applicable),
  "lysine": number (mg per 100g/100ml, 0 if not applicable),
  "methionine": number (mg per 100g/100ml, 0 if not applicable),
  "phenylalanine": number (mg per 100g/100ml, 0 if not applicable),
  "valine": number (mg per 100g/100ml, 0 if not applicable),
  "histidine": number (mg per 100g/100ml, 0 if not applicable)
}

Be precise and realistic. Use your knowledge of food composition.''';

      final prompt = isGerman
          ? '''Generiere vollständige Nährwertinformationen für dieses Lebensmittel:

"$foodName"

Gib ein JSON-Objekt mit ALLEN Nährwertinformationen zurück (pro 100g/100ml).'''
          : '''Generate complete nutritional information for this food:

"$foodName"

Return a JSON object with ALL nutritional information (per 100g/100ml).''';

      final url = Uri.parse('$_baseUrl/predictions');
      
      final inputMap = <String, dynamic>{
        'prompt': prompt,
        'system_instruction': systemInstruction,
        'temperature': 0.3,
        'max_output_tokens': 4000, // Increased for Gemini 3.0 Pro
        'top_p': 0.95,
      };

      final body = {
        'version': versionId,
        'input': inputMap,
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 201) {
        print('Replicate API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create prediction: ${response.statusCode}');
      }

      final predictionData = jsonDecode(response.body);
      final predictionId = predictionData['id'] as String;

      // Poll for completion
      final result = await _pollForResult(predictionId);

      // Parse JSON response
      try {
        String cleanedResult = result.trim();
        if (cleanedResult.startsWith('```json')) {
          cleanedResult = cleanedResult.substring(7);
        }
        if (cleanedResult.startsWith('```')) {
          cleanedResult = cleanedResult.substring(3);
        }
        if (cleanedResult.endsWith('```')) {
          cleanedResult = cleanedResult.substring(0, cleanedResult.length - 3);
        }
        cleanedResult = cleanedResult.trim();
        
        final parsedData = jsonDecode(cleanedResult);
        
        Map<String, dynamic> foodData;
        
        if (parsedData is Map) {
          foodData = Map<String, dynamic>.from(parsedData);
        } else {
          throw Exception('Unexpected response format: expected object');
        }
        
        // Detect unit intelligently
        final detectedUnit = _detectUnitFromFoodName(foodData['name'] ?? foodName);
        
        // Convert to proper format with all nutrients
        return {
          'name': foodData['name'] ?? foodName,
          'german_name': foodData['german_name'] ?? foodData['name'] ?? foodName,
          'unit': detectedUnit, // Add detected unit
          'calories': (foodData['calories'] as num?)?.toDouble() ?? 0.0,
          'protein': (foodData['protein'] as num?)?.toDouble() ?? 0.0,
          'carbs': (foodData['carbs'] as num?)?.toDouble() ?? 0.0,
          'fat': (foodData['fat'] as num?)?.toDouble() ?? 0.0,
          'fiber': (foodData['fiber'] as num?)?.toDouble() ?? 0.0,
          'sugar': (foodData['sugar'] as num?)?.toDouble() ?? 0.0,
          'saturated_fat': (foodData['saturated_fat'] as num?)?.toDouble() ?? 0.0,
          'omega3': (foodData['omega3'] as num?)?.toDouble() ?? 0.0,
          'omega6': (foodData['omega6'] as num?)?.toDouble() ?? 0.0,
          'vitamin_a': (foodData['vitamin_a'] as num?)?.toDouble() ?? 0.0,
          'vitamin_c': (foodData['vitamin_c'] as num?)?.toDouble() ?? 0.0,
          'vitamin_d': (foodData['vitamin_d'] as num?)?.toDouble() ?? 0.0,
          'vitamin_e': (foodData['vitamin_e'] as num?)?.toDouble() ?? 0.0,
          'vitamin_k': (foodData['vitamin_k'] as num?)?.toDouble() ?? 0.0,
          'vitamin_b1_thiamine': (foodData['vitamin_b1_thiamine'] as num?)?.toDouble() ?? 0.0,
          'vitamin_b2_riboflavin': (foodData['vitamin_b2_riboflavin'] as num?)?.toDouble() ?? 0.0,
          'vitamin_b3_niacin': (foodData['vitamin_b3_niacin'] as num?)?.toDouble() ?? 0.0,
          'vitamin_b5_pantothenic_acid': (foodData['vitamin_b5_pantothenic_acid'] as num?)?.toDouble() ?? 0.0,
          'vitamin_b6': (foodData['vitamin_b6'] as num?)?.toDouble() ?? 0.0,
          'vitamin_b7_biotin': (foodData['vitamin_b7_biotin'] as num?)?.toDouble() ?? 0.0,
          'vitamin_b9_folate': (foodData['vitamin_b9_folate'] as num?)?.toDouble() ?? 0.0,
          'vitamin_b12': (foodData['vitamin_b12'] as num?)?.toDouble() ?? 0.0,
          'calcium': (foodData['calcium'] as num?)?.toDouble() ?? 0.0,
          'iron': (foodData['iron'] as num?)?.toDouble() ?? 0.0,
          'magnesium': (foodData['magnesium'] as num?)?.toDouble() ?? 0.0,
          'phosphorus': (foodData['phosphorus'] as num?)?.toDouble() ?? 0.0,
          'potassium': (foodData['potassium'] as num?)?.toDouble() ?? 0.0,
          'sodium': (foodData['sodium'] as num?)?.toDouble() ?? 0.0,
          'zinc': (foodData['zinc'] as num?)?.toDouble() ?? 0.0,
          'copper': (foodData['copper'] as num?)?.toDouble() ?? 0.0,
          'manganese': (foodData['manganese'] as num?)?.toDouble() ?? 0.0,
          'selenium': (foodData['selenium'] as num?)?.toDouble() ?? 0.0,
          'choline': (foodData['choline'] as num?)?.toDouble() ?? 0.0,
          'lycopene': (foodData['lycopene'] as num?)?.toDouble() ?? 0.0,
          'lutein_zeaxanthin': (foodData['lutein_zeaxanthin'] as num?)?.toDouble() ?? 0.0,
          'beta_carotene': (foodData['beta_carotene'] as num?)?.toDouble() ?? 0.0,
          'alpha_carotene': (foodData['alpha_carotene'] as num?)?.toDouble() ?? 0.0,
          'water': (foodData['water'] as num?)?.toDouble() ?? 0.0,
          'caffeine': (foodData['caffeine'] as num?)?.toDouble() ?? 0.0,
          'tryptophan': (foodData['tryptophan'] as num?)?.toDouble() ?? 0.0,
          'threonine': (foodData['threonine'] as num?)?.toDouble() ?? 0.0,
          'isoleucine': (foodData['isoleucine'] as num?)?.toDouble() ?? 0.0,
          'leucine': (foodData['leucine'] as num?)?.toDouble() ?? 0.0,
          'lysine': (foodData['lysine'] as num?)?.toDouble() ?? 0.0,
          'methionine': (foodData['methionine'] as num?)?.toDouble() ?? 0.0,
          'phenylalanine': (foodData['phenylalanine'] as num?)?.toDouble() ?? 0.0,
          'valine': (foodData['valine'] as num?)?.toDouble() ?? 0.0,
          'histidine': (foodData['histidine'] as num?)?.toDouble() ?? 0.0,
        };
      } catch (e) {
        print('Error parsing food details: $e');
        print('Raw response: $result');
        throw Exception('Failed to parse food details: $e');
      }
    } catch (e) {
      print('Error generating food details from name: $e');
      rethrow;
    }
  }

  /// Helper function to detect unit from food name
  String _detectUnitFromFoodName(String foodName) {
    final nameLower = foodName.toLowerCase().trim();
    
    // Liquid keywords
    final liquidKeywords = [
      'juice', 'saft', 'drink', 'getränk', 'soda', 'cola', 'water', 'wasser',
      'milk', 'milch', 'coffee', 'kaffee', 'tea', 'tee', 'beer', 'bier',
      'wine', 'wein', 'smoothie', 'shake', 'lemonade', 'limonade',
      'soup', 'suppe', 'broth', 'brühe', 'sauce', 'soße',
    ];
    
    for (var keyword in liquidKeywords) {
      if (nameLower.contains(keyword)) {
        return 'ml';
      }
    }
    
    // Piece keywords
    final pieceKeywords = [
      'apple', 'apfel', 'banana', 'banane', 'orange', 'apfelsine',
      'egg', 'ei', 'eggs', 'eier', 'slice', 'scheibe', 'slices', 'scheiben',
      'cookie', 'keks', 'cookies', 'kekse', 'cracker', 'crackers',
      'meatball', 'frikadelle', 'meatballs', 'frikadellen',
      'bread', 'brot', 'loaf', 'laib',
    ];
    
    for (var keyword in pieceKeywords) {
      if (nameLower.contains(keyword)) {
        return 'piece';
      }
    }
    
    // Default to grams
    return 'g';
  }

  /// Transcribe audio using Whisper (professional transcription)
  /// Accepts a public URL to the audio file
  Future<String> transcribeAudio(String audioUrl, {String language = 'en'}) async {
    try {
      // Use OpenAI Whisper via Replicate
      // Try different Whisper models - some accept URLs, some need files
      const whisperModel = 'openai/whisper';
      
      final modelUrl = Uri.parse('$_baseUrl/models/$whisperModel');
      final modelResponse = await http.get(
        modelUrl,
        headers: {
          'Authorization': 'Token $_apiToken',
          'Content-Type': 'application/json',
        },
      );

      if (modelResponse.statusCode != 200) {
        throw Exception('Failed to get Whisper model: ${modelResponse.statusCode}');
      }

      final modelData = jsonDecode(modelResponse.body);
      final latestVersion = modelData['latest_version'] as Map<String, dynamic>?;
      final versionId = latestVersion?['id'] as String?;

      if (versionId == null) {
        throw Exception('No version found for Whisper model');
      }

      // Create prediction - Whisper on Replicate expects the audio URL
      final url = Uri.parse('$_baseUrl/predictions');
      
      // Build input - Whisper expects 'audio' parameter with URL
      // Replicate Whisper accepts: audio (URL or file), language (optional), task (optional)
      final inputMap = <String, dynamic>{
        'audio': audioUrl,
      };
      
      // Language is optional - only add if specified
      // Whisper supports ISO 639-1 codes: 'en', 'de', 'es', etc.
      if (language.isNotEmpty && language != 'auto') {
        inputMap['language'] = language; // Use 'en' or 'de' directly
      }
      
      // Task is optional - 'transcribe' is default, can also use 'translate'
      // Don't add if using default
      
      final body = {
        'version': versionId,
        'input': inputMap,
      };

      print('Whisper request - URL: $audioUrl, Language: $language');
      print('Whisper request body: ${jsonEncode(body)}');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 201) {
        final errorBody = response.body;
        print('Whisper API Error: ${response.statusCode}');
        print('Error response: $errorBody');
        print('Request URL: $audioUrl');
        throw Exception('Failed to create transcription: ${response.statusCode} - $errorBody');
      }

      final predictionData = jsonDecode(response.body);
      final predictionId = predictionData['id'] as String;

      // Poll for result (returns String)
      final result = await _pollForResult(predictionId);
      
      print('Whisper transcription result: $result');
      print('Whisper transcription result length: ${result.length}');
      print('Whisper transcription result type: ${result.runtimeType}');
      
      // Whisper returns text directly - trim and return
      final trimmedResult = result.trim();
      print('Whisper transcription trimmed: $trimmedResult');
      return trimmedResult;
    } catch (e) {
      print('Error transcribing audio: $e');
      rethrow;
    }
  }

  /// Generate exercise details from name using AI
  /// With retry logic for incomplete responses
  Future<Map<String, dynamic>> generateExerciseDetailsFromName(
    String exerciseName, {
    String language = 'en',
    int maxRetries = 2,
  }) async {
    int attempt = 0;
    Exception? lastException;
    
    while (attempt < maxRetries) {
      try {
        attempt++;
        print('[Exercise Details] Attempt $attempt/$maxRetries for: $exerciseName');
        
        final result = await _generateExerciseDetailsAttempt(exerciseName, language: language);
        
        // Validate completeness
        final instructionsEn = result['instructions_en'] as String? ?? '';
        final instructionsDe = result['instructions_de'] as String? ?? '';
        
        final isComplete = instructionsEn.trim().isNotEmpty && 
                          instructionsDe.trim().isNotEmpty &&
                          !instructionsEn.endsWith('...') &&
                          !instructionsDe.endsWith('...') &&
                          instructionsEn.length >= 50 &&
                          instructionsDe.length >= 50 &&
                          instructionsEn.split('.').length >= 3 &&
                          instructionsDe.split('.').length >= 3;
        
        if (isComplete) {
          print('[Exercise Details] Success on attempt $attempt - complete response');
          return result;
        } else {
          print('[Exercise Details] Incomplete response on attempt $attempt');
          print('[Exercise Details] instructions_en: ${instructionsEn.length} chars, ${instructionsEn.split('.').length} sentences');
          print('[Exercise Details] instructions_de: ${instructionsDe.length} chars, ${instructionsDe.split('.').length} sentences');
          
          if (attempt < maxRetries) {
            print('[Exercise Details] Retrying...');
            await Future.delayed(Duration(seconds: 2));
            continue;
          } else {
            print('[Exercise Details] Max retries reached, using partial response');
            return result; // Return even if incomplete
          }
        }
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        print('[Exercise Details] Error on attempt $attempt: $e');
        
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: 2));
        } else {
          rethrow;
        }
      }
    }
    
    throw lastException ?? Exception('Failed to generate exercise details after $maxRetries attempts');
  }

  /// Single attempt to generate exercise details
  Future<Map<String, dynamic>> _generateExerciseDetailsAttempt(
    String exerciseName, {
    String language = 'en',
  }) async {
    try {
      final modelUrl = Uri.parse('$_baseUrl/models/$_model');
      final modelResponse = await http.get(
        modelUrl,
        headers: {
          'Authorization': 'Token $_apiToken',
          'Content-Type': 'application/json',
        },
      );

      if (modelResponse.statusCode != 200) {
        throw Exception('Failed to get model: ${modelResponse.statusCode}');
      }

      final modelData = jsonDecode(modelResponse.body);
      final latestVersion = modelData['latest_version'] as Map<String, dynamic>?;
      final versionId = latestVersion?['id'] as String?;

      if (versionId == null) {
        throw Exception('No version found for model');
      }

      final isGerman = language == 'de';

      final systemInstruction = isGerman
          ? '''Du bist ein Experte für Fitness und Übungen. Deine Aufgabe ist es, detaillierte Informationen über eine Übung zu generieren.

WICHTIGE REGELN:
1. Gib NUR ein gültiges JSON-Objekt zurück, keine Erklärungen, kein Markdown, keine Code-Blöcke
2. STELLE SICHER, dass ALLE Felder vollständig ausgefüllt sind - besonders instructions_en und instructions_de müssen KOMPLETT sein
3. instructions_en und instructions_de müssen identische, vollständige Anleitungen sein (nur in verschiedenen Sprachen)
4. Wenn die Anleitung lang ist, gib sie trotzdem VOLLSTÄNDIG wieder - kürze NICHT ab
5. Jede Anleitung muss mindestens 3-5 Schritte enthalten, je nach Komplexität der Übung

Struktur des JSON-Objekts (ALLE Felder müssen vollständig sein):
{
  "name_en": "Englischer Name der Übung",
  "name_de": "Deutscher Name der Übung",
  "muscle_group": "Chest|Legs|Back|Abs|Arms|Shoulders|Cardio|Full Body",
  "equipment": "None|Dumbbells|Resistance Band|Barbell|Kettlebell|Machine|Other",
  "difficulty": "Beginner|Intermediate|Advanced",
  "instructions_en": "VOLLSTÄNDIGE detaillierte Anleitung auf Englisch - MUSS komplett sein, nicht abgebrochen",
  "instructions_de": "VOLLSTÄNDIGE detaillierte Anleitung auf Deutsch - MUSS komplett sein, nicht abgebrochen, identisch mit instructions_en",
  "calories_per_rep": Zahl (Kalorien pro Wiederholung, für Cardio pro Minute)
}

KRITISCH: instructions_en und instructions_de müssen beide VOLLSTÄNDIG und IDENTISCH sein (nur Sprache unterschiedlich). Keine abgebrochenen Sätze!'''
          : '''You are an expert in fitness and exercises. Your task is to generate detailed information about an exercise.

IMPORTANT RULES:
1. Return ONLY a valid JSON object, no explanations, no markdown, no code blocks
2. ENSURE that ALL fields are COMPLETELY filled - especially instructions_en and instructions_de must be COMPLETE
3. instructions_en and instructions_de must be identical, complete instructions (only in different languages)
4. If the instructions are long, still provide them COMPLETELY - do NOT truncate
5. Each instruction must contain at least 3-5 steps, depending on exercise complexity

Structure of the JSON object (ALL fields must be complete):
{
  "name_en": "English name of the exercise",
  "name_de": "German name of the exercise",
  "muscle_group": "Chest|Legs|Back|Abs|Arms|Shoulders|Cardio|Full Body",
  "equipment": "None|Dumbbells|Resistance Band|Barbell|Kettlebell|Machine|Other",
  "difficulty": "Beginner|Intermediate|Advanced",
  "instructions_en": "COMPLETE detailed instructions in English - MUST be complete, not truncated",
  "instructions_de": "COMPLETE detailed instructions in German - MUST be complete, not truncated, identical to instructions_en",
  "calories_per_rep": number (calories per rep, or per minute for cardio)
}

CRITICAL: instructions_en and instructions_de must both be COMPLETE and IDENTICAL (only language differs). No incomplete sentences!''';

      final prompt = isGerman
          ? '''Generiere detaillierte Informationen für diese Übung: "$exerciseName"'''
          : '''Generate detailed information for this exercise: "$exerciseName"''';

      final url = Uri.parse('$_baseUrl/predictions');
      final inputMap = <String, dynamic>{
        'prompt': prompt,
        'system_instruction': systemInstruction,
        'temperature': 0.7,
        'max_output_tokens': 4000, // Increased for complete instructions in both languages
        'top_p': 0.95,
      };

      final body = {
        'version': versionId,
        'input': inputMap,
      };

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Token $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 201) {
        print('Replicate API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create prediction: ${response.statusCode}');
      }

      final predictionData = jsonDecode(response.body);
      final predictionId = predictionData['id'] as String;

      final result = await _pollForResult(predictionId);
      
      // Check if result is empty or too short
      if (result.trim().isEmpty || result.trim().length < 50) {
        print('[Exercise Details] Empty or too short response: ${result.length} chars');
        throw Exception('Empty or invalid response from AI');
      }

      // Check if JSON appears to be truncated (doesn't end with closing brace)
      final trimmedResult = result.trim();
      final endsWithBrace = trimmedResult.endsWith('}') || 
                           trimmedResult.endsWith('}"') ||
                           trimmedResult.endsWith('}\n') ||
                           trimmedResult.endsWith('}\r\n');
      
      if (!endsWithBrace) {
        print('[Exercise Details] WARNING: Response appears truncated - does not end with }');
        print('[Exercise Details] Response length: ${trimmedResult.length}');
        print('[Exercise Details] Last 150 chars: ${trimmedResult.length > 150 ? trimmedResult.substring(trimmedResult.length - 150) : trimmedResult}');
        throw Exception('Truncated JSON response from AI - missing closing brace');
      }

      try {
        String cleanedResult = trimmedResult;
        if (cleanedResult.startsWith('```json')) {
          cleanedResult = cleanedResult.substring(7);
        }
        if (cleanedResult.startsWith('```')) {
          cleanedResult = cleanedResult.substring(3);
        }
        if (cleanedResult.endsWith('```')) {
          cleanedResult = cleanedResult.substring(0, cleanedResult.length - 3);
        }
        cleanedResult = cleanedResult.trim();
        
        // Verify JSON is complete after cleaning
        if (!cleanedResult.endsWith('}') && !cleanedResult.endsWith('}"')) {
          print('[Exercise Details] WARNING: JSON incomplete after cleaning');
          throw Exception('Incomplete JSON after cleaning');
        }

        final parsedData = jsonDecode(cleanedResult);
        final exerciseData = Map<String, dynamic>.from(parsedData);

        // Validate completeness
        final instructionsEn = exerciseData['instructions_en'] as String? ?? '';
        final instructionsDe = exerciseData['instructions_de'] as String? ?? '';
        
        // Check if instructions are complete (not truncated)
        final isIncomplete = instructionsEn.trim().isEmpty || 
                           instructionsDe.trim().isEmpty ||
                           instructionsEn.endsWith('...') ||
                           instructionsDe.endsWith('...') ||
                           (instructionsEn.length < 50 && instructionsDe.length < 50) ||
                           instructionsEn.split('.').length < 3 ||
                           instructionsDe.split('.').length < 3;
        
        if (isIncomplete) {
          print('[Exercise Details] WARNING: Incomplete response detected');
          print('[Exercise Details] instructions_en length: ${instructionsEn.length}, sentences: ${instructionsEn.split('.').length}');
          print('[Exercise Details] instructions_de length: ${instructionsDe.length}, sentences: ${instructionsDe.split('.').length}');
          print('[Exercise Details] instructions_en preview: ${instructionsEn.substring(0, instructionsEn.length > 200 ? 200 : instructionsEn.length)}');
          print('[Exercise Details] instructions_de preview: ${instructionsDe.substring(0, instructionsDe.length > 200 ? 200 : instructionsDe.length)}');
        }

        // Validate and set defaults
        return {
          'name_en': exerciseData['name_en'] ?? exerciseName,
          'name_de': exerciseData['name_de'] ?? exerciseData['name_en'] ?? exerciseName,
          'muscle_group': _validateMuscleGroup(exerciseData['muscle_group'] as String?),
          'equipment': exerciseData['equipment'] ?? 'None',
          'difficulty': _validateDifficulty(exerciseData['difficulty'] as String?),
          'instructions_en': instructionsEn.isNotEmpty ? instructionsEn : 'Instructions for this exercise. Please consult a fitness professional for detailed guidance.',
          'instructions_de': instructionsDe.isNotEmpty ? instructionsDe : (instructionsEn.isNotEmpty ? instructionsEn : 'Anleitung für diese Übung. Bitte konsultieren Sie einen Fitness-Experten für detaillierte Anweisungen.'),
          'calories_per_rep': (exerciseData['calories_per_rep'] as num?)?.toDouble() ?? 0.5,
        };
      } catch (e) {
        print('Error parsing exercise data: $e');
        print('Raw response: $result');
        throw Exception('Failed to parse exercise data: $e');
      }
    } catch (e) {
      print('Error generating exercise details: $e');
      rethrow;
    }
  }

  // Helper: Validate muscle group
  String _validateMuscleGroup(String? muscleGroup) {
    if (muscleGroup == null) return 'Full Body';
    final normalized = muscleGroup.trim();
    const validGroups = ['Chest', 'Legs', 'Back', 'Abs', 'Arms', 'Shoulders', 'Cardio', 'Full Body'];
    if (validGroups.contains(normalized)) return normalized;
    return 'Full Body';
  }

  // Helper: Validate difficulty
  String _validateDifficulty(String? difficulty) {
    if (difficulty == null) return 'Beginner';
    final normalized = difficulty.trim();
    const validDifficulties = ['Beginner', 'Intermediate', 'Advanced'];
    if (validDifficulties.contains(normalized)) return normalized;
    return 'Beginner';
  }

  /// Process journal entry and extract structured data (workouts, meals, etc.)
  /// With retry logic and validation for empty/invalid responses
  Future<Map<String, dynamic>> processJournalEntry(
    String journalText, {
    String language = 'en',
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    Exception? lastException;
    
    while (attempt < maxRetries) {
      try {
        attempt++;
        print('[Journal Processing] Attempt $attempt/$maxRetries');
        
        final result = await _processJournalEntryAttempt(journalText, language: language);
        
        // Validate result
        if (_isValidJournalResponse(result)) {
          print('[Journal Processing] Success on attempt $attempt');
          return result;
        } else {
          print('[Journal Processing] Invalid/empty response on attempt $attempt');
          print('[Journal Processing] Response: $result');
          
          if (attempt < maxRetries) {
            // Wait before retry with exponential backoff
            final delaySeconds = (attempt * 2).clamp(2, 10);
            print('[Journal Processing] Retrying in $delaySeconds seconds...');
            await Future.delayed(Duration(seconds: delaySeconds));
            continue;
          } else {
            throw Exception('Invalid or empty response after $maxRetries attempts');
          }
        }
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        print('[Journal Processing] Error on attempt $attempt: $e');
        
        if (attempt < maxRetries) {
          // Wait before retry with exponential backoff
          final delaySeconds = (attempt * 2).clamp(2, 10);
          print('[Journal Processing] Retrying in $delaySeconds seconds...');
          await Future.delayed(Duration(seconds: delaySeconds));
        } else {
          print('[Journal Processing] All attempts failed');
          rethrow;
        }
      }
    }
    
    // If we get here, all retries failed
    throw lastException ?? Exception('Failed to process journal entry after $maxRetries attempts');
  }

  /// Single attempt to process journal entry
  Future<Map<String, dynamic>> _processJournalEntryAttempt(
    String journalText, {
    String language = 'en',
  }) async {
    final modelUrl = Uri.parse('$_baseUrl/models/$_model');
    final modelResponse = await http.get(
      modelUrl,
      headers: {
        'Authorization': 'Token $_apiToken',
        'Content-Type': 'application/json',
      },
    );

    if (modelResponse.statusCode != 200) {
      throw Exception('Failed to get model: ${modelResponse.statusCode}');
    }

    final modelData = jsonDecode(modelResponse.body);
    final latestVersion = modelData['latest_version'] as Map<String, dynamic>?;
    final versionId = latestVersion?['id'] as String?;

    if (versionId == null) {
      throw Exception('No version found for model');
    }

    final isGerman = language == 'de';

    final systemInstruction = isGerman
        ? '''Du bist ein Experte für Fitness und Ernährung. Deine Aufgabe ist es, aus einem täglichen Journal-Eintrag strukturierte Informationen zu extrahieren.

WICHTIGE REGELN:
1. Analysiere den Text und extrahiere ALLE relevanten Informationen
2. Identifiziere Workouts (Übungen, Sets, Wiederholungen, Gewicht, Dauer)
3. Identifiziere Mahlzeiten (Essen, Mengen, Mahlzeitentyp)
4. Identifiziere Wasseraufnahme
5. Gib NUR ein gültiges JSON-Objekt zurück, keine Erklärungen, kein Markdown
6. Wenn keine Informationen gefunden werden, gib leere Arrays zurück, aber NIE ein leeres Objekt

Gib ein JSON-OBJEKT mit dieser EXAKTEN Struktur zurück:
{
  "workouts": [
    {
      "exercise_name": "Name der Übung (auf Englisch)",
      "sets": Zahl (Anzahl der Sätze),
      "reps": Zahl (Anzahl der Wiederholungen pro Satz, 0 wenn nicht erwähnt),
      "weight_kg": Zahl (Gewicht in kg das für die Übung verwendet wurde - z.B. bei Bench Press, Squat, Deadlift etc. 0 wenn nicht erwähnt oder nicht anwendbar für Cardio/bodyweight),
      "duration_minutes": Zahl (für Cardio/Timed-Übungen - WICHTIG: Wenn der Benutzer eine Distanz erwähnt wie "4 km" oder "10 km", schätze die Dauer basierend auf durchschnittlichem Tempo. Für Running/Jogging: ~6-8 min/km, für Walking: ~10-12 min/km),
      "calories_burned": Zahl (geschätzte Kalorien - WICHTIG: Berechne basierend auf Übung, Dauer und Intensität. Für Running: ~60-80 kcal/km, für Walking: ~40-50 kcal/km, für andere Cardio: ~8-12 kcal/min)
    }
  ],
  "meals": [
    {
      "food_name": "Name des Essens",
      "quantity": Zahl,
      "unit": "g" oder "ml" oder "piece",
      "meal_type": "BREAKFAST" oder "LUNCH" oder "DINNER" oder "SNACK"
    }
  ],
  "water_ml": Zahl (Wasseraufnahme in ml, 0 wenn nicht erwähnt),
  "notes": "Zusätzliche Notizen oder Aktivitäten"
}'''
        : '''You are an expert in fitness and nutrition. Your task is to extract structured information from a daily journal entry.

IMPORTANT RULES:
1. Analyze the text and extract ALL relevant information
2. Identify workouts (exercises, sets, reps, weight, duration)
3. Identify meals (food, quantities, meal type)
4. Identify water intake
5. Return ONLY a valid JSON object, no explanations, no markdown
6. If no information is found, return empty arrays, but NEVER an empty object

Return a JSON OBJECT with this EXACT structure:
{
  "workouts": [
    {
      "exercise_name": "Exercise name (in English)",
      "sets": number (number of sets),
      "reps": number (number of repetitions per set, 0 if not mentioned),
      "weight_kg": number (weight in kg used for the exercise - e.g. for Bench Press, Squat, Deadlift etc. 0 if not mentioned or not applicable for cardio/bodyweight exercises),
      "duration_minutes": number (for cardio/timed exercises - IMPORTANT: If user mentions distance like "4 km" or "10 km", estimate duration based on average pace. For Running/Jogging: ~6-8 min/km, for Walking: ~10-12 min/km),
      "calories_burned": number (estimated calories - IMPORTANT: Calculate based on exercise, duration and intensity. For Running: ~60-80 kcal/km, for Walking: ~40-50 kcal/km, for other cardio: ~8-12 kcal/min)
    }
  ],
  "meals": [
    {
      "food_name": "Food name",
      "quantity": number,
      "unit": "g" or "ml" or "piece",
      "meal_type": "BREAKFAST" or "LUNCH" or "DINNER" or "SNACK"
    }
  ],
  "water_ml": number (water intake in ml, 0 if not mentioned),
  "notes": "Additional notes or activities"
}''';

    final prompt = isGerman
        ? '''Analysiere diesen Journal-Eintrag und extrahiere strukturierte Informationen:\n\n$journalText'''
        : '''Analyze this journal entry and extract structured information:\n\n$journalText''';

    final url = Uri.parse('$_baseUrl/predictions');
    final inputMap = <String, dynamic>{
      'prompt': prompt,
      'system_instruction': systemInstruction,
      'temperature': 0.3,
      'max_output_tokens': 4000,
      'top_p': 0.95,
    };

    final body = {
      'version': versionId,
      'input': inputMap,
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Token $_apiToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      print('[Journal Processing] Replicate API Error: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to create prediction: ${response.statusCode}');
    }

    final predictionData = jsonDecode(response.body);
    final predictionId = predictionData['id'] as String;

    final result = await _pollForResult(predictionId);

    // Check if result is empty or too short
    if (result.trim().isEmpty || result.trim().length < 10) {
      print('[Journal Processing] Empty or too short response: ${result.length} chars');
      throw Exception('Empty or invalid response from AI');
    }

    try {
      String cleanedResult = result.trim();
      if (cleanedResult.startsWith('```json')) {
        cleanedResult = cleanedResult.substring(7);
      }
      if (cleanedResult.startsWith('```')) {
        cleanedResult = cleanedResult.substring(3);
      }
      if (cleanedResult.endsWith('```')) {
        cleanedResult = cleanedResult.substring(0, cleanedResult.length - 3);
      }
      cleanedResult = cleanedResult.trim();

      if (cleanedResult.isEmpty) {
        throw Exception('Empty response after cleaning');
      }

      final parsedData = jsonDecode(cleanedResult);
      final structuredData = Map<String, dynamic>.from(parsedData);
      
      print('[Journal Processing] Parsed data keys: ${structuredData.keys}');
      return structuredData;
    } catch (e) {
      print('[Journal Processing] Error parsing journal data: $e');
      print('[Journal Processing] Raw response length: ${result.length}');
      print('[Journal Processing] Raw response preview: ${result.substring(0, result.length > 200 ? 200 : result.length)}');
      throw Exception('Failed to parse journal data: $e');
    }
  }

  /// Validate that the journal response has the expected structure
  bool _isValidJournalResponse(Map<String, dynamic> data) {
    // Check if data is empty
    if (data.isEmpty) {
      print('[Journal Validation] Data is empty');
      return false;
    }

    // Check for required keys
    final requiredKeys = ['workouts', 'meals', 'water_ml', 'notes'];
    for (var key in requiredKeys) {
      if (!data.containsKey(key)) {
        print('[Journal Validation] Missing required key: $key');
        return false;
      }
    }

    // Validate workouts is a list
    if (data['workouts'] is! List) {
      print('[Journal Validation] workouts is not a list');
      return false;
    }

    // Validate meals is a list
    if (data['meals'] is! List) {
      print('[Journal Validation] meals is not a list');
      return false;
    }

    // Check if water_ml is a number
    if (data['water_ml'] is! num) {
      print('[Journal Validation] water_ml is not a number');
      return false;
    }

    print('[Journal Validation] Response is valid');
    return true;
  }
}

