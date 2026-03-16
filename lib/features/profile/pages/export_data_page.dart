import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ExportDataPage extends StatefulWidget {
  const ExportDataPage({super.key});

  @override
  State<ExportDataPage> createState() => _ExportDataPageState();
}

class _ExportDataPageState extends State<ExportDataPage> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isExporting = false;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  Future<void> _exportToCSV() async {
    setState(() => _isExporting = true);
    try {
      final logs = await _getLogsForDateRange();
      
      if (logs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noDataFoundForRange),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      
      final csvData = _convertLogsToCSV(logs);
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'flow_nutrition_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csvData);
      
      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Flow Nutrition Data Export (${logs.length} entries)',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.exportCsvSuccess(logs.length)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.exportError(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportToJSON() async {
    setState(() => _isExporting = true);
    try {
      final logs = await _getLogsForDateRange();
      
      if (logs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noDataFoundForRange),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      
      final jsonData = jsonEncode(logs);
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'flow_nutrition_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonData);
      
      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Flow Nutrition Data Export (${logs.length} entries)',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.exportJsonSuccess(logs.length)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.exportError(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportToPDF() async {
    setState(() => _isExporting = true);
    try {
      final logs = await _getLogsForDateRange();
      
      if (logs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noDataFoundForRange),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      
      final totals = _calculateTotals(logs);
      
      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            _buildPDFHeader(),
            pw.SizedBox(height: 20),
            _buildPDFSummary(totals),
            pw.SizedBox(height: 20),
            _buildPDFDailyBreakdown(logs),
          ],
        ),
      );
      
