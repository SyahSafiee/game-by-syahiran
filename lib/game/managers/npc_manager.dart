import 'package:flame/components.dart' show Vector2, World;

import '../components/npc_component.dart';
import '../levels/level.dart';

/// Owns the Degree-chapter campus NPC roster: where each one stands, adding
/// their component to the world, and the grid-key lookup `RpgGame` uses to
/// find "the NPC the player is facing" when interact is pressed.
class NpcManager {
  final Map<String, NPCComponent> _npcsByGridKey = {};

  /// Degree-chapter campus NPCs, each keyed to a dialogue file under
  /// `lib/config/dialogue/`. Grid positions land on the path/grass tiles
  /// bordering each building footprint in `degree_campus.tmx` - see that
  /// file's generation notes for the zone layout (lecture hall/library and
  /// hostel along the row-7 corridor; club room and cafeteria along row 9;
  /// the groundskeeper on the south plaza).
  static const _placements = <(String npcId, double x, double y)>[
    // Lecture hall / library corridor (row 7, west block)
    ('npc_librarian', 4, 7),
    ('npc_ajim', 3, 7),
    ('npc_amer', 7, 7),
    // Hostel corridor (row 7, east block)
    ('npc_dorm_keeper', 18, 7),
    ('npc_john', 15, 7),
    ('npc_hariz', 19, 7),
    // North lawn, above the lecture hall
    ('npc_intan', 3, 1),
    ('npc_aleeya', 7, 1),
    // Beside the club room door (row 14, west block); the tile directly in
    // front of the door stays free so the player can walk in
    ('npc_azib', 4, 14),
    // Beside the cafeteria door (row 14, east block)
    ('npc_ain_najwa', 18, 14),
    // South plaza
    ('npc_groundskeeper', 11, 14),
  ];

  /// Spawns every NPC into [world] and registers their tile as blocked on
  /// [level] - NPCs occupy their tile exactly like a wall.
  void spawnAll(World world, Level level) {
    for (final (npcId, x, y) in _placements) {
      final gridPosition = Vector2(x, y);
      final npc = NPCComponent(npcId: npcId, gridPosition: gridPosition);
      world.add(npc);

      _npcsByGridKey[_gridKey(gridPosition)] = npc;
      level.blockTile(gridPosition);
    }
  }

  /// Removes every spawned NPC (used when the player walks into a building).
  void clear() {
    for (final npc in _npcsByGridKey.values) {
      npc.removeFromParent();
    }
    _npcsByGridKey.clear();
  }

  /// The NPC standing at [gridPosition], if any. Used to check whether the
  /// player is facing an NPC when interact is pressed.
  NPCComponent? at(Vector2 gridPosition) => _npcsByGridKey[_gridKey(gridPosition)];

  String _gridKey(Vector2 gridPosition) => '${gridPosition.x.round()},${gridPosition.y.round()}';
}
