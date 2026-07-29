import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/painting.dart' show FilterQuality;

import '../../config/controls_config.dart';
import '../../config/game_config.dart';
import '../rpg_game.dart';

/// Internal animation states, one idle + one walk cycle per facing direction.
enum PlayerAnimState { idleDown, idleUp, idleLeft, idleRight, walkDown, walkUp, walkLeft, walkRight }

/// Grid-locked player character.
///
/// Movement is tile-by-tile (like classic GBA Pokémon games): a direction
/// input starts a glide from the current tile to the adjacent one, and no
/// new movement is accepted until that glide finishes. This keeps the player
/// always resting on an exact tile boundary, which the rest of the game
/// (collision, camera bounds, and later NPC/dialogue triggers) can rely on.
class PlayerComponent extends SpriteAnimationGroupComponent<PlayerAnimState>
    with HasGameReference<RpgGame> {
  PlayerComponent({required Vector2 startGridPosition})
    : gridPosition = startGridPosition,
      super(
        size: Vector2.all(GameConfig.displayTileSize),
        anchor: Anchor.topLeft,
      );

  /// Current tile coordinate (in grid units, not pixels). While the player is
  /// gliding between tiles this already reflects the *destination* tile.
  Vector2 gridPosition;

  GameDirection facingDirection = GameDirection.down;

  /// Direction currently held on the virtual D-pad, or null if none.
  /// Read every frame so movement repeats smoothly while the button is held.
  GameDirection? heldDirection;

  bool _isMoving = false;
  double _moveElapsed = 0;
  late Vector2 _moveFrom;
  late Vector2 _moveTo;

  static const _framePixelSize = 16.0;

  @override
  Future<void> onLoad() async {
    position = gridPosition * GameConfig.displayTileSize;

    // Loaded via a dedicated Images cache (prefix: assets/sprites/) so this
    // stays independent of flame_tiled's own image cache/prefix for the
    // assets/tiles/ folder.
    final spriteImages = Images(prefix: 'assets/sprites/');
    final image = await spriteImages.load('player_spritesheet.png');
    final sheet = SpriteSheet(image: image, srcSize: Vector2.all(_framePixelSize));

    SpriteAnimation idleAnim(int row) =>
        SpriteAnimation.spriteList([sheet.getSprite(row, 0)], stepTime: double.infinity);
    SpriteAnimation walkAnim(int row) => sheet.createAnimation(row: row, stepTime: 0.12, to: 4);

    animations = {
      PlayerAnimState.idleDown: idleAnim(0),
      PlayerAnimState.idleUp: idleAnim(1),
      PlayerAnimState.idleLeft: idleAnim(2),
      PlayerAnimState.idleRight: idleAnim(3),
      PlayerAnimState.walkDown: walkAnim(0),
      PlayerAnimState.walkUp: walkAnim(1),
      PlayerAnimState.walkLeft: walkAnim(2),
      PlayerAnimState.walkRight: walkAnim(3),
    };
    current = PlayerAnimState.idleDown;

    // Nearest-neighbor sampling keeps the upscaled pixel art crisp.
    paint.filterQuality = FilterQuality.none;
    paint.isAntiAlias = false;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isMoving) {
      _moveElapsed += dt;
      final t = (_moveElapsed / GameConfig.tileMoveDuration).clamp(0.0, 1.0);
      position = Vector2(
        _moveFrom.x + (_moveTo.x - _moveFrom.x) * t,
        _moveFrom.y + (_moveTo.y - _moveFrom.y) * t,
      );
      if (t >= 1.0) {
        _isMoving = false;
        position = _moveTo;
        _updateAnimation(moving: false);
      }
      return;
    }

    final direction = heldDirection;
    if (direction != null) {
      _tryStartMove(direction);
    }
  }

  void _tryStartMove(GameDirection direction) {
    facingDirection = direction;

    final targetGridPosition = gridPosition + _directionVector(direction);
    if (game.isTileBlocked(targetGridPosition)) {
      // Bumped into a wall/edge: face the direction but don't move,
      // matching the classic GBA "bump" feel.
      _updateAnimation(moving: false);
      return;
    }

    _isMoving = true;
    _moveElapsed = 0;
    _moveFrom = gridPosition * GameConfig.displayTileSize;
    _moveTo = targetGridPosition * GameConfig.displayTileSize;
    gridPosition = targetGridPosition;
    _updateAnimation(moving: true);
  }

  void _updateAnimation({required bool moving}) {
    current = switch (facingDirection) {
      GameDirection.down => moving ? PlayerAnimState.walkDown : PlayerAnimState.idleDown,
      GameDirection.up => moving ? PlayerAnimState.walkUp : PlayerAnimState.idleUp,
      GameDirection.left => moving ? PlayerAnimState.walkLeft : PlayerAnimState.idleLeft,
      GameDirection.right => moving ? PlayerAnimState.walkRight : PlayerAnimState.idleRight,
    };
  }

  Vector2 _directionVector(GameDirection direction) => switch (direction) {
    GameDirection.up => Vector2(0, -1),
    GameDirection.down => Vector2(0, 1),
    GameDirection.left => Vector2(-1, 0),
    GameDirection.right => Vector2(1, 0),
  };

  // --- Phase 2 hook point -------------------------------------------------
  // When NPC/dialogue triggers land, this is where an "interact" call would
  // check the tile directly in front of the player (gridPosition +
  // _directionVector(facingDirection)) for an NPC/sign/object to talk to.
  // -------------------------------------------------------------------------
}
