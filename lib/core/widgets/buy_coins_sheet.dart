import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/l10n/app_localizations.dart';

class BuyCoinsSheet extends StatefulWidget {
  final int currentCoins;
  final Function(int) onBought;

  const BuyCoinsSheet({
    super.key,
    required this.currentCoins,
    required this.onBought,
  });

  @override
  State<BuyCoinsSheet> createState() => _BuyCoinsSheetState();
}

class _BuyCoinsSheetState extends State<BuyCoinsSheet> {
  final _supabaseService = SupabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _packages = [];

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final packages = await _supabaseService.getCoinPackages();
    if (mounted) {
      setState(() {
        _packages = packages;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '${AppLocalizations.of(context)!.topUpCoins} 🪙',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${AppLocalizations.of(context)!.currentBalance}: ${widget.currentCoins} ${AppLocalizations.of(context)!.coins.toLowerCase()}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_packages.isEmpty)
            Center(child: Text(AppLocalizations.of(context)!.noPackages))
          else
            ..._packages.map(
              (pkg) => Column(
                children: [
                  _buildCoinOption(
                    context,
                    pkg['coins_amount'],
                    '\$${pkg['price_value']}',
                    isPopular: pkg['is_popular'] ?? false,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCoinOption(
    BuildContext context,
    int amount,
    String price, {
    bool isPopular = false,
  }) {
    return InkWell(
      onTap: () => widget.onBought(amount),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: isPopular
              ? Border.all(color: AppColors.primary, width: 2)
              : Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('🪙', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$amount ${AppLocalizations.of(context)!.coins}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (isPopular)
                    Text(
                      AppLocalizations.of(context)!.mostPopular,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isPopular ? AppColors.primary : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                price,
                style: TextStyle(
                  color: isPopular ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
