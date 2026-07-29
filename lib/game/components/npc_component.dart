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

  static const _framePixelSize = 16.0;
  static const _rowForDirection = {
    GameDirection.down: 0,
    GameDirection.up: 1,
    GameDirection.left: 2,
    GameDirection.right: 3,
  };

  @override
  Future<void> onLoad() async {
    position = gridPosition * GameConfig.displayTileSize;

    // Dedicated Images cache (prefix: assets/sprites/), same convention as
    // PlayerComponent, kept independent of flame_tiled's own image cache.
    final npcImages = Images(prefix: 'assets/sprites/');
    final image = await npcImages.load('npc_spritesheet.png');
    final sheet = SpriteSheet(image: image, srcSize: Vector2.all(_framePixelSize));
    sprite = sheet.getSprite(_rowForDirection[facing]!, 0);

    // Nearest-neighbor sampling keeps the upscaled pixel art crisp.
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;
  }
}
