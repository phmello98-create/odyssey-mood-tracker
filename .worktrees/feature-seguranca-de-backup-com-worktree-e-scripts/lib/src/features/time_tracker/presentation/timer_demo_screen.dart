import 'dart:async';
import 'package:flutter/material.dart';
import 'package:odyssey/src/features/time_tracker/widgets/gamified_timer_widget.dart';
import 'package:odyssey/src/features/time_tracker/widgets/tomato_timer_widget.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

/// Tela de demonstração dos novos Timers
/// Use esta tela para testar os designs antes de integrar
class TimerDemoScreen extends StatefulWidget {
  const TimerDemoScreen({super.key});

  @override
  State<TimerDemoScreen> createState() => _TimerDemoScreenState();
}

class _TimerDemoScreenState extends State<TimerDemoScreen> {
  // Estado do timer
  Duration _timeLeft = const Duration(minutes: 25);
  Duration _totalTime = const Duration(minutes: 25);
  bool _isRunning = false;
  bool _isBreak = false;
  int _completedSessions = 0;
  Timer? _timer;
  
  // Configurações
  final Color _accentColor = const Color(0xFFFF6B6B);
  String _taskName = 'Desenvolvimento App';
  
  // Estilo selecionado (0 = Neumorphic, 1 = Tomato)
  int _selectedStyle = 1;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft.inSeconds > 0) {
        setState(() {
          _timeLeft = _timeLeft - const Duration(seconds: 1);
        });
      } else {
        _completeSession();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _timeLeft = _isBreak 
          ? const Duration(minutes: 5) 
          : const Duration(minutes: 25);
      _totalTime = _timeLeft;
    });
  }

  void _completeSession() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      if (!_isBreak) {
        _completedSessions++;
        _isBreak = true;
        _timeLeft = _completedSessions % 4 == 0 
            ? const Duration(minutes: 15) 
            : const Duration(minutes: 5);
      } else {
        _isBreak = false;
        _timeLeft = const Duration(minutes: 25);
      }
      _totalTime = _timeLeft;
    });
  }

  void _skipSession() {
    _completeSession();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D14) : const Color(0xFFF5F5FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.timerDemo),
        centerTitle: true,
        actions: [
          // Seletor de estilo
          IconButton(
            icon: Icon(
              _selectedStyle == 0 ? Icons.wb_sunny : Icons.eco,
              color: _selectedStyle == 0 
                  ? const Color(0xFFFF6B6B) 
                  : const Color(0xFFE74C3C),
            ),
            onPressed: () {
              setState(() {
                _selectedStyle = _selectedStyle == 0 ? 1 : 0;
              });
            },
            tooltip: _selectedStyle == 0 ? 'Mudar para Tomate' : 'Mudar para Neumorphic',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Style selector chips
              _buildStyleSelector(),
              const SizedBox(height: 24),
              
              // Widget do Timer (animação de troca)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _selectedStyle == 0
                    ? GamifiedTimerWidget(
                        key: const ValueKey('neumorphic'),
                        timeLeft: _timeLeft,
                        totalTime: _totalTime,
                        isRunning: _isRunning,
                        isBreak: _isBreak,
                        completedSessions: _completedSessions,
                        totalSessions: 4,
                        xpToGain: 25,
                        accentColor: _accentColor,
                        taskName: _taskName,
                        onStart: _startTimer,
                        onPause: _pauseTimer,
                        onReset: _resetTimer,
                        onSkip: _skipSession,
                      )
                    : TomatoTimerWidget(
                        key: const ValueKey('tomato'),
                        timeLeft: _timeLeft,
                        totalTime: _totalTime,
                        isRunning: _isRunning,
                        isBreak: _isBreak,
                        completedSessions: _completedSessions,
                        totalSessions: 4,
                        xpToGain: 25,
                        taskName: _taskName,
                        onStart: _startTimer,
                        onPause: _pauseTimer,
                        onReset: _resetTimer,
                        onSkip: _skipSession,
                      ),
              ),
              
              const SizedBox(height: 40),
              
              // Controles de teste
              _buildTestControls(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyleSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStyleChip(
          label: '🎮 Neumorphic',
          isSelected: _selectedStyle == 0,
          onTap: () => setState(() => _selectedStyle = 0),
        ),
        const SizedBox(width: 12),
        _buildStyleChip(
          label: '🍅 Tomate',
          isSelected: _selectedStyle == 1,
          onTap: () => setState(() => _selectedStyle = 1),
        ),
      ],
    );
  }

  Widget _buildStyleChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: label.contains('Tomate')
                      ? [const Color(0xFFE74C3C), const Color(0xFFC0392B)]
                      : [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
                )
              : null,
          color: isSelected ? null : Colors.white10,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (label.contains('Tomate')
                            ? const Color(0xFFE74C3C)
                            : const Color(0xFFFF6B6B))
                        .withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTestControls(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🧪 Controles de Teste',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // Simular sessões completadas
          Row(
            children: [
              Text(
                'Sessões: $_completedSessions',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _completedSessions > 0
                    ? () => setState(() => _completedSessions--)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _completedSessions++),
              ),
            ],
          ),
          
          // Toggle break mode
          SwitchListTile(
            title: Text(
              'Modo Intervalo (Lua)',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            value: _isBreak,
            onChanged: (v) {
              setState(() {
                _isBreak = v;
                _timeLeft = v 
                    ? const Duration(minutes: 5) 
                    : const Duration(minutes: 25);
                _totalTime = _timeLeft;
              });
            },
          ),
          
          // Mudar tarefa
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Tarefa',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            subtitle: Text(
              _taskName,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            trailing: const Icon(Icons.edit),
            onTap: _showTaskPicker,
          ),
        ],
      ),
    );
  }

  void _showTaskPicker() {
    final tasks = [
      'Desenvolvimento App',
      'Estudar Flutter',
      'Leitura',
      'Exercícios',
      'Meditação',
      AppLocalizations.of(context)!.categoryWork,
    ];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(tasks[index]),
            trailing: _taskName == tasks[index]
                ? const Icon(Icons.check, color: Color(0xFF667EEA))
                : null,
            onTap: () {
              setState(() => _taskName = tasks[index]);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
