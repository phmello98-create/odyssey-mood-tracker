import 'package:flutter/material.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/constants/app_sizes.dart';
import 'package:odyssey/src/utils/services/haptic_service.dart';

/// ============================================
/// HIERARQUIA DE TEXTO
/// ============================================

/// Estilos de texto com hierarquia visual clara
class AppText extends StatelessWidget {
  final String text;
  final AppTextStyle style;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppText(
    this.text, {
    super.key,
    this.style = AppTextStyle.body,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  /// Display grande - para números destacados, títulos principais
  const AppText.displayLarge(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : style = AppTextStyle.displayLarge;

  /// Display médio - para títulos de seção importantes
  const AppText.displayMedium(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : style = AppTextStyle.displayMedium;

  /// Display pequeno - para subtítulos destacados
  const AppText.displaySmall(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : style = AppTextStyle.displaySmall;

  /// Título grande - para títulos de tela
  const AppText.titleLarge(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : style = AppTextStyle.titleLarge;

  /// Título médio - para títulos de cards/seções
  const AppText.titleMedium(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : style = AppTextStyle.titleMedium;

  /// Título pequeno - para subtítulos
  const AppText.titleSmall(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : style = AppTextStyle.titleSmall;

  /// Corpo de texto grande
  const AppText.bodyLarge(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : style = AppTextStyle.bodyLarge;

  /// Corpo de texto padrão
  const AppText.body(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : style = AppTextStyle.body;

  /// Corpo de texto pequeno
  const AppText.bodySmall(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : style = AppTextStyle.bodySmall;

  /// Label/etiqueta
  const AppText.label(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : style = AppTextStyle.label;

  /// Caption/legenda
  const AppText.caption(this.text, {super.key, this.color, this.textAlign, this.maxLines, this.overflow})
      : style = AppTextStyle.caption;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: _getStyle(),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  TextStyle _getStyle() {
    final baseStyle = switch (style) {
      AppTextStyle.displayLarge => TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w700,
          color: color ?? UltravioletColors.onSurface,
          height: 1.1,
          letterSpacing: -1,
        ),
      AppTextStyle.displayMedium => TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: color ?? UltravioletColors.onSurface,
          height: 1.2,
          letterSpacing: -0.5,
        ),
      AppTextStyle.displaySmall => TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: color ?? UltravioletColors.onSurface,
          height: 1.2,
        ),
      AppTextStyle.titleLarge => TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: color ?? UltravioletColors.onSurface,
          height: 1.3,
        ),
      AppTextStyle.titleMedium => TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: color ?? UltravioletColors.onSurface,
          height: 1.3,
        ),
      AppTextStyle.titleSmall => TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color ?? UltravioletColors.onSurfaceVariant,
          height: 1.4,
        ),
      AppTextStyle.bodyLarge => TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: color ?? UltravioletColors.onSurface,
          height: 1.5,
        ),
      AppTextStyle.body => TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: color ?? UltravioletColors.onSurface,
          height: 1.5,
        ),
      AppTextStyle.bodySmall => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: color ?? UltravioletColors.onSurfaceVariant,
          height: 1.4,
        ),
      AppTextStyle.label => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color ?? UltravioletColors.onSurface,
          height: 1.3,
          letterSpacing: 0.5,
        ),
      AppTextStyle.caption => TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: color ?? UltravioletColors.onSurfaceVariant,
          height: 1.3,
        ),
    };
    return baseStyle;
  }
}

enum AppTextStyle {
  displayLarge,
  displayMedium,
  displaySmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  body,
  bodySmall,
  label,
  caption,
}

/// ============================================
/// SEÇÕES COLAPSÁVEIS
/// ============================================

/// Seção expansível/colapsável com animação suave
class CollapsibleSection extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool initiallyExpanded;
  final IconData? leadingIcon;
  final Color? iconColor;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? childPadding;
  final VoidCallback? onToggle;
  final Duration animationDuration;

