import 'package:flame/components.dart' show CameraComponent;
import 'package:flame/experimental.dart' show Rectangle;

import '../../config/game_config.dart';
import '../components/player_component.dart';

/// Configures the world camera: zoom, follow-the-player, and bounds clamped
/// to the map's pixel size so it never shows past the map edge. Pulled out
/// of `RpgGame.onLoad` since it's pure camera setup, unrelated to level
/// loading/collision or NPC spawning.
class CameraManager {
  CameraManager._();

  /// Applies zoom, follow, and world-bounds to [camera]. Called once from
  /// `RpgGame.onLoad`, after the level and player are both ready (bounds
  /// need the level's pixel size, follow needs the player component).
  static void setup(
    CameraComponent camera, {
    required PlayerComponent target,
    required double mapWidthPx,
    required double mapHeightPx,
  }) {
    camera.viewfinder.zoom = GameConfig.cameraZoom;
    camera.follow(target, snap: true);
    camera.setBounds(
      Rectangle.fromLTWH(0, 0, mapWidthPx, mapHeightPx),
      considerViewport: true,
    );
  }
}
