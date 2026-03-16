import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2';

  // Get product by barcode/EAN with retry logic
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode, {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Add small delay between retries (except first attempt)
        if (attempt > 1) {
          await Future.delayed(Duration(milliseconds: 500 * attempt));
        }

        final url = Uri.parse('$_baseUrl/product/$barcode.json');
        final response = await http.get(
          url,
          headers: {
            'User-Agent': 'FlowApp/1.0 (Android)',
          },
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Request timeout');
          },
        );

        if (response.statusCode != 200) {
          print('Open Food Facts API Error: ${response.statusCode} (attempt $attempt/$maxRetries)');
          if (attempt < maxRetries) continue;
          return null;
        }

        final data = jsonDecode(response.body);
        
        if (data['status'] != 1 || data['product'] == null) {
          print('Product not found in Open Food Facts (attempt $attempt/$maxRetries)');
          if (attempt < maxRetries) continue;
          return null;
        }

        final product = data['product'] as Map<String, dynamic>;
        
        // Extract and normalize nutrition data
        final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};
        
        // Try to get serving size from product
        double estimatedWeight = 100.0;
        final servingSize = (nutriments['serving_size'] as num?)?.toDouble();
        if (servingSize != null && servingSize > 0) {
          estimatedWeight = servingSize;
        } else {
          // Try to parse from quantity field
          final quantity = product['quantity']?.toString() ?? '';
          final quantityMatch = RegExp(r'(\d+(?:\.\d+)?)\s*(g|ml|kg|l)').firstMatch(quantity.toLowerCase());
          if (quantityMatch != null) {
            estimatedWeight = double.tryParse(quantityMatch.group(1) ?? '100') ?? 100.0;
            final qtyUnit = quantityMatch.group(2) ?? 'g';
            if (qtyUnit == 'kg') estimatedWeight *= 1000;
            if (qtyUnit == 'l') estimatedWeight *= 1000;
          }
        }
        
        // Open Food Facts uses different field names, normalize them
        return {
          'name': product['product_name']?.toString() ?? product['product_name_en']?.toString() ?? 'Unknown Product',
          'german_name': product['product_name_de']?.toString() ?? product['product_name']?.toString(),
          'calories': (nutriments['energy-kcal_100g'] as num?)?.toDouble() ?? 
                     ((nutriments['energy-kcal'] as num?)?.toDouble() ?? 0.0),
          'protein': (nutriments['proteins_100g'] as num?)?.toDouble() ?? 
                    ((nutriments['proteins'] as num?)?.toDouble() ?? 0.0),
          'carbs': (nutriments['carbohydrates_100g'] as num?)?.toDouble() ?? 
                  ((nutriments['carbohydrates'] as num?)?.toDouble() ?? 0.0),
          'fat': (nutriments['fat_100g'] as num?)?.toDouble() ?? 
                ((nutriments['fat'] as num?)?.toDouble() ?? 0.0),
          'fiber': (nutriments['fiber_100g'] as num?)?.toDouble() ?? 
                  ((nutriments['fiber'] as num?)?.toDouble() ?? 0.0),
          'sugar': (nutriments['sugars_100g'] as num?)?.toDouble() ?? 
                  ((nutriments['sugars'] as num?)?.toDouble() ?? 0.0),
          'sodium': (nutriments['sodium_100g'] as num?)?.toDouble() ?? 
                   ((nutriments['sodium'] as num?)?.toDouble() ?? 0.0) * 1000, // Convert to mg
          'water': (nutriments['water_100g'] as num?)?.toDouble() ?? 0.0,
          'caffeine': (nutriments['caffeine_100g'] as num?)?.toDouble() ?? 
                     ((nutriments['caffeine'] as num?)?.toDouble() ?? 0.0),
          'estimated_weight': estimatedWeight,
          'unit': _detectUnit(product),
          'barcode': barcode,
          'image_url': product['image_url']?.toString(),
          'brands': product['brands']?.toString(),
        };
      } catch (e) {
        print('Error fetching product from Open Food Facts (attempt $attempt/$maxRetries): $e');
        if (attempt < maxRetries) continue;
        return null;
      }
    }
    
    return null;
  }

  String _detectUnit(Map<String, dynamic> product) {
    final quantity = product['quantity']?.toString().toLowerCase() ?? '';
    final productName = (product['product_name']?.toString() ?? '').toLowerCase();
    
    if (quantity.contains('ml') || quantity.contains('l') || 
        productName.contains('drink') || productName.contains('juice') ||
        productName.contains('water') || productName.contains('cola') ||
        productName.contains('soda') || productName.contains('beer') ||
        productName.contains('wine')) {
      return 'ml';
    }
    return 'g';
  }
}

