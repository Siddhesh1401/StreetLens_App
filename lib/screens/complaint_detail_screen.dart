import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/issue_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/status_badge.dart';
import 'package:intl/intl.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final IssueModel issue;
  const ComplaintDetailScreen({super.key, required this.issue});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  late String _currentStatus;
  bool _isUpdating = false;

  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.issue.status;
  }

  Future<void> _updateStatus(String newStatus) async {
    if (newStatus == _currentStatus) return;
    setState(() => _isUpdating = true);
    try {
      await _firestoreService.updateIssueStatus(widget.issue.issueId, newStatus);
      if (mounted) {
        setState(() => _currentStatus = newStatus);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return FutureBuilder<UserModel?>(
      future: _authService.getUserData(currentUser?.uid ?? ''),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final isAdmin = userData?.role == 'admin';

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
                if (widget.issue.imageUrl.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    height: 240,
                    child: Image.network(widget.issue.imageUrl,
                        fit: BoxFit.cover),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(widget.issue.category,
                                style: const TextStyle(
                                    color: Color(0xFF1565C0),
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          StatusBadge(status: _currentStatus),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Description',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(widget.issue.description,
                          style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                              height: 1.5)),
                      const SizedBox(height: 16),
                      _InfoRow(
                        icon: Icons.location_on,
                        label: 'Location',
                        value:
                            '${widget.issue.latitude.toStringAsFixed(5)}, ${widget.issue.longitude.toStringAsFixed(5)}',
                      ),
                      _InfoRow(
                        icon: Icons.person_outline,
                        label: 'Reported by',
                        value: widget.issue.userName,
                      ),
                      _InfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Reported on',
                        value: DateFormat('dd MMM yyyy, hh:mm a')
                            .format(widget.issue.createdAt),
                      ),
                      _InfoRow(
                        icon: Icons.flag_outlined,
                        label: 'Priority',
                        value: widget.issue.priority,
                      ),
                      _InfoRow(
                        icon: Icons.update_outlined,
                        label: 'Last updated',
                        value: DateFormat('dd MMM yyyy, hh:mm a')
                            .format(widget.issue.updatedAt),
                      ),
                      if (widget.issue.assignedWorker.isNotEmpty)
                        _InfoRow(
                          icon: Icons.engineering_outlined,
                          label: 'Assigned to',
                          value: widget.issue.assignedWorker,
                        ),
                      const SizedBox(height: 20),
                      const Text('Status Timeline',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      _StatusTimeline(status: _currentStatus),
                      if (isAdmin) ...[
                        const SizedBox(height: 20),
                        const Text('Update Status',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: _currentStatus,
                            items: const [
                              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                              DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                              DropdownMenuItem(value: 'Resolved', child: Text('Resolved')),
                            ],
                            onChanged: _isUpdating
                                ? null
                                : (value) {
                                    if (value != null) {
                                      _updateStatus(value);
                                    }
                                  },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF5F6FA),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _firestoreService.upvoteIssue(widget.issue.issueId);
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
                          label: Text('Upvote (${widget.issue.upvotes})',
                              style: const TextStyle(
                                  color: Color(0xFF1565C0))),
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
      },
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
    final currentIndex = steps.indexOf(status == 'Submitted' ? 'Pending' : status);

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
