import 'package:flutter/material.dart';

class RecoveryBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const RecoveryBanner({
    super.key,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFD1D5DB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.restore,
            size: 18,
            color: Color(0xFF111827),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Active trip recovered from previous session. Tracking resumed.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Color(0xFF4B5563)),
            onPressed: onDismiss,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
