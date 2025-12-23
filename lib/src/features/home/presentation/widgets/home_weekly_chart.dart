import 'package:flutter/material.dart';

class HomeWeeklyChart extends StatelessWidget {
  const HomeWeeklyChart({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final days = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    final todayIndex = DateTime.now().weekday - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF26A69A).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: Color(0xFF26A69A),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Atividade Semanal',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final isToday = index == todayIndex;
                final height = 15.0 + (index * 5) + (isToday ? 15 : 0);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 24,
                      height: height.clamp(10, 45),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isToday
                              ? [
                                  const Color(0xFF26A69A),
                                  const Color(0xFF26A69A).withOpacity(0.7),
                                ]
                              : [
                                  const Color(0xFF26A69A).withOpacity(0.4),
                                  const Color(0xFF26A69A).withOpacity(0.2),
                                ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      days[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        color: isToday
                            ? const Color(0xFF26A69A)
                            : colors.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
