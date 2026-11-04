/// Runtime affection points for one NPC, plus the display name to show for
/// them in the Relationships panel (captured the first time affection
/// changes, from that dialogue's own `name` field).
class AffectionEntry {
  AffectionEntry({required this.npcId, required this.displayName, required this.points});

  final String npcId;
  String displayName;
  int points;

  Map<String, dynamic> toJson() => {'npcId': npcId, 'displayName': displayName, 'points': points};

  factory AffectionEntry.fromJson(Map<String, dynamic> json) {
    return AffectionEntry(
      npcId: json['npcId'] as String,
      displayName: json['displayName'] as String,
      points: json['points'] as int,
    );
  }
}

/// Named affection tiers, purely for display (e.g. in the Relationships
/// panel). Thresholds are a starting point - tune once real romance
/// questlines exist.
enum AffectionStage {
  stranger(0, 'Stranger'),
  friend(10, 'Friend'),
  closeFriend(25, 'Close Friend'),
  dating(45, 'Dating'),
  couple(70, 'Couple');

  const AffectionStage(this.threshold, this.label);

  final int threshold;
  final String label;

  static AffectionStage fromPoints(int points) {
    var stage = AffectionStage.stranger;
    for (final candidate in AffectionStage.values) {
      if (points >= candidate.threshold) {
        stage = candidate;
      }
    }
    return stage;
  }
}

/// Tracks per-NPC affection points, the "Phase 4" system the dialogue effect
/// hook in [RpgGame] was already scoped for (see `_applyDialogueEffects`).
///
/// Mirrors [InventoryModel]'s shape deliberately: plain Dart, no Flame/
/// Flutter imports, `RpgGame` owns the single instance and wires it to
/// dialogue effects (an optional `affectionDelta` field) the same way item
/// grants and quest progress are wired. [toJson]/[loadFromJson] feed
/// [GameSaveService] the same way.
///
/// Points can go negative (a breakup / falling out), there's no upper cap -
/// [AffectionStage] just labels whatever the current total is.
class AffectionModel {
  final Map<String, AffectionEntry> _byNpc = {};

  List<AffectionEntry> get entries => List.unmodifiable(_byNpc.values);

  int getPoints(String npcId) => _byNpc[npcId]?.points ?? 0;

  AffectionStage getStage(String npcId) => AffectionStage.fromPoints(getPoints(npcId));

  void addAffection(String npcId, int delta, {required String displayName}) {
    final existing = _byNpc[npcId];
    if (existing == null) {
      _byNpc[npcId] = AffectionEntry(npcId: npcId, displayName: displayName, points: delta);
    } else {
      existing.displayName = displayName;
      existing.points += delta;
    }
  }

  List<Map<String, dynamic>> toJson() => _byNpc.values.map((e) => e.toJson()).toList();

  void loadFromJson(List<dynamic> json) {
    _byNpc.clear();
    for (final raw in json) {
      final entry = AffectionEntry.fromJson(raw as Map<String, dynamic>);
      _byNpc[entry.npcId] = entry;
    }
  }
}
