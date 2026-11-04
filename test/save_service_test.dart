import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:game_by_syahiran/game/inventory/inventory_model.dart';
import 'package:game_by_syahiran/game/quest/quest_data.dart';
import 'package:game_by_syahiran/game/quest/quest_model.dart';
import 'package:game_by_syahiran/game/relationship/affection_model.dart';
import 'package:game_by_syahiran/game/save/save_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('no save exists before anything is saved', () async {
    expect(await GameSaveService.hasSave(), isFalse);
    expect(await GameSaveService.load(), isNull);
  });

  test('save then load round-trips player name, inventory, quests, affection', () async {
    final inventory = InventoryModel()..addItem('old_library_key', quantity: 2);

    final quest = QuestData(
      id: 'quest_return_the_book',
      title: 'Return the Book',
      description: 'desc',
      objectives: const ['Talk to the librarian', 'Deliver the book to the dorm keeper'],
    );
    final quests = QuestModel()
      ..startQuest(quest)
      ..completeObjective(quest, 'Talk to the librarian');

    final affection = AffectionModel()
      ..addAffection('npc_ain_najwa', 5, displayName: 'Ain Najwa')
      ..addAffection('npc_ain_najwa', 7, displayName: 'Ain Najwa');

    await GameSaveService.save(
      playerName: 'Alex',
      inventory: inventory,
      quests: quests,
      affection: affection,
    );

    expect(await GameSaveService.hasSave(), isTrue);

    final loaded = await GameSaveService.load();
    expect(loaded, isNotNull);
    expect(loaded!.playerName, 'Alex');

    final restoredInventory = InventoryModel()..loadFromJson(loaded.inventoryJson);
    expect(restoredInventory.getQuantity('old_library_key'), 2);

    final restoredQuests = QuestModel()..loadFromJson(loaded.questsJson);
    expect(restoredQuests.isQuestStarted('quest_return_the_book'), isTrue);
    expect(restoredQuests.isQuestComplete('quest_return_the_book'), isFalse);
    expect(
      restoredQuests.isObjectiveComplete('quest_return_the_book', 'Talk to the librarian'),
      isTrue,
    );
    expect(
      restoredQuests.isObjectiveComplete(
        'quest_return_the_book',
        'Deliver the book to the dorm keeper',
      ),
      isFalse,
    );

    final restoredAffection = AffectionModel()..loadFromJson(loaded.affectionJson);
    expect(restoredAffection.getPoints('npc_ain_najwa'), 12);
    expect(restoredAffection.getStage('npc_ain_najwa'), AffectionStage.friend);
  });

  test('a fully-completed quest round-trips as completed', () async {
    final quest = QuestData(
      id: 'q1',
      title: 'Q1',
      description: 'desc',
      objectives: const ['step 1'],
    );
    final quests = QuestModel()
      ..startQuest(quest)
      ..completeObjective(quest, 'step 1');
    expect(quests.isQuestComplete('q1'), isTrue);

    await GameSaveService.save(
      playerName: 'Alex',
      inventory: InventoryModel(),
      quests: quests,
      affection: AffectionModel(),
    );
    final loaded = await GameSaveService.load();
    final restored = QuestModel()..loadFromJson(loaded!.questsJson);
    expect(restored.isQuestComplete('q1'), isTrue);
  });

  test('clear wipes the save', () async {
    await GameSaveService.save(
      playerName: 'Alex',
      inventory: InventoryModel(),
      quests: QuestModel(),
      affection: AffectionModel(),
    );
    expect(await GameSaveService.hasSave(), isTrue);

    await GameSaveService.clear();
    expect(await GameSaveService.hasSave(), isFalse);
    expect(await GameSaveService.load(), isNull);
  });

  test('load tolerates a corrupt/incompatible save instead of throwing', () async {
    SharedPreferences.setMockInitialValues({'game_save_v1': 'not valid json {{{'});
    expect(await GameSaveService.load(), isNull);
  });
}
