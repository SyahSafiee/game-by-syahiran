import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/painting.dart' show FilterQuality;

import '../../config/controls_config.dart';
import '../../config/game_config.dart';
import '../rpg_game.dart';

/// A static, non-moving NPC placed at a fixed grid tile.
///
/// Rendering-wise this is intentionally simple (one static facing sprite,
/// no animation, no AI/movement) — the interesting behavior is entirely in
/// [RpgGame], which blocks the NPC's tile like a wall and opens dialogue
/// (looked up by [npcId] from `lib/config/dialogue/`) when the player
/// interacts with it.
///
/// `npc_spritesheet.png` holds one column per named character (see
/// [_columnForNpcId]) and one row per facing direction, so every NPC has
/// their own look (hair/skin/outfit, long vs short hair as the male/female
/// cue) instead of sharing a single generic sprite.
class NPCComponent extends SpriteComponent with HasGameReference<RpgGame> {
  NPCComponent({
    required this.npcId,
    required this.gridPosition,
    this.facing = GameDirection.down,
  }) : super(size: Vector2.all(GameConfig.displayTileSize), anchor: Anchor.topLeft);

  /// Matches a JSON file under `lib/config/dialogue/<npcId>.json`.
  final String npcId;
  final Vector2 gridPosition;
  final GameDirection facing;

  // Sprite art is drawn at 24x24 source pixels (more room for hair/face
  // detail than the map's 16x16 tile grid) but still renders at exactly
  // one displayTileSize box - independent of GameConfig.tileSize, which
  // only governs map/collision grid math, not character art resolution.
  static const _framePixelSize = 24.0;
  static const _rowForDirection = {
    GameDirection.down: 0,
    GameDirection.up: 1,
    GameDirection.left: 2,
    GameDirection.right: 3,
  };

  /// Column index of each character in `npc_spritesheet.png`. Must match
  /// the generation order used to build that sheet - adding a new NPC's
  /// dialogue file alone isn't enough, their column needs adding here too
  /// (falls back to column 0 otherwise, matching whichever character is
  /// generated first, rather than crashing).
  static const _columnForNpcId = {
    'npc_librarian': 0,
    'npc_dorm_keeper': 1,
    'npc_groundskeeper': 2,
    'npc_ajim': 3,
    'npc_amer': 4,
    'npc_john': 5,
    'npc_hariz': 6,
    'npc_intan': 7,
    'npc_aleeya': 8,
    'npc_azib': 9,
    'npc_ain_najwa': 10,
  };

  @override
  Future<void> onLoad() async {
    position = gridPosition * GameConfig.displayTileSize;

    // Dedicated Images cache (prefix: assets/sprites/), same convention as
    // PlayerComponent, kept independent of flame_tiled's own image cache.
    final npcImages = Images(prefix: 'assets/sprites/');
    final image = await npcImages.load('npc_spritesheet.png');
    final sheet = SpriteSheet(image: image, srcSize: Vector2.all(_framePixelSize));
    final column = _columnForNpcId[npcId] ?? 0;
    sprite = sheet.getSprite(_rowForDirection[facing]!, column);

    // Nearest-neighbor sampling keeps the upscaled pixel art crisp.
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;
  }
}
