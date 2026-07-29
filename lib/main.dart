import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/controls_config.dart';
import 'game/dialogue/dialogue_view_state.dart';
import 'game/menu_screen.dart';
import 'game/rpg_game.dart';
import 'widgets/dialogue_box.dart';
import 'widgets/menu_overlay.dart';
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
          ValueListenableBuilder<DialogueViewState?>(
            valueListenable: _game.dialogue,
            builder: (context, dialogueState, _) {
              return ValueListenableBuilder<MenuScreen>(
                valueListenable: _game.menuScreen,
                builder: (context, menuScreenState, _) {
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: VirtualControllerOverlay(
                          onDirectionPressed: _game.onDirectionPressed,
                          onDirectionReleased: _game.onDirectionReleased,
                          onAction: _game.onAction,
                          isMovementBlocked: dialogueState != null || menuScreenState != MenuScreen.closed,
                        ),
                      ),
                      Positioned.fill(
                        child: MenuOverlay(
                          screen: menuScreenState,
                          inventory: _game.inventory,
                          quests: _game.quests,
                          onOpenInventory: _game.openInventoryScreen,
                          onOpenQuests: _game.openQuestsScreen,
                          onClose: _game.closeMenu,
                          onBack: () => _game.onAction(ControllerAction.cancel),
                        ),
                      ),
                      if (dialogueState != null)
                        Positioned.fill(child: DialogueBox(state: dialogueState)),
                      // --- Phase 4 hook point ---------------------------------
                      // An affection-stat indicator would get its own layer
                      // here, driven by a new ValueNotifier on RpgGame
                      // alongside `dialogue`/`menuScreen`.
                      // ---------------------------------------------------------
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
