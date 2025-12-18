import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../providers/radio_provider.dart';

class RadioMiniPlayer extends ConsumerWidget {
  const RadioMiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radioState = ref.watch(radioProvider);
    final colors = Theme.of(context).colorScheme;

    if (radioState.status == RadioStatus.stopped &&
        radioState.currentTrack == null) {
      // Show a "Start Radio" FAB or minimal button if nothing is playing?
      // For now, let's show a minimal "Start Radio" pill
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
          color: colors.surfaceContainerHighest.withOpacity(
            0.95,
          ), // Glassy effect capability if backlog
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
            // Album Art / Vinyl
            _buildSpinningDisc(context, track, radioState.isPlaying),

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

  Widget _buildSpinningDisc(
    BuildContext context,
    RadioTrack track,
    bool isPlaying,
  ) {
    // Note: For a real spinning animation, we'd use an AnimationController.
    // Since this is a stateless widget demo, we'll just show the art styled as a disc.
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black, // Vinyl background
        image: DecorationImage(
          image: NetworkImage(
            track.coverUrl,
          ), // In real app, use cached network image
          fit: BoxFit.cover,
        ),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
