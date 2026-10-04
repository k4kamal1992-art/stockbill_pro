import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget icon;
  final EdgeInsetsGeometry margin;

  const SectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.margin = const EdgeInsets.fromLTRB(20, 16, 20, 10),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Row(
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey[600],
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
