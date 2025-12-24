// lib/src/features/diary/presentation/widgets/diary_search_bar.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/diary_isar_provider.dart';

/// Barra de busca inteligente para o diário com debounce e animações
class DiarySearchBar extends ConsumerStatefulWidget {
  final Duration debounceDuration;
  final String hintText;
  final bool autoFocus;

  const DiarySearchBar({
    super.key,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.hintText = 'Buscar no diário...',
    this.autoFocus = false,
  });

  @override
  ConsumerState<DiarySearchBar> createState() => _DiarySearchBarState();
}

class _DiarySearchBarState extends ConsumerState<DiarySearchBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Timer? _debounce;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
    if (_focusNode.hasFocus) {
      ref.read(diarySearchExpandedProvider.notifier).state = true;
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      ref.read(diarySearchQueryProvider.notifier).state = value;
    });
  }

  void _onClear() {
    _controller.clear();
    ref.read(diarySearchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasText = _controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      height: 52,
      decoration: BoxDecoration(
        color: _isFocused
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: _isFocused
              ? colorScheme.primary.withValues(alpha: 0.5)
              : colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isFocused ? Icons.search_rounded : Icons.search_rounded,
              key: ValueKey(_isFocused),
              color: _isFocused
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: widget.autoFocus,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          if (hasText) ...[
            _AnimatedClearButton(
              onPressed: _onClear,
              color: colorScheme.onSurfaceVariant,
            ),
          ] else ...[
            // Ícone de filtro ou dica
            Icon(
              Icons.filter_alt_outlined,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              size: 20,
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _AnimatedClearButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Color color;

  const _AnimatedClearButton({required this.onPressed, required this.color});

  @override
  State<_AnimatedClearButton> createState() => _AnimatedClearButtonState();
}

class _AnimatedClearButtonState extends State<_AnimatedClearButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: IconButton(
        icon: Icon(
          Icons.cancel_rounded,
          color: widget.color.withValues(alpha: 0.6),
          size: 20,
        ),
        onPressed: () {
          _controller.reverse().then((_) => widget.onPressed());
        },
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

// ====================================
// WIDGET DE DESTAQUE DE RESULTADOS
// ====================================

/// Widget que destaca o termo buscado no texto
class SearchHighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;
  final int maxLines;
  final TextOverflow overflow;

  const SearchHighlightText({
    super.key,
    required this.text,
    required this.query,
    this.style,
    this.maxLines = 2,
    this.overflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty || query.length < 2) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }

    final theme = Theme.of(context);
    final normalStyle = style ?? theme.textTheme.bodyMedium;
    final highlightStyle = normalStyle?.copyWith(
      backgroundColor: theme.colorScheme.primaryContainer,
      color: theme.colorScheme.onPrimaryContainer,
      fontWeight: FontWeight.w600,
    );

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      // Texto antes do match
      if (index > start) {
        spans.add(
          TextSpan(text: text.substring(start, index), style: normalStyle),
        );
      }

      // Match destacado
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: highlightStyle,
        ),
      );

      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    // Resto do texto
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: normalStyle));
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

// ====================================
// CHIPS DE FILTRO RÁPIDO
// ====================================

/// Sugestões de busca rápida (tags populares, feelings, etc)
class DiarySearchSuggestions extends ConsumerWidget {
  const DiarySearchSuggestions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sugestões de busca rápida
    final suggestions = [
      ('Hoje', Icons.today_rounded, 'hoje'),
      ('Feliz', Icons.sentiment_very_satisfied_rounded, 'feliz'),
      ('Triste', Icons.sentiment_dissatisfied_rounded, 'triste'),
      ('Favoritos', Icons.star_rounded, '⭐'),
      ('Reflexão', Icons.psychology_rounded, 'reflexão'),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (label, icon, query) = suggestions[index];
          return _QuickSearchChip(
            label: label,
            icon: icon,
            onTap: () {
              ref.read(diarySearchQueryProvider.notifier).state = query;
            },
          );
        },
      ),
    );
  }
}

class _QuickSearchChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickSearchChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: colorScheme.primary.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================================
// ESTADO DE BUSCA VAZIA
// ====================================

/// Widget exibido quando não há resultados na busca
class DiarySearchEmptyState extends StatelessWidget {
  final String query;

  const DiarySearchEmptyState({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 40,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhum resultado encontrado',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Não encontramos nada para "$query"',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Tente buscar por:\n• Títulos\n• Conteúdo\n• Tags (#meditação)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================
// CONTADOR DE RESULTADOS
// ====================================

/// Mostra quantos resultados foram encontrados
class DiarySearchResultsCount extends StatelessWidget {
  final int count;
  final String query;

  const DiarySearchResultsCount({
    super.key,
    required this.count,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$count ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  TextSpan(
                    text: count == 1 ? 'resultado para ' : 'resultados para ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  TextSpan(
                    text: '"$query"',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
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
