import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Serviço de exportação de dados do usuário
/// Conforme LGPD Art. 18 - Direito à Portabilidade
class DataExportService {
  
  /// Exportar TODOS os dados do usuário em formato JSON legível
  static Future<File> exportAllUserData() async {
    debugPrint('📦 Iniciando exportação de dados...');
    
    final exportData = <String, dynamic>{
      'export_metadata': {
        'date': DateTime.now().toIso8601String(),
        'app': 'Odyssey',
        'app_version': '1.0.0',
        'format': 'JSON',
        'description': 'Exportação completa de dados conforme LGPD Art. 18 - Direito à Portabilidade',
        'platform': Platform.operatingSystem,
      },
      'user_info': await _exportUserInfo(),
      'mood_records': await _exportMoodRecords(),
      'diary_entries': await _exportDiary(),
      'tasks': await _exportTasks(),
      'habits': await _exportHabits(),
      'notes': await _exportNotes(),
      'books': await _exportBooks(),
      'time_tracking': await _exportTimeTracking(),
      'gamification': await _exportGamification(),
      'quotes': await _exportQuotes(),
      'settings': await _exportSettings(),
      'consent_info': await _exportConsentInfo(),
    };
    
    // Converter para JSON formatado (legível)
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
    
    // Salvar em arquivo
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-')
        .split('T')[0];
    final file = File('${directory.path}/odyssey_meus_dados_$timestamp.json');
    
    await file.writeAsString(jsonString);
    
    debugPrint('✅ Dados exportados para: ${file.path}');
    return file;
  }
  
