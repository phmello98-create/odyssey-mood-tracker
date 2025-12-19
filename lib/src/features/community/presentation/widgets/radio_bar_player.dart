import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/radio_provider.dart';

/// Player de rádio em barra com controles de reprodução
class RadioBarPlayer extends ConsumerWidget {
  const RadioBarPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final radioState = ref.watch(radioProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primaryContainer.withOpacity(0.8),
            colors.tertiaryContainer.withOpacity(0.6),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Spinning disc icon
          _SpinningDisc(isPlaying: radioState.isPlaying),
          const SizedBox(width: 12),

          // Track info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  radioState.currentTrack?.title ?? 'Rádio Odyssey',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: colors.onPrimaryContainer,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  radioState.currentTrack?.artist ??
                      'Música ambiente para foco',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onPrimaryContainer.withOpacity(0.7),
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
              // Previous
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(radioProvider.notifier).previousStation();
                },

                icon: Icon(
                  Icons.skip_previous_rounded,
                  color: colors.onPrimaryContainer,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36),
              ),

              // Play/Pause
              Container(
                decoration: BoxDecoration(
                  color: radioState.status == RadioStatus.error
                      ? colors.error
                      : colors.primary,
                  shape: BoxShape.circle,
                ),
                child: radioState.status == RadioStatus.buffering
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.onPrimary,
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          await ref
                              .read(radioProvider.notifier)
                              .togglePlayPause();
                        },
                        icon: Icon(
                          radioState.status == RadioStatus.error
                              ? Icons.refresh_rounded
                              : radioState.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: colors.onPrimary,
                          size: 28,
                        ),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
              ),

              // Next
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(radioProvider.notifier).nextStation();
                },

                icon: Icon(
                  Icons.skip_next_rounded,
                  color: colors.onPrimaryContainer,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpinningDisc extends StatefulWidget {
  final bool isPlaying;

  const _SpinningDisc({required this.isPlaying});

  @override
  State<_SpinningDisc> createState() => _SpinningDiscState();
}

class _SpinningDiscState extends State<_SpinningDisc>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(_SpinningDisc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _controller.repeat();
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1A1A1A), // Cor base do vinil
          boxShadow: widget.isPlaying
              ? [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Sulcos do vinil (círculos concêntricos)
            ...List.generate(3, (i) {
              return Container(
                width: 36 - (i * 8),
                height: 36 - (i * 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.15),
                    width: 1,
                  ),
                ),
              );
            }),
            // Label central (colorido)
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: widget.isPlaying
                      ? [Colors.purple, Colors.pink]
                      : [Colors.grey.shade600, Colors.grey.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Furo central
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
