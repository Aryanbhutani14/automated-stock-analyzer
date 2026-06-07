import 'package:flutter/material.dart';
import '../../core/theme.dart';

class SignalBadge extends StatelessWidget {
  final String type; // BUY | SELL | HOLD
  const SignalBadge(this.type, {super.key});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;

    switch (type.toUpperCase()) {
      case 'BUY':
        bg = AppTheme.bullish.withOpacity(0.15);
        fg = AppTheme.bullish;
        break;
      case 'SELL':
        bg = AppTheme.bearish.withOpacity(0.15);
        fg = AppTheme.bearish;
        break;
      default:
        bg = AppTheme.surfaceAlt;
        fg = AppTheme.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withOpacity(0.5)),
      ),
      child: Text(type.toUpperCase(),
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
