import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

// --- State Model ---

enum RadioStatus { stopped, playing, paused, buffering, error }

class RadioTrack {
  final String title;
  final String artist;
  final String coverUrl;
  final String streamUrl;
  final Color themeColor;

  const RadioTrack({
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.streamUrl,
    required this.themeColor,
  });
}

class RadioState {
  final RadioStatus status;
  final RadioTrack? currentTrack;
  final int currentIndex;
  final double volume;
  final bool isMuted;

  const RadioState({
    this.status = RadioStatus.stopped,
    this.currentTrack,
    this.currentIndex = 0,
    this.volume = 1.0,
    this.isMuted = false,
  });

  RadioState copyWith({
    RadioStatus? status,
    RadioTrack? currentTrack,
    int? currentIndex,
    double? volume,
    bool? isMuted,
  }) {
    return RadioState(
      status: status ?? this.status,
      currentTrack: currentTrack ?? this.currentTrack,
      currentIndex: currentIndex ?? this.currentIndex,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  bool get isPlaying => status == RadioStatus.playing;
}

// --- Provider ---

class RadioNotifier extends StateNotifier<RadioState> {
  RadioNotifier() : super(const RadioState()) {
    _initPlayer();
  }

  final AudioPlayer _player = AudioPlayer();

  // Real Free Streaming Stations (Royalty-Free)
  // Dica: Esses links podem mudar. Considere carregar de um JSON no Firebase.
  final List<RadioTrack> stations = [
    // Lofi Hip Hop - Hunter.FM Brasil (estável e gratuita)
    const RadioTrack(
      title: 'Lofi Hip Hop',
      artist: 'Hunter.FM',
      coverUrl:
          'https://i.scdn.co/image/ab67616d0000b2735af263b6522c061266b7dd25',
      streamUrl: 'https://live.hunter.fm/lofi_high',
      themeColor: Color(0xFF6C63FF),
    ),
    // Chillout Lounge - 1.FM (europeia, links abertos)
    const RadioTrack(
      title: 'Chillout Lounge',
      artist: '1.FM Network',
      coverUrl:
          'https://i.scdn.co/image/ab67616d0000b273d2a3d02772522744312ce06e',
      streamUrl: 'http://strm112.1.fm/chilloutlounge_mobile_mp3',
      themeColor: Color(0xFF00BFA5),
    ),
    // Deep House / Tech - Costa Del Mar
    const RadioTrack(
      title: 'Deep House',
      artist: 'Costa Del Mar',
      coverUrl:
          'https://i.scdn.co/image/ab67616d0000b273e913337604471017359dae3d',
      streamUrl: 'http://sc-costadelmar.1.fm:10156/;',
      themeColor: Color(0xFFE91E63),
    ),
    // Ambient / Nature - Soma FM (Creative Commons)
    const RadioTrack(
      title: 'Drone Zone',
      artist: 'SomaFM',
      coverUrl:
          'https://i.scdn.co/image/ab67616d0000b2736fc4cc0aaf0c6f4d5f8c9a3d',
      streamUrl: 'https://ice1.somafm.com/dronezone-128-mp3',
      themeColor: Color(0xFF9C27B0),
    ),
    // Electronic Chill - DBM Radio
    const RadioTrack(
      title: 'Electronic Chill',
      artist: 'DBM Radio',
      coverUrl:
          'https://i.scdn.co/image/ab67616d0000b2730f0cfe4a7e9b9b3e6c6d8f9a',
      streamUrl: 'https://chillout.dbm.radio/stream',
      themeColor: Color(0xFF795548),
    ),
  ];

  void _initPlayer() {
    // Listen to player state changes
    _player.playerStateStream.listen((playerState) {
      debugPrint('🎵 Player state: ${playerState.processingState}');

      switch (playerState.processingState) {
        case ProcessingState.idle:
          state = state.copyWith(status: RadioStatus.stopped);
          break;
        case ProcessingState.loading:
        case ProcessingState.buffering:
          state = state.copyWith(status: RadioStatus.buffering);
          break;
        case ProcessingState.ready:
          if (playerState.playing) {
            state = state.copyWith(status: RadioStatus.playing);
          } else {
            state = state.copyWith(status: RadioStatus.paused);
          }
          break;
        case ProcessingState.completed:
          // For streaming, this shouldn't happen often
          state = state.copyWith(status: RadioStatus.stopped);
          break;
      }
    });

    // Listen to errors
    _player.playbackEventStream.listen(
      (event) {},
      onError: (Object e, StackTrace stackTrace) {
        debugPrint('❌ Playback error: $e');
        state = state.copyWith(status: RadioStatus.error);
      },
    );
  }

  Future<void> playStation(int index) async {
    if (index < 0 || index >= stations.length) return;

    final track = stations[index];
    debugPrint('🎵 Playing: ${track.title} - ${track.streamUrl}');

    state = state.copyWith(
      status: RadioStatus.buffering,
      currentTrack: track,
      currentIndex: index,
    );

    try {
      await _player.setUrl(track.streamUrl);
      await _player.setVolume(state.volume);
      await _player.play();
      debugPrint('🎵 Now playing: ${track.title}');
    } catch (e) {
      debugPrint('❌ Error playing station: $e');
      state = state.copyWith(status: RadioStatus.error);
    }
  }

  Future<void> togglePlayPause() async {
    debugPrint('🎵 togglePlayPause called');

    if (state.currentTrack == null) {
      debugPrint('🎵 No current track, starting station 0...');
      await playStation(0);
      return;
    }

    if (state.isPlaying) {
      debugPrint('🎵 Pausing...');
      await _player.pause();
    } else if (state.status == RadioStatus.paused) {
      debugPrint('🎵 Resuming...');
      await _player.play();
    } else if (state.status == RadioStatus.error ||
        state.status == RadioStatus.stopped) {
      debugPrint('🎵 Restarting...');
      await playStation(state.currentIndex);
    }
  }

  Future<void> stop() async {
    await _player.stop();
    state = state.copyWith(status: RadioStatus.stopped);
  }

  Future<void> nextStation() async {
    final nextIndex = (state.currentIndex + 1) % stations.length;
    await playStation(nextIndex);
  }

  Future<void> previousStation() async {
    final prevIndex =
        (state.currentIndex - 1 + stations.length) % stations.length;
    await playStation(prevIndex);
  }

  void setVolume(double volume) {
    _player.setVolume(volume);
    state = state.copyWith(volume: volume, isMuted: volume == 0);
  }

  void toggleMute() {
    if (state.isMuted) {
      _player.setVolume(state.volume);
      state = state.copyWith(isMuted: false);
    } else {
      _player.setVolume(0);
      state = state.copyWith(isMuted: true);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

// Provider
final radioProvider = StateNotifierProvider<RadioNotifier, RadioState>((ref) {
  return RadioNotifier();
});