      if (mounted) {
        await Printing.layoutPdf(
          onLayout: (format) async => pdf.save(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pdfReportSuccess(logs.length)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pdfReportError(e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getLogsForDateRange() async {
    final allLogs = <Map<String, dynamic>>[];
    var currentDate = _startDate;
    
    while (currentDate.isBefore(_endDate) || currentDate.isAtSameMomentAs(_endDate)) {
      final logs = await _supabaseService.getDailyMealLogs(currentDate);
      allLogs.addAll(logs);
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return allLogs;
  }

  String _convertLogsToCSV(List<Map<String, dynamic>> logs) {
    final csvData = <List<dynamic>>[];
    
    // Header
    csvData.add([
      'Date',
      'Meal Type',
      'Food Name',
      'Quantity',
      'Unit',
      'Calories',
      'Protein (g)',
      'Carbs (g)',
      'Fat (g)',
      'Fiber (g)',
      'Sugar (g)',
      'Sodium (mg)',
      'Calcium (mg)',
      'Iron (mg)',
      'Vitamin C (mg)',
      'Vitamin D (mcg)',
    ]);
    
    // Data rows
    for (var log in logs) {
      final nutritionData = log['nutrition_data'] as Map<String, dynamic>? ?? {};
      final loggedAt = DateTime.parse(log['logged_at'] as String);
      
      csvData.add([
        DateFormat('yyyy-MM-dd').format(loggedAt),
        log['meal_type'] ?? '',
        log['custom_food_name'] ?? (log['general_food_flow']?['name'] ?? '') ?? '',
        log['quantity'] ?? 0,
        log['unit'] ?? '',
        nutritionData['calories'] ?? log['calories'] ?? 0,
        nutritionData['protein'] ?? log['protein'] ?? 0,
        nutritionData['carbs'] ?? log['carbs'] ?? 0,
        nutritionData['fat'] ?? log['fat'] ?? 0,
        nutritionData['fiber'] ?? 0,
        nutritionData['sugar'] ?? 0,
        nutritionData['sodium'] ?? 0,
        nutritionData['calcium'] ?? 0,
        nutritionData['iron'] ?? 0,
        nutritionData['vitamin_c'] ?? 0,
        nutritionData['vitamin_d'] ?? 0,
      ]);
    }
    
    return const ListToCsvConverter().convert(csvData);
  }

  Map<String, double> _calculateTotals(List<Map<String, dynamic>> logs) {
    final totals = <String, double>{};
    
    for (var log in logs) {
      final nutritionData = log['nutrition_data'] as Map<String, dynamic>?;
      if (nutritionData != null && nutritionData.isNotEmpty) {
        nutritionData.forEach((key, value) {
          if (value is num) {
            totals[key] = (totals[key] ?? 0.0) + value.toDouble();
          }
        });
      } else {
        // Fallback to old fields
        final calories = (log['calories'] as num?)?.toDouble() ?? 0.0;
        final protein = (log['protein'] as num?)?.toDouble() ?? 0.0;
        final carbs = (log['carbs'] as num?)?.toDouble() ?? 0.0;
        final fat = (log['fat'] as num?)?.toDouble() ?? 0.0;
        totals['calories'] = (totals['calories'] ?? 0.0) + calories;
        totals['protein'] = (totals['protein'] ?? 0.0) + protein;
        totals['carbs'] = (totals['carbs'] ?? 0.0) + carbs;
        totals['fat'] = (totals['fat'] ?? 0.0) + fat;
      }
    }
    
    return totals;
  }

  pw.Widget _buildPDFHeader() {
    return pw.Header(
      level: 0,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Flow Nutrition Report',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            DateFormat('MMMM yyyy').format(DateTime.now()),
            style: pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFSummary(Map<String, double> totals) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Summary',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            _buildPDFTableRow('Calories', '${totals['calories']?.toStringAsFixed(0) ?? 0} kcal'),
            _buildPDFTableRow('Protein', '${totals['protein']?.toStringAsFixed(1) ?? 0} g'),
            _buildPDFTableRow('Carbs', '${totals['carbs']?.toStringAsFixed(1) ?? 0} g'),
            _buildPDFTableRow('Fat', '${totals['fat']?.toStringAsFixed(1) ?? 0} g'),
            _buildPDFTableRow('Fiber', '${totals['fiber']?.toStringAsFixed(1) ?? 0} g'),
            _buildPDFTableRow('Calcium', '${totals['calcium']?.toStringAsFixed(1) ?? 0} mg'),
            _buildPDFTableRow('Iron', '${totals['iron']?.toStringAsFixed(1) ?? 0} mg'),
          ],
        ),
      ],
    );
  }

  pw.TableRow _buildPDFTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  pw.Widget _buildPDFDailyBreakdown(List<Map<String, dynamic>> logs) {
    final dailyData = <String, Map<String, double>>{};
    
    for (var log in logs) {
      final date = DateFormat('yyyy-MM-dd').format(DateTime.parse(log['logged_at'] as String));
      if (!dailyData.containsKey(date)) {
        dailyData[date] = {};
      }
      
      final nutritionData = log['nutrition_data'] as Map<String, dynamic>?;
      if (nutritionData != null) {
        nutritionData.forEach((key, value) {
          if (value is num) {
            dailyData[date]![key] = (dailyData[date]![key] ?? 0.0) + value.toDouble();
          }
        });
      }
    }
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Daily Breakdown',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        ...dailyData.entries.map((entry) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                entry.key,
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Calories: ${entry.value['calories']?.toStringAsFixed(0) ?? 0} | Protein: ${entry.value['protein']?.toStringAsFixed(1) ?? 0}g',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.exportData),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateRangeSelector(),
            const SizedBox(height: 32),
            _buildExportOption(
              icon: Icons.table_chart,
              title: AppLocalizations.of(context)!.exportToCSV,
              description: AppLocalizations.of(context)!.exportToCSVDesc,
              onTap: _exportToCSV,
            ),
            const SizedBox(height: 16),
            _buildExportOption(
              icon: Icons.code,
              title: AppLocalizations.of(context)!.exportToJSON,
              description: AppLocalizations.of(context)!.exportToJSONDesc,
              onTap: _exportToJSON,
            ),
            const SizedBox(height: 16),
            _buildExportOption(
              icon: Icons.picture_as_pdf,
              title: AppLocalizations.of(context)!.generatePDFReport,
              description: AppLocalizations.of(context)!.generatePDFReportDesc,
              onTap: _exportToPDF,
            ),
            if (_isExporting) ...[
              const SizedBox(height: 32),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.dateRange,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(
                  AppLocalizations.of(context)!.from,
                  _startDate,
                  () => _selectDateRange(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateButton(
                  AppLocalizations.of(context)!.to,
                  _endDate,
                  () => _selectDateRange(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy').format(date),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isExporting ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}


