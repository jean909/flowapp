/// Intelligent unit detection and conversion for food items
class FoodUnitDetector {
  // Common foods measured in pieces with average weights
  static final Map<String, double> _pieceWeights = {
    // Fruits
    'apple': 182.0, // grams per medium apple
    'apfel': 182.0,
    'banana': 118.0,
    'banane': 118.0,
    'orange': 131.0,
    'apfelsine': 131.0,
    'egg': 50.0, // per large egg
    'ei': 50.0,
    'bread': 25.0, // per slice
    'brot': 25.0,
    'slice': 25.0, // generic slice
    'scheibe': 25.0,
    // Common items
    'cookie': 15.0,
    'keks': 15.0,
    'cracker': 5.0,
    'cracker': 5.0,
    'meatball': 30.0,
    'frikadelle': 30.0,
    'meatball': 30.0,
  };

  // Keywords that indicate liquid/drink
  static final List<String> _liquidKeywords = [
    'juice', 'saft', 'drink', 'getränk', 'soda', 'cola', 'water', 'wasser',
    'milk', 'milch', 'coffee', 'kaffee', 'tea', 'tee', 'beer', 'bier',
    'wine', 'wein', 'smoothie', 'shake', 'lemonade', 'limonade',
    'soup', 'suppe', 'broth', 'brühe', 'sauce', 'soße',
  ];

  // Keywords that indicate piece-based measurement
  static final List<String> _pieceKeywords = [
    'piece', 'stück', 'bucata', 'pcs', 'pc', 'each', 'pro',
    'apple', 'apfel', 'banana', 'banane', 'orange', 'apfelsine',
    'egg', 'ei', 'eggs', 'eier', 'slice', 'scheibe', 'slices', 'scheiben',
    'cookie', 'keks', 'cookies', 'kekse', 'cracker', 'crackers',
    'meatball', 'frikadelle', 'meatballs', 'frikadellen',
    'bread', 'brot', 'loaf', 'laib',
  ];

  /// Detect the appropriate unit for a food item based on its name
  /// Returns: 'g' (grams), 'ml' (milliliters), or 'piece' (pieces)
  static String detectUnit(String foodName) {
    final nameLower = foodName.toLowerCase().trim();
    
    // Check for liquid keywords first
    for (var keyword in _liquidKeywords) {
      if (nameLower.contains(keyword)) {
        return 'ml';
      }
    }
    
    // Check for piece keywords
    for (var keyword in _pieceKeywords) {
      if (nameLower.contains(keyword)) {
        return 'piece';
      }
    }
    
    // Default to grams for solid foods
    return 'g';
  }

  /// Get average weight for a piece-based food item
  /// Returns weight in grams, or null if not found
  static double? getPieceWeight(String foodName) {
    final nameLower = foodName.toLowerCase().trim();
    
    // Direct match
    if (_pieceWeights.containsKey(nameLower)) {
      return _pieceWeights[nameLower];
    }
    
    // Check for partial matches
    for (var entry in _pieceWeights.entries) {
      if (nameLower.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Default weights based on food type
    if (nameLower.contains('fruit') || nameLower.contains('obst')) {
      return 150.0; // Average fruit
    }
    if (nameLower.contains('vegetable') || nameLower.contains('gemüse')) {
      return 100.0; // Average vegetable
    }
    if (nameLower.contains('meat') || nameLower.contains('fleisch')) {
      return 100.0; // Average meat portion
    }
    if (nameLower.contains('bread') || nameLower.contains('brot')) {
      return 25.0; // Average slice
    }
    
    // Default: 100g per piece if unknown
    return 100.0;
  }

  /// Convert piece-based nutrition values to per-100g values
  /// This is used when AI generates values "per piece" but we need "per 100g"
  static Map<String, double> convertPieceToPer100g(
    Map<String, double> nutritionPerPiece,
    double pieceWeightGrams,
  ) {
    final multiplier = 100.0 / pieceWeightGrams;
    final converted = <String, double>{};
    
    for (var entry in nutritionPerPiece.entries) {
      converted[entry.key] = entry.value * multiplier;
    }
    
    return converted;
  }

  /// Calculate nutrition for a given quantity and unit
  /// Returns multiplier to apply to per-100g values
  static double calculateMultiplier({
    required double quantity,
    required String unit,
    String? foodName,
  }) {
    switch (unit.toLowerCase()) {
      case 'g':
      case 'gram':
      case 'grams':
        // Direct: quantity is already in grams
        return quantity / 100.0;
        
      case 'ml':
      case 'milliliter':
      case 'millilitre':
        // For liquids, ml ≈ g (density ~1)
        return quantity / 100.0;
        
      case 'piece':
      case 'pieces':
      case 'stück':
      case 'stücke':
      case 'bucata':
      case 'bucati':
        // Need to convert pieces to grams first
        final pieceWeight = foodName != null 
            ? getPieceWeight(foodName) ?? 100.0
            : 100.0;
        final totalGrams = quantity * pieceWeight;
        return totalGrams / 100.0;
        
      default:
        // Unknown unit, assume grams
        return quantity / 100.0;
    }
  }
}

