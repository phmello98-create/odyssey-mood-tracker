import 'package:flutter/material.dart';
import 'package:odyssey/src/localization/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:odyssey/src/features/home/data/home_widgets_provider.dart';

class WidgetsConfigScreen extends ConsumerStatefulWidget {
  const WidgetsConfigScreen({super.key});

  @override
  ConsumerState<WidgetsConfigScreen> createState() => _WidgetsConfigScreenState();
}

class _WidgetsConfigScreenState extends ConsumerState<WidgetsConfigScreen> {
  @override
  Widget build(BuildContext context) {
    final widgetsState = ref.watch(homeWidgetsProvider);
    final colors = Theme.of(context).colorScheme;

    final enabledWidgets = widgetsState.enabledWidgets;
    final disabledWidgets = widgetsState.widgets.where((w) => !w.isEnabled).toList();

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primary.withValues(alpha: 0.1), colors.surface],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.arrow_back_ios_new, size: 18, color: colors.onSurface),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(AppLocalizations.of(context)!.widgetsDaHome, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colors.onSurface)),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      ref.read(homeWidgetsProvider.notifier).resetToDefaults();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.widgetsRestauradosParaOPadrao)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.restart_alt_rounded, size: 18, color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: colors.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.dragToReorder,
                              style: TextStyle(fontSize: 13, color: colors.onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Widgets ativos - ReorderableListView
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF07E092), size: 18),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.activeWidgets(enabledWidgets.length.toString()), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.onSurfaceVariant, letterSpacing: 1)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ReorderableListView para widgets ativos
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: enabledWidgets.length,
                      onReorder: (oldIndex, newIndex) {
                        HapticFeedback.mediumImpact();
                        ref.read(homeWidgetsProvider.notifier).reorderWidgets(oldIndex, newIndex);
                      },
                      proxyDecorator: (child, index, animation) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            final scale = Tween<double>(begin: 1.0, end: 1.03).animate(animation);
                            return Transform.scale(
                              scale: scale.value,
                              child: Material(
                                elevation: 8,
                                borderRadius: BorderRadius.circular(16),
                                shadowColor: colors.shadow.withValues(alpha: 0.3),
                                child: child,
                              ),
                            );
                          },
                          child: child,
                        );
                      },
                      itemBuilder: (context, index) {
                        final widget = enabledWidgets[index];
                        return Padding(
                          key: ValueKey(widget.id),
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildWidgetCard(context, ref, widget, true, colors, index),
                        );
                      },
                    ),

                    // Widgets inativos
                    if (disabledWidgets.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.remove_circle_outline_rounded, color: colors.onSurfaceVariant, size: 18),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.availableWidgets(disabledWidgets.length.toString()), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.onSurfaceVariant, letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...disabledWidgets.map((widget) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildWidgetCard(context, ref, widget, false, colors, null),
                      )),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetCard(BuildContext context, WidgetRef ref, HomeWidgetConfig widget, bool isEnabled, ColorScheme colors, int? dragIndex) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isEnabled ? widget.color.withValues(alpha: 0.08) : colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled ? widget.color.withValues(alpha: 0.25) : colors.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Drag handle
          if (isEnabled && dragIndex != null)
            ReorderableDragStartListener(
              index: dragIndex,
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(Icons.drag_indicator_rounded, color: widget.color.withValues(alpha: 0.6), size: 22),
              ),
            ),
          
          // Ícone
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isEnabled ? widget.color.withValues(alpha: 0.15) : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.icon, color: isEnabled ? widget.color : colors.onSurfaceVariant, size: 22),
          ),
          const SizedBox(width: 12),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.description,
                  style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Switch
          Switch.adaptive(
            value: isEnabled,
            onChanged: (_) {
              HapticFeedback.selectionClick();
              ref.read(homeWidgetsProvider.notifier).toggleWidget(widget.id);
            },
            activeColor: widget.color,
          ),
        ],
      ),
    );
  }
}
