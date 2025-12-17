import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/mood_records/data/mood_log/synced_mood_repository.dart';
import 'package:odyssey/src/features/mood_records/domain/mood_log/mood_record.dart';
import 'package:odyssey/src/features/mood_records/presentation/mood_log/mood_log_screen.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

enum MoodRecordCardMenuOption { delete, edit, addNote, addPhoto }

class MoodRecordCardOptions extends StatelessWidget {
  const MoodRecordCardOptions({
    super.key,
    required this.id,
    required this.recordEntry,
    required this.record,
  });

  final dynamic id;
  final MapEntry<dynamic, MoodRecord> recordEntry;
  final MoodRecord record;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) => PopupMenuButton<MoodRecordCardMenuOption>(
        onSelected: (value) {
          switch (value) {
            case MoodRecordCardMenuOption.delete:
              () {
                final repository = ref.read(syncedMoodRepositoryProvider);
                repository.deleteMoodRecord(id);
              }();
              break;
            case MoodRecordCardMenuOption.edit:
              MoodRecordsScreen.showAddMoodRecordForm(context, recordEntry);
              break;
            default:
          }
        },
        itemBuilder: (context) {
          return [
            PopupMenuItem<MoodRecordCardMenuOption>(
              value: MoodRecordCardMenuOption.edit,
              child: Text(AppLocalizations.of(context)!.edit),
            ),
            PopupMenuItem<MoodRecordCardMenuOption>(
              value: MoodRecordCardMenuOption.addNote,
              child: Text(record.note == null ? AppLocalizations.of(context)!.addNote : AppLocalizations.of(context)!.editNote),
            ),
            PopupMenuItem<MoodRecordCardMenuOption>(
              value: MoodRecordCardMenuOption.addPhoto,
              child: Text(AppLocalizations.of(context)!.addPhoto),
            ),
            PopupMenuItem<MoodRecordCardMenuOption>(
              value: MoodRecordCardMenuOption.delete,
              child: Text(
                AppLocalizations.of(context)!.delete,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ];
        },
      ),
    );
  }
}
