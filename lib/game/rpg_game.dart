import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;

import '../config/controls_config.dart';
import 'components/player_component.dart';
import 'dialogue/dialogue_view_state.dart';
import 'inventory/inventory_model.dart';
import 'inventory/item_data.dart';
import 'levels/level.dart';
import 'managers/camera_manager.dart';
import 'managers/dialogue_manager.dart';
import 'managers/input_manager.dart';
import 'managers/menu_manager.dart';
import 'managers/npc_manager.dart';
import 'menu_screen.dart';
import 'quest/quest_data.dart';
import 'quest/quest_model.dart';
import 'relationship/affection_model.dart';

/// Root game instance. Acts only as the central orchestrator: it owns the
/// [Level], [NpcManager], [PlayerComponent], and the manager classes under
/// `lib/game/managers/`, wires them together in [onLoad], and forwards
/// input/UI calls to whichever manager owns that behavior. No map/collision,
/// dialogue-state, menu-state, or input-dispatch logic lives here directly
/// anymore - see the individual manager/level files for that.
class RpgGame extends FlameGame {
  RpgGame({required this.playerName}) {
    // Built eagerly (not in onLoad) because `main.dart` reads [dialogue] via
    // a ValueListenableBuilder as soon as this game object exists, before
    // onLoad has had a chance to run.
    dialogueManager = DialogueManager(
      playerName: playerName,
      inventory: inventory,
      quests: quests,
      affection: affection,
    );
  }

  /// Chosen on the name-entry screen before the game starts (defaults to
  /// [GameConfig.defaultPlayerName] there if left blank). Used to fill the
  /// `{playerName}` token in dialogue lines - see [DialogueManager].
  final String playerName;

  final Level level = Level();
  final NpcManager npcManager = NpcManager();
  late final PlayerComponent player;

  late final DialogueManager dialogueManager;
  final MenuManager menuManager = MenuManager();
  late final InputManager _inputManager;

  /// Player's held items and quest progress. Plain-Dart models (see their
  /// own files) - [DialogueManager] is what wires their mutations to
  /// dialogue effects; this class just exposes their current state to the
  /// menu UI.
  final InventoryModel inventory = InventoryModel();
  final QuestModel quests = QuestModel();

  /// Per-NPC romance/relationship progress (Phase 4). See
  /// [AffectionModel] - wired to dialogue the same way inventory/quests are.
  final AffectionModel affection = AffectionModel();

  /// Published for the Flutter widget tree (see `main.dart`) to render the
  /// dialogue box reactively, without reaching into game internals.
  ValueNotifier<DialogueViewState?> get dialogue => dialogueManager.state;

  /// Which pause-menu panel (if any) is open. Published the same way as
  /// [dialogue] so `main.dart` can render [MenuOverlay] reactively.
  ValueNotifier<MenuScreen> get menuScreen => menuManager.screen;

  bool get isDialogueActive => dialogueManager.isActive;

  /// True while any UI that should freeze player movement is open -
  /// dialogue, or a pause-menu screen. [PlayerComponent] checks this once
  /// per frame before accepting new movement input.
  bool get isUiBlockingInput => isDialogueActive || menuManager.isOpen;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await Future.wait([
      ItemCatalog.ensureLoaded(),
      QuestCatalog.ensureLoaded(),
    ]);

    await level.load();
    world.add(level.map);

    npcManager.spawnAll(world, level);

    player = PlayerComponent(startGridPosition: Vector2(11, 7));
    world.add(player);

    _inputManager = InputManager(
      player: player,
      npcManager: npcManager,
      dialogueManager: dialogueManager,
      menuManager: menuManager,
    );

    CameraManager.setup(
      camera,
      target: player,
      mapWidthPx: level.mapWidthPx,
      mapHeightPx: level.mapHeightPx,
    );
  }

  /// Whether the given grid coordinate is out of bounds or blocked (terrain
  /// or NPC). Used by [PlayerComponent] before it commits to a tile-to-tile
  /// glide.
  bool isTileBlocked(Vector2 gridPosition) => level.isTileBlocked(gridPosition);

  // --- Virtual controller wiring ------------------------------------------

  void onDirectionPressed(GameDirection direction) => _inputManager.onDirectionPressed(direction);

  void onDirectionReleased() => _inputManager.onDirectionReleased();

  void onSprintChanged({required bool sprinting}) => _inputManager.onSprintChanged(sprinting: sprinting);

  void onAction(ControllerAction action) => _inputManager.onAction(action);

  // --- Pause menu / inventory / quests -----------------------------------

  void openInventoryScreen() => menuManager.openInventory();

  void openQuestsScreen() => menuManager.openQuests();

  void openRelationshipsScreen() => menuManager.openRelationships();

  void closeMenu() => menuManager.close();
}
