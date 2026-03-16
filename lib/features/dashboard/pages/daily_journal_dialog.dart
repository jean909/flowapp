import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/services/replicate_service.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';

class DailyJournalDialog extends StatefulWidget {
  const DailyJournalDialog({super.key});

  @override
  State<DailyJournalDialog> createState() => _DailyJournalDialogState();
}

class _DailyJournalDialogState extends State<DailyJournalDialog> {
  final TextEditingController _textController = TextEditingController();
  final ReplicateService _replicateService = ReplicateService();
  final SupabaseService _supabaseService = SupabaseService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isListening = false;
  String _liveTranscription = '';
  DateTime? _recordingStartTime;
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  @override
  void dispose() {
    _textController.dispose();
    _speech.stop();
    _durationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    final available = await _speech.initialize(
      onError: (error) {
        print('Speech recognition error: $error');
        if (mounted) {
          setState(() {
            _isListening = false;
            _isRecording = false;
          });
        }
      },
      onStatus: (status) {
        print('Speech recognition status: $status');
        if (status == 'done' && _isRecording) {
          _startListening();
        }
      },
    );
    
    if (!available && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.speechRecognitionNotAvailable)),
      );
    }
  }

  Future<void> _startListening({String? languageCode}) async {
    if (!_isRecording) return;
    
    final locale = Localizations.localeOf(context);
    final langCode = languageCode ?? (locale.languageCode == 'de' ? 'de_DE' : 'en_US');
    
    await _speech.listen(
      onResult: (result) {
        if (mounted && result.finalResult) {
          setState(() {
            _liveTranscription = result.recognizedWords;
            _textController.text = result.recognizedWords;
          });
        } else if (mounted) {
          setState(() {
            _liveTranscription = result.recognizedWords;
            _textController.text = result.recognizedWords;
          });
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: langCode,
      listenMode: stt.ListenMode.confirmation,
      cancelOnError: false,
      partialResults: true,
    );
  }

  Future<void> _startRecording() async {
    try {
      final locale = Localizations.localeOf(context);
      final languageCode = locale.languageCode == 'de' ? 'de_DE' : 'en_US';
      
      setState(() {
        _isRecording = true;
        _isListening = true;
        _liveTranscription = '';
        _textController.clear();
        _recordingStartTime = DateTime.now();
        _recordingDuration = Duration.zero;
      });

      _startListening(languageCode: languageCode);
      _updateRecordingDuration();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isListening = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorStartingRecording(e.toString()))),
        );
      }
    }
  }

  void _updateRecordingDuration() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isRecording && _recordingStartTime != null) {
        setState(() {
          _recordingDuration = DateTime.now().difference(_recordingStartTime!);
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _stopRecording() async {
    try {
      await _speech.stop();
      _durationTimer?.cancel();
      
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isListening = false;
        });
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _processAndSave() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.journalEntryHint)),
      );
      return;
    }

    // Close dialog immediately
    Navigator.pop(context);

    // Show processing notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(AppLocalizations.of(context)!.processingJournal),
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.blue,
      ),
    );

    // Process in background
    _processInBackground(text);
  }

  Future<void> _processInBackground(String text) async {
    try {
      print('[Daily Journal] Starting background processing...');
      
      // Get language
      final locale = Localizations.localeOf(context);
      final language = locale.languageCode;
      
      print('[Daily Journal] Language: $language, Text length: ${text.length}');
      
      // Process journal entry with AI (with automatic retry)
      print('[Daily Journal] Calling AI to process journal entry...');
      final structuredData = await _replicateService.processJournalEntry(
        text,
        language: language,
        maxRetries: 3, // Will retry up to 3 times automatically
      );
      
      print('[Daily Journal] AI processing completed. Workouts: ${structuredData['workouts']?.length ?? 0}, Meals: ${structuredData['meals']?.length ?? 0}');
      
      // Save structured data
      print('[Daily Journal] Saving to database...');
      final summary = await _supabaseService.saveJournalEntry(
        journalText: text,
        structuredData: structuredData,
        language: language,
      );

      print('[Daily Journal] Successfully saved journal entry');
      print('[Daily Journal] Summary: $summary');
      
      if (mounted) {
        // Show detailed notifications for what was saved
        final List<String> notifications = [];
        
        if (summary['workouts_saved'] > 0) {
          notifications.add('${summary['workouts_saved']} ${summary['workouts_saved'] == 1 ? 'workout' : 'workouts'} added 🏋️');
        }
        
        if (summary['meals_saved'] > 0) {
          notifications.add('${summary['meals_saved']} ${summary['meals_saved'] == 1 ? 'meal' : 'meals'} logged 🍽️');
        }
        
        if (summary['water_ml_saved'] > 0) {
          notifications.add('${summary['water_ml_saved']}ml water added 💧');
        }
        
        // Show notifications one by one with a delay
        if (notifications.isNotEmpty) {
          for (int i = 0; i < notifications.length; i++) {
            Future.delayed(Duration(milliseconds: i * 500), () {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(notifications[i]),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            });
          }
        } else {
          // Fallback if nothing was saved
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.journalSavedSuccessfully),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('[Daily Journal] Error processing journal: $e');
      print('[Daily Journal] Stack trace: $stackTrace');
      
      if (mounted) {
        final errorMessage = e.toString().contains('Invalid or empty response')
            ? 'AI returned empty response. Please try again or add more details to your journal entry.'
            : 'Error processing journal: ${e.toString().length > 100 ? e.toString().substring(0, 100) + "..." : e}';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.retry,
              textColor: Colors.white,
              onPressed: () {
                // Retry processing
                _processInBackground(text);
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.book_outlined, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.dailyJournal,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Recording status
                    if (_isRecording)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Recording... ${_formatDuration(_recordingDuration)}',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Text field (editable)
                    TextField(
                      controller: _textController,
                      maxLines: 8,
                      minLines: 5,
                      decoration: InputDecoration(
                        hintText: l10n.journalEntryHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      enabled: !_isProcessing,
                    ),
                    const SizedBox(height: 16),
                    // Info message
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You can edit the text before sending. Processing may take a few minutes.',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  // Record/Stop button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : (_isRecording ? _stopRecording : _startRecording),
                      icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                      label: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRecording ? Colors.red : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Send button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (_isProcessing || _textController.text.trim().isEmpty)
                          ? null
                          : _processAndSave,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(_isProcessing ? 'Processing...' : 'Send to AI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

