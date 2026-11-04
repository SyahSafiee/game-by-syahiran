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
    this.backDoorTile,
    this.backInteriorSpawn = const (5, 2),
  });

  final String id;

  /// Grid position of the door tile on the campus map.
  final (int, int) doorTile;

  /// `.tmx` file under `assets/tiles/`.
  final String interiorMap;

  /// Where the player appears inside (just in front of the exit mat).
  final (int, int) interiorSpawn;

  /// Optional rear entrance (only some buildings have one). It sits in the
  /// building's top edge and is entered from the tile north of it, walking
  /// down; the interior has a matching back door tile (`backExit`).
  final (int, int)? backDoorTile;

  /// Where the player appears inside after entering through the back door
  /// (just in front of the interior's back door).
  final (int, int) backInteriorSpawn;

  Vector2 get backInteriorSpawnVector =>
      Vector2(backInteriorSpawn.$1.toDouble(), backInteriorSpawn.$2.toDouble());

  /// Outside after leaving by the back: the tile north of the back door.
  Vector2 get backOutdoorSpawn => Vector2(backDoorTile!.$1.toDouble(), backDoorTile!.$2 - 1.0);

  Vector2 get interiorSpawnVector => Vector2(interiorSpawn.$1.toDouble(), interiorSpawn.$2.toDouble());

  /// Where the player appears outside after leaving: the tile in front of
  /// the door, facing away from it.
  Vector2 get outdoorExitSpawn => Vector2(doorTile.$1.toDouble(), doorTile.$2 + 1.0);

  static const GameDirection exitFacing = GameDirection.down;
  static const GameDirection enterFacing = GameDirection.up;
  static const GameDirection backEnterFacing = GameDirection.down;
  static const GameDirection backExitFacing = GameDirection.up;
}

class Doors {
  Doors._();

  static const all = <DoorConfig>[
    DoorConfig(
      id: 'library',
      doorTile: (5, 6),
      interiorMap: 'interior_library.tmx',
      backDoorTile: (5, 2),
    ),
    DoorConfig(id: 'hostel', doorTile: (17, 6), interiorMap: 'interior_hostel.tmx'),
    DoorConfig(id: 'club_room', doorTile: (5, 13), interiorMap: 'interior_club.tmx'),
    DoorConfig(
      id: 'cafeteria',
      doorTile: (17, 13),
      interiorMap: 'interior_cafeteria.tmx',
      backDoorTile: (17, 10),
    ),
  ];

  /// The building whose front door is at [x],[y], or null.
  static DoorConfig? atTile(int x, int y) {
    for (final door in all) {
      if (door.doorTile.$1 == x && door.doorTile.$2 == y) {
        return door;
      }
    }
    return null;
  }

  /// The building whose back door is at [x],[y], or null.
  static DoorConfig? atBackTile(int x, int y) {
    for (final door in all) {
      final back = door.backDoorTile;
      if (back != null && back.$1 == x && back.$2 == y) {
        return door;
      }
    }
    return null;
  }
}
