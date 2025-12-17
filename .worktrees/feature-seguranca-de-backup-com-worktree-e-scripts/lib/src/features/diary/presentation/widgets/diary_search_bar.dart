// lib/src/features/diary/presentation/widgets/diary_search_bar.dart

import 'dart:async';
import 'package:flutter/material.dart';

/// Barra de busca com debounce para o diário
class DiarySearchBar extends StatefulWidget {
  final String? initialQuery;
  final ValueChanged<String> onSearch;
  final VoidCallback? onClear;
  final Duration debounceDuration;
  final String hintText;
  final bool autoFocus;

  const DiarySearchBar({
    super.key,
    this.initialQuery,
    required this.onSearch,
    this.onClear,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.hintText = 'Buscar no diário...',
    this.autoFocus = false,
  });

  @override
  State<DiarySearchBar> createState() => _DiarySearchBarState();
}

class _DiarySearchBarState extends State<DiarySearchBar> {
  late TextEditingController _controller;
  Timer? _debounce;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {
      _hasText = value.isNotEmpty;
    });

    _debounce?.cancel();
    _debounce = Timer(widget.debounceDuration, () {
      widget.onSearch(value);
    });
  }

  void _onClear() {
    _controller.clear();
    setState(() {
      _hasText = false;
    });
    widget.onSearch('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(
            Icons.search_rounded,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: widget.autoFocus,
              onChanged: _onChanged,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          if (_hasText) ...[
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                size: 20,
              ),
              onPressed: _onClear,
              visualDensity: VisualDensity.compact,
            ),
          ] else ...[
            const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }
}

/// Barra de busca expansível para AppBar
class DiarySearchBarExpanding extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final VoidCallback? onClose;

  const DiarySearchBarExpanding({
    super.key,
    required this.onSearch,
    this.onClose,
  });

  @override
  State<DiarySearchBarExpanding> createState() => _DiarySearchBarExpandingState();
}

class _DiarySearchBarExpandingState extends State<DiarySearchBarExpanding>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  final TextEditingController _textController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _widthAnimation = Tween<double>(begin: 48, end: 250).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _textController.clear();
        widget.onSearch('');
        widget.onClose?.call();
      }
    });
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          height: 40,
          decoration: BoxDecoration(
            color: _isExpanded
                ? colorScheme.surfaceContainerHighest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _isExpanded ? Icons.close : Icons.search_rounded,
                  color: colorScheme.onSurface,
                ),
                onPressed: _toggleExpand,
                visualDensity: VisualDensity.compact,
              ),
              if (_isExpanded) ...[
                Expanded(
                  child: TextField(
                    controller: _textController,
                    autofocus: true,
                    onChanged: _onChanged,
                    decoration: const InputDecoration(
                      hintText: 'Buscar...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
