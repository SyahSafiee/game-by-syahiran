import 'package:flame/cache.dart';
import 'package:flame/experimental.dart' show Rectangle;
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/painting.dart';

import '../config/controls_config.dart';
import '../config/game_config.dart';
import 'components/npc_component.dart';
import 'components/player_component.dart';
import 'dialogue/dialogue_data.dart';
import 'dialogue/dialogue_view_state.dart';
import 'inventory/inventory_model.dart';
import 'inventory/item_data.dart';
import 'menu_screen.dart';
import 'quest/quest_data.dart';
import 'quest/quest_model.dart';

/// Root game instance: owns the tile map, the player, the camera, the
/// grid/collision bookkeeping, NPCs, dialogue state, and (as of Phase 3)
/// the inventory/quest models everything else queries against.
///
/// Kept intentionally "dumb": dialogue is a flat line sequence with no
/// branching/choices, and item/quest effects are a fixed set of optional
/// dialogue fields (see [_applyDialogueEffects]). Phase 4 (affection stat)
/// should follow the exact same pattern - a new optional `DialogueData`
/// field, applied alongside `givesItem`/`startsQuest` when dialogue closes.
class RpgGame extends FlameGame {
  late final TiledComponent _map;
  late final PlayerComponent player;

  /// `true` at [x, y] (grid coordinates) if that tile blocks movement.
  /// Built once from the tileset's `collidable` custom property (plus NPC
  /// positions, added in [_spawnNpcs]), so adding new blocking tiles later
  /// only requires flagging them in Tiled.
  final Map<String, bool> _collisionByTile = {};
  final Map<String, NPCComponent> _npcsByGridKey = {};
  late int _mapWidthInTiles;
  late int _mapHeightInTiles;

  /// Published for the Flutter widget tree (see `main.dart`) to render the
  /// dialogue box reactively, without reaching into game internals.
  final ValueNotifier<DialogueViewState?> dialogue = ValueNotifier(null);
  DialogueData? _activeDialogue;
  int _dialogueLineIndex = 0;

  /// Which item ids have already been granted by a dialogue, so re-talking
  /// to the same NPC doesn't hand out duplicate copies of a one-time item.
  final Set<String> _grantedItemDialogueIds = {};

  /// Player's held items and quest progress. Plain-Dart models (see their
  /// own files) - this class is what wires their mutations to dialogue
  /// effects and their current state to the menu UI.
  final InventoryModel inventory = InventoryModel();
  final QuestModel quests = QuestModel();

  /// Which pause-menu panel (if any) is open. Published the same way as
  /// [dialogue] so `main.dart` can render [MenuOverlay] reactively.
  final ValueNotifier<MenuScreen> menuScreen = ValueNotifier(MenuScreen.closed);

  bool get isDialogueActive => dialogue.value != null;

  /// True while any UI that should freeze player movement is open -
  /// dialogue, or a pause-menu screen. [PlayerComponent] checks this once
  /// per frame before accepting new movement input.
  bool get isUiBlockingInput => isDialogueActive || menuScreen.value != MenuScreen.closed;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await Future.wait([
      ItemCatalog.ensureLoaded(),
      QuestCatalog.ensureLoaded(),
    ]);

    _map = await TiledComponent.load(
      GameConfig.testMapPath,
      Vector2.all(GameConfig.displayTileSize),
      // flame_tiled resolves the tileset image relative to this same
      // prefix, so it must match where the .tmx/.tsx/.png actually live -
      // the default Images cache (prefix: assets/images/) would look in
      // the wrong folder otherwise.
      images: Images(prefix: 'assets/tiles/'),
      // Nearest-neighbor sampling keeps upscaled tiles crisp (pixel-perfect,
      // GBA-style) instead of blurry from the default bilinear filtering.
      layerPaintFactory: (opacity) => Paint()
        ..color = Color.fromRGBO(255, 255, 255, opacity)
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false,
    );
    world.add(_map);

    _buildCollisionMap();
    _spawnNpcs();

    player = PlayerComponent(startGridPosition: Vector2(7, 7));
    world.add(player);

