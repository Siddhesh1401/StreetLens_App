import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case 'Pending':
      case 'Submitted':
        return Colors.blue;
      case 'Resolved': return Colors.green;
      case 'In Progress': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData get _icon {
    switch (status) {
      case 'Pending':
      case 'Submitted':
        return Icons.schedule;
      case 'Resolved': return Icons.check_circle;
      case 'In Progress': return Icons.autorenew;
      default: return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 11, color: _color),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: _color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
