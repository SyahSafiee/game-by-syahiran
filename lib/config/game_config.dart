/// Global tuning constants for the game world.
///
/// Centralizing these here means Phase 2+ features (bigger maps, NPCs that
/// need to know tile size, etc.) can reference the same source of truth
/// instead of hardcoding magic numbers.
class GameConfig {
  GameConfig._();

  /// Width/height of a single tile in source pixels (matches the tileset art).
  static const double tileSize = 16;

  /// How much the raw tile art is scaled up for on-screen rendering.
  /// Kept as a whole number so pixel-perfect (nearest-neighbor) scaling
  /// never produces sub-pixel blur/shimmer.
  static const double renderScale = 3;

  /// Effective on-screen size of one tile after [renderScale] is applied.
  static const double displayTileSize = tileSize * renderScale;

  /// Path to the test/placeholder map, relative to the `assets/tiles/`
  /// prefix that flame_tiled uses by default. Superseded by
  /// [degreeCampusMapPath] as the map [RpgGame] actually loads; kept around
  /// as a minimal fallback map for reference/experiments.
  static const String testMapPath = 'test_map.tmx';

  /// The Degree-chapter campus map (Chapter 4b - "University of Technology
  /// Araustralian"): lecture hall/library, hostel, cafeteria, and academic
  /// club room footprints around a central plaza. Building interiors are
  /// flat-color placeholders (see `placeholder_tileset.tsx`) pending real art.
  static const String degreeCampusMapPath = 'degree_campus.tmx';

  /// Seconds it takes the player to glide from one tile to the next.
  /// Lower = snappier (Fire Red is quite fast, ~0.13-0.16s).
  static const double tileMoveDuration = 0.15;

  /// Grace period, after the first tile of a press, before movement starts
  /// auto-repeating. Without this, any tap held even slightly longer than
  /// [tileMoveDuration] (which is most real touch taps - they easily last
  /// 150-250ms) would move 2 tiles instead of 1. A deliberate hold still
  /// produces smooth continuous movement once past this buffer.
  static const double moveRepeatDelay = 0.15;

  /// How far the camera is zoomed in. Combined with [renderScale], this
  /// controls how many tiles are visible on screen at once.
  static const double cameraZoom = 1.0;

  /// Pre-filled on the name-entry screen shown before the game starts.
  /// The player can always type over it; kept as one constant so it's easy
  /// to change later without touching the naming screen itself.
  static const String defaultPlayerName = 'Syah';
}
