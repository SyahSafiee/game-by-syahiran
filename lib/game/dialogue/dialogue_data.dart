import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// A reference to one objective on one quest, e.g. what a dialogue's
/// `completesObjective` field points at.
class DialogueObjectiveRef {
  const DialogueObjectiveRef({required this.questId, required this.objective});

  factory DialogueObjectiveRef.fromJson(Map<String, dynamic> json) {
    return DialogueObjectiveRef(
      questId: json['questId'] as String,
      objective: json['objective'] as String,
    );
  }

  final String questId;
  final String objective;
}

/// One NPC's dialogue script, loaded from `lib/config/dialogue/<id>.json`.
///
/// Deliberately just a linear line list for this phase — no branching, no
/// choices. A later phase adding branching dialogue/quest hooks should grow
/// this model (e.g. a `List<DialogueNode>` with `next` ids) rather than
/// bolting conditionals onto [lines].
///
/// [givesItem], [startsQuest], and [completesObjective] are optional
/// inventory/quest hooks (Phase 3): when the conversation ends, [RpgGame]
/// applies whichever of these are set. Phase 4 (affection/romance) should
/// add a similarly optional field here (e.g. `affectionDelta`) rather than
/// its own separate dialogue format.
class DialogueData {
  const DialogueData({
    required this.id,
    required this.name,
    required this.portrait,
    required this.lines,
    this.givesItem,
    this.givesItemQuantity = 1,
    this.startsQuest,
    this.completesObjective,
  });

  factory DialogueData.fromJson(Map<String, dynamic> json) {
    return DialogueData(
      id: json['id'] as String,
      name: json['name'] as String,
      portrait: json['portrait'] as String? ?? '',
      lines: List<String>.from(json['lines'] as List),
      givesItem: json['givesItem'] as String?,
      givesItemQuantity: json['givesItemQuantity'] as int? ?? 1,
      startsQuest: json['startsQuest'] as String?,
      completesObjective: json['completesObjective'] == null
          ? null
          : DialogueObjectiveRef.fromJson(json['completesObjective'] as Map<String, dynamic>),
    );
  }

  final String id;
  final String name;

  /// Path to a portrait/sprite asset for this NPC. Carried through from JSON
  /// for a future dialogue-box portrait; not rendered yet in this phase.
  final String portrait;
  final List<String> lines;

  /// Item id to grant (see `lib/config/items/items.json`) when this
  /// conversation ends, or `null` for none.
  final String? givesItem;
  final int givesItemQuantity;

  /// Quest id to start (see `lib/config/quests/quests.json`) when this
  /// conversation ends, or `null` for none.
  final String? startsQuest;

  /// Quest objective to mark complete when this conversation ends, or
  /// `null` for none.
  final DialogueObjectiveRef? completesObjective;
}

/// Loads and caches [DialogueData] from the `lib/config/dialogue/` folder.
///
/// Keeping dialogue purely data-driven (JSON in, no Dart changes needed)
/// means adding a new NPC is just: write `npc_whoever.json`, list it in
/// `pubspec.yaml` assets, and reference its id when placing an [NPCComponent].
class DialogueLoader {
  DialogueLoader._();

  static final Map<String, DialogueData> _cache = {};

  static Future<DialogueData> load(String npcId) async {
    final cached = _cache[npcId];
    if (cached != null) {
      return cached;
    }
    final raw = await rootBundle.loadString('lib/config/dialogue/$npcId.json');
    final data = DialogueData.fromJson(json.decode(raw) as Map<String, dynamic>);
    _cache[npcId] = data;
    return data;
  }
}
