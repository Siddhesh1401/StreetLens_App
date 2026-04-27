import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import '../services/firestore_service.dart';
import '../services/draft_service.dart';
import '../services/location_service.dart';
import '../models/issue_model.dart';
import '../models/issue_draft_model.dart';
import 'package:uuid/uuid.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _draftService = DraftService();
  final _locationService = LocationService();

  File? _selectedImage;
  Uint8List? _imageBytes;
  String? _selectedCategory;
  String _selectedPriority = 'Normal';
  bool _isAnonymous = false;
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  bool _isRestoringDraft = true;

  final List<Map<String, dynamic>> _categories = [
    {
      'label': 'Pothole',
      'icon': Icons.warning_amber_rounded,
      'color': Colors.orange,
    },
    {'label': 'Garbage', 'icon': Icons.delete_outline, 'color': Colors.green},
    {
      'label': 'Water Leak',
      'icon': Icons.water_drop_outlined,
      'color': Colors.blue,
    },
    {
      'label': 'Streetlight',
      'icon': Icons.lightbulb_outline,
      'color': Colors.yellow.shade700,
    },
    {'label': 'Road Damage', 'icon': Icons.construction, 'color': Colors.red},
    {'label': 'Other', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _descController.addListener(_saveDraft);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _restoreDraft();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() => _imageBytes = bytes);
      } else {
        setState(() => _selectedImage = File(picked.path));
      }
      await _saveDraft();
    }
  }

  Future<void> _restoreDraft() async {
    final draft = await _draftService.loadDraft();
    if (!mounted) return;

    if (draft == null) {
      setState(() => _isRestoringDraft = false);
      return;
    }

    setState(() {
      _descController.text = draft.description;
      _selectedCategory = draft.category;
      _selectedPriority = draft.priority;
      _isAnonymous = draft.isAnonymous;
      _latitude = draft.latitude;
      _longitude = draft.longitude;
      if (kIsWeb && draft.imageBase64 != null) {
        _imageBytes = base64Decode(draft.imageBase64!);
      } else if (!kIsWeb && draft.imagePath != null) {
        _selectedImage = File(draft.imagePath!);
      }
      _isRestoringDraft = false;
    });
  }

  Future<void> _saveDraft() async {
    if (_isRestoringDraft) return;

    final draft = IssueDraftModel(
      description: _descController.text.trim(),
      category: _selectedCategory,
      latitude: _latitude,
      longitude: _longitude,
      priority: _selectedPriority,
      isAnonymous: _isAnonymous,
      imagePath: kIsWeb ? null : _selectedImage?.path,
      imageBase64: kIsWeb && _imageBytes != null ? base64Encode(_imageBytes!) : null,
    );

    await _draftService.saveDraft(draft);
  }

  Future<bool> _checkForDuplicateIssue() async {
    if (_selectedCategory == null || _latitude == null || _longitude == null) {
      return false;
    }

    final issues = await _firestoreService.getAllIssuesOnce();
    final duplicates = issues.where((issue) {
      if (issue.category != _selectedCategory) return false;
      final distance = _distanceMeters(
        _latitude!,
        _longitude!,
        issue.latitude,
        issue.longitude,
      );
      return distance <= 120;
    }).toList();

    if (duplicates.isEmpty) return false;

    if (!mounted) return true;

    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Possible duplicate complaint'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'We found a similar complaint nearby. Review the latest ones before submitting.',
              ),
              const SizedBox(height: 12),
              ...duplicates.take(3).map(
                    (issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '• ${issue.category} - ${issue.description}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Review'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit anyway'),
          ),
        ],
      ),
    );

    return shouldContinue ?? false;
  }

  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0;
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
            cos(_degToRad(lat1)) *
                cos(_degToRad(lat2)) *
                (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (3.1415926535897932 / 180.0);

  Future<void> _detectLocation() async {
    setState(() => _isLoadingLocation = true);
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      await _saveDraft();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get location. Check permissions.'),
          ),
        );
      }
    }
    setState(() => _isLoadingLocation = false);
  }

  Future<void> _submitIssue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null && _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please detect your location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final issueId = const Uuid().v4();
      final imageUrl = kIsWeb
          ? await _firestoreService.uploadImageFromBytes(_imageBytes!, issueId)
          : await _firestoreService.uploadImage(_selectedImage!, issueId);

      final issue = IssueModel(
        issueId: issueId,
        userId: user.uid,
        imageUrl: imageUrl,
        category: _selectedCategory!,
        description: _descController.text.trim(),
        latitude: _latitude!,
        longitude: _longitude!,
        status: 'Pending',
        upvotes: 0,
        assignedWorker: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        userName: user.displayName ?? 'Citizen',
      );

      await _firestoreService.submitIssue(issue);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Issue reported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Report an Issue',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image picker
              GestureDetector(
                onTap: () => _showImageSourceSheet(),
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: (_selectedImage != null || _imageBytes != null)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: kIsWeb
                              ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                              : Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 48,
                              color: Color(0xFF1565C0),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap to add photo',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Category
              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat['label'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = cat['label']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (cat['color'] as Color).withOpacity(0.15)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? (cat['color'] as Color)
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            size: 18,
                            color: cat['color'] as Color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat['label'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? (cat['color'] as Color)
                                  : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Description
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe the issue in detail...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF1565C0)),
                  ),
                ),
                validator: (v) =>
                    v!.isEmpty ? 'Please add a description' : null,
              ),
              const SizedBox(height: 20),

              // Location
              const Text(
                'Location',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      _latitude != null
                          ? Icons.location_on
                          : Icons.location_off,
                      color: _latitude != null ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _latitude != null
                            ? 'Lat: ${_latitude!.toStringAsFixed(5)}, Lng: ${_longitude!.toStringAsFixed(5)}'
                            : 'Location not detected',
                        style: TextStyle(
                          color: _latitude != null
                              ? Colors.black87
                              : Colors.grey,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoadingLocation ? null : _detectLocation,
                      child: _isLoadingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Detect',
                              style: TextStyle(color: Color(0xFF1565C0)),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitIssue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Issue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF1565C0)),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Color(0xFF1565C0),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
