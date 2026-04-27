import 'package:flutter/material.dart';
import '../models/issue_model.dart';
import '../screens/complaint_detail_screen.dart';
import 'status_badge.dart';
import 'package:intl/intl.dart';

class IssueCard extends StatelessWidget {
  final IssueModel issue;
  const IssueCard({super.key, required this.issue});

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Pothole': return Icons.warning_amber_rounded;
      case 'Garbage': return Icons.delete_outline;
      case 'Water Leak': return Icons.water_drop_outlined;
      case 'Streetlight': return Icons.lightbulb_outline;
      case 'Road Damage': return Icons.construction;
      default: return Icons.report_problem_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Pothole': return Colors.orange;
      case 'Garbage': return Colors.green;
      case 'Water Leak': return Colors.blue;
      case 'Streetlight': return Colors.yellow.shade700;
      case 'Road Damage': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ComplaintDetailScreen(issue: issue),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: issue.imageUrl.isNotEmpty
                  ? Image.network(
                      issue.imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                        _PlaceholderImage(
                          color: _getCategoryColor(issue.category)),
                    )
                  : _PlaceholderImage(color: _getCategoryColor(issue.category)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_getCategoryIcon(issue.category),
                            size: 14,
                            color: _getCategoryColor(issue.category)),
                        const SizedBox(width: 4),
                        Text(
                          issue.category,
                          style: TextStyle(
                              color: _getCategoryColor(issue.category),
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                        const SizedBox(width: 8),
                        _PriorityBadge(priority: issue.priority),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      issue.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        StatusBadge(status: issue.status),
                        const Spacer(),
                        Icon(Icons.thumb_up_outlined,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text('${issue.upvotes}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd MMM').format(issue.createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  final Color color;
  const _PlaceholderImage({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      color: color.withValues(alpha: 0.1),
      child: Icon(Icons.image_outlined, color: color, size: 32),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;
  const _PriorityBadge({required this.priority});

  Color get _color {
    switch (priority) {
      case 'Low':
        return Colors.green;
      case 'High':
        return Colors.orange;
      case 'Urgent':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
