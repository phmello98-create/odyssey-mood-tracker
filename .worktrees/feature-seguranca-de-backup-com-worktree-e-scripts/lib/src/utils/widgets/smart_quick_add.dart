import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:odyssey/src/constants/app_theme.dart';
import 'package:odyssey/src/utils/smart_classifier.dart';

/// Widget de adição rápida unificada
/// Classifica automaticamente entre Hábito e Tarefa
class SmartQuickAddSheet extends StatefulWidget {
  final Function(String text, ItemType type)? onAdd;
  
  const SmartQuickAddSheet({super.key, this.onAdd});

  static void show(BuildContext context, {Function(String text, ItemType type)? onAdd}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SmartQuickAddSheet(onAdd: onAdd),
    );
  }

  @override
  State<SmartQuickAddSheet> createState() => _SmartQuickAddSheetState();
}

class _SmartQuickAddSheetState extends State<SmartQuickAddSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  ClassificationResult? _classification;
  ItemType? _manualOverride;
  bool _showSuggestions = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    
    // Auto-focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _classification = null;
        _manualOverride = null;
        _showSuggestions = true;
      });
      return;
    }

    setState(() {
      _classification = SmartClassifier.classify(text);
      _showSuggestions = false;
    });
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final type = _manualOverride ?? _classification?.type ?? ItemType.task;
    
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    widget.onAdd?.call(text, type);
  }

  void _selectSuggestion(String suggestion) {
    // Remove emoji do início
    final cleanText = suggestion.replaceFirst(RegExp(r'^[^\w\s]+\s*'), '');
    _controller.text = cleanText;
    _onTextChanged();
  }

  ItemType get _effectiveType => _manualOverride ?? _classification?.type ?? ItemType.unknown;

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      margin: EdgeInsets.only(bottom: keyboardHeight),
      decoration: const BoxDecoration(
        color: UltravioletColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: UltravioletColors.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  const Icon(Icons.bolt, color: UltravioletColors.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Adicionar rapidamente',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Input field
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'O que você quer adicionar?',
                  hintStyle: TextStyle(
                    color: UltravioletColors.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: UltravioletColors.surfaceVariant.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _controller.clear();
                            _onTextChanged();
                          },
                        )
                      : null,
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),

              // Classification indicator
              if (_classification != null && _controller.text.isNotEmpty) ...[
                _buildClassificationIndicator(),
                const SizedBox(height: 16),
              ],

              // Manual type selector (always visible when typing)
              if (_controller.text.isNotEmpty) ...[
                _buildTypeSelector(),
                const SizedBox(height: 16),
              ],

              // Suggestions (only when empty)
              if (_showSuggestions && _controller.text.isEmpty) ...[
                _buildSuggestions(),
                const SizedBox(height: 16),
              ],

              // Submit button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _controller.text.trim().isNotEmpty ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _effectiveType == ItemType.habit
                        ? UltravioletColors.primary
                        : UltravioletColors.accentGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _effectiveType == ItemType.habit
                            ? Icons.repeat
                            : Icons.check_circle_outline,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _effectiveType == ItemType.habit
                            ? 'Criar Hábito'
                            : _effectiveType == ItemType.task
                                ? 'Criar Tarefa'
                                : 'Criar',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassificationIndicator() {
    final classification = _classification!;
    final isConfident = classification.isConfident;
    
    Color indicatorColor;
    IconData indicatorIcon;
    String indicatorText;

    switch (classification.type) {
      case ItemType.habit:
        indicatorColor = UltravioletColors.primary;
        indicatorIcon = Icons.repeat;
        indicatorText = 'Parece ser um Hábito';
        break;
      case ItemType.task:
        indicatorColor = UltravioletColors.accentGreen;
        indicatorIcon = Icons.check_circle_outline;
        indicatorText = 'Parece ser uma Tarefa';
        break;
      case ItemType.unknown:
        indicatorColor = UltravioletColors.onSurfaceVariant;
        indicatorIcon = Icons.help_outline;
        indicatorText = 'Não tenho certeza...';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: indicatorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(indicatorIcon, color: indicatorColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  indicatorText,
                  style: TextStyle(
                    color: indicatorColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (!isConfident && classification.suggestion != null)
                  Text(
                    classification.suggestion!,
                    style: const TextStyle(
                      color: UltravioletColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (isConfident)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: indicatorColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(classification.confidence * 100).round()}%',
                style: TextStyle(
                  color: indicatorColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeOption(
            type: ItemType.habit,
            icon: Icons.repeat,
            label: 'Hábito',
            description: 'Repetir regularmente',
            color: UltravioletColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTypeOption(
            type: ItemType.task,
            icon: Icons.check_circle_outline,
            label: 'Tarefa',
            description: 'Fazer uma vez',
            color: UltravioletColors.accentGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption({
    required ItemType type,
    required IconData icon,
    required String label,
    required String description,
    required Color color,
  }) {
    final isSelected = _effectiveType == type;
    final isOverridden = _manualOverride == type;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _manualOverride = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : UltravioletColors.surfaceVariant.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : UltravioletColors.onSurfaceVariant, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? color : UltravioletColors.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: const TextStyle(
                fontSize: 11,
                color: UltravioletColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (isOverridden) ...[
              const SizedBox(height: 4),
              Text(
                '(manual)',
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sugestões rápidas',
          style: TextStyle(
            color: UltravioletColors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...SmartClassifier.getSuggestions(ItemType.habit).take(4).map(
              (s) => _buildSuggestionChip(s, ItemType.habit),
            ),
            ...SmartClassifier.getSuggestions(ItemType.task).take(4).map(
              (s) => _buildSuggestionChip(s, ItemType.task),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String suggestion, ItemType type) {
    final color = type == ItemType.habit ? UltravioletColors.primary : UltravioletColors.accentGreen;
    
    return GestureDetector(
      onTap: () => _selectSuggestion(suggestion),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          suggestion,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
