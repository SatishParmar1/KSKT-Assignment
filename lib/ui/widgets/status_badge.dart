import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final bool isDark;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.isDark = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 13,
              color: isDark ? Colors.white : const Color(0xFF374151),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF374151),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
