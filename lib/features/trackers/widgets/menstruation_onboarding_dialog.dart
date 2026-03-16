import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:flow/services/supabase_service.dart';

class MenstruationOnboardingDialog extends StatefulWidget {
  final VoidCallback onComplete;

  const MenstruationOnboardingDialog({super.key, required this.onComplete});

  @override
  State<MenstruationOnboardingDialog> createState() =>
      _MenstruationOnboardingDialogState();
}

class _MenstruationOnboardingDialogState
    extends State<MenstruationOnboardingDialog> {
  final _supabaseService = SupabaseService();
  int _currentStep = 0;

  // Data collection
  DateTime? _lastPeriodStart;
  int _averageCycleLength = 28;
  String _flowIntensity = 'medium';
  final List<String> _commonSymptoms = [];

  final List<String> _symptomOptions = [
    'Cramps',
    'Headache',
    'Mood Swings',
    'Fatigue',
    'Bloating',
    'Breast Tenderness',
    'Acne',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Expanded(child: _buildCurrentStep()),
            const SizedBox(height: 24),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFE91E63).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Text('🩸', style: TextStyle(fontSize: 40)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Menstruation Tracker Setup',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Step ${_currentStep + 1} of 4',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildLastPeriodStep();
      case 1:
        return _buildCycleLengthStep();
      case 2:
        return _buildFlowIntensityStep();
      case 3:
        return _buildSymptomsStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildLastPeriodStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'When did your last period start?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().subtract(const Duration(days: 7)),
              firstDate: DateTime.now().subtract(const Duration(days: 90)),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() => _lastPeriodStart = date);
            }
          },
          icon: const Icon(Icons.calendar_today),
          label: Text(
            _lastPeriodStart == null
                ? 'Select Date'
                : '${_lastPeriodStart!.day}/${_lastPeriodStart!.month}/${_lastPeriodStart!.year}',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE91E63),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildCycleLengthStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'What is your average cycle length?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Text(
          '$_averageCycleLength days',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE91E63),
          ),
        ),
        const SizedBox(height: 16),
        Slider(
          value: _averageCycleLength.toDouble(),
          min: 21,
          max: 35,
          divisions: 14,
          activeColor: const Color(0xFFE91E63),
          onChanged: (value) =>
              setState(() => _averageCycleLength = value.toInt()),
        ),
        const Text(
          '21-35 days',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildFlowIntensityStep() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'How would you describe your flow?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ...[
            ('light', 'Light', '💧'),
            ('medium', 'Medium', '💧💧'),
            ('heavy', 'Heavy', '💧💧💧'),
          ].map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildFlowOption(option.$1, option.$2, option.$3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowOption(String value, String label, String emoji) {
    final isSelected = _flowIntensity == value;
    return InkWell(
      onTap: () => setState(() => _flowIntensity = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFE91E63).withOpacity(0.1)
              : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFE91E63) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomsStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'What symptoms do you usually experience?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Select all that apply',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _symptomOptions.map((symptom) {
                final isSelected = _commonSymptoms.contains(symptom);
                return FilterChip(
                  label: Text(symptom),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _commonSymptoms.add(symptom);
                      } else {
                        _commonSymptoms.remove(symptom);
                      }
                    });
                  },
                  selectedColor: const Color(0xFFE91E63).withOpacity(0.2),
                  checkmarkColor: const Color(0xFFE91E63),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          TextButton(
            onPressed: () => setState(() => _currentStep--),
            child: Text(AppLocalizations.of(context)!.back),
          )
        else
          const SizedBox(),
        ElevatedButton(
          onPressed: _canProceed() ? _handleNext : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE91E63),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: Text(_currentStep == 3 ? AppLocalizations.of(context)!.finish : AppLocalizations.of(context)!.next),
        ),
      ],
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _lastPeriodStart != null;
      case 1:
      case 2:
        return true;
      case 3:
        return true;
      default:
        return false;
    }
  }

  void _handleNext() async {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      // Save initial data
      await _saveInitialData();
      if (mounted) {
        Navigator.pop(context);
        widget.onComplete();
      }
    }
  }

  Future<void> _saveInitialData() async {
    if (_lastPeriodStart == null) return;

    try {
      // Save setup configuration
      await _supabaseService.saveMenstruationSetup(
        lastPeriodStart: _lastPeriodStart!,
        averageCycleLength: _averageCycleLength,
        averagePeriodLength: 5, // Default period length
      );

      // Log the initial period
      await _supabaseService.logPeriod(
        periodStart: _lastPeriodStart!,
        flowIntensity: _flowIntensity,
      );

      // Save initial symptoms if any were selected
      if (_commonSymptoms.isNotEmpty) {
        await _supabaseService.saveSymptoms(
          date: DateTime.now(),
          symptoms: _commonSymptoms,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.menstruationTrackerActivated),
            backgroundColor: Color(0xFFE91E63),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSavingData(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
