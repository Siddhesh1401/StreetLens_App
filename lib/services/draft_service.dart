import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/issue_draft_model.dart';

class DraftService {
  static const String _draftKey = 'issue_report_draft';

  Future<IssueDraftModel?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null || raw.isEmpty) return null;
    return IssueDraftModel.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveDraft(IssueDraftModel draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, jsonEncode(draft.toMap()));
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }
}
