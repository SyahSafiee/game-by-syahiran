import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart' show ValueNotifier;

import '../dialogue/dialogue_data.dart';
import '../dialogue/dialogue_view_state.dart';
import '../inventory/inventory_model.dart';
import '../quest/quest_data.dart';
import '../quest/quest_model.dart';
import '../relationship/affection_model.dart';
import '../save/save_service.dart';

/// Owns the active-conversation state machine: which dialogue is open, which
/// line it's on, and applying a dialogue's item/quest/affection effects once
/// it closes. Pulled out of `RpgGame`, which now just loads the facing NPC's
/// [DialogueData] and forwards interact/cancel presses here while [isActive]
/// is true.
class DialogueManager {
  DialogueManager({
    required this.playerName,
    required this.inventory,
    required this.quests,
    required this.affection,
  });

  /// Used to fill the `{playerName}` token in dialogue lines - see
  /// [_fillTemplate].
  final String playerName;

  final InventoryModel inventory;
  final QuestModel quests;
  final AffectionModel affection;

  /// Published for the Flutter widget tree (see `main.dart`) to render the
  /// dialogue box reactively, without reaching into game internals.
  final ValueNotifier<DialogueViewState?> state = ValueNotifier(null);

  DialogueData? _activeDialogue;
  int _lineIndex = 0;

  /// Which item ids have already been granted by a dialogue, so re-talking
  /// to the same NPC doesn't hand out duplicate copies of a one-time item.
  final Set<String> _grantedItemDialogueIds = {};

  bool get isActive => state.value != null;

  /// Starts showing [data]'s first line (a no-op if it has no lines).
  void start(DialogueData data) {
    if (data.lines.isEmpty) {
      return;
    }
    _activeDialogue = data;
    _lineIndex = 0;
    state.value = DialogueViewState(
      npcName: data.name,
      line: _fillTemplate(data.lines.first),
      isLastLine: data.lines.length == 1,
    );
  }

  /// Advances to the next line, or closes the box if this was the last one.
  void advance() {
    final data = _activeDialogue;
    if (data == null) {
      return;
    }
    if (_lineIndex >= data.lines.length - 1) {
      close();
      return;
    }
    _lineIndex++;
    state.value = DialogueViewState(
      npcName: data.name,
      line: _fillTemplate(data.lines[_lineIndex]),
      isLastLine: _lineIndex == data.lines.length - 1,
    );
  }

  /// Closes the dialogue box, however it closed (natural end or an early
  /// 'B' cancel), and applies whatever inventory/quest/affection effects it
  /// declared.
  void close() {
    final data = _activeDialogue;
    _activeDialogue = null;
    _lineIndex = 0;
    state.value = null;
    if (data != null) {
      _applyEffects(data);
    }
  }

  /// Substitutes personalization tokens into a dialogue line. Currently just
  /// `{playerName}`; a natural place to add more (e.g. a chosen family
  /// member's name) as those become dialogue-relevant.
  String _fillTemplate(String line) => line.replaceAll('{playerName}', playerName);

  /// Applies a dialogue's optional `givesItem`/`startsQuest`/
  /// `completesObjective`/`affectionDelta` fields once the conversation
  /// finishes.
  void _applyEffects(DialogueData data) {
    final itemId = data.givesItem;
    if (itemId != null && !_grantedItemDialogueIds.contains(data.id)) {
      inventory.addItem(itemId, quantity: data.givesItemQuantity);
      _grantedItemDialogueIds.add(data.id);
    }

    final questId = data.startsQuest;
    if (questId != null) {
      final quest = QuestCatalog.byId(questId);
      if (quest != null) {
        quests.startQuest(quest);
      }
    }

    final objectiveRef = data.completesObjective;
    if (objectiveRef != null) {
      final quest = QuestCatalog.byId(objectiveRef.questId);
      if (quest != null) {
        quests.completeObjective(quest, objectiveRef.objective);
      }
    }

    final affectionDelta = data.affectionDelta;
    if (affectionDelta != null && affectionDelta != 0) {
      affection.addAffection(data.id, affectionDelta, displayName: data.name);
    }

    // Fire-and-forget: a conversation closing is exactly the moments
    // inventory/quest/affection state can change, so autosave here rather
    // than on a timer. `unawaited` because nothing needs to block on a local
    // SharedPreferences write finishing.
    unawaited(
      GameSaveService.save(playerName: playerName, inventory: inventory, quests: quests, affection: affection),
    );
  }
}
