import 'package:flame/components.dart' show Vector2;

import 'controls_config.dart';

/// One enterable building: where its door sits on the campus map, which
/// interior map it leads to, and where the player appears on each side.
///
/// Doors are `warp` tiles in the tileset and are flanked/topped by wall
/// tiles, so the only way onto one is walking up from the tile in front of
/// it - buildings can only be entered from the front.
class DoorConfig {
  const DoorConfig({
    required this.id,
    required this.doorTile,
    required this.interiorMap,
    this.interiorSpawn = const (5, 6),
  });

  final String id;

  /// Grid position of the door tile on the campus map.
  final (int, int) doorTile;

  /// `.tmx` file under `assets/tiles/`.
  final String interiorMap;

  /// Where the player appears inside (just in front of the exit mat).
  final (int, int) interiorSpawn;

  Vector2 get interiorSpawnVector => Vector2(interiorSpawn.$1.toDouble(), interiorSpawn.$2.toDouble());

  /// Where the player appears outside after leaving: the tile in front of
  /// the door, facing away from it.
  Vector2 get outdoorExitSpawn => Vector2(doorTile.$1.toDouble(), doorTile.$2 + 1.0);

  static const GameDirection exitFacing = GameDirection.down;
  static const GameDirection enterFacing = GameDirection.up;
}

class Doors {
  Doors._();

  static const all = <DoorConfig>[
    DoorConfig(id: 'library', doorTile: (5, 6), interiorMap: 'interior_library.tmx'),
    DoorConfig(id: 'hostel', doorTile: (17, 6), interiorMap: 'interior_hostel.tmx'),
    DoorConfig(id: 'club_room', doorTile: (5, 13), interiorMap: 'interior_club.tmx'),
    DoorConfig(id: 'cafeteria', doorTile: (17, 13), interiorMap: 'interior_cafeteria.tmx'),
  ];

  static DoorConfig? atTile(int x, int y) {
    for (final door in all) {
      if (door.doorTile.$1 == x && door.doorTile.$2 == y) {
        return door;
      }
    }
    return null;
  }
}
