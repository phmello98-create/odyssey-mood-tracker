import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../providers/radio_provider.dart';

class RadioMiniPlayer extends ConsumerStatefulWidget {
  const RadioMiniPlayer({super.key});

  @override
  ConsumerState<RadioMiniPlayer> createState() => _RadioMiniPlayerState();
}

class _RadioMiniPlayerState extends ConsumerState<RadioMiniPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4), // Velocidade de rotação
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radioState = ref.watch(radioProvider);
    final colors = Theme.of(context).colorScheme;

    // Controlar animação baseado no estado do player
    if (radioState.isPlaying && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!radioState.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }

    if (radioState.status == RadioStatus.stopped &&
        radioState.currentTrack == null) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FloatingActionButton.extended(
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(radioProvider.notifier).playStation(0);
            },
            icon: const Icon(Icons.radio_rounded),
            label: const Text('Rádio Odyssey'),
            backgroundColor: colors.primaryContainer,
            foregroundColor: colors.onPrimaryContainer,
            elevation: 4,
          ),
        ),
      );
    }

    final track = radioState.currentTrack!;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withOpacity(0.95),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: colors.outline.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            // Vinyl Spinning Disc
            RotationTransition(
              turns: _controller,
              child: _buildVinylDisc(track),
            ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    track.artist,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Controls
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(radioProvider.notifier).previousStation();
                  },
                  icon: const Icon(Icons.skip_previous_rounded),
                  color: colors.onSurface,
                  iconSize: 24,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      ref.read(radioProvider.notifier).togglePlayPause();
                    },
                    icon: Icon(
                      radioState.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    color: colors.onPrimary,
                    iconSize: 28,
                    padding: EdgeInsets.zero,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(radioProvider.notifier).nextStation();
                  },
                  icon: const Icon(Icons.skip_next_rounded),
                  color: colors.onSurface,
                  iconSize: 24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVinylDisc(RadioTrack track) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black, // Cor do vinil
        gradient: const RadialGradient(
          colors: [Colors.black, Color(0xFF222222), Colors.black],
          stops: [0.9, 0.95, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        image: DecorationImage(
          image: NetworkImage(track.coverUrl),
          fit: BoxFit.cover,
        ),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Colors.black, // Furo central do vinil
            shape: BoxShape.circle,
          ),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white, // Brilho no pino central
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
