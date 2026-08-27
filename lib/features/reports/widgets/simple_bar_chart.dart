import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/money.dart';
import '../../../services/reporting_service.dart';

class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({
    super.key,
    required this.points,
    this.showExpenses = true,
  });

  final List<MonthlyPoint> points;
  final bool showExpenses;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 160,
        child: Center(child: Text('No trend data yet.')),
      );
    }

    final maxValue = points.fold<int>(0, (max, point) {
      final localMax = showExpenses
          ? (point.revenueCents > point.expenseCents
              ? point.revenueCents
              : point.expenseCents)
          : point.revenueCents;
      return localMax > max ? localMax : max;
    });
    final chartMax = maxValue == 0 ? 1 : maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 160,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: points.map((point) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: _Bar(
                                  value: point.revenueCents,
                                  max: chartMax,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (showExpenses) ...[
                                const SizedBox(width: 2),
                                Expanded(
                                  child: _Bar(
                                    value: point.expenseCents,
                                    max: chartMax,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        point.label,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          children: [
            _Legend(color: AppColors.primary, label: 'Revenue'),
            if (showExpenses)
              _Legend(color: AppColors.warning, label: 'Expenses'),
          ],
        ),
        if (maxValue > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Scale max ${Money.formatZar(chartMax)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.max,
    required this.color,
  });

  final int value;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final heightFactor = (value / max).clamp(0.0, 1.0);
    return FractionallySizedBox(
      heightFactor: heightFactor == 0 ? 0.02 : heightFactor,
      widthFactor: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: value == 0 ? AppColors.border : color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
