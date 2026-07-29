import 'package:flame/cache.dart';
import 'package:flame/experimental.dart' show Rectangle;
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/painting.dart';

import '../config/controls_config.dart';
import '../config/game_config.dart';
import 'components/player_component.dart';

/// Root game instance: owns the tile map, the player, the camera, and the
/// grid/collision bookkeeping everything else queries against.
///
/// Kept intentionally "dumb": it has no concept of dialogue, NPCs, or menus.
/// Phase 2 should add a router (e.g. an `InputRouter`) in front of
/// [onDirection]/[onAction] rather than growing this class directly.
class RpgGame extends FlameGame {
  late final TiledComponent _map;
  late final PlayerComponent player;

  /// `true` at [x, y] (grid coordinates) if that tile blocks movement.
  /// Built once from the tileset's `collidable` custom property, so adding
  /// new blocking tiles later only requires flagging them in Tiled.
  final Map<String, bool> _collisionByTile = {};
  late int _mapWidthInTiles;
  late int _mapHeightInTiles;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

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

  /// Whether the given grid coordinate is out of bounds or flagged
  /// `collidable` in the tileset. Used by [PlayerComponent] before it
  /// commits to a tile-to-tile glide.
  bool isTileBlocked(Vector2 gridPosition) {
    final x = gridPosition.x.round();
    final y = gridPosition.y.round();
    if (x < 0 || y < 0 || x >= _mapWidthInTiles || y >= _mapHeightInTiles) {
      return true;
    }
    return _collisionByTile['$x,$y'] ?? false;
  }

  // --- Virtual controller wiring ------------------------------------------

  void onDirectionPressed(GameDirection direction) {
    player.heldDirection = direction;
  }

  void onDirectionReleased() {
    player.heldDirection = null;
  }

  /// `interact`/`cancel`/`menu` are intentionally no-ops right now.
  ///
  /// Phase 2 hook point: route [ControllerAction.interact] into a dialogue
  /// system (check the tile the player is facing for an NPC/sign), route
  /// [ControllerAction.menu] into a pause/inventory menu, and use
  /// [ControllerAction.cancel] to back out of whichever UI is open.
  void onAction(ControllerAction action) {
    switch (action) {
      case ControllerAction.interact:
        break;
      case ControllerAction.cancel:
        break;
      case ControllerAction.menu:
        break;
    }
  }
}
