import 'package:flame/components.dart' show Vector2;

/// The four cardinal directions the player (and later, NPCs) can face/move.
enum GameDirection { up, down, left, right }

/// Per-direction unit offset in grid coordinates. Shared by [PlayerComponent]
/// movement and [RpgGame]'s "tile the player is facing" lookup (used for NPC
/// interaction), so both always agree on what "in front of the player" means.
extension GameDirectionVector on GameDirection {
  Vector2 get gridDelta => switch (this) {
    GameDirection.up => Vector2(0, -1),
    GameDirection.down => Vector2(0, 1),
    GameDirection.left => Vector2(-1, 0),
    GameDirection.right => Vector2(1, 0),
  };
}

/// Buttons exposed by the virtual controller overlay.
///
/// [ControllerAction.interact] talks to NPCs / advances dialogue,
/// [ControllerAction.cancel] closes dialogue early. [ControllerAction.menu]
/// is still a no-op — Phase 3 hooks a pause/inventory menu into it.
enum ControllerAction { interact, cancel, menu }

/// Signature used by the virtual controller overlay to report input to
/// whatever is listening (currently [RpgGame], eventually a higher-level
/// input router once menus/dialogue exist).
typedef DirectionCallback = void Function(GameDirection direction);
typedef DirectionStopCallback = void Function();
typedef ActionCallback = void Function(ControllerAction action);
