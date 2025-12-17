import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:showcaseview/showcaseview.dart';

/// Enum para identificar cada tela com showcase tour
enum ShowcaseTour {
  home,
  tasks,
  habits,
  notes,
  library,
  timeTracker,
  // Novas telas
  settings,
  calendar,
  moodLog,
  analytics,
  profile,
  news,
  languageLearning,
}

/// Serviço centralizado para gerenciar ShowcaseView tours
/// 
/// Uso correto do showcaseview v5.0.1:
/// 1. Chamar ShowcaseService.init() no main/app_initializer
/// 2. Em cada tela, chamar ShowcaseService.registerForScreen() no initState
/// 3. Envolver widgets com Showcase(key: ..., title: ..., child: ...)
/// 4. Chamar ShowcaseService.startIfNeeded() ou start() para iniciar
/// 5. Chamar ShowcaseService.unregisterScreen() no dispose
class ShowcaseService {
  static const String _boxName = 'showcase_tours';
  static const String _completedKey = 'completed_tours';
  static Box? _box;
  
  /// Inicializa o serviço (chamar no app_initializer após Hive.init)
  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }
  
  /// Verifica se tour foi completado
  static bool isCompleted(ShowcaseTour tour) {
    if (_box == null) return true; // Se não inicializou, não mostra
    final completed = _box!.get(_completedKey, defaultValue: <String>[]) as List;
    return completed.contains(tour.name);
  }
  
  /// Marca tour como completado
  static Future<void> complete(ShowcaseTour tour) async {
    if (_box == null) return;
    final completed = List<String>.from(_box!.get(_completedKey, defaultValue: <String>[]) as List);
    if (!completed.contains(tour.name)) {
      completed.add(tour.name);
      await _box!.put(_completedKey, completed);
    }
  }
  
  /// Reseta um tour específico
  static Future<void> reset(ShowcaseTour tour) async {
    if (_box == null) return;
    final completed = List<String>.from(_box!.get(_completedKey, defaultValue: <String>[]) as List);
    completed.remove(tour.name);
    await _box!.put(_completedKey, completed);
  }
  
  /// Reseta todos os tours
  static Future<void> resetAll() async {
    await _box?.put(_completedKey, <String>[]);
  }
  
  /// Registra ShowcaseView para uma tela específica
  /// Chamar no initState de cada tela que tem showcase
  static void registerForScreen({
    required ShowcaseTour tour,
    List<GlobalKey>? firstAndLastKeys,
    VoidCallback? onFinish,
  }) {
    ShowcaseView.register(
      scope: tour.name,
      blurValue: 1,
      enableAutoScroll: true,
      globalFloatingActionWidget: (ctx) => FloatingActionWidget(
        left: 16,
        bottom: 16,
        child: ElevatedButton.icon(
          onPressed: () => ShowcaseView.getNamed(tour.name).dismiss(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF07E092),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            elevation: 8,
          ),
          icon: const Icon(Icons.skip_next_rounded, size: 20),
          label: const Text('Pular', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ),
      hideFloatingActionWidgetForShowcase: firstAndLastKeys ?? [],
      onFinish: () {
        complete(tour);
        onFinish?.call();
      },
      globalTooltipActionConfig: const TooltipActionConfig(
        position: TooltipActionPosition.inside,
        alignment: MainAxisAlignment.spaceBetween,
        actionGap: 12,
      ),
      globalTooltipActions: [
        TooltipActionButton(
          type: TooltipDefaultActionType.previous,
          name: 'Anterior',
          textStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
          hideActionWidgetForShowcase: firstAndLastKeys?.isNotEmpty == true ? [firstAndLastKeys!.first] : [],
        ),
        TooltipActionButton(
          type: TooltipDefaultActionType.next,
          name: 'Próximo',
          textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          hideActionWidgetForShowcase: firstAndLastKeys?.isNotEmpty == true ? [firstAndLastKeys!.last] : [],
        ),
      ],
    );
  }
  
  /// Inicia tour se ainda não completado
  static void startIfNeeded(ShowcaseTour tour, List<GlobalKey> keys) {
    if (!isCompleted(tour) && keys.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          ShowcaseView.getNamed(tour.name).startShowCase(keys);
        } catch (e) {
          debugPrint('ShowcaseService: Erro ao iniciar tour $tour: $e');
        }
      });
    }
  }
  
  /// Inicia tour forçadamente (ignora se já foi completado)
  static void start(ShowcaseTour tour, List<GlobalKey> keys) {
    if (keys.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          ShowcaseView.getNamed(tour.name).startShowCase(keys);
        } catch (e) {
          debugPrint('ShowcaseService: Erro ao iniciar tour $tour: $e');
        }
      });
    }
  }
  
  /// Desregistra ShowcaseView de uma tela
  /// Chamar no dispose de cada tela
  static void unregisterScreen(ShowcaseTour tour) {
    try {
      ShowcaseView.getNamed(tour.name).unregister();
    } catch (_) {
      // Ignora se não estava registrado
    }
  }
}

/// Botão de ajuda flutuante para iniciar tours manualmente
class ShowcaseHelpFab extends StatelessWidget {
  final VoidCallback onPressed;
  final Color? color;
  
  const ShowcaseHelpFab({super.key, required this.onPressed, this.color});
  
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'showcase_help_fab_${UniqueKey()}',
      onPressed: onPressed,
      backgroundColor: color ?? Theme.of(context).colorScheme.primary,
      elevation: 4,
      child: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 20),
    );
  }
}

/// Mixin para facilitar implementação em StatefulWidgets
/// 
/// Exemplo de uso:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with ShowcaseMixin {
///   final GlobalKey _key1 = GlobalKey();
///   final GlobalKey _key2 = GlobalKey();
///   
///   @override
///   ShowcaseTour get showcaseTour => ShowcaseTour.home;
///   
///   @override
///   List<GlobalKey> get showcaseKeys => [_key1, _key2];
///   
///   @override
///   void initState() {
///     super.initState();
///     initShowcase();
///   }
///   
///   @override
///   void dispose() {
///     disposeShowcase();
///     super.dispose();
///   }
/// }
/// ```
mixin ShowcaseMixin<T extends StatefulWidget> on State<T> {
  ShowcaseTour get showcaseTour;
  List<GlobalKey> get showcaseKeys;
  
  void initShowcase() {
    ShowcaseService.registerForScreen(
      tour: showcaseTour,
      firstAndLastKeys: showcaseKeys.isNotEmpty ? [showcaseKeys.first, showcaseKeys.last] : null,
    );
    ShowcaseService.startIfNeeded(showcaseTour, showcaseKeys);
  }
  
  void startShowcaseTour() {
    ShowcaseService.start(showcaseTour, showcaseKeys);
  }
  
  void disposeShowcase() {
    ShowcaseService.unregisterScreen(showcaseTour);
  }
}
