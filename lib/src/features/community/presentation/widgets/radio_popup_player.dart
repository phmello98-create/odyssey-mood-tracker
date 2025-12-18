import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../providers/radio_provider.dart';

class RadioPopupPlayer extends ConsumerWidget {
  final VoidCallback onClose;

  const RadioPopupPlayer({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radioState = ref.watch(radioProvider);
    final colors = Theme.of(context).colorScheme;

    if (radioState.currentTrack == null) {
      // Show station selection
      return _buildStationSelector(context, ref, colors);
    }

    final track = radioState.currentTrack!;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: colors.surface,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outline.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rádio Odyssey',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 20),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Album Art
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
                image: DecorationImage(
                  image: NetworkImage(track.coverUrl),
                  fit: BoxFit.cover,
                ),
                border: Border.all(color: colors.primary, width: 3),
              ),
            ),
            const SizedBox(height: 16),

            // Track Info
            Text(
              track.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              track.artist,
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(radioProvider.notifier).previousStation();
                  },
                  icon: const Icon(Icons.skip_previous_rounded),
                  color: colors.onSurface,
                  iconSize: 28,
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      ref.read(radioProvider.notifier).togglePlayPause();
                    },
                    icon: Icon(
                      radioState.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    color: colors.onPrimary,
                    iconSize: 32,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(radioProvider.notifier).nextStation();
                  },
                  icon: const Icon(Icons.skip_next_rounded),
                  color: colors.onSurface,
                  iconSize: 28,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Stop Button
            TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                // TODO: Implement stop functionality
                onClose();
              },
              icon: Icon(Icons.stop_rounded, size: 18),
              label: const Text('Parar'),
              style: TextButton.styleFrom(foregroundColor: colors.error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationSelector(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colors,
  ) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: colors.surface,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outline.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Escolha uma estação',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, size: 20),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStationItem(context, ref, colors, 0, 'Lofi Hip Hop', '🎵'),
            _buildStationItem(context, ref, colors, 1, 'Deep Focus', '🎧'),
            _buildStationItem(context, ref, colors, 2, 'Chill Sky', '☁️'),
          ],
        ),
      ),
    );
  }

  Widget _buildStationItem(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colors,
    int index,
    String name,
    String emoji,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(radioProvider.notifier).playStation(index);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.play_circle_outline_rounded,
              color: colors.primary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
