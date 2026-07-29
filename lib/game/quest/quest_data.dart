import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Static definition of one quest, loaded from `lib/config/quests/quests.json`.
///
/// [objectives] is a plain string checklist for now (no branching, no
/// ordering requirements between objectives). The JSON's own `completed`
/// field is just a content-authoring default (always `false`) - actual
/// progress is tracked at runtime by [QuestModel], never on this static
/// definition.
class QuestData {
  const QuestData({
    required this.id,
    required this.title,
    required this.description,
    required this.objectives,
  });

  factory QuestData.fromJson(Map<String, dynamic> json) {
    return QuestData(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      objectives: List<String>.from(json['objectives'] as List),
    );
  }

  final String id;
  final String title;
  final String description;
  final List<String> objectives;
}

/// Loads and caches every quest definition from `lib/config/quests/quests.json`.
///
/// Adding a new quest is purely data: append an entry to that one JSON file
/// and reference its id from a dialogue file's `startsQuest`/
/// `completesObjective` fields - no Dart changes needed.
class QuestCatalog {
  QuestCatalog._();

  static Map<String, QuestData>? _questsById;

  static Future<void> ensureLoaded() async {
    if (_questsById != null) {
      return;
    }
    final raw = await rootBundle.loadString('lib/config/quests/quests.json');
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final entries = (decoded['quests'] as List).cast<Map<String, dynamic>>();
    _questsById = {
      for (final entry in entries) entry['id'] as String: QuestData.fromJson(entry),
    };
  }

  static QuestData? byId(String id) => _questsById?[id];

  static List<QuestData> get all => List.unmodifiable(_questsById?.values ?? const <QuestData>[]);
}
