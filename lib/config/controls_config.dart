/// The four cardinal directions the player (and later, NPCs) can face/move.
enum GameDirection { up, down, left, right }

/// Buttons exposed by the virtual controller overlay.
///
/// `interact` and `cancel` are wired up to callbacks now but intentionally
/// do nothing yet — Phase 2 (dialogue/NPC interaction) hooks into
/// [ControllerAction.interact], and menus hook into [ControllerAction.menu].
enum ControllerAction { interact, cancel, menu }

/// Signature used by the virtual controller overlay to report input to
/// whatever is listening (currently [RpgGame], eventually a higher-level
/// input router once menus/dialogue exist).
typedef DirectionCallback = void Function(GameDirection direction);
typedef DirectionStopCallback = void Function();
typedef ActionCallback = void Function(ControllerAction action);
