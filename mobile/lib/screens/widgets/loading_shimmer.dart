import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme.dart';

/// Full-screen shimmer placeholder while data loads.
class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor:  AppTheme.surface,
    highlightColor: AppTheme.surfaceAlt,
    child: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 72,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
