import 'package:flutter/material.dart';
import 'package:odyssey/src/features/tasks/data/task_repository.dart';
import 'package:odyssey/src/localization/app_localizations.dart';

class TaskTags {
  static List<Widget> buildTags(BuildContext context, TaskData task) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    List<Widget> tags = [];
    final l10n = AppLocalizations.of(context)!;
    final isEnglish = l10n.localeName == 'en';
    
    if (task.dueDate != null) {
      final dueDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      final difference = dueDate.difference(today).inDays;
      
      if (!task.completed) {
        if (difference < 0) {
          final daysOverdue = difference.abs();
          tags.add(_buildTag(
            '🔥 ${daysOverdue}d ${isEnglish ? "late" : "atrasada"}',
            Colors.red,
            Colors.red.withValues(alpha: 0.15),
          ));
        } else if (difference == 0) {
          tags.add(_buildTag(
            '📌 ${l10n.today.toUpperCase()}',
            const Color(0xFF8B5CF6),
            const Color(0xFF8B5CF6).withValues(alpha: 0.15),
          ));
        } else if (difference == 1) {
          tags.add(_buildTag(
            '⏰ ${l10n.tomorrow}',
            Colors.blue,
            Colors.blue.withValues(alpha: 0.15),
          ));
        } else if (difference <= 3) {
          tags.add(_buildTag(
            '📅 ${isEnglish ? "In $difference days" : "Em $difference dias"}',
            Colors.orange,
            Colors.orange.withValues(alpha: 0.15),
          ));
        } else if (difference <= 7) {
          tags.add(_buildTag(
            '🗓️ ${l10n.thisWeek}',
            Colors.teal,
            Colors.teal.withValues(alpha: 0.15),
          ));
        }
      } else {
        final completedTime = task.completedAt ?? now;
        final completedDuration = now.difference(completedTime);
        
        if (completedDuration.inHours < 1) {
          tags.add(_buildTag(
            '✨ ${isEnglish ? "Just done" : "Acabou"}',
            const Color(0xFF07E092),
            const Color(0xFF07E092).withValues(alpha: 0.15),
          ));
        } else if (completedDuration.inDays == 0) {
          tags.add(_buildTag(
            '✓ ${l10n.today}',
            const Color(0xFF07E092),
            const Color(0xFF07E092).withValues(alpha: 0.15),
          ));
        }
      }
    }
    
    if (task.priority == 'high' && !task.completed) {
      tags.add(_buildTag(
        '⚡ ${isEnglish ? "URGENT" : "URGENTE"}',
        Colors.red,
        Colors.red.withValues(alpha: 0.15),
      ));
    }
    
    if (task.dueTime != null && !task.completed) {
      tags.add(_buildTag(
        '🕐 ${task.dueTime}',
        Colors.blueGrey,
        Colors.blueGrey.withValues(alpha: 0.15),
      ));
    }
    
    return tags;
  }
  
  static Widget _buildTag(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
