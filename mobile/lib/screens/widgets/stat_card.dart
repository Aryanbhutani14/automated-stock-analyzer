import 'package:flutter/material.dart';
import '../../core/theme.dart';

class StatCard extends StatelessWidget {
  final String  label;
  final String  value;
  final String? sub;
  final Color?  color;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.sub,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:  MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color ?? AppTheme.textPrimary)),
          if (sub != null)
            Text(sub!,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    ),
  );
}
