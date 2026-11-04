import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/controls_config.dart';
import 'game/dialogue/dialogue_view_state.dart';
import 'game/menu_screen.dart';
import 'game/rpg_game.dart';
import 'game/save/save_service.dart';
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
  /// Null while [_checkingSave] is true (still awaiting the startup save
  /// check) or once the name-entry screen is showing; set once a game has
  /// started, either resumed from a save or fresh (see
  /// [RpgGame.playerName]).
  RpgGame? _game;

  /// True only during the brief async [GameSaveService.load] check on
  /// startup, so the very first frame doesn't flash the name-entry screen
  /// before we know whether there's a save to resume instead.
  bool _checkingSave = true;

  @override
  void initState() {
    super.initState();
    _loadSaveIfAny();
  }

  Future<void> _loadSaveIfAny() async {
    final save = await GameSaveService.load();
    if (!mounted) {
      return;
    }
    if (save == null) {
      setState(() => _checkingSave = false);
      return;
    }
    final game = RpgGame(playerName: save.playerName);
    game.inventory.loadFromJson(save.inventoryJson);
    game.quests.loadFromJson(save.questsJson);
    game.affection.loadFromJson(save.affectionJson);
    setState(() {
      _game = game;
      _checkingSave = false;
    });
  }

  void _startGame(String playerName) {
    final game = RpgGame(playerName: playerName);
    // Persist immediately so progress/name survive even if the player
    // closes the app before ever finishing a conversation (the other save
    // point - see DialogueManager._applyEffects).
    GameSaveService.save(
      playerName: playerName,
      inventory: game.inventory,
      quests: game.quests,
      affection: game.affection,
    );
    setState(() => _game = game);
  }

  Future<void> _confirmNewGame() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Start a new game?', style: TextStyle(color: Colors.white)),
        content: const Text(
          "This erases your current name, inventory, quests, and relationships. This can't be undone.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start new game', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await GameSaveService.clear();
    setState(() => _game = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSave) {
      return const Scaffold(backgroundColor: Colors.black);
    }

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
                          onSprintChanged: (sprinting) => game.onSprintChanged(sprinting: sprinting),
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
                          onNewGame: _confirmNewGame,
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
