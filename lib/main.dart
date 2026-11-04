import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/controls_config.dart';
import 'game/dialogue/dialogue_view_state.dart';
import 'game/menu_screen.dart';
import 'game/rpg_game.dart';
import 'widgets/dialogue_box.dart';
import 'widgets/menu_overlay.dart';
import 'widgets/name_entry_screen.dart';
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
  /// Null until the name-entry screen has been confirmed, at which point the
  /// game itself is created with that name baked in (see [RpgGame.playerName]).
  RpgGame? _game;

  void _startGame(String playerName) {
    setState(() {
      _game = RpgGame(playerName: playerName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    if (game == null) {
      return NameEntryScreen(onStart: _startGame);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: game)),
          ValueListenableBuilder<DialogueViewState?>(
            valueListenable: game.dialogue,
            builder: (context, dialogueState, _) {
              return ValueListenableBuilder<MenuScreen>(
                valueListenable: game.menuScreen,
                builder: (context, menuScreenState, _) {
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: VirtualControllerOverlay(
                          onDirectionPressed: game.onDirectionPressed,
                          onDirectionReleased: game.onDirectionReleased,
                          onAction: game.onAction,
                          isMovementBlocked: dialogueState != null || menuScreenState != MenuScreen.closed,
                        ),
                      ),
                      Positioned.fill(
                        child: MenuOverlay(
                          screen: menuScreenState,
                          inventory: game.inventory,
                          quests: game.quests,
                          affection: game.affection,
                          onOpenInventory: game.openInventoryScreen,
                          onOpenQuests: game.openQuestsScreen,
                          onOpenRelationships: game.openRelationshipsScreen,
                          onClose: game.closeMenu,
                          onBack: () => game.onAction(ControllerAction.cancel),
                        ),
                      ),
                      if (dialogueState != null)
                        Positioned.fill(child: DialogueBox(state: dialogueState)),
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
