import 'package:flutter/material.dart';
import '../models/issue_model.dart';
import '../services/firestore_service.dart';
import '../widgets/status_badge.dart';
import 'package:intl/intl.dart';

class ComplaintDetailScreen extends StatelessWidget {
  final IssueModel issue;
  const ComplaintDetailScreen({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Issue Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (issue.imageUrl.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 240,
                child: Image.network(issue.imageUrl, fit: BoxFit.cover),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + Status row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(issue.category,
                            style: const TextStyle(
                                color: Color(0xFF1565C0),
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      StatusBadge(status: issue.status),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const Text('Description',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(issue.description,
                      style: const TextStyle(
                          fontSize: 15, color: Colors.black87, height: 1.5)),
                  const SizedBox(height: 16),

                  // Location
                  _InfoRow(
                    icon: Icons.location_on,
                    label: 'Location',
                    value:
                        '${issue.latitude.toStringAsFixed(5)}, ${issue.longitude.toStringAsFixed(5)}',
                  ),
                  _InfoRow(
                    icon: Icons.person_outline,
                    label: 'Reported by',
                    value: issue.userName,
                  ),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Reported on',
                    value: DateFormat('dd MMM yyyy, hh:mm a')
                        .format(issue.createdAt),
                  ),
                  if (issue.assignedWorker.isNotEmpty)
                    _InfoRow(
                      icon: Icons.engineering_outlined,
                      label: 'Assigned to',
                      value: issue.assignedWorker,
                    ),

                  const SizedBox(height: 20),

                  // Status Timeline
                  const Text('Status Timeline',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _StatusTimeline(status: issue.status),

                  const SizedBox(height: 20),

                  // Upvote button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await firestoreService.upvoteIssue(issue.issueId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Upvoted!'),
                                backgroundColor: Colors.green),
                          );
                        }
                      },
                      icon: const Icon(Icons.thumb_up_outlined,
                          color: Color(0xFF1565C0)),
                      label: Text('Upvote (${issue.upvotes})',
                          style:
                              const TextStyle(color: Color(0xFF1565C0))),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFF1565C0)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(
                  color: Colors.grey, fontWeight: FontWeight.w500)),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final String status;
  const _StatusTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = ['Pending', 'In Progress', 'Resolved'];
    final currentIndex = steps.indexOf(status);

    return Row(
      children: List.generate(steps.length, (i) {
        final isCompleted = i <= currentIndex;
        final isLast = i == steps.length - 1;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? const Color(0xFF1565C0)
                            : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : Icons.circle_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(steps[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: i == currentIndex
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCompleted
                              ? const Color(0xFF1565C0)
                              : Colors.grey,
                        ),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    color: i < currentIndex
                        ? const Color(0xFF1565C0)
                        : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}
