import 'package:flame/cache.dart';
import 'package:flame/components.dart' show Vector2;
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/painting.dart';

import '../../config/game_config.dart';

/// Owns the tile map itself and all grid/collision bookkeeping that used to
/// live inline in `RpgGame`: loading the `.tmx`, building the walkable/
/// blocked lookup from the tileset's `collidable` custom property, and
/// answering "is this grid tile blocked" for [PlayerComponent] movement.
///
/// NPCs also occupy tiles like walls - see [blockTile], called by
/// `NpcManager` once per spawned NPC - so this is the single source of
/// truth for "can the player step here", whether the reason is terrain or
/// an NPC standing there.
class Level {
  late TiledComponent map;

  /// `true` at `x,y` (grid coordinates) if that tile blocks movement.
  final Map<String, bool> _collisionByTile = {};
  final Set<String> _warpTiles = {};
  final Set<String> _exitTiles = {};
  final Set<String> _backExitTiles = {};
  late int _mapWidthInTiles;
  late int _mapHeightInTiles;

  int get mapWidthInTiles => _mapWidthInTiles;
  int get mapHeightInTiles => _mapHeightInTiles;

  double get mapWidthPx => _mapWidthInTiles * GameConfig.displayTileSize;
  double get mapHeightPx => _mapHeightInTiles * GameConfig.displayTileSize;

  /// Loads the Degree-chapter campus map and builds the collision lookup
  /// from its `Ground` layer. Must be awaited before [isTileBlocked] or
  /// [blockTile] are used, and before [map] is added to the world.
  Future<void> load([String mapPath = GameConfig.degreeCampusMapPath]) async {
    map = await TiledComponent.load(
      mapPath,
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

    _buildCollisionMap();
  }

  void _buildCollisionMap() {
    _collisionByTile.clear();
    _warpTiles.clear();
    _exitTiles.clear();
    _backExitTiles.clear();
    final tiledMap = map.tileMap.map;
    _mapWidthInTiles = tiledMap.width;
    _mapHeightInTiles = tiledMap.height;

    final groundLayer = tiledMap.layerByName('Ground') as TileLayer;
    final data = groundLayer.tileData!;

    for (var y = 0; y < data.length; y++) {
      for (var x = 0; x < data[y].length; x++) {
        final gid = data[y][x].tile;
        final collidable = tiledMap.tileByGid(gid)?.properties.getValue<bool>('collidable') ?? false;
        if (collidable) {
          _collisionByTile[_gridKey(x, y)] = true;
        }
        final properties = tiledMap.tileByGid(gid)?.properties;
        if (properties?.getValue<bool>('warp') ?? false) {
          _warpTiles.add(_gridKey(x, y));
        }
        if (properties?.getValue<bool>('exit') ?? false) {
          _exitTiles.add(_gridKey(x, y));
        }
        if (properties?.getValue<bool>('backExit') ?? false) {
          _backExitTiles.add(_gridKey(x, y));
        }
      }
    }
  }

  String _gridKey(int x, int y) => '$x,$y';

  /// True if [gridPosition] is a building door (`warp` tile property).
  bool isWarpTile(Vector2 gridPosition) =>
      _warpTiles.contains(_gridKey(gridPosition.x.round(), gridPosition.y.round()));

  /// True if [gridPosition] is an interior's back door (`backExit` property).
  bool isBackExitTile(Vector2 gridPosition) =>
      _backExitTiles.contains(_gridKey(gridPosition.x.round(), gridPosition.y.round()));

  /// True if [gridPosition] is an interior exit mat (`exit` tile property).
  bool isExitTile(Vector2 gridPosition) =>
      _exitTiles.contains(_gridKey(gridPosition.x.round(), gridPosition.y.round()));

  /// Flags the given grid tile as blocked - used by `NpcManager` so a
  /// spawned NPC occupies its tile exactly like a wall.
  void blockTile(Vector2 gridPosition) {
    _collisionByTile[_gridKey(gridPosition.x.round(), gridPosition.y.round())] = true;
  }

  /// Whether the given grid coordinate is out of bounds or flagged
  /// `collidable` in the tileset (or occupied by an NPC via [blockTile]).
  /// Used by [PlayerComponent] before it commits to a tile-to-tile glide.
  bool isTileBlocked(Vector2 gridPosition) {
    final x = gridPosition.x.round();
    final y = gridPosition.y.round();
    if (x < 0 || y < 0 || x >= _mapWidthInTiles || y >= _mapHeightInTiles) {
      return true;
    }
    return _collisionByTile[_gridKey(x, y)] ?? false;
  }
}
