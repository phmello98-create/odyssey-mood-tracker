import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/features/activities/model/activity.dart';
import 'package:odyssey/src/features/activities/data/activity_categories.dart';
import 'package:odyssey/src/features/mood_records/domain/add_mood_record/mood_option.dart';
import 'package:odyssey/src/features/mood_records/data/mood_log/synced_mood_repository.dart';
import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:odyssey/gen/assets.gen.dart';
import 'package:odyssey/src/utils/icon_map.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:odyssey/src/features/onboarding/presentation/onboarding_providers.dart';

class AddMoodRecordFormControllerNotifier extends AutoDisposeFamilyNotifier<MoodRecord, MapEntry<dynamic, MoodRecord>?> {
  late final MapEntry<dynamic, MoodRecord>? toEdit;

  @override
  build(MapEntry<dynamic, MoodRecord>? arg) {
    if (arg == null) {
      return MoodRecord(
        label: "Alright",
        score: 3,
        iconPath: Assets.moodIcons.neutral,
        color: Colors.blue.value,
        date: DateTime.now(),
      );
    } else {
      toEdit = arg;
      return arg.value;
    }
  }

  void saveOrUpdate(dynamic key, MoodRecord value) {
    final moodRecordRepository = ref.read(syncedMoodRepositoryProvider);
    if (key == null) {
      moodRecordRepository.createMoodRecord(value);
      // Track first mood registration for onboarding
      ref.read(interactiveOnboardingProvider.notifier).completeFirstStep('register_mood');
    } else {
      moodRecordRepository.updateMoodRecord(key, value);
    }
  }

  void updateTime(BuildContext context) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: state.date.hour,
        minute: state.date.minute,
      ),
    );

    if (selectedTime != null) {
      state = state.copyWith(
        date: state.date.copyWith(
          hour: selectedTime.hour,
          minute: selectedTime.minute,
        ),
      );
    }
  }

  void updateDate(BuildContext context) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: state.date,
      firstDate: DateTime.fromMillisecondsSinceEpoch(1),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      state = state.copyWith(
        date: state.date.copyWith(
          day: selectedDate.day,
          month: selectedDate.month,
          year: selectedDate.year,
        ),
      );
    }
  }

  void updateMoodConfiguration(MoodConfiguration configuration) {
    state = state.copyWith(
      label: configuration.label,
      color: configuration.color.value,
      iconPath: configuration.iconPath,
      score: configuration.score,
    );
  }

  void updateNote(String note) {
    if (note.isEmpty && state.note != note) {
      state = state.copyWith(note: null);
    }
    state = state.copyWith(note: note);
  }

  void openActivitySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: UltravioletColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ActivitySelectorSheet(
        selectedActivities: state.activities,
        onSave: (activities) {
          updateActivities(activities);
        },
      ),
    );
  }

  void updateActivities(List<Activity> activities) {
    state = state.copyWith(activities: activities);
  }
}

final addMoodRecordFormControllerNotifierProvider = NotifierProvider.autoDispose
    .family<AddMoodRecordFormControllerNotifier, MoodRecord, MapEntry<dynamic, MoodRecord>?>(AddMoodRecordFormControllerNotifier.new);

class _ActivitySelectorSheet extends StatefulWidget {
  final List<Activity> selectedActivities;
  final Function(List<Activity>) onSave;

  const _ActivitySelectorSheet({
    required this.selectedActivities,
    required this.onSave,
  });

  @override
  State<_ActivitySelectorSheet> createState() => _ActivitySelectorSheetState();
}

class _ActivitySelectorSheetState extends State<_ActivitySelectorSheet> {
  late List<Activity> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedActivities);
  }

  void _toggle(Activity activity) {
    setState(() {
      if (_selected.any((a) => a.activityName == activity.activityName)) {
        _selected.removeWhere((a) => a.activityName == activity.activityName);
      } else {
        _selected.add(activity);
      }
    });
  }

  bool _isSelected(Activity activity) {
    return _selected.any((a) => a.activityName == activity.activityName);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: UltravioletColors.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'O que você fez?',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_selected.length} selecionadas',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: UltravioletColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.onSave(_selected);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(AppLocalizations.of(context)!.save),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: kActivityCategories.length,
                itemBuilder: (context, categoryIndex) {
                  final category = kActivityCategories[categoryIndex];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          getLocalizedCategoryName(context, category.categoryName),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: UltravioletColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: category.activityList.map((activity) {
                          final selected = _isSelected(activity);
                          return GestureDetector(
                            onTap: () => _toggle(activity),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected
                                    ? UltravioletColors.primary.withValues(alpha: 0.15)
                                    : UltravioletColors.surfaceVariant.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? UltravioletColors.primary
                                      : UltravioletColors.outline.withValues(alpha: 0.2),
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    OdysseyIcons.fromCodePoint(activity.iconCode),
                                    size: 18,
                                    color: selected
                                        ? UltravioletColors.primary
                                        : UltravioletColors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    getLocalizedActivityName(context, activity.activityName),
                                    style: TextStyle(
                                      color: selected
                                          ? UltravioletColors.primary
                                          : UltravioletColors.onSurfaceVariant,
                                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
