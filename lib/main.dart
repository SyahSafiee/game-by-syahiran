import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/rpg_game.dart';
import 'widgets/virtual_controller_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape + hide system UI chrome, matching a handheld-style
  // mobile game rather than a general app.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const GameApp());
}

class GameApp extends StatelessWidget {
  const GameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'game-by-syahiran',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: const ColorScheme.dark()),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final RpgGame _game;

  @override
  void initState() {
    super.initState();
    _game = RpgGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: _game)),
          Positioned.fill(
            child: VirtualControllerOverlay(
              onDirectionPressed: _game.onDirectionPressed,
              onDirectionReleased: _game.onDirectionReleased,
              onAction: _game.onAction,
            ),
          ),
          // --- Phase 2 hook point -----------------------------------------
          // A dialogue box / NPC name banner widget would be layered here,
          // above the controller overlay, driven by RpgGame.onAction's
          // ControllerAction.interact branch.
          // ------------------------------------------------------------------
        ],
      ),
    );
  }
}
