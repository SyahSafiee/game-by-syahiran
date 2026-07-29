import 'quest_data.dart';

/// Runtime progress for one active quest: which of its objectives (matched
/// by exact text against [QuestData.objectives]) are done so far.
class QuestProgress {
  QuestProgress({required this.questId}) : completedObjectives = <String>{};

  final String questId;
  final Set<String> completedObjectives;
}

/// Tracks which quests the player has started, their objective progress,
/// and which quests are fully complete.
///
/// Deliberately plain Dart - no Flame or Flutter imports - matching
/// [InventoryModel]. `RpgGame` owns the single instance and wires it to the
/// dialogue system ([RpgGame] applies `startsQuest`/`completesObjective`
/// dialogue effects by calling into this) and to the quest log UI.
class QuestModel {
  final Map<String, QuestProgress> _active = {};
  final Set<String> _completedQuestIds = {};

  List<String> get activeQuestIds => List.unmodifiable(_active.keys);
  Set<String> get completedQuestIds => Set.unmodifiable(_completedQuestIds);

  bool isQuestStarted(String questId) =>
      _active.containsKey(questId) || _completedQuestIds.contains(questId);

  bool isQuestComplete(String questId) => _completedQuestIds.contains(questId);

  /// No-ops if [quest] is already active or already completed, so talking
  /// to the same NPC twice doesn't reset progress.
  void startQuest(QuestData quest) {
    if (isQuestStarted(quest.id)) {
      return;
    }
    _active[quest.id] = QuestProgress(questId: quest.id);
  }

  bool isObjectiveComplete(String questId, String objective) {
    if (_completedQuestIds.contains(questId)) {
      return true;
    }
    return _active[questId]?.completedObjectives.contains(objective) ?? false;
  }

  /// Marks [objective] done on [quest]. No-ops if the quest isn't active or
  /// [objective] isn't one of [quest]'s known objectives. Once every
  /// objective is complete, the quest itself moves from active to
  /// [completedQuestIds].
  void completeObjective(QuestData quest, String objective) {
    final progress = _active[quest.id];
    if (progress == null || !quest.objectives.contains(objective)) {
      return;
    }
    progress.completedObjectives.add(objective);
    if (progress.completedObjectives.length == quest.objectives.length) {
      _active.remove(quest.id);
      _completedQuestIds.add(quest.id);
    }
  }
}
