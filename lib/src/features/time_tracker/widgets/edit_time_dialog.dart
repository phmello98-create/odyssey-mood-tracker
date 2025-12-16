import 'package:flutter/material.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:odyssey/src/features/time_tracker/domain/time_tracking_record.dart';

/// Dialog para editar o tempo de uma atividade
/// Funciona mesmo em atividades concluídas
class EditTimeDialog extends StatefulWidget {
  final TimeTrackingRecord record;
  final Function(Duration newDuration) onSave;

  const EditTimeDialog({
    super.key,
    required this.record,
    required this.onSave,
  });

  static Future<Duration?> show({
    required BuildContext context,
    required TimeTrackingRecord record,
    required Function(Duration newDuration) onSave,
  }) async {
    return showDialog<Duration>(
      context: context,
      builder: (ctx) => EditTimeDialog(
        record: record,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditTimeDialog> createState() => _EditTimeDialogState();
}

class _EditTimeDialogState extends State<EditTimeDialog> {
  late int _hours;
  late int _minutes;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _hours = widget.record.duration.inHours;
    _minutes = widget.record.duration.inMinutes.remainder(60);
    _seconds = widget.record.duration.inSeconds.remainder(60);
  }

  Duration get _newDuration => Duration(
        hours: _hours,
        minutes: _minutes,
        seconds: _seconds,
      );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final recordColor = widget.record.colorValue != null
        ? Color(widget.record.colorValue!)
        : colors.primary;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: recordColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    color: recordColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Editar Tempo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      Text(
                        widget.record.activityName,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 28),
            
            // Time Pickers
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hours
                _TimePickerColumn(
                  value: _hours,
                  label: 'Horas',
                  maxValue: 23,
                  onChanged: (v) => setState(() => _hours = v),
                  color: recordColor,
                ),
                
                _TimeSeparator(color: colors.onSurfaceVariant),
                
                // Minutes
                _TimePickerColumn(
                  value: _minutes,
                  label: 'Min',
                  maxValue: 59,
                  onChanged: (v) => setState(() => _minutes = v),
                  color: recordColor,
                ),
                
                _TimeSeparator(color: colors.onSurfaceVariant),
                
                // Seconds
                _TimePickerColumn(
                  value: _seconds,
                  label: 'Seg',
                  maxValue: 59,
                  onChanged: (v) => setState(() => _seconds = v),
                  color: recordColor,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Quick presets
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _QuickPresetChip(
                  label: '15min',
                  onTap: () => _setDuration(const Duration(minutes: 15)),
                  color: recordColor,
                ),
                _QuickPresetChip(
                  label: '25min',
                  onTap: () => _setDuration(const Duration(minutes: 25)),
                  color: recordColor,
                ),
                _QuickPresetChip(
                  label: '45min',
                  onTap: () => _setDuration(const Duration(minutes: 45)),
                  color: recordColor,
                ),
                _QuickPresetChip(
                  label: '1h',
                  onTap: () => _setDuration(const Duration(hours: 1)),
                  color: recordColor,
                ),
                _QuickPresetChip(
                  label: '2h',
                  onTap: () => _setDuration(const Duration(hours: 2)),
                  color: recordColor,
                ),
              ],
            ),
            
            const SizedBox(height: 28),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.cancel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _newDuration.inSeconds > 0
                        ? () {
                            HapticFeedback.mediumImpact();
                            widget.onSave(_newDuration);
                            Navigator.pop(context, _newDuration);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: recordColor,
                      disabledBackgroundColor: colors.surfaceContainerHighest,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(AppLocalizations.of(context)!.save,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _newDuration.inSeconds > 0 
                            ? Colors.white 
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _setDuration(Duration duration) {
    HapticFeedback.lightImpact();
    setState(() {
      _hours = duration.inHours;
      _minutes = duration.inMinutes.remainder(60);
      _seconds = duration.inSeconds.remainder(60);
    });
  }
}

class _TimePickerColumn extends StatelessWidget {
  final int value;
  final String label;
  final int maxValue;
  final ValueChanged<int> onChanged;
  final Color color;

  const _TimePickerColumn({
    required this.value,
    required this.label,
    required this.maxValue,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        // Increment
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(value < maxValue ? value + 1 : 0);
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.keyboard_arrow_up_rounded,
              color: color,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Value
        Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Decrement
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(value > 0 ? value - 1 : maxValue);
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: color,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 6),
        
        // Label
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TimeSeparator extends StatelessWidget {
  final Color color;

  const _TimeSeparator({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          const SizedBox(height: 44),
          Text(
            ':',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickPresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _QuickPresetChip({
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}