  const CollapsibleSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.initiallyExpanded = true,
    this.leadingIcon,
    this.iconColor,
    this.trailing,
    this.padding,
    this.childPadding,
    this.onToggle,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
      value: _isExpanded ? 1.0 : 0.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _rotateAnimation = Tween<double>(begin: 0, end: 0.5).animate(_expandAnimation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    hapticService.selection();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
    widget.onToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header clicável
        GestureDetector(
          onTap: _toggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: widget.padding ?? EdgeInsets.zero,
            child: Row(
              children: [
                // Ícone leading
                if (widget.leadingIcon != null) ...[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (widget.iconColor ?? UltravioletColors.primary)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.leadingIcon,
                      color: widget.iconColor ?? UltravioletColors.primary,
                      size: 18,
                    ),
                  ),
                  gapW12,
                ],
                // Título e subtítulo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: UltravioletColors.onSurface,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: UltravioletColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Trailing ou ícone de expansão
                if (widget.trailing != null)
                  widget.trailing!
                else
                  RotationTransition(
                    turns: _rotateAnimation,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: UltravioletColors.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Conteúdo expansível
        SizeTransition(
          sizeFactor: _expandAnimation,
          axisAlignment: -1,
          child: FadeTransition(
            opacity: _expandAnimation,
            child: Padding(
              padding: widget.childPadding ?? const EdgeInsets.only(top: 12),
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}

/// Card colapsável com estilo de card
class CollapsibleCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool initiallyExpanded;
  final IconData? leadingIcon;
  final Color? accentColor;
  final EdgeInsetsGeometry? margin;

  const CollapsibleCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.initiallyExpanded = false,
    this.leadingIcon,
    this.accentColor,
    this.margin,
  });

  @override
  State<CollapsibleCard> createState() => _CollapsibleCardState();
}

class _CollapsibleCardState extends State<CollapsibleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: _isExpanded ? 1.0 : 0.0,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    hapticService.selection();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor ?? UltravioletColors.primary;

    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: UltravioletColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isExpanded
              ? color.withValues(alpha: 0.3)
              : UltravioletColors.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: _toggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (widget.leadingIcon != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.leadingIcon,
                        color: color,
                        size: 20,
                      ),
                    ),
                    gapW12,
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: UltravioletColors.onSurface,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: UltravioletColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _isExpanded ? color : UltravioletColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Conteúdo
          ClipRect(
            child: SizeTransition(
              sizeFactor: _expandAnimation,
              axisAlignment: -1,
              child: Column(
                children: [
                  Divider(
                    height: 1,
                    color: UltravioletColors.outline.withValues(alpha: 0.1),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: widget.child,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================
/// GRUPOS DE CONTEÚDO
/// ============================================

/// Grupo de itens com título de categoria
class ContentGroup extends StatelessWidget {
  final String title;
  final String? description;
  final List<Widget> children;
  final Widget? action;
  final EdgeInsetsGeometry? padding;
  final double spacing;

  const ContentGroup({
    super.key,
    required this.title,
    this.description,
    required this.children,
    this.action,
    this.padding,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do grupo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: UltravioletColors.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: UltravioletColors.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (action != null) action!,
            ],
          ),
          SizedBox(height: spacing),
          // Itens do grupo
          ...children.map((child) => Padding(
                padding: EdgeInsets.only(bottom: spacing),
                child: child,
              )),
        ],
      ),
    );
  }
}

/// Lista de itens agrupados por categoria
class CategorizedList extends StatelessWidget {
  final Map<String, List<Widget>> categories;
  final double categorySpacing;
  final double itemSpacing;
  final bool collapsible;

  const CategorizedList({
    super.key,
    required this.categories,
    this.categorySpacing = 24,
    this.itemSpacing = 8,
    this.collapsible = false,
  });

  @override
  Widget build(BuildContext context) {
    final entries = categories.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(entries.length, (index) {
        final entry = entries[index];
        final isLast = index == entries.length - 1;

        if (collapsible) {
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : categorySpacing),
            child: CollapsibleSection(
              title: entry.key,
              initiallyExpanded: index == 0,
              child: Column(
                children: entry.value
                    .map((item) => Padding(
                          padding: EdgeInsets.only(bottom: itemSpacing),
                          child: item,
                        ))
                    .toList(),
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : categorySpacing),
          child: ContentGroup(
            title: entry.key,
            spacing: itemSpacing,
            children: entry.value,
          ),
        );
      }),
    );
  }
}

/// ============================================
/// TABS E SEGMENTED CONTROLS
/// ============================================

/// Segmented control customizado
class SegmentedControl<T> extends StatelessWidget {
  final List<T> items;
  final T selectedItem;
  final String Function(T) labelBuilder;
  final IconData Function(T)? iconBuilder;
  final ValueChanged<T> onChanged;
  final Color? selectedColor;
  final bool expanded;

  const SegmentedControl({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.labelBuilder,
    this.iconBuilder,
    required this.onChanged,
    this.selectedColor,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? UltravioletColors.primary;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: UltravioletColors.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: items.map((item) {
          final isSelected = item == selectedItem;
          final label = labelBuilder(item);
          final icon = iconBuilder?.call(item);

          return Expanded(
            flex: expanded ? 1 : 0,
            child: GestureDetector(
              onTap: () {
                if (!isSelected) {
                  hapticService.selection();
                  onChanged(item);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: 16,
                        color: isSelected ? Colors.white : UltravioletColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : UltravioletColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Chip filter group
class FilterChipGroup extends StatelessWidget {
  final List<String> filters;
  final String? selectedFilter;
  final ValueChanged<String?> onChanged;
  final bool allowDeselect;
  final Color? selectedColor;

  const FilterChipGroup({
    super.key,
    required this.filters,
    this.selectedFilter,
    required this.onChanged,
    this.allowDeselect = true,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = selectedColor ?? UltravioletColors.primary;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = filter == selectedFilter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                hapticService.selection();
                if (isSelected && allowDeselect) {
                  onChanged(null);
                } else {
                  onChanged(filter);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color : UltravioletColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : Colors.transparent,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : UltravioletColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// ============================================
/// LISTAS ORDENÁVEIS
/// ============================================

/// Item de lista com drag handle
class DraggableListItem extends StatelessWidget {
  final Widget child;
  final bool showDragHandle;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const DraggableListItem({
    super.key,
    required this.child,
    this.showDragHandle = true,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: UltravioletColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: UltravioletColors.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            if (showDragHandle) ...[
              Icon(
                Icons.drag_indicator,
                color: UltravioletColors.onSurfaceVariant.withValues(alpha: 0.5),
                size: 20,
              ),
              gapW12,
            ],
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// ============================================
/// INDICADORES DE PROGRESSO DE SEÇÃO
/// ============================================

/// Indicador de progresso de seção (etapas)
class SectionProgress extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final List<String>? stepLabels;
  final Color? activeColor;
  final Color? inactiveColor;

  const SectionProgress({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    this.stepLabels,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? UltravioletColors.primary;
    final inactive = inactiveColor ?? UltravioletColors.surfaceVariant;

    return Column(
      children: [
        // Barra de progresso
        Row(
          children: List.generate(totalSteps, (index) {
            final isActive = index <= currentStep;
            final isLast = index == totalSteps - 1;

            return Expanded(
              child: Row(
                children: [
                  // Círculo
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isActive ? active : inactive,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isActive && index < currentStep
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isActive ? Colors.white : UltravioletColors.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ),
                  // Linha conectora
                  if (!isLast)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: index < currentStep ? active : inactive,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        // Labels
        if (stepLabels != null && stepLabels!.length == totalSteps) ...[
          gapH8,
          Row(
            children: List.generate(totalSteps, (index) {
              return Expanded(
                child: Text(
                  stepLabels![index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: index <= currentStep
                        ? UltravioletColors.onSurface
                        : UltravioletColors.onSurfaceVariant,
                    fontWeight: index == currentStep ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}
