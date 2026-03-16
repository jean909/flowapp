import 'package:flutter/material.dart';
import 'package:flow/core/theme/app_colors.dart';
import 'package:flow/services/replicate_service.dart';
import 'package:flow/services/supabase_service.dart';
import 'package:flow/l10n/app_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyJournalPage extends StatefulWidget {
  const DailyJournalPage({super.key});

  @override
  State<DailyJournalPage> createState() => _DailyJournalPageState();
}

class _DailyJournalPageState extends State<DailyJournalPage> {
  final TextEditingController _textController = TextEditingController();
  final ReplicateService _replicateService = ReplicateService();
  final SupabaseService _supabaseService = SupabaseService();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isListening = false;
  String _liveTranscription = '';
  String _finalText = '';
  DateTime? _recordingStartTime;
  Duration _recordingDuration = Duration.zero;
  double _confidence = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
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
          // Restart listening if still recording
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

  @override
  void dispose() {
    _textController.dispose();
    _speech.stop();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final locale = Localizations.localeOf(context);
      final languageCode = locale.languageCode == 'de' ? 'de_DE' : 'en_US';
      
      setState(() {
        _isRecording = true;
        _isListening = true;
        _liveTranscription = '';
        _finalText = '';
        _recordingStartTime = DateTime.now();
        _recordingDuration = Duration.zero;
      });

      // Start listening for live transcription
      _startListening(languageCode: languageCode);
      
      // Update duration every second
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

  void _startListening({String languageCode = 'en_US'}) {
    _speech.listen(
      onResult: (result) {
        if (mounted && _isRecording) {
          setState(() {
            _liveTranscription = result.recognizedWords;
            _confidence = result.confidence;
            
            // Update text controller with live transcription
            if (result.finalResult) {
              // When final, append to final text
              if (_finalText.isNotEmpty) {
                _finalText += ' ';
              }
              _finalText += result.recognizedWords;
              _textController.text = _finalText;
            } else {
              // Show live transcription
              _textController.text = _finalText + (_finalText.isNotEmpty ? ' ' : '') + _liveTranscription;
            }
          });
        }
      },
      localeId: languageCode,
      listenMode: stt.ListenMode.confirmation,
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );
  }

  void _updateRecordingDuration() {
    if (_isRecording && _recordingStartTime != null) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _isRecording) {
          setState(() {
            _recordingDuration = DateTime.now().difference(_recordingStartTime!);
          });
          _updateRecordingDuration();
        }
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _speech.stop();
      
      setState(() {
        _isRecording = false;
        _isListening = false;
        // Finalize text - use what we have
        if (_textController.text.isEmpty && _finalText.isNotEmpty) {
          _textController.text = _finalText;
        }
      });
      
      // Automatically process and save in background
      if (_textController.text.trim().isNotEmpty) {
        _processAndSaveInBackground();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isListening = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorStoppingRecording(e.toString()))),
        );
      }
    }
  }

  Future<void> _processAndSaveInBackground() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Get language
      final locale = Localizations.localeOf(context);
      final language = locale.languageCode == 'de' ? 'de' : 'en';

      // Process journal entry with AI in background
      final structuredData = await _replicateService.processJournalEntry(
        text,
        language: language,
      );

      // Show what was extracted
      final workoutsCount = (structuredData['workouts'] as List<dynamic>?)?.length ?? 0;
      final mealsCount = (structuredData['meals'] as List<dynamic>?)?.length ?? 0;
      final waterMl = (structuredData['water_ml'] as num?)?.toInt() ?? 0;
      
      print('Extracted: $workoutsCount workouts, $mealsCount meals, $waterMl ml water');

      // Save structured data
      final summary = await _supabaseService.saveJournalEntry(
        journalText: text,
        structuredData: structuredData,
        language: language,
        audioUrl: null, // No audio file for live transcription
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

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
              onPressed: () {},
            ),
          ),
        );
        
        // Clear and go back after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _textController.clear();
            _liveTranscription = '';
            _finalText = '';
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorProcessing(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dailyJournal),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Recording section
            Card(
              color: AppColors.card,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_isRecording)
                      Column(
                        children: [
                          // Animated microphone icon
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 1.0, end: 1.3),
                            duration: const Duration(milliseconds: 500),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Icon(
                                  Icons.mic,
                                  size: 48,
                                  color: Colors.red,
                                ),
                              );
                            },
                            onEnd: () {
                              if (_isRecording && mounted) {
                                setState(() {});
                              }
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDuration(_recordingDuration),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          if (_confidence > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Confidence: ${(_confidence * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                        ],
                      )
                    else if (_isProcessing)
                      Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(
                            'Processing...',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      )
                    else
                      Icon(
                        Icons.mic_none,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_isRecording)
                          ElevatedButton.icon(
                            onPressed: _startRecording,
                            icon: const Icon(Icons.mic),
                            label: Text(l10n.startRecording),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: _stopRecording,
                            icon: const Icon(Icons.stop),
                            label: Text(l10n.stopRecording),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Text input section
            Text(
              l10n.journalEntry,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: l10n.journalEntryHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.card,
              ),
            ),
            const SizedBox(height: 24),
            
            
            // Info card
            Card(
              color: AppColors.card,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          l10n.howItWorks,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.journalHowItWorks,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

