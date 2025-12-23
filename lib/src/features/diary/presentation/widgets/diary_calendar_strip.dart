import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DiaryCalendarStrip extends StatefulWidget {
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onDateSelected;

  const DiaryCalendarStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<DiaryCalendarStrip> createState() => _DiaryCalendarStripState();
}

class _DiaryCalendarStripState extends State<DiaryCalendarStrip> {
  late ScrollController _scrollController;
  final int _totalDays = 30; // 30 dias de histórico

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Auto scroll para o final (hoje) após build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Tenta centralizar a data selecionada ou vai pro fim
        _scrollToSelected();
      }
    });
  }

  void _scrollToSelected() {
    // Calculo aproximado: 60px (55 width + 5 gap) por item
    // Se selecionado é null (TODOS), vai pro fim
    final maxScroll = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      maxScroll,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final theme = Theme.of(context);

    // Gerar dias: D-29 até D+0 (Hoje)
    final days = List.generate(
      _totalDays,
      (index) => now.subtract(Duration(days: _totalDays - 1 - index)),
    );

    return Column(
      children: [
        SizedBox(
          height: 85,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: days.length + 1, // +1 para o botão "Todos"
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                // Botão "Todos"
                final isSelected = widget.selectedDate == null;
                return GestureDetector(
                  onTap: () => widget.onDateSelected(null),
                  child: _buildDateItem(
                    context,
                    isAll: true,
                    isSelected: isSelected,
                    label: 'TODOS',
                    day: '∞',
                    color: isSelected
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.surfaceContainerHighest,
                    textColor: isSelected
                        ? theme.colorScheme.onSecondary
                        : theme.colorScheme.onSurface,
                  ),
                );
              }

              final date = days[index - 1];
              final isSelected =
                  widget.selectedDate != null &&
                  _isSameDay(date, widget.selectedDate!);
              final isToday = _isSameDay(date, now);

              return GestureDetector(
                onTap: () => widget.onDateSelected(isSelected ? null : date),
                child: _buildDateItem(
                  context,
                  isSelected: isSelected,
                  isToday: isToday,
                  label: DateFormat(
                    'EEE',
                    'pt_BR',
                  ).format(date).toUpperCase().replaceAll('.', ''),
                  day: date.day.toString(),
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainer,
                  textColor: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  borderColor: isToday && !isSelected
                      ? theme.colorScheme.primary
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateItem(
    BuildContext context, {
    required bool isSelected,
    bool isAll = false,
    bool isToday = false,
    required String label,
    required String day,
    required Color color,
    required Color textColor,
    Color? borderColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 55,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
        border: borderColor != null
            ? Border.all(color: borderColor, width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor.withValues(alpha: isSelected ? 1 : 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          isAll
              ? Icon(Icons.all_inclusive, size: 20, color: textColor)
              : Text(
                  day,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