    _setupCamera();
  }

  void _setupCamera() {
    camera.viewfinder.zoom = GameConfig.cameraZoom;
    camera.follow(player, snap: true);

    final mapWidthPx = _mapWidthInTiles * GameConfig.displayTileSize;
    final mapHeightPx = _mapHeightInTiles * GameConfig.displayTileSize;
    camera.setBounds(
      Rectangle.fromLTWH(0, 0, mapWidthPx, mapHeightPx),
      considerViewport: true,
    );
  }

  void _buildCollisionMap() {
    final tiledMap = _map.tileMap.map;
    _mapWidthInTiles = tiledMap.width;
    _mapHeightInTiles = tiledMap.height;

    final groundLayer = tiledMap.layerByName('Ground') as TileLayer;
    final data = groundLayer.tileData!;

    for (var y = 0; y < data.length; y++) {
      for (var x = 0; x < data[y].length; x++) {
        final gid = data[y][x].tile;
        final collidable = tiledMap.tileByGid(gid)?.properties.getValue<bool>('collidable') ?? false;
        if (collidable) {
          _collisionByTile['$x,$y'] = true;
        }
      }
    }
  }

  /// Test NPCs, each keyed to a dialogue file under `lib/config/dialogue/`.
  /// Grid positions were picked by hand to land on plain grass tiles in
  /// `test_map.tmx` (avoiding the pond, obstacles, and border walls) - swap
  /// these for real placements once campus content exists.
  void _spawnNpcs() {
    const placements = <(String npcId, double x, double y)>[
      ('npc_librarian', 2, 9), // "library" zone, west side
      ('npc_dorm_keeper', 11, 9), // "dorms" zone, east side
      ('npc_groundskeeper', 5, 1), // courtyard, north side
    ];

    for (final (npcId, x, y) in placements) {
      final gridPosition = Vector2(x, y);
      final npc = NPCComponent(npcId: npcId, gridPosition: gridPosition);
      world.add(npc);

      final key = _gridKey(gridPosition);
      _npcsByGridKey[key] = npc;
      // NPCs block movement exactly like a wall tile.
      _collisionByTile[key] = true;
    }
  }

  String _gridKey(Vector2 gridPosition) => '${gridPosition.x.round()},${gridPosition.y.round()}';

  /// Whether the given grid coordinate is out of bounds or flagged
  /// `collidable` in the tileset (or occupied by an NPC). Used by
  /// [PlayerComponent] before it commits to a tile-to-tile glide.
  bool isTileBlocked(Vector2 gridPosition) {
    final x = gridPosition.x.round();
    final y = gridPosition.y.round();
    if (x < 0 || y < 0 || x >= _mapWidthInTiles || y >= _mapHeightInTiles) {
      return true;
    }
    return _collisionByTile[_gridKey(gridPosition)] ?? false;
  }

  // --- Virtual controller wiring ------------------------------------------

  void onDirectionPressed(GameDirection direction) {
    player.heldDirection = direction;
  }

  void onDirectionReleased() {
    player.heldDirection = null;
  }

  void onAction(ControllerAction action) {
    if (isDialogueActive) {
      switch (action) {
        case ControllerAction.interact:
          _advanceDialogue();
          break;
        case ControllerAction.cancel:
          _closeDialogue();
          break;
        case ControllerAction.menu:
          // Menu is suppressed while a conversation is open.
          break;
      }
      return;
    }

    if (menuScreen.value != MenuScreen.closed) {
      switch (action) {
        case ControllerAction.cancel:
          _menuBack();
          break;
        case ControllerAction.menu:
          // Pressing Menu again from anywhere inside it closes it entirely.
          menuScreen.value = MenuScreen.closed;
          break;
        case ControllerAction.interact:
          // Menu options are tapped directly (see MenuOverlay); interact
          // has no separate "confirm selection" role here.
          break;
      }
      return;
    }

    switch (action) {
      case ControllerAction.interact:
        _tryStartDialogueWithFacingNpc();
        break;
      case ControllerAction.cancel:
        break;
      case ControllerAction.menu:
        menuScreen.value = MenuScreen.main;
        break;
    }
  }

  // --- Pause menu / inventory / quests -----------------------------------

  void openInventoryScreen() => menuScreen.value = MenuScreen.inventory;

  void openQuestsScreen() => menuScreen.value = MenuScreen.quests;

  void closeMenu() => menuScreen.value = MenuScreen.closed;

  void _menuBack() {
    switch (menuScreen.value) {
      case MenuScreen.closed:
        break;
      case MenuScreen.main:
        menuScreen.value = MenuScreen.closed;
        break;
      case MenuScreen.inventory:
      case MenuScreen.quests:
        menuScreen.value = MenuScreen.main;
        break;
    }
  }

  // --- Dialogue --------------------------------------------------------

  Future<void> _tryStartDialogueWithFacingNpc() async {
    final npc = _npcsByGridKey[_gridKey(player.facingGridPosition)];
    if (npc == null) {
      return;
    }

    final data = await DialogueLoader.load(npc.npcId);
    if (data.lines.isEmpty) {
      return;
    }

    _activeDialogue = data;
    _dialogueLineIndex = 0;
    dialogue.value = DialogueViewState(
      npcName: data.name,
      line: data.lines.first,
      isLastLine: data.lines.length == 1,
    );
  }

  /// Advances to the next line, or closes the box if this was the last one.
  void _advanceDialogue() {
    final data = _activeDialogue;
    if (data == null) {
      return;
    }
    if (_dialogueLineIndex >= data.lines.length - 1) {
      _closeDialogue();
      return;
    }
    _dialogueLineIndex++;
    dialogue.value = DialogueViewState(
      npcName: data.name,
      line: data.lines[_dialogueLineIndex],
      isLastLine: _dialogueLineIndex == data.lines.length - 1,
    );
  }

  /// Closes the dialogue box, however it closed (natural end or an early
  /// 'B' cancel), and applies whatever inventory/quest effects it declared.
  void _closeDialogue() {
    final data = _activeDialogue;
    _activeDialogue = null;
    _dialogueLineIndex = 0;
    dialogue.value = null;
    if (data != null) {
      _applyDialogueEffects(data);
    }
  }

  /// Applies a dialogue's optional `givesItem`/`startsQuest`/
  /// `completesObjective` fields once the conversation finishes.
  ///
  /// Phase 4 hook point: an affection/romance stat would plug in right here
  /// as another optional `DialogueData` field (e.g. `affectionDelta`),
  /// applied the same way as these quest/inventory effects.
  void _applyDialogueEffects(DialogueData data) {
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
  }
}