  static Future<Map<String, dynamic>> _exportUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'uid': user?.uid ?? prefs.getString('guest_id') ?? 'local_user',
        'email': user?.email ?? 'Não informado',
        'display_name': user?.displayName ?? prefs.getString('user_name') ?? 'Usuário',
        'is_anonymous': user?.isAnonymous ?? true,
        'created_at': user?.metadata.creationTime?.toIso8601String() ?? 'Desconhecido',
        'last_sign_in': user?.metadata.lastSignInTime?.toIso8601String(),
      };
    } catch (e) {
      debugPrint('Erro ao exportar user info: $e');
      return {'error': e.toString()};
    }
  }
  
  static Future<List<Map<String, dynamic>>> _exportMoodRecords() async {
    try {
      if (!Hive.isBoxOpen('mood_records')) {
        await Hive.openBox('mood_records');
      }
      final box = Hive.box('mood_records');
      
      return box.values.map((record) {
        try {
          return {
            'date': record.date?.toIso8601String() ?? 'Desconhecido',
            'label': record.label ?? '',
            'score': record.score ?? 0,
            'note': record.note ?? '',
            'activities': record.activities?.toString() ?? '[]',
          };
        } catch (e) {
          return {'raw_data': record.toString(), 'parse_error': e.toString()};
        }
      }).toList();
    } catch (e) {
      debugPrint('Erro ao exportar mood_records: $e');
      return [{'error': e.toString()}];
    }
  }
  
  static Future<List<Map<String, dynamic>>> _exportDiary() async {
    try {
      if (!Hive.isBoxOpen('diary_entries')) {
        await Hive.openBox('diary_entries');
      }
      final box = Hive.box('diary_entries');
      
      return box.values.map((entry) {
        try {
          return {
            'id': entry.id ?? '',
            'title': entry.title ?? '',
            'content': entry.content ?? '',
            'entry_date': entry.entryDate?.toIso8601String() ?? '',
            'created_at': entry.createdAt?.toIso8601String() ?? '',
            'tags': entry.tags?.toString() ?? '[]',
            'feeling': entry.feeling ?? '',
            'starred': entry.starred ?? false,
          };
        } catch (e) {
          return {'raw_data': entry.toString(), 'parse_error': e.toString()};
        }
      }).toList();
    } catch (e) {
      debugPrint('Erro ao exportar diary: $e');
      return [{'error': e.toString()}];
    }
  }
  
  static Future<List<Map<String, dynamic>>> _exportTasks() async {
    try {
      if (!Hive.isBoxOpen('tasks')) {
        await Hive.openBox('tasks');
      }
      final box = Hive.box('tasks');
      
      return box.toMap().entries.map((entry) {
        try {
          final task = entry.value;
          if (task is Map) {
            return Map<String, dynamic>.from(task);
          }
          return {
            'key': entry.key.toString(),
            'data': task.toString(),
          };
        } catch (e) {
          return {'key': entry.key.toString(), 'parse_error': e.toString()};
        }
      }).toList();
    } catch (e) {
      debugPrint('Erro ao exportar tasks: $e');
      return [{'error': e.toString()}];
    }
  }
  
  static Future<List<Map<String, dynamic>>> _exportHabits() async {
    try {
      if (!Hive.isBoxOpen('habits')) {
        await Hive.openBox('habits');
      }
      final box = Hive.box('habits');
      
      return box.values.map((habit) {
        try {
          return {
            'id': habit.id ?? '',
            'name': habit.name ?? '',
            'description': habit.description ?? '',
            'frequency': habit.frequency?.toString() ?? '',
            'created_at': habit.createdAt?.toIso8601String() ?? '',
            'completions': habit.completions?.toString() ?? '[]',
          };
        } catch (e) {
          return {'raw_data': habit.toString(), 'parse_error': e.toString()};
        }
      }).toList();
    } catch (e) {
      debugPrint('Erro ao exportar habits: $e');
      return [{'error': e.toString()}];
    }
  }
  
  static Future<List<Map<String, dynamic>>> _exportNotes() async {
    try {
      if (!Hive.isBoxOpen('notes_v2')) {
        await Hive.openBox('notes_v2');
      }
      final box = Hive.box('notes_v2');
      
      return box.toMap().entries.map((entry) {
        try {
          final note = entry.value;
          if (note is Map) {
            return Map<String, dynamic>.from(note);
          }
          return {
            'key': entry.key.toString(),
            'data': note.toString(),
          };
        } catch (e) {
          return {'key': entry.key.toString(), 'parse_error': e.toString()};
        }
      }).toList();
    } catch (e) {
      debugPrint('Erro ao exportar notes: $e');
      return [{'error': e.toString()}];
    }
  }
  
  static Future<List<Map<String, dynamic>>> _exportBooks() async {
    try {
      if (!Hive.isBoxOpen('books_v3')) {
        await Hive.openBox('books_v3');
      }
      final box = Hive.box('books_v3');
      
      return box.values.map((book) {
        try {
          return {
            'title': book.title ?? '',
            'author': book.author ?? '',
            'cover_url': book.coverUrl ?? '',
            'total_pages': book.totalPages ?? 0,
            'current_page': book.currentPage ?? 0,
            'status': book.status?.toString() ?? '',
            'rating': book.rating ?? 0,
            'notes': book.notes ?? '',
            'start_date': book.startDate?.toIso8601String(),
            'finish_date': book.finishDate?.toIso8601String(),
          };
        } catch (e) {
          return {'raw_data': book.toString(), 'parse_error': e.toString()};
        }
      }).toList();
    } catch (e) {
      debugPrint('Erro ao exportar books: $e');
      return [{'error': e.toString()}];
    }
  }
  
  static Future<List<Map<String, dynamic>>> _exportTimeTracking() async {
    try {
      if (!Hive.isBoxOpen('time_tracking_records')) {
        await Hive.openBox('time_tracking_records');
      }
      final box = Hive.box('time_tracking_records');
      
      return box.toMap().entries.map((entry) {
        try {
          final record = entry.value;
          if (record is Map) {
            return Map<String, dynamic>.from(record);
          }
          return {
            'key': entry.key.toString(),
            'data': record.toString(),
          };
        } catch (e) {
          return {'key': entry.key.toString(), 'parse_error': e.toString()};
        }
      }).toList();
    } catch (e) {
      debugPrint('Erro ao exportar time_tracking: $e');
      return [{'error': e.toString()}];
    }
  }
  
  static Future<Map<String, dynamic>> _exportGamification() async {
    try {
      if (!Hive.isBoxOpen('gamification')) {
        await Hive.openBox('gamification');
      }
      final box = Hive.box('gamification');
      
      final result = <String, dynamic>{};
      for (final key in box.keys) {
        result[key.toString()] = box.get(key);
      }
      return result;
    } catch (e) {
      debugPrint('Erro ao exportar gamification: $e');
      return {'error': e.toString()};
    }
  }
  
  static Future<List<Map<String, dynamic>>> _exportQuotes() async {
    try {
      if (!Hive.isBoxOpen('quotes')) {
        await Hive.openBox('quotes');
      }
      final box = Hive.box('quotes');
      
      return box.toMap().entries.map((entry) {
        try {
          final quote = entry.value;
          if (quote is Map) {
            return Map<String, dynamic>.from(quote);
          }
          return {
            'key': entry.key.toString(),
            'data': quote.toString(),
          };
        } catch (e) {
          return {'key': entry.key.toString(), 'parse_error': e.toString()};
        }
      }).toList();
    } catch (e) {
      debugPrint('Erro ao exportar quotes: $e');
      return [{'error': e.toString()}];
    }
  }
  
  static Future<Map<String, dynamic>> _exportSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = <String, dynamic>{};
      
      for (final key in prefs.getKeys()) {
        // Não exportar dados sensíveis de autenticação
        if (key.contains('password') || key.contains('token') || key.contains('secret')) {
          continue;
        }
        result[key] = prefs.get(key);
      }
      
      return result;
    } catch (e) {
      debugPrint('Erro ao exportar settings: $e');
      return {'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> _exportConsentInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'health_data_consent_given': prefs.getBool('health_data_consent_given') ?? false,
        'health_data_consent_date': prefs.getString('health_data_consent_date'),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  /// Compartilhar export via Share sheet
  static Future<void> shareExport(File file) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Meus Dados - Odyssey',
        text: 'Exportação completa dos meus dados do app Odyssey '
              '(conforme LGPD Art. 18 - Direito à Portabilidade)',
      ),
    );
  }
  
  /// Obter tamanho estimado dos dados
  static Future<DataStats> getDataStats() async {
    int totalRecords = 0;
    final stats = <String, int>{};
    
    final boxNames = ['mood_records', 'diary_entries', 'notes_v2', 'tasks', 'habits', 'books_v3', 'quotes'];
    
    for (final boxName in boxNames) {
      try {
        if (!Hive.isBoxOpen(boxName)) {
          await Hive.openBox(boxName);
        }
        final count = Hive.box(boxName).length;
        stats[boxName] = count;
        totalRecords += count;
      } catch (e) {
        stats[boxName] = 0;
      }
    }
    
    return DataStats(totalRecords: totalRecords, perBox: stats);
  }
}

/// Estatísticas de dados do usuário
class DataStats {
  final int totalRecords;
  final Map<String, int> perBox;
  
  DataStats({required this.totalRecords, required this.perBox});
}
