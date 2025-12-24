import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/water_tracker/domain/water_record.dart';
import 'package:odyssey/src/features/water_tracker/data/water_tracker_repository.dart';

/// Provider do repositório
final waterTrackerRepositoryProvider = Provider<WaterTrackerRepository>((ref) {
  final repo = WaterTrackerRepository();
  ref.onDispose(() => repo.close());
  return repo;
});

/// Estado do water tracker
class WaterTrackerState {
  final WaterRecord? record;
  final bool isLoading;
  final String? error;

  const WaterTrackerState({this.record, this.isLoading = false, this.error});

  WaterTrackerState copyWith({
    WaterRecord? record,
    bool? isLoading,
    String? error,
  }) {
    return WaterTrackerState(
      record: record ?? this.record,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier para gerenciar estado do water tracker
class WaterTrackerNotifier extends StateNotifier<WaterTrackerState> {
  final WaterTrackerRepository _repository;

  WaterTrackerNotifier(this._repository)
    : super(const WaterTrackerState(isLoading: true)) {
    _loadToday();
  }

  Future<void> _loadToday() async {
    try {
      await _repository.init();
      final record = await _repository.getTodayRecord();
      state = WaterTrackerState(record: record);
    } catch (e) {
      state = WaterTrackerState(error: e.toString());
    }
  }

  /// Adiciona um copo de água
  Future<void> addGlass() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);
    try {
      final record = await _repository.addGlass();
      state = WaterTrackerState(record: record);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Remove um copo de água
  Future<void> removeGlass() async {
    if (state.isLoading || (state.record?.glassesCount ?? 0) <= 0) return;

    state = state.copyWith(isLoading: true);
    try {
      final record = await _repository.removeGlass();
      state = WaterTrackerState(record: record);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Atualiza a meta
  Future<void> updateGoal(int glasses) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);
    try {
      final record = await _repository.updateGoal(glasses);
      state = WaterTrackerState(record: record);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Atualiza tamanho do copo
  Future<void> updateGlassSize(int sizeMl) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);
    try {
      final record = await _repository.updateGlassSize(sizeMl);
      state = WaterTrackerState(record: record);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Reseta o dia
  Future<void> resetToday() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);
    try {
      final record = await _repository.resetToday();
      state = WaterTrackerState(record: record);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Recarrega dados
  Future<void> refresh() async {
    await _loadToday();
  }
}

/// Provider principal do water tracker
final waterTrackerProvider =
    StateNotifierProvider<WaterTrackerNotifier, WaterTrackerState>((ref) {
      final repository = ref.watch(waterTrackerRepositoryProvider);
      return WaterTrackerNotifier(repository);
    });

/// Provider para estatísticas semanais
final waterWeekStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) async {
    final repository = ref.watch(waterTrackerRepositoryProvider);
    await repository.init();
    return repository.getWeekStats();
  },
);
