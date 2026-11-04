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

  /// True while the B button is held; shortens the tile glide (see
  /// [GameConfig.sprintTileMoveDuration]) and skips the auto-repeat delay.
  bool isSprinting = false;

  bool _isMoving = false;
  double _moveElapsed = 0;
  double _moveDuration = GameConfig.tileMoveDuration;
  late Vector2 _moveFrom;
  late Vector2 _moveTo;

  /// Which direction the *current* press already stepped once for, or null
  /// if this press hasn't moved yet. Used (with [_heldElapsed]) to gate
  /// auto-repeat behind [GameConfig.moveRepeatDelay] - see that field's doc.
  GameDirection? _steppedDirection;
  double _heldElapsed = 0;

  // Sprite art is drawn at 24x24 source pixels (more room for hair/face
  // detail than the map's 16x16 tile grid) but still renders at exactly
  // one displayTileSize box - independent of GameConfig.tileSize, which
  // only governs map/collision grid math, not character art resolution.
  static const _framePixelSize = 24.0;

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
      final t = (_moveElapsed / _moveDuration).clamp(0.0, 1.0);
      position = Vector2(
        _moveFrom.x + (_moveTo.x - _moveFrom.x) * t,
        _moveFrom.y + (_moveTo.y - _moveFrom.y) * t,
      );
      if (t >= 1.0) {
        _isMoving = false;
        position = _moveTo;
        _updateAnimation(moving: false);
        game.onPlayerArrived(gridPosition);
      }
      return;
    }

    // Dialogue and pause-menu screens (inventory/quests/main) all freeze
    // movement so the player can't wander off mid-conversation or while
    // browsing a menu. heldDirection is intentionally left as-is (not
    // cleared) so releasing/re-pressing isn't required once the UI closes.
    if (game.isUiBlockingInput) {
      return;
    }

    final direction = heldDirection;
    if (direction == null) {
      _steppedDirection = null;
      _heldElapsed = 0;
      return;
    }

    if (direction != _steppedDirection) {
      // Either a fresh press, or the held direction just changed - either
      // way, that always moves one tile immediately, no repeat-delay wait.
      _tryStartMove(direction);
      _steppedDirection = direction;
      _heldElapsed = 0;
      return;
    }

    // Same direction still held after its first step: only start another
    // glide once the repeat-delay buffer has passed, so a normal tap (which
    // easily outlasts one glide) never produces a second, unintended tile.
    _heldElapsed += dt;
    if (isSprinting || _heldElapsed >= GameConfig.moveRepeatDelay) {
      _tryStartMove(direction);
      _heldElapsed = 0;
    }
  }

  /// Instantly places the player on [grid] facing [direction] - used for
  /// map changes (entering/leaving a building). Cancels any glide in
  /// progress and requires the next press to be a fresh one.
  void teleportTo(Vector2 grid, GameDirection direction) {
    gridPosition = grid.clone();
    position = gridPosition * GameConfig.displayTileSize;
    facingDirection = direction;
    _isMoving = false;
    _steppedDirection = null;
    _heldElapsed = 0;
    _updateAnimation(moving: false);
  }

  void _tryStartMove(GameDirection direction) {
    facingDirection = direction;

    final targetGridPosition = gridPosition + direction.gridDelta;
    if (game.isTileBlocked(targetGridPosition)) {
      // Bumped into a wall/edge: face the direction but don't move,
      // matching the classic GBA "bump" feel.
      _updateAnimation(moving: false);
      return;
    }

    _isMoving = true;
    _moveElapsed = 0;
    _moveDuration = isSprinting ? GameConfig.sprintTileMoveDuration : GameConfig.tileMoveDuration;
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

  /// The grid tile directly in front of the player, based on
  /// [facingDirection]. This is what [RpgGame] checks for an NPC when the
  /// player presses the interact button.
  Vector2 get facingGridPosition => gridPosition + facingDirection.gridDelta;
}
