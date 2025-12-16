import 'package:flutter/material.dart';
import '../../domain/entities/diary_preferences.dart';

/// Seletor de temas visuais para entradas do diário
/// Permite ao usuário escolher entre temas pré-definidos ou personalizar
class DiaryThemeSelector extends StatelessWidget {
  final DiaryPreferences? currentPreferences;
  final ValueChanged<DiaryPreferences> onThemeSelected;
  final bool showCustomize;

  const DiaryThemeSelector({
    super.key,
    this.currentPreferences,
    required this.onThemeSelected,
    this.showCustomize = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Estilo da Entrada',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: DiaryTheme.presets.length,
            itemBuilder: (context, index) {
              final theme = DiaryTheme.presets[index];
              final isSelected = _isThemeSelected(theme);
              
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _ThemePreviewCard(
                  theme: theme,
                  isSelected: isSelected,
                  onTap: () => onThemeSelected(theme.preferences),
                ),
              );
            },
          ),
        ),
        if (showCustomize) ...[
          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => _showCustomizeDialog(context),
              icon: const Icon(Icons.palette_rounded),
              label: const Text('Personalizar Tema'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  bool _isThemeSelected(DiaryTheme theme) {
    if (currentPreferences == null && theme.name == 'Padrão') return true;
    if (currentPreferences == null) return false;
    
    return currentPreferences!.fontFamily == theme.preferences.fontFamily &&
           currentPreferences!.fontSize == theme.preferences.fontSize &&
           currentPreferences!.backgroundColorHex == theme.preferences.backgroundColorHex;
  }

  void _showCustomizeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => DiaryThemeCustomizer(
          currentPreferences: currentPreferences ?? const DiaryPreferences(),
          onSave: (preferences) {
            Navigator.pop(context);
            onThemeSelected(preferences);
          },
        ),
      ),
    );
  }
}

/// Card de preview do tema
class _ThemePreviewCard extends StatelessWidget {
  final DiaryTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemePreviewCard({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        decoration: BoxDecoration(
          color: theme.preferences.backgroundColor ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.15 : 0.08),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header com gradiente
            if (theme.preferences.headerGradient != null)
              Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: theme.preferences.headerGradient,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
                child: Center(
                  child: Icon(
                    theme.icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              )
            else
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
                child: Center(
                  child: Icon(
                    theme.icon,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 28,
                  ),
                ),
              ),

            // Preview do conteúdo
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theme.name,
                      style: TextStyle(
                        fontFamily: theme.preferences.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.preferences.textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        'Aa Bb Cc\n123 456',
                        style: TextStyle(
                          fontFamily: theme.preferences.fontFamily,
                          fontSize: 11,
                          color: theme.preferences.textColor?.withValues(alpha: 0.7),
                          height: theme.preferences.lineHeight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Indicador de seleção
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Selecionado',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Personalizador completo de tema
class DiaryThemeCustomizer extends StatefulWidget {
  final DiaryPreferences currentPreferences;
  final ValueChanged<DiaryPreferences> onSave;

  const DiaryThemeCustomizer({
    super.key,
    required this.currentPreferences,
    required this.onSave,
  });

  @override
  State<DiaryThemeCustomizer> createState() => _DiaryThemeCustomizerState();
}

class _DiaryThemeCustomizerState extends State<DiaryThemeCustomizer> {
  late DiaryPreferences _preferences;

  @override
  void initState() {
    super.initState();
    _preferences = widget.currentPreferences;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Personalizar Tema',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => widget.onSave(_preferences),
                    icon: const Icon(Icons.check),
                    label: const Text('Salvar'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Conteúdo
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Seletor de fonte
                  _buildSection(
                    'Fonte',
                    DropdownButtonFormField<String>(
                      initialValue: _preferences.fontFamily,
                      decoration: const InputDecoration(
                        labelText: 'Família da Fonte',
                        border: OutlineInputBorder(),
                      ),
                      items: DiaryFont.values.map((font) {
                        return DropdownMenuItem(
                          value: font.fontFamily,
                          child: Text(
                            font.displayName,
                            style: TextStyle(fontFamily: font.fontFamily),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _preferences = _preferences.copyWith(
                              fontFamily: value,
                            );
                          });
                        }
                      },
                    ),
                  ),

                  // Tamanho da fonte
                  _buildSection(
                    'Tamanho',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_preferences.fontSize.toInt()}pt'),
                        Slider(
                          value: _preferences.fontSize,
                          min: 12,
                          max: 24,
                          divisions: 12,
                          label: '${_preferences.fontSize.toInt()}pt',
                          onChanged: (value) {
                            setState(() {
                              _preferences = _preferences.copyWith(
                                fontSize: value,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Espaçamento de linha
                  _buildSection(
                    'Espaçamento',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_preferences.lineHeight.toStringAsFixed(1)}x'),
                        Slider(
                          value: _preferences.lineHeight,
                          min: 1.0,
                          max: 2.5,
                          divisions: 15,
                          label: _preferences.lineHeight.toStringAsFixed(1),
                          onChanged: (value) {
                            setState(() {
                              _preferences = _preferences.copyWith(
                                lineHeight: value,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  // Preview
                  const SizedBox(height: 24),
                  Text(
                    'Preview',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _preferences.backgroundColor ?? theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Este é um exemplo de como seu texto ficará. '
                      'A fonte escolhida, tamanho e espaçamento serão aplicados '
                      'em todas as suas entradas do diário.',
                      style: _preferences.toTextStyle(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
