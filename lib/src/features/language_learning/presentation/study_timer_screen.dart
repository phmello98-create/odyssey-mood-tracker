import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/language_learning_repository.dart';
import '../domain/language.dart';
import '../domain/study_session.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

class StudyTimerScreen extends ConsumerStatefulWidget {
  final String? preselectedLanguageId;

  const StudyTimerScreen({super.key, this.preselectedLanguageId});

  @override
  ConsumerState<StudyTimerScreen> createState() => _StudyTimerScreenState();
}

class _StudyTimerScreenState extends ConsumerState<StudyTimerScreen> with TickerProviderStateMixin {
  late LanguageLearningRepository _repository;
  bool _isInitialized = false;

  // Timer state
  String? _selectedLanguageId;
  String _selectedActivity = StudyActivityTypes.reading;
  int _targetMinutes = 25;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  Timer? _timer;
  
  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initRepository();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initRepository() async {
    _repository = ref.read(languageLearningRepositoryProvider);
    await _repository.init();
    if (mounted) {
      setState(() {
        _isInitialized = true;
        _selectedLanguageId = widget.preselectedLanguageId ??
            _repository.getAllLanguages().firstOrNull?.id;
      });
    }
  }

  void _startTimer() {
    if (_selectedLanguageId == null) return;
    
    HapticFeedback.mediumImpact();
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    _pulseController.repeat(reverse: true);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
      
      // Check if target reached
      if (_elapsedSeconds >= _targetMinutes * 60) {
        _completeSession();
      }
    });
  }

  void _pauseTimer() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    _pulseController.stop();
    setState(() {
      _isPaused = true;
      _isRunning = false;
    });
  }

  void _resumeTimer() {
    HapticFeedback.lightImpact();
    _startTimer();
  }

  void _resetTimer() {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _elapsedSeconds = 0;
      _isRunning = false;
      _isPaused = false;
    });
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    _pulseController.stop();
    
    final minutes = (_elapsedSeconds / 60).ceil();
    
    // Save session
    await _repository.addSession(
      languageId: _selectedLanguageId!,
      durationMinutes: minutes,
      activityType: _selectedActivity,
    );

    HapticFeedback.heavyImpact();
    
    if (mounted) {
      _showCompletionDialog(minutes);
    }
  }

  void _showCompletionDialog(int minutes) {
    final colors = Theme.of(context).colorScheme;
    final language = _repository.getLanguage(_selectedLanguageId!);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(Icons.celebration, size: 40, color: Color(0xFF10B981)),
            ),
            const SizedBox(height: 20),
            Text(
              'Sessão Completa! 🎉',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Você estudou ${language?.name ?? "idioma"} por $minutes minutos!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt, color: Colors.orange, size: 20),
                const SizedBox(width: 4),
                Text(
                  '+${minutes * 2} XP',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetTimer();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Continuar', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _savePartialSession() async {
    if (_elapsedSeconds < 60) return; // At least 1 minute
    
    final minutes = (_elapsedSeconds / 60).floor();
    
    await _repository.addSession(
      languageId: _selectedLanguageId!,
      durationMinutes: minutes,
      activityType: _selectedActivity,
    );

    HapticFeedback.mediumImpact();
    _resetTimer();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sessão de $minutes min salva!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final languages = _repository.getAllLanguages();
    if (languages.isEmpty) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.translate, size: 64, color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(
                  'Adicione um idioma primeiro',
                  style: TextStyle(fontSize: 16, color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.voltar),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final selectedLanguage = _selectedLanguageId != null 
        ? _repository.getLanguage(_selectedLanguageId!) 
        : null;
    final languageColor = selectedLanguage != null 
        ? Color(selectedLanguage.colorValue) 
        : colors.primary;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(colors),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Language selector (only when not running)
                    if (!_isRunning && !_isPaused) ...[
                      _buildLanguageSelector(colors, languages),
                      const SizedBox(height: 24),
                      _buildActivitySelector(colors),
                      const SizedBox(height: 24),
                      _buildDurationSelector(colors, languageColor),
                      const SizedBox(height: 32),
                    ],

                    // Timer display
                    _buildTimerDisplay(colors, languageColor),

                    const SizedBox(height: 32),

                    // Controls
                    _buildControls(colors, languageColor),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_isRunning || _isPaused) {
                _showExitConfirmation();
              } else {
                Navigator.pop(context);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back_ios_new, size: 18, color: colors.onSurface),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Sessão de Estudo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(ColorScheme colors, List<Language> languages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'IDIOMA',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colors.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: languages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final lang = languages[index];
              final isSelected = _selectedLanguageId == lang.id;
              final color = Color(lang.colorValue);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedLanguageId = lang.id);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.2) : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? color : colors.outline.withValues(alpha: 0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(lang.flag, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Text(
                        lang.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? color : colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySelector(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ATIVIDADE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colors.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: StudyActivityTypes.all.map((activity) {
            final isSelected = _selectedActivity == activity['id'];
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedActivity = activity['id']);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary.withValues(alpha: 0.15)
                      : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? colors.primary : colors.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      StudyActivityTypes.getIcon(activity['id']),
                      size: 16,
                      color: isSelected ? colors.primary : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      activity['name'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? colors.primary : colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDurationSelector(ColorScheme colors, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DURAÇÃO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colors.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [15, 25, 45, 60].map((mins) {
            final isSelected = _targetMinutes == mins;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _targetMinutes = mins);
              },
              child: Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor.withValues(alpha: 0.2) : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? accentColor : colors.outline.withValues(alpha: 0.1),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$mins',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? accentColor : colors.onSurface,
                      ),
                    ),
                    Text(
                      'min',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimerDisplay(ColorScheme colors, Color accentColor) {
    final progress = _targetMinutes > 0 ? _elapsedSeconds / (_targetMinutes * 60) : 0.0;
    final remainingSeconds = (_targetMinutes * 60) - _elapsedSeconds;
    final displayMinutes = (remainingSeconds ~/ 60).clamp(0, 999);
    final displaySeconds = (remainingSeconds % 60).clamp(0, 59);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isRunning ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accentColor.withValues(alpha: 0.15),
                  colors.surface,
                ],
              ),
              boxShadow: _isRunning ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ] : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress ring
                SizedBox(
                  width: 240,
                  height: 240,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 12,
                    backgroundColor: colors.outline.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(accentColor),
                  ),
                ),
                // Time display
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${displayMinutes.toString().padLeft(2, '0')}:${displaySeconds.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w200,
                        color: colors.onSurface,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isRunning ? 'Estudando...' : (_isPaused ? 'Pausado' : 'Pronto'),
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls(ColorScheme colors, Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_isRunning || _isPaused) ...[
          // Reset button
          GestureDetector(
            onTap: _resetTimer,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.refresh, size: 24, color: colors.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 24),
        ],

        // Main button
        GestureDetector(
          onTap: () {
            if (_isRunning) {
              _pauseTimer();
            } else if (_isPaused) {
              _resumeTimer();
            } else {
              _startTimer();
            }
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _isRunning ? Colors.orange : accentColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isRunning ? Colors.orange : accentColor).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              _isRunning ? Icons.pause : Icons.play_arrow,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),

        if (_isRunning || _isPaused) ...[
          const SizedBox(width: 24),
          // Save button
          GestureDetector(
            onTap: _elapsedSeconds >= 60 ? _savePartialSession : null,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _elapsedSeconds >= 60 
                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                    : colors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                size: 24,
                color: _elapsedSeconds >= 60 
                    ? const Color(0xFF10B981)
                    : colors.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showExitConfirmation() {
    final colors = Theme.of(context).colorScheme;
    final elapsedMinutes = _elapsedSeconds ~/ 60;
    final elapsedSecondsRemainder = _elapsedSeconds % 60;
    
    // Buscar a cor do idioma selecionado
    Color languageColor = colors.primary;
    if (_selectedLanguageId != null) {
      final languages = _repository.getAllLanguages();
      final selectedLang = languages.where((l) => l.id == _selectedLanguageId).firstOrNull;
      if (selectedLang != null) {
        languageColor = Color(selectedLang.colorValue);
      }
    }
    
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.surface,
                colors.surface.withValues(alpha: 0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
              BoxShadow(
                color: languageColor.withValues(alpha: 0.1),
                blurRadius: 40,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated icon container
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.amber.withValues(alpha: 0.2),
                        Colors.orange.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.2),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.pause_rounded, 
                    size: 36, 
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'Pausar sessão?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Time badge
                if (_elapsedSeconds > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: languageColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: languageColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: languageColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.timer_rounded, 
                            size: 16, 
                            color: languageColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${elapsedMinutes.toString().padLeft(2, '0')}:${elapsedSecondsRemainder.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: languageColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'estudados',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                
                Text(
                  _elapsedSeconds >= 60 
                      ? 'Seu progresso pode ser salvo!'
                      : 'Estude mais ${60 - _elapsedSeconds}s para salvar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                
                // Continue button - Primary
                _buildPopupButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  icon: Icons.play_arrow_rounded,
                  label: 'Continuar Estudando',
                  backgroundColor: languageColor,
                  foregroundColor: Colors.white,
                  isElevated: true,
                ),
                
                const SizedBox(height: 12),
                
                // Save button - Only if >= 1 minute
                if (_elapsedSeconds >= 60) ...[
                  _buildPopupButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                      _savePartialSession();
                      Navigator.pop(context);
                    },
                    icon: Icons.check_circle_rounded,
                    label: 'Salvar ${elapsedMinutes}min e Sair',
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    isElevated: false,
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Discard button - Danger
                _buildPopupButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  icon: Icons.close_rounded,
                  label: 'Descartar',
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.red.shade400,
                  isElevated: false,
                  isOutlined: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPopupButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    bool isElevated = false,
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: isOutlined ? Colors.transparent : backgroundColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: isOutlined 
                  ? Border.all(color: foregroundColor.withValues(alpha: 0.5), width: 1.5)
                  : null,
              boxShadow: isElevated ? [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ] : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: foregroundColor),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: foregroundColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
