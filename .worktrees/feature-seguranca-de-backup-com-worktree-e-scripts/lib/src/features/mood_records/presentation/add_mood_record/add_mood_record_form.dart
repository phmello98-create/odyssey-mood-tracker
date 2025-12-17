import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:odyssey/src/features/mood_records/data/add_mood_record/mood_configurations.dart';
import 'package:odyssey/src/features/activities/presentation/activity_chips.dart';
import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:odyssey/src/features/mood_records/presentation/add_mood_record/add_mood_record_form_controller.dart';
import 'package:odyssey/src/features/mood_records/presentation/add_mood_record/mood_option.dart';
import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';
import 'package:odyssey/src/features/gamification/data/synced_gamification_repository.dart';
import 'package:odyssey/src/utils/services/sound_service.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

class AddMoodRecordForm extends ConsumerStatefulWidget {
  const AddMoodRecordForm({super.key, this.recordToEdit});

  final MapEntry<dynamic, MoodRecord>? recordToEdit;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _AddMoodRecordFormState();
  }
}

class _AddMoodRecordFormState extends ConsumerState<AddMoodRecordForm> {
  late final TextEditingController _noteController;
  final FocusNode _noteFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _noteFieldKey = GlobalKey();
  bool _isNoteFocused = false;
  int _previousTextLength = 0;
  bool _isUserScrolling = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.recordToEdit?.value.note);
    _previousTextLength = _noteController.text.length;
    _noteFocusNode.addListener(_onNoteFocusChange);
    _noteController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final currentLength = _noteController.text.length;
    
    if (currentLength > _previousTextLength) {
      // Texto adicionado - som de digitação
      soundService.playSndType();
    } else if (currentLength < _previousTextLength) {
      // Texto deletado - som de delete
      soundService.playSndType();
      HapticFeedback.selectionClick();
    }
    
    _previousTextLength = currentLength;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      // Detecta se o usuário começou a arrastar (drag)
      if (notification.dragDetails != null) {
        _isUserScrolling = true;
      }
    } else if (notification is ScrollEndNotification) {
      // Quando termina o scroll iniciado pelo usuário, fecha o teclado
      if (_isUserScrolling && _noteFocusNode.hasFocus) {
        FocusScope.of(context).unfocus();
      }
      _isUserScrolling = false;
    }
    return false;
  }

  void _onNoteFocusChange() {
    setState(() => _isNoteFocused = _noteFocusNode.hasFocus);
    
    if (_noteFocusNode.hasFocus) {
      // Aguardar animação do teclado + layout rebuild
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted || !_noteFocusNode.hasFocus) return;
        
        final context = _noteFieldKey.currentContext;
        if (context != null && _scrollController.hasClients) {
          // Scroll até o campo de nota ficar visível
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: 0.3, // Posiciona um pouco acima do centro
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _noteController.removeListener(_onTextChanged);
    _noteController.dispose();
    _noteFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(AddMoodRecordFormControllerNotifier controller, MoodRecord record) async {
    try {
      controller.saveOrUpdate(widget.recordToEdit?.key, record);
      HapticFeedback.mediumImpact();
      soundService.playSuccess();
      
      final isEditing = widget.recordToEdit != null;
      
      if (!isEditing) {
        try {
          final gamificationRepo = ref.read(syncedGamificationRepositoryProvider);
          final result = await gamificationRepo.recordMood();

          if (mounted) {
            final l10n = AppLocalizations.of(context)!;
            Navigator.of(context).pop();
            FeedbackService.showSuccessWithXP(
              context,
              l10n.keepItUp,
              10,
              title: '🎉 ${l10n.moodRegistered}',
            );

            if (result.newBadges.isNotEmpty) {
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) {
                  FeedbackService.showAchievement(
                    context,
                    '${result.newBadges.first.icon} ${result.newBadges.first.name}',
                    result.newBadges.first.description,
                  );
                }
              });
            }
          }
        } catch (e) {
          if (mounted) {
            final l10n = AppLocalizations.of(context)!;
            Navigator.of(context).pop();
            FeedbackService.showSuccess(context, '🎉 ${l10n.moodRegistered}!');
          }
        }
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context)!;
          Navigator.of(context).pop();
          FeedbackService.showSuccess(
            context, 
            l10n.moodUpdated,
            icon: Icons.edit_note,
          );
        }
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      final l10n = AppLocalizations.of(context)!;
      FeedbackService.showError(context, l10n.errorSaving(e.toString()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
    final colors = Theme.of(context).colorScheme;

    final tempMoodRecord = ref.watch(addMoodRecordFormControllerNotifierProvider(widget.recordToEdit));
    final controller = ref.read(addMoodRecordFormControllerNotifierProvider(widget.recordToEdit).notifier);
    
    final selectedMood = kMoodConfigurations.firstWhere(
      (config) => config.score == tempMoodRecord.score,
      orElse: () => kMoodConfigurations[2],
    );
    
    return GestureDetector(
      onTap: () {
        // Só fecha o teclado se o campo de nota não estiver focado
        // ou se o toque for fora de qualquer campo de texto
        if (_noteFocusNode.hasFocus) {
          FocusScope.of(context).unfocus();
        }
      },
      behavior: HitTestBehavior.translucent,
      child: AnimatedPadding(
        padding: EdgeInsets.only(bottom: keyboardSpace),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: selectedMood.color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.recordToEdit != null 
                            ? "Editar Registro" 
                            : "Como você está?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)!.chooseYourMood,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: colors.onSurfaceVariant),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Date & Time
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDateTimeChip(
                      icon: Icons.calendar_today_rounded,
                      label: DateFormat('dd MMM, yyyy', 'pt_BR').format(tempMoodRecord.date),
                      onTap: () => controller.updateDate(context),
                      colors: colors,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: colors.outlineVariant,
                  ),
                  Expanded(
                    child: _buildDateTimeChip(
                      icon: Icons.access_time_rounded,
                      label: DateFormat('HH:mm').format(tempMoodRecord.date),
                      onTap: () => controller.updateTime(context),
                      colors: colors,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Mood Selector
            _buildMoodSelector(tempMoodRecord, controller, selectedMood, colors),
            
            const SizedBox(height: 24),
            
            // Atividades
            _buildActivitiesSection(tempMoodRecord, controller, colors),
            
            const SizedBox(height: 20),
            
            // Campo de nota
            _buildNoteSection(controller, selectedMood, colors),
            
            const SizedBox(height: 28),
            
            // Botão de salvar
            _buildSaveButton(controller, tempMoodRecord, selectedMood, colors),
          ],
        ),
      ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colors,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: colors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSelector(MoodRecord tempMoodRecord, AddMoodRecordFormControllerNotifier controller, dynamic selectedMood, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            selectedMood.color.withValues(alpha: 0.08),
            colors.surfaceContainerHighest.withValues(alpha: 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selectedMood.color.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header com texto e emoji grande do humor selecionado
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.selectYourMood,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedMood.label,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: selectedMood.color,
                      ),
                    ),
                  ],
                ),
              ),
              // Emoji gigante animado
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selectedMood.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selectedMood.color.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: MoodOption(
                    moodConfiguration: selectedMood,
                    isSelected: true,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Grid de opções de humor (5 moods)
          Row(
            children: kMoodConfigurations.map((config) {
              final isSelected = tempMoodRecord.score == config.score;
              
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      soundService.playMoodSelect();
                      controller.updateMoodConfiguration(config);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? config.color : colors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected 
                              ? config.color 
                              : colors.outline.withValues(alpha: 0.15),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: config.color.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ] : [],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Ícone animado
                          MoodOption(
                            moodConfiguration: config,
                            isSelected: isSelected,
                          ),
                          const SizedBox(height: 4),
                          // Label
                          Text(
                            config.label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? Colors.white : colors.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Descrição contextual baseada no humor
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: selectedMood.color,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getMoodDescription(selectedMood.score),
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMoodDescription(int score) {
    final l10n = AppLocalizations.of(context)!;
    switch (score) {
      case 1:
        return l10n.moodAdviceTerrible;
      case 2:
        return l10n.moodAdviceBad;
      case 3:
        return l10n.moodAdviceOkay;
      case 4:
        return l10n.moodAdviceGood;
      case 5:
        return l10n.moodAdviceGreat;
      default:
        return 'Registre seu humor para acompanhar sua jornada emocional.';
    }
  }

  Widget _buildActivitiesSection(MoodRecord tempMoodRecord, AddMoodRecordFormControllerNotifier controller, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.interests_rounded, size: 18, color: colors.primary),
            const SizedBox(width: 8),
            Text(
              'O que você fez?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            if (tempMoodRecord.activities.isNotEmpty) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${tempMoodRecord.activities.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => controller.openActivitySelector(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  tempMoodRecord.activities.isEmpty ? Icons.add_rounded : Icons.edit_rounded,
                  color: colors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tempMoodRecord.activities.isEmpty
                        ? 'Adicionar atividades'
                        : 'Editar atividades',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant, size: 20),
              ],
            ),
          ),
        ),
        if (tempMoodRecord.activities.isNotEmpty) ...[
          const SizedBox(height: 10),
          ActivityChips(tempMoodRecord.activities),
        ],
      ],
    );
  }

  Widget _buildNoteSection(AddMoodRecordFormControllerNotifier controller, dynamic selectedMood, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit_note_rounded, size: 18, color: colors.tertiary),
            const SizedBox(width: 8),
            Text(
              'Como foi seu dia?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          key: _noteFieldKey,
          controller: _noteController,
          focusNode: _noteFocusNode,
          maxLines: _isNoteFocused ? 5 : 3,
          style: TextStyle(
            fontSize: 14,
            color: colors.onSurface,
            height: 1.5,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.surfaceContainerHighest,
            hintText: 'Escreva sobre seu dia, sentimentos, pensamentos...',
            hintStyle: TextStyle(
              color: colors.onSurfaceVariant.withValues(alpha: 0.6),
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
          onChanged: (value) => controller.updateNote(value),
        ),
      ],
    );
  }

  Widget _buildSaveButton(AddMoodRecordFormControllerNotifier controller, MoodRecord tempMoodRecord, dynamic selectedMood, ColorScheme colors) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => _handleSave(controller, tempMoodRecord),
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedMood.color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              widget.recordToEdit != null ? AppLocalizations.of(context)!.saveChanges : AppLocalizations.of(context)!.recordMood,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.cancel,
            style: TextStyle(
              fontSize: 14,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
