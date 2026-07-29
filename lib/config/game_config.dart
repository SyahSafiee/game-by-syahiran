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
  /// prefix that flame_tiled uses by default.
  static const String testMapPath = 'test_map.tmx';

  /// Seconds it takes the player to glide from one tile to the next.
  /// Lower = snappier (Fire Red is quite fast, ~0.13-0.16s).
  static const double tileMoveDuration = 0.15;

  /// How far the camera is zoomed in. Combined with [renderScale], this
  /// controls how many tiles are visible on screen at once.
  static const double cameraZoom = 1.0;
}
