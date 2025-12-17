import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/engines/health_score_engine.dart';

/// Widget principal do Health Score
class HealthScoreWidget extends StatelessWidget {
  final HealthReport report;
  final VoidCallback? onTap;
  final bool compact;

  const HealthScoreWidget({
    super.key,
    required this.report,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact(context);
    }
    return _buildFull(context);
  }

  Widget _buildFull(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getLevelColor(report.level).withValues(alpha: 0.15),
              colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _getLevelColor(report.level).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            // Header com score circular
            Row(
              children: [
                _buildScoreCircle(context),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Health Score',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(report.trendIcon, style: const TextStyle(fontSize: 18)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.levelText,
                        style: TextStyle(
                          color: _getLevelColor(report.level),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Dimensões
            ...report.dimensions.map((dim) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDimensionBar(context, dim),
            )),

            // Ação prioritária
            if (report.priorityActions.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('💡', style: TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      report.priorityActions.first,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getLevelColor(report.level).withValues(alpha: 0.1),
              colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getLevelColor(report.level).withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            _buildScoreCircle(context, size: 50),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health Score',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${report.levelText} ${report.trendIcon}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCircle(BuildContext context, {double size = 70}) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: size * 0.08,
              backgroundColor: Colors.grey.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(Colors.grey.withValues(alpha: 0.1)),
            ),
          ),
          // Progress circle
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: report.overallScore / 100,
              strokeWidth: size * 0.08,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(_getLevelColor(report.level)),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Score text
          Text(
            report.overallScore.toStringAsFixed(0),
            style: TextStyle(
              fontSize: size * 0.32,
              fontWeight: FontWeight.bold,
              color: _getLevelColor(report.level),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionBar(BuildContext context, DimensionScore dim) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(dim.icon, style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            dim.name,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: dim.score / 100,
              minHeight: 8,
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(_getLevelColor(dim.level)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 35,
          child: Text(
            dim.score.toStringAsFixed(0),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: _getLevelColor(dim.level),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _getLevelColor(HealthLevel level) {
    switch (level) {
      case HealthLevel.excellent:
        return Colors.green;
      case HealthLevel.good:
        return Colors.lightGreen;
      case HealthLevel.moderate:
        return Colors.amber;
      case HealthLevel.needsAttention:
        return Colors.orange;
      case HealthLevel.critical:
        return Colors.red;
    }
  }
}

/// Widget de gauge animado do Health Score
class HealthScoreGauge extends StatefulWidget {
  final double score;
  final HealthLevel level;
  final double size;

  const HealthScoreGauge({
    super.key,
    required this.score,
    required this.level,
    this.size = 150,
  });

  @override
  State<HealthScoreGauge> createState() => _HealthScoreGaugeState();
}

class _HealthScoreGaugeState extends State<HealthScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.score).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(HealthScoreGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(begin: _animation.value, end: widget.score).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _GaugePainter(
            score: _animation.value,
            level: widget.level,
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final HealthLevel level;

  _GaugePainter({required this.score, required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 15;
    const startAngle = 2.4; // ~135 degrees
    const sweepAngle = 4.0; // ~230 degrees total

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Progress arc
    final progressSweep = (score / 100) * sweepAngle;
    final progressPaint = Paint()
      ..color = _getLevelColor(level)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      progressSweep,
      false,
      progressPaint,
    );

    // Score text
    final textPainter = TextPainter(
      text: TextSpan(
        text: score.toStringAsFixed(0),
        style: TextStyle(
          fontSize: size.width * 0.25,
          fontWeight: FontWeight.bold,
          color: _getLevelColor(level),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2 - 5),
    );

    // Label
    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'Health Score',
        style: TextStyle(
          fontSize: size.width * 0.09,
          color: Colors.grey,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      center + Offset(-labelPainter.width / 2, size.height * 0.2),
    );
  }

  Color _getLevelColor(HealthLevel level) {
    switch (level) {
      case HealthLevel.excellent:
        return Colors.green;
      case HealthLevel.good:
        return Colors.lightGreen;
      case HealthLevel.moderate:
        return Colors.amber;
      case HealthLevel.needsAttention:
        return Colors.orange;
      case HealthLevel.critical:
        return Colors.red;
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.level != level;
  }
}

/// Card de dimensão expandível
class DimensionCard extends StatefulWidget {
  final DimensionScore dimension;

  const DimensionCard({super.key, required this.dimension});

  @override
  State<DimensionCard> createState() => _DimensionCardState();
}

class _DimensionCardState extends State<DimensionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dim = widget.dimension;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _expanded = !_expanded);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(dim.icon, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dim.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: dim.score / 100,
                            minHeight: 6,
                            backgroundColor: Colors.grey.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation(_getLevelColor(dim.level)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    dim.score.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getLevelColor(dim.level),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Detalhes expandidos
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  // Fatores
                  ...dim.factors.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          e.key.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          e.value is int
                              ? e.value.toString()
                              : (e.value).toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )),

                  // Recomendações
                  if (dim.recommendations.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              dim.recommendations.first,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(HealthLevel level) {
    switch (level) {
      case HealthLevel.excellent:
        return Colors.green;
      case HealthLevel.good:
        return Colors.lightGreen;
      case HealthLevel.moderate:
        return Colors.amber;
      case HealthLevel.needsAttention:
        return Colors.orange;
      case HealthLevel.critical:
        return Colors.red;
    }
  }
}
