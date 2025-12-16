import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/language_learning_repository.dart';
import '../domain/study_session.dart';

class AddSessionSheet extends StatefulWidget {
  final LanguageLearningRepository repository;
  final String? preselectedLanguageId;

  const AddSessionSheet({
    super.key,
    required this.repository,
    this.preselectedLanguageId,
  });

  @override
  State<AddSessionSheet> createState() => _AddSessionSheetState();
}

class _AddSessionSheetState extends State<AddSessionSheet> {
  late String? _selectedLanguageId;
  String _selectedActivity = StudyActivityTypes.reading;
  int _durationMinutes = 30;
  int? _rating;
  final _notesController = TextEditingController();
  final _resourceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedLanguageId = widget.preselectedLanguageId ??
        widget.repository.getAllLanguages().firstOrNull?.id;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _resourceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final languages = widget.repository.getAllLanguages();

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
            Row(
              children: [
                Icon(Icons.timer_outlined, color: colors.primary),
                const SizedBox(width: 10),
                Text(
                  'Registrar Sessão de Estudo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Language selector
            Text(
              'IDIOMA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: languages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final lang = languages[index];
                  final isSelected = _selectedLanguageId == lang.id;
                  final color = Color(lang.colorValue);

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedLanguageId = lang.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected ? LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.25),
                            color.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ) : null,
                        color: isSelected ? null : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? color : colors.outline.withValues(alpha: 0.1),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                lang.flag,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            lang.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? color : colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Activity type selector
            Text(
              'ATIVIDADE',
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
              runSpacing: 8,
              children: StudyActivityTypes.all.map((activity) {
                final isSelected = _selectedActivity == activity['id'];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedActivity = activity['id']);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary.withValues(alpha: 0.15)
                          : colors.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? colors.primary
                            : colors.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          StudyActivityTypes.getIcon(activity['id']),
                          size: 16,
                          color: isSelected ? colors.primary : colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          activity['name'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? colors.primary : colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Duration selector
            Text(
              'DURAÇÃO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: _durationMinutes > 5
                            ? () => setState(() => _durationMinutes -= 5)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 32,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 20),
                      Column(
                        children: [
                          Text(
                            _formatDuration(_durationMinutes),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                          Text(
                            _durationMinutes >= 60 ? 'horas' : 'minutos',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        onPressed: _durationMinutes < 480
                            ? () => setState(() => _durationMinutes += 5)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 32,
                        color: colors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Quick duration buttons
                  Wrap(
                    spacing: 8,
                    children: [15, 30, 45, 60, 90, 120].map((mins) {
                      final isSelected = _durationMinutes == mins;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _durationMinutes = mins);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.primary.withValues(alpha: 0.2)
                                : colors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? colors.primary
                                  : colors.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            mins >= 60 ? '${mins ~/ 60}h' : '${mins}m',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              color: isSelected ? colors.primary : colors.onSurface,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Rating (optional)
            Text(
              'COMO FOI A SESSÃO? (opcional)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                final isSelected = _rating != null && _rating! >= starValue;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (_rating == starValue) {
                        _rating = null;
                      } else {
                        _rating = starValue;
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 36,
                      color: isSelected ? Colors.amber : colors.onSurfaceVariant,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Resource (optional)
            TextField(
              controller: _resourceController,
              style: TextStyle(color: colors.onSurface),
              decoration: InputDecoration(
                labelText: 'Recurso usado (opcional)',
                hintText: 'Ex: Duolingo, livro, série...',
                hintStyle: TextStyle(color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
                labelStyle: TextStyle(color: colors.onSurfaceVariant),
                prefixIcon: Icon(Icons.book_outlined, color: colors.onSurfaceVariant),
                filled: true,
                fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes (optional)
            TextField(
              controller: _notesController,
              style: TextStyle(color: colors.onSurface),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notas (opcional)',
                hintText: 'O que você estudou hoje?',
                hintStyle: TextStyle(color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
                labelStyle: TextStyle(color: colors.onSurfaceVariant),
                prefixIcon: Icon(Icons.notes, color: colors.onSurfaceVariant),
                filled: true,
                fillColor: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedLanguageId == null ? null : _saveSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: colors.surfaceContainerHighest,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check),
                    SizedBox(width: 8),
                    Text('Registrar Sessão', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours:00';
      }
      return '$hours:${mins.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _saveSession() async {
    if (_selectedLanguageId == null) return;

    await widget.repository.addSession(
      languageId: _selectedLanguageId!,
      durationMinutes: _durationMinutes,
      activityType: _selectedActivity,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      rating: _rating,
      resource: _resourceController.text.isEmpty ? null : _resourceController.text,
    );

    if (mounted) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Text('Sessão de $_durationMinutes min registrada! 🎉'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}
