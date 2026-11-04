import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../inventory/inventory_model.dart';
import '../quest/quest_model.dart';
import '../relationship/affection_model.dart';

/// Snapshot of everything [GameSaveService] persists: the player's chosen
/// name plus their inventory/quest/affection progress. Read back on launch
/// to resume exactly where the last session left off.
class SaveData {
  const SaveData({
    required this.playerName,
    required this.inventoryJson,
    required this.questsJson,
    required this.affectionJson,
  });

  final String playerName;
  final List<dynamic> inventoryJson;
  final Map<String, dynamic> questsJson;
  final List<dynamic> affectionJson;
}

/// Local persistence for a single save slot, backed by [SharedPreferences].
///
/// Deliberately one slot, not a save-file list - this is a single-player
/// life story, not a game with multiple playthroughs to juggle. [RpgGame]
/// calls [save] after any dialogue effect changes inventory/quest/affection
/// state, and the app checks [load] once on startup (see `main.dart`) to
/// decide whether to resume straight into the game or show the name-entry
/// screen for a first playthrough.
class GameSaveService {
  GameSaveService._();

  static const _storageKey = 'game_save_v1';

  static Future<bool> hasSave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_storageKey);
  }

  static Future<SaveData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) {
      return null;
    }
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return SaveData(
        playerName: decoded['playerName'] as String,
        inventoryJson: decoded['inventory'] as List<dynamic>? ?? const [],
        questsJson: decoded['quests'] as Map<String, dynamic>? ?? const {},
        affectionJson: decoded['affection'] as List<dynamic>? ?? const [],
      );
    } catch (_) {
      // Corrupt/incompatible save (e.g. an older schema) - treat as if
      // there were none, rather than crashing the app on launch.
      return null;
    }
  }

  static Future<void> save({
    required String playerName,
    required InventoryModel inventory,
    required QuestModel quests,
    required AffectionModel affection,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = json.encode({
      'playerName': playerName,
      'inventory': inventory.toJson(),
      'quests': quests.toJson(),
      'affection': affection.toJson(),
    });
    await prefs.setString(_storageKey, payload);
  }

  /// Wipes the save slot, e.g. for a deliberate "New Game" restart.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
