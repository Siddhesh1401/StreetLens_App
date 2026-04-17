import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import '../models/issue_model.dart';

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
    await _firestore.collection('issues').doc(issueId).update({
      'status': status,
      'updated_at': DateTime.now(),
    });
  }
}
