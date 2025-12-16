// lib/src/features/diary/services/diary_export_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../domain/entities/diary_entry_entity.dart';
import '../data/synced_diary_repository.dart';

/// Formato de exportação
enum DiaryExportFormat {
  json,
  markdown,
  txt,
}

/// Resultado da exportação
class ExportResult {
  final bool success;
  final String? filePath;
  final String? error;
  final int entriesCount;

  const ExportResult({
    required this.success,
    this.filePath,
    this.error,
    this.entriesCount = 0,
  });
}

/// Serviço de exportação do diário
class DiaryExportService {
  final SyncedDiaryRepository _repository;

  DiaryExportService(this._repository);

  /// Exporta entradas como JSON
  Future<ExportResult> exportAsJson({
    List<String>? entryIds,
    bool share = true,
  }) async {
    try {
      final entries = await _getEntriesToExport(entryIds);
      if (entries.isEmpty) {
        return const ExportResult(
          success: false,
          error: 'Nenhuma entrada para exportar',
        );
      }

      final data = {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
        'appVersion': '1.0.0',
        'entriesCount': entries.length,
        'entries': entries.map(_entryToJson).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final filePath = await _saveToFile(jsonString, 'diary_export', 'json');

      if (share && filePath != null) {
        await _shareFile(filePath, 'Exportar Diário');
      }

      return ExportResult(
        success: true,
        filePath: filePath,
        entriesCount: entries.length,
      );
    } catch (e) {
      debugPrint('[DiaryExportService] Error exporting JSON: $e');
      return ExportResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Exporta entradas como Markdown
  Future<ExportResult> exportAsMarkdown({
    List<String>? entryIds,
    bool share = true,
  }) async {
    try {
      final entries = await _getEntriesToExport(entryIds);
      if (entries.isEmpty) {
        return const ExportResult(
          success: false,
          error: 'Nenhuma entrada para exportar',
        );
      }

      final buffer = StringBuffer();
      buffer.writeln('# Meu Diário');
      buffer.writeln();
      buffer.writeln('Exportado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
      buffer.writeln('Total de entradas: ${entries.length}');
      buffer.writeln();
      buffer.writeln('---');
      buffer.writeln();

      for (final entry in entries) {
        buffer.writeln(_entryToMarkdown(entry));
        buffer.writeln('---');
        buffer.writeln();
      }

      final content = buffer.toString();
      final filePath = await _saveToFile(content, 'diary_export', 'md');

      if (share && filePath != null) {
        await _shareFile(filePath, 'Exportar Diário');
      }

      return ExportResult(
        success: true,
        filePath: filePath,
        entriesCount: entries.length,
      );
    } catch (e) {
      debugPrint('[DiaryExportService] Error exporting Markdown: $e');
      return ExportResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Exporta entradas como texto simples
  Future<ExportResult> exportAsTxt({
    List<String>? entryIds,
    bool share = true,
  }) async {
    try {
      final entries = await _getEntriesToExport(entryIds);
      if (entries.isEmpty) {
        return const ExportResult(
          success: false,
          error: 'Nenhuma entrada para exportar',
        );
      }

      final buffer = StringBuffer();
      buffer.writeln('MEU DIÁRIO');
      buffer.writeln('=' * 50);
      buffer.writeln();
      buffer.writeln('Exportado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
      buffer.writeln('Total de entradas: ${entries.length}');
      buffer.writeln();
      buffer.writeln('=' * 50);
      buffer.writeln();

      for (final entry in entries) {
        buffer.writeln(_entryToTxt(entry));
        buffer.writeln('-' * 50);
        buffer.writeln();
      }

      final content = buffer.toString();
      final filePath = await _saveToFile(content, 'diary_export', 'txt');

      if (share && filePath != null) {
        await _shareFile(filePath, 'Exportar Diário');
      }

      return ExportResult(
        success: true,
        filePath: filePath,
        entriesCount: entries.length,
      );
    } catch (e) {
      debugPrint('[DiaryExportService] Error exporting TXT: $e');
      return ExportResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Compartilha uma entrada específica
  Future<void> shareEntry(DiaryEntryEntity entry) async {
    final text = _entryToShareText(entry);
    await Share.share(text, subject: entry.title ?? 'Entrada do Diário');
  }

  /// Obtém entradas para exportar
  Future<List<DiaryEntryEntity>> _getEntriesToExport(List<String>? entryIds) async {
    final allEntries = await _repository.getAllEntries();

    if (entryIds != null && entryIds.isNotEmpty) {
      return allEntries.where((e) => entryIds.contains(e.id)).toList();
    }

    return allEntries;
  }

  /// Converte entrada para JSON
  Map<String, dynamic> _entryToJson(DiaryEntryEntity entry) {
    return {
      'id': entry.id,
      'createdAt': entry.createdAt.toIso8601String(),
      'updatedAt': entry.updatedAt.toIso8601String(),
      'entryDate': entry.entryDate.toIso8601String(),
      'title': entry.title,
      'content': entry.content,
      'searchableText': entry.searchableText,
      'feeling': entry.feeling,
      'tags': entry.tags,
      'starred': entry.starred,
      'photoIds': entry.photoIds,
      'wordCount': entry.effectiveWordCount,
    };
  }

  /// Converte entrada para Markdown
  String _entryToMarkdown(DiaryEntryEntity entry) {
    final buffer = StringBuffer();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(entry.entryDate);

    if (entry.title != null && entry.title!.isNotEmpty) {
      buffer.writeln('## $dateStr - ${entry.title}');
    } else {
      buffer.writeln('## $dateStr');
    }
    buffer.writeln();

    if (entry.feeling != null) {
      buffer.writeln('**Sentimento:** ${entry.feeling}');
      buffer.writeln();
    }

    if (entry.tags.isNotEmpty) {
      buffer.writeln('**Tags:** ${entry.tags.map((t) => '#$t').join(' ')}');
      buffer.writeln();
    }

    if (entry.starred) {
      buffer.writeln('⭐ *Favorito*');
      buffer.writeln();
    }

    buffer.writeln('### Conteúdo');
    buffer.writeln();
    buffer.writeln(entry.searchableText ?? '*Sem conteúdo*');
    buffer.writeln();

    buffer.writeln('*${entry.effectiveWordCount} palavras*');

    return buffer.toString();
  }

  /// Converte entrada para texto simples
  String _entryToTxt(DiaryEntryEntity entry) {
    final buffer = StringBuffer();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(entry.entryDate);

    buffer.writeln('Data: $dateStr');

    if (entry.title != null && entry.title!.isNotEmpty) {
      buffer.writeln('Título: ${entry.title}');
    }

    if (entry.feeling != null) {
      buffer.writeln('Sentimento: ${entry.feeling}');
    }

    if (entry.tags.isNotEmpty) {
      buffer.writeln('Tags: ${entry.tags.join(', ')}');
    }

    if (entry.starred) {
      buffer.writeln('Favorito: Sim');
    }

    buffer.writeln();
    buffer.writeln(entry.searchableText ?? 'Sem conteúdo');
    buffer.writeln();
    buffer.writeln('(${entry.effectiveWordCount} palavras)');

    return buffer.toString();
  }

  /// Converte entrada para texto de compartilhamento
  String _entryToShareText(DiaryEntryEntity entry) {
    final buffer = StringBuffer();
    final dateStr = DateFormat('dd/MM/yyyy').format(entry.entryDate);

    if (entry.title != null && entry.title!.isNotEmpty) {
      buffer.writeln('📝 ${entry.title}');
    } else {
      buffer.writeln('📝 Entrada de $dateStr');
    }

    if (entry.feeling != null) {
      buffer.writeln('${entry.feeling}');
    }

    buffer.writeln();
    buffer.writeln(entry.searchableText ?? '');

    if (entry.tags.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(entry.tags.map((t) => '#$t').join(' '));
    }

    return buffer.toString();
  }

  /// Salva conteúdo em arquivo
  Future<String?> _saveToFile(String content, String baseName, String extension) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = '${baseName}_$timestamp.$extension';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(content);
      debugPrint('[DiaryExportService] File saved: ${file.path}');

      return file.path;
    } catch (e) {
      debugPrint('[DiaryExportService] Error saving file: $e');
      return null;
    }
  }

  /// Compartilha arquivo
  Future<void> _shareFile(String filePath, String subject) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject,
      );
    } catch (e) {
      debugPrint('[DiaryExportService] Error sharing file: $e');
    }
  }
}

/// Provider para o DiaryExportService
final diaryExportServiceProvider = Provider<DiaryExportService>((ref) {
  final repository = ref.watch(syncedDiaryRepositoryProvider);
  return DiaryExportService(repository);
});
