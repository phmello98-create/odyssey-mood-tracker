import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

// --- State Model ---

enum RadioStatus { stopped, playing, paused, buffering, error }

class RadioTrack {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final String streamUrl;
  final Color themeColor;

  const RadioTrack({
    required this.id,
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

  // Real Free Streaming Stations (Royalty-Free) - URLs testadas e funcionais
  // Dica: Esses links podem mudar. Considere carregar de um JSON no Firebase.
  final List<RadioTrack> stations = [
    // Lofi Hip Hop - Hunter.FM Brasil (estável e gratuita)
    const RadioTrack(
      id: 'lofi_hipHop',
      title: 'Lofi Hip Hop',
      artist: 'Hunter.FM',
      coverUrl:
          'https://i.scdn.co/image/ab67616d0000b2735af263b6522c061266b7dd25',
      streamUrl: 'https://live.hunter.fm/lofi_high',
      themeColor: Color(0xFF6C63FF),
    ),
    // Chillout Lounge - 1.FM (europeia, links abertos)
    const RadioTrack(
      id: 'chillout_lounge',
      title: 'Chillout Lounge',
      artist: '1.FM Network',
      coverUrl:
          'https://i.scdn.co/image/ab67616d0000b273d2a3d02772522744312ce06e',
      streamUrl: 'http://strm112.1.fm/chilloutlounge_mobile_mp3',
      themeColor: Color(0xFF00BFA5),
    ),
    // Deep House - Deeper Link (NYC, 8000 port)
    const RadioTrack(
      id: 'deep_house',
      title: 'Deep House',
      artist: 'Deeper Link',
      coverUrl:
          'https://i.scdn.co/image/ab67616d0000b273e913337604471017359dae3d',
      streamUrl: 'http://deeperlink.com:8000/stream',
      themeColor: Color(0xFFE91E63),
    ),
    // Tech House - United Music (Italy, Direct MP3)
    const RadioTrack(
      id: 'tech_house',
      title: 'Tech House',
      artist: 'United Music',
      coverUrl:
          'https://i.scdn.co/image/ab67616d0000b2736fc4cc0aaf0c6f4d5f8c9a3d',
      streamUrl: 'https://icy.unitedradio.it/um065.mp3',
      themeColor: Color(0xFF9C27B0),
    ),
    // Drum & Bass - DnB Base (Working)
    const RadioTrack(
      id: 'dnb_base',
      title: 'DnB Base',
      artist: 'Laut.FM',
      coverUrl:
          'https://i.scdn.co/image/ab67616d0000b273b852a657f495574dc5d69114',
      streamUrl: 'https://stream.laut.fm/dnb-base',
      themeColor: Color(0xFFFFD700),
    ),
    // Drum & Bass - Bassdrive (Official)
    const RadioTrack(
      id: 'bassdrive',
      title: 'Bassdrive',
      artist: 'Worldwide DnB',
      coverUrl:
          'https://i.scdn.co/image/ab67616d0000b273df1f0d367c30959f64c6778f',
      streamUrl: 'http://ice.bassdrive.net:80/stream',
      themeColor: Color(0xFF000000),
    ),
    // Chill Electro Slow - Costa Del Mar (vibe lounge)
    const RadioTrack(
      id: 'chill_lounge',
      title: 'Chill Lounge',
      artist: 'Costa Del Mar',
      coverUrl:
          'https://i.scdn.co/image/ab67616d0000b2730f0cfe4a7e9b9b3e6c6d8f9a',
      streamUrl: 'https://stream.costadelmar-radio.com/chillout.mp3',
      themeColor: Color(0xFF795548),
    ),
    // Ambient / Nature - Soma FM (Creative Commons)
    const RadioTrack(
      id: 'drone_zone',
      title: 'Drone Zone',
      artist: 'SomaFM',
      coverUrl:
          'https://i.scdn.co/image/ab67616d0000b273d4b0e6f8e6f8e6f8e6f8e6f8',
      streamUrl: 'https://ice1.somafm.com/dronezone-128-mp3',
      themeColor: Color(0xFF607D8B),
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
      // Usar AudioSource com metadata para notificação em background
      final audioSource = AudioSource.uri(
        Uri.parse(track.streamUrl),
        tag: MediaItem(
          id: track.id,
          title: track.title,
          artist: track.artist,
          artUri: Uri.parse(track.coverUrl),
          album: 'Rádio Odyssey',
        ),
      );
      await _player.setAudioSource(audioSource);
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

// Provider - Usando keepAlive para manter o player ativo mesmo quando sai da tela
final radioProvider = StateNotifierProvider<RadioNotifier, RadioState>((ref) {
  final notifier = RadioNotifier();

  // Manter o provider vivo para não perder o estado
  ref.keepAlive();

  return notifier;
});
