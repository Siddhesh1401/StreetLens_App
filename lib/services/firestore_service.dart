import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import '../models/issue_model.dart';
import '../models/notification_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _cloudName = 'dv02anfu1';
  static const String _uploadPreset = 'streetlens_upload';

  // Upload image to Cloudinary and return download URL
  Future<String> uploadImage(File imageFile, String issueId) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['public_id'] = 'issues/$issueId'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final responseData = await response.stream.toBytes();
    final jsonData = json.decode(String.fromCharCodes(responseData));

    if (response.statusCode == 200) {
      return jsonData['secure_url'] as String;
    } else {
      throw Exception('Image upload failed: ${jsonData['error']['message']}');
    }
  }

  // Upload image from bytes (for web) to Cloudinary and return download URL
  Future<String> uploadImageFromBytes(
    Uint8List imageBytes,
    String issueId,
  ) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['public_id'] = 'issues/$issueId'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'issue_$issueId.jpg',
        ),
      );

    final response = await request.send();
    final responseData = await response.stream.toBytes();
    final jsonData = json.decode(String.fromCharCodes(responseData));

    if (response.statusCode == 200) {
      return jsonData['secure_url'] as String;
    } else {
      throw Exception('Image upload failed: ${jsonData['error']['message']}');
    }
  }

  // Submit a new issue
  Future<void> submitIssue(IssueModel issue) async {
    await _firestore.collection('issues').doc(issue.issueId).set(issue.toMap());
  }

  // Get all issues (real-time stream)
  Stream<List<IssueModel>> getAllIssues() {
    return _firestore
        .collection('issues')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => IssueModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<List<IssueModel>> getAllIssuesOnce() async {
    final snapshot = await _firestore
        .collection('issues')
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => IssueModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Get issues by current user
  Stream<List<IssueModel>> getUserIssues(String userId) {
    return _firestore
        .collection('issues')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => IssueModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort client-side to avoid needing a Firestore composite index
          docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return docs;
        });
  }

  // Get single issue by ID
  Future<IssueModel?> getIssueById(String issueId) async {
    final doc = await _firestore.collection('issues').doc(issueId).get();
    if (doc.exists) {
      return IssueModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // Upvote an issue
  Future<void> upvoteIssue(String issueId) async {
    await _firestore.collection('issues').doc(issueId).update({
      'upvotes': FieldValue.increment(1),
    });
  }

  // Update issue status (admin)
  Future<void> updateIssueStatus(String issueId, String status) async {
    final issueRef = _firestore.collection('issues').doc(issueId);
    final issueSnap = await issueRef.get();
    if (!issueSnap.exists) {
      throw Exception('Issue not found');
    }

    final issueData = issueSnap.data() ?? {};
    final previousStatus = issueData['status'] as String? ?? 'Pending';
    final userId = issueData['user_id'] as String? ?? '';
    final userName = issueData['user_name'] as String? ?? 'Citizen';
    final category = issueData['category'] as String? ?? 'issue';

    await issueRef.update({
      'status': status,
      'updated_at': DateTime.now(),
    });

    if (userId.isNotEmpty && previousStatus != status) {
      final notification = NotificationModel(
        notificationId: '',
        userId: userId,
        issueId: issueId,
        title: 'Your $category has been updated',
        body: '$userName\'s complaint is now marked as $status.',
        type: 'status_update',
        isRead: false,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('notifications').add(notification.toMap());
    }
  }

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    if (userId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<int> getUnreadNotificationCount(String userId) {
    if (userId.isEmpty) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('user_id', isEqualTo: userId)
        .where('is_read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'is_read': true,
    });
  }
}
