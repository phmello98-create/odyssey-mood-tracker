import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

/// Service for speech-to-text functionality using native device APIs (free!)
class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String? _lastError;

  bool get isListening => _isListening;
  bool get isAvailable => _isInitialized;
  String? get lastError => _lastError;

  /// Initialize the speech recognition service
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      // Request permission and initialize
      _isInitialized = await _speechToText.initialize(
        onError: (SpeechRecognitionError error) {
          _lastError = error.errorMsg;
          debugPrint('Speech error: ${error.errorMsg}');
        },
        onStatus: (status) => debugPrint('Speech status: $status'),
        debugLogging: false,
      );
      
      if (!_isInitialized) {
        _lastError = 'Speech recognition not available on this device';
      }
      
      return _isInitialized;
    } catch (e) {
      _lastError = 'Failed to initialize: $e';
      debugPrint('Failed to initialize speech: $e');
      return false;
    }
  }
  
  /// Check if speech recognition is available without initializing
  Future<bool> hasPermission() async {
    return _speechToText.hasPermission;
  }

  /// Start listening for speech input
  Future<void> startListening({
    required Function(String text) onResult,
    Function(String text)? onPartialResult,
    VoidCallback? onDone,
    String localeId = 'pt_BR',
  }) async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) return;
    }

    if (_isListening) return;

    _isListening = true;
    
    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult) {
          onResult(result.recognizedWords);
          onDone?.call();
        } else {
          onPartialResult?.call(result.recognizedWords);
        }
      },
      localeId: localeId,
      listenMode: ListenMode.dictation,
      cancelOnError: true,
      partialResults: true,
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    _isListening = false;
    await _speechToText.stop();
  }

  /// Cancel listening without processing
  Future<void> cancelListening() async {
    if (!_isListening) return;
    
    _isListening = false;
    await _speechToText.cancel();
  }

  /// Get available locales for speech recognition
  Future<List<LocaleName>> getLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speechToText.locales();
  }
}

// Global instance
final speechService = SpeechService();

/// A widget that provides voice input functionality
class VoiceInputButton extends StatefulWidget {
  final Function(String text) onResult;
  final String locale;
  final Color? activeColor;
  final Color? inactiveColor;
  final double size;

  const VoiceInputButton({
    super.key,
    required this.onResult,
    this.locale = 'pt_BR',
    this.activeColor,
    this.inactiveColor,
    this.size = 48,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  String _partialText = '';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    speechService.initialize();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (_isListening) {
      speechService.stopListening();
    }
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    if (!speechService.isAvailable) {
      final initialized = await speechService.initialize();
      if (!initialized) {
        if (mounted) {
          final errorMsg = speechService.lastError ?? 'Reconhecimento de voz não disponível';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Tentar',
                textColor: Colors.white,
                onPressed: () => _startListening(),
              ),
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isListening = true;
      _partialText = '';
    });
    
    _pulseController.repeat(reverse: true);

    await speechService.startListening(
      onResult: (text) {
        widget.onResult(text);
        _stopListening();
      },
      onPartialResult: (text) {
        setState(() => _partialText = text);
      },
      onDone: () {
        _stopListening();
      },
      localeId: widget.locale,
    );
  }

  Future<void> _stopListening() async {
    await speechService.stopListening();
    _pulseController.stop();
    _pulseController.reset();
    
    if (mounted) {
      setState(() {
        _isListening = false;
        _partialText = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? Theme.of(context).colorScheme.primary;
    final inactiveColor = widget.inactiveColor ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isListening ? _pulseAnimation.value : 1.0,
              child: GestureDetector(
                onTap: _toggleListening,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: _isListening
                        ? activeColor.withValues(alpha: 0.2)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isListening ? activeColor : inactiveColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: activeColor.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? activeColor : inactiveColor,
                    size: widget.size * 0.5,
                  ),
                ),
              ),
            );
          },
        ),
        if (_isListening && _partialText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _partialText,
              style: TextStyle(
                fontSize: 12,
                color: activeColor,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

/// Elegant inline microphone button for text fields
/// Place this as a suffixIcon in InputDecoration for a clean look
class InlineMicButton extends StatefulWidget {
  final Function(String text) onResult;
  final String locale;
  final Color? activeColor;
  final Color? inactiveColor;

  const InlineMicButton({
    super.key,
    required this.onResult,
    this.locale = 'pt_BR',
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<InlineMicButton> createState() => _InlineMicButtonState();
}

class _InlineMicButtonState extends State<InlineMicButton>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    speechService.initialize();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (_isListening) {
      speechService.stopListening();
    }
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    if (!speechService.isAvailable) {
      final initialized = await speechService.initialize();
      if (!initialized) {
        if (mounted) {
          final errorMsg = speechService.lastError ?? 'Reconhecimento de voz não disponível';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Tentar',
                textColor: Colors.white,
                onPressed: () => _startListening(),
              ),
            ),
          );
        }
        return;
      }
    }

    setState(() => _isListening = true);
    _pulseController.repeat(reverse: true);

    await speechService.startListening(
      onResult: (text) {
        widget.onResult(text);
        _stopListening();
      },
      onDone: () => _stopListening(),
      localeId: widget.locale,
    );
  }

  Future<void> _stopListening() async {
    await speechService.stopListening();
    _pulseController.stop();
    _pulseController.reset();
    
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? Theme.of(context).colorScheme.primary;
    final inactiveColor = widget.inactiveColor ?? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: _toggleListening,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isListening 
                  ? activeColor.withValues(alpha: 0.15) 
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Transform.scale(
              scale: _isListening ? _pulseAnimation.value : 1.0,
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none_outlined,
                color: _isListening ? activeColor : inactiveColor,
                size: 22,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A text field with integrated voice input
class VoiceTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final int maxLines;
  final String locale;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;
  final bool appendMode; // If true, appends to existing text instead of replacing

  const VoiceTextField({
    super.key,
    required this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.maxLines = 1,
    this.locale = 'pt_BR',
    this.decoration,
    this.keyboardType,
    this.onChanged,
    this.appendMode = true,
  });

  @override
  State<VoiceTextField> createState() => _VoiceTextFieldState();
}

class _VoiceTextFieldState extends State<VoiceTextField> {
  void _handleVoiceResult(String text) {
    if (widget.appendMode && widget.controller.text.isNotEmpty) {
      final currentText = widget.controller.text;
      final newText = currentText.endsWith(' ') 
          ? '$currentText$text' 
          : '$currentText $text';
      widget.controller.text = newText;
    } else {
      widget.controller.text = text;
    }
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: widget.controller.text.length),
    );
    widget.onChanged?.call(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Build the base decoration
    final baseDecoration = widget.decoration ?? InputDecoration(
      hintText: widget.hintText,
      labelText: widget.labelText,
      prefixIcon: widget.prefixIcon != null 
          ? Icon(widget.prefixIcon) 
          : null,
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
    
    // Add the mic button as suffix
    final decorationWithMic = baseDecoration.copyWith(
      suffixIcon: InlineMicButton(
        onResult: _handleVoiceResult,
        locale: widget.locale,
      ),
    );
    
    return TextField(
      controller: widget.controller,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      decoration: decorationWithMic,
    );
  }
}
