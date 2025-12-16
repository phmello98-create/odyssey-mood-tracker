import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/language_learning_repository.dart';
import '../domain/language.dart';

class AddLanguageSheet extends StatefulWidget {
  final LanguageLearningRepository repository;

  const AddLanguageSheet({super.key, required this.repository});

  @override
  State<AddLanguageSheet> createState() => _AddLanguageSheetState();
}

class _AddLanguageSheetState extends State<AddLanguageSheet> {
  final _nameController = TextEditingController();
  String _selectedIcon = '✦';
  int _selectedColor = 0xFF3B82F6;
  String _selectedLevel = 'A1';
  bool _isCustomLanguage = false;

  final List<int> _availableColors = [
    0xFF3B82F6, // Blue
    0xFFEF4444, // Red
    0xFF10B981, // Green
    0xFFF59E0B, // Amber
    0xFF8B5CF6, // Purple
    0xFFEC4899, // Pink
    0xFF06B6D4, // Cyan
    0xFFF97316, // Orange
    0xFF6366F1, // Indigo
    0xFF14B8A6, // Teal
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPadding + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Adicionar Idioma',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 24),

            // Common Languages Grid
            if (!_isCustomLanguage) ...[
              Text(
                'IDIOMAS POPULARES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.55,
                  ),
                  itemCount: CommonLanguages.list.length,
                  itemBuilder: (context, index) {
                    final lang = CommonLanguages.list[index];
                    return _buildLanguageOption(
                      colors,
                      lang['name'],
                      lang['icon'],
                      Color(lang['color']),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Custom language button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _isCustomLanguage = true);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 18, color: colors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Outro idioma...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Custom Language Form
            if (_isCustomLanguage) ...[
              // Back button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _isCustomLanguage = false);
                },
                child: Row(
                  children: [
                    Icon(Icons.arrow_back, size: 18, color: colors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Voltar para lista',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Icon + Name
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showIconPicker(),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(_selectedColor).withValues(alpha: 0.3),
                            Color(_selectedColor).withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(_selectedColor).withValues(alpha: 0.4)),
                      ),
                      child: Center(
                        child: Text(
                          _selectedIcon,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(_selectedColor),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      style: TextStyle(color: colors.onSurface),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Nome do idioma',
                        labelStyle: TextStyle(color: colors.onSurfaceVariant),
                        filled: true,
                        fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.primary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Color selector
              Text(
                'COR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _availableColors.map((colorValue) {
                  final isSelected = _selectedColor == colorValue;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedColor = colorValue);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(colorValue),
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected
                            ? Border.all(color: colors.onSurface, width: 2)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Level selector
              Text(
                'NÍVEL ATUAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: LanguageLevels.levels.map((level) {
                  final isSelected = _selectedLevel == level;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedLevel = level);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(_selectedColor).withValues(alpha: 0.2)
                            : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? Color(_selectedColor)
                              : colors.outline.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        level,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? Color(_selectedColor) : colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nameController.text.isEmpty ? null : _saveCustomLanguage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: colors.surfaceContainerHighest,
                  ),
                  child: const Text('Adicionar', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(ColorScheme colors, String name, String icon, Color color) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        await widget.repository.createLanguage(
          name: name,
          flag: icon,
          colorValue: color.value,
          level: 'A1',
        );
        if (mounted) Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  icon,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIconPicker() {
    final icons = ['EN', 'ES', 'FR', 'DE', 'IT', 'あ', '한', '中', 'RU', 'PT', 'ع', 'हि', 'NL', 'SV', 'TR', 'PL', 'Ω', 'עב', 'ไท', 'VI', '✦', '◆', '★', '●'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Escolha um ícone',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: icons.map((icon) {
                final isSelected = _selectedIcon == icon;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedIcon = icon);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: isSelected ? LinearGradient(
                        colors: [
                          Color(_selectedColor).withValues(alpha: 0.3),
                          Color(_selectedColor).withValues(alpha: 0.1),
                        ],
                      ) : null,
                      color: isSelected ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? Border.all(color: Color(_selectedColor)) : null,
                    ),
                    child: Center(
                      child: Text(
                        icon,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Color(_selectedColor) : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCustomLanguage() async {
    if (_nameController.text.isEmpty) return;

    await widget.repository.createLanguage(
      name: _nameController.text,
      flag: _selectedIcon,
      colorValue: _selectedColor,
      level: _selectedLevel,
    );

    if (mounted) Navigator.pop(context);
  }
}
