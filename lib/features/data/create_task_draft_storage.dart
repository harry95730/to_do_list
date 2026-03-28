import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// In-progress "new task" form data — not a real task until the user creates one.
class CreateTaskDraft {
  const CreateTaskDraft({
    required this.name,
    required this.description,
    required this.dueMillis,
    required this.priorityIndex,
    required this.statusIndex,
    required this.dependencyIds,
    required this.recurrenceText,
  });

  final String name;
  final String description;
  final int dueMillis;
  final int priorityIndex;
  final int statusIndex;
  final List<String> dependencyIds;
  final String recurrenceText;

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'dueMillis': dueMillis,
    'priorityIndex': priorityIndex,
    'statusIndex': statusIndex,
    'dependencyIds': dependencyIds,
    'recurrenceText': recurrenceText,
  };

  factory CreateTaskDraft.fromJson(Map<String, dynamic> json) {
    return CreateTaskDraft(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dueMillis:
          (json['dueMillis'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      priorityIndex: (json['priorityIndex'] as num?)?.toInt() ?? 0,
      statusIndex: (json['statusIndex'] as num?)?.toInt() ?? 0,
      dependencyIds:
          (json['dependencyIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      recurrenceText: json['recurrenceText'] as String? ?? '',
    );
  }
}

class CreateTaskDraftStorage {
  static const _key = 'create_task_draft_v1';

  static Future<void> save(CreateTaskDraft draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(draft.toJson()));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static Future<CreateTaskDraft?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return CreateTaskDraft.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
