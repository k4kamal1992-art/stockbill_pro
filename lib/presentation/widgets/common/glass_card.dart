import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double? borderWidth;

  const GlassCard({
    super.key,
    required this.child,
    this.borderColor,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 10),
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor != null
            ? Border(left: BorderSide(color: borderColor!, width: borderWidth ?? 3))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
