import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:odyssey/src/constants/app_sizes.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/features/activities/data/activity_repository.dart';
import 'package:odyssey/src/features/activities/model/activity.dart';
import 'package:odyssey/src/features/activities/presentation/activity_group.dart';
import 'package:odyssey/src/utils/widgets/responsive_centered.dart';
import 'package:odyssey/src/utils/widgets/feedback_widgets.dart';

class ActivitySelectorScreen extends ConsumerStatefulWidget {
  const ActivitySelectorScreen({super.key, required this.recordActivities, required this.updateActivitiesCallback});
  // final MoodRecord =
  final Function updateActivitiesCallback;
  final List<Activity> recordActivities;

  @override
  ConsumerState<ActivitySelectorScreen> createState() => _ActivitySelectorScreenState();
}

class _ActivitySelectorScreenState extends ConsumerState<ActivitySelectorScreen> {
  late List<Activity> _selectedActivities;

  void _addOrRemoveActivity(Activity activity) {
    HapticFeedback.selectionClick();
    setState(
      () {
        if (_selectedActivities.contains(activity)) {
          _selectedActivities.remove(activity);
        } else {
          _selectedActivities.add(activity);
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedActivities = List.of(widget.recordActivities);
  }

  @override
  Widget build(BuildContext context) {
    final activityCategoriesValue = ref.watch(activityRepositoryProvider);
    return activityCategoriesValue.when(
      data: (repository) {
        final categories = repository.getCategories();

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              onPressed: () {
                context.pop();
              },
              icon: const Icon(Icons.close),
            ),
            title: Text(
              'Selecionar Atividades',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.updateActivitiesCallback(_selectedActivities);
                    context.pop();
                    
                    if (_selectedActivities.isNotEmpty) {
                      FeedbackService.showSuccess(
                        context, 
                        '${_selectedActivities.length} atividade${_selectedActivities.length > 1 ? 's' : ''} selecionada${_selectedActivities.length > 1 ? 's' : ''}',
                        icon: Icons.check_circle,
                      );
                    }
                  },
                  icon: const Icon(Icons.check, size: 18),
                  label: Text(
                    _selectedActivities.isEmpty 
                        ? 'Pular' 
                        : 'Confirmar (${_selectedActivities.length})',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedActivities.isEmpty 
                        ? UltravioletColors.surfaceVariant 
                        : UltravioletColors.primary,
                    foregroundColor: _selectedActivities.isEmpty 
                        ? UltravioletColors.onSurfaceVariant 
                        : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ResponsiveCenter(
              padding: const EdgeInsets.all(Sizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          UltravioletColors.primary.withValues(alpha: 0.1),
                          UltravioletColors.secondary.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '🎯',
                          style: TextStyle(fontSize: 40),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "O que você esteve fazendo?",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Selecione as atividades relacionadas ao seu humor",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: UltravioletColors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Selected count
                  if (_selectedActivities.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: UltravioletColors.accentGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: UltravioletColors.accentGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: UltravioletColors.accentGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedActivities.length} selecionada${_selectedActivities.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                              color: UltravioletColors.accentGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _selectedActivities.clear();
                              });
                            },
                            child: Text(AppLocalizations.of(context)!.limpar,
                              style: const TextStyle(
                                color: UltravioletColors.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  for (var category in categories)
                    ActivityGroup(
                      activityCategory: category,
                      selectedActivities: _selectedActivities,
                      onSelectedActivity: _addOrRemoveActivity,
                    ),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: UltravioletColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  "Erro ao carregar atividades",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: UltravioletColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
