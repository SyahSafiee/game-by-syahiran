import '../../config/controls_config.dart';
import '../components/player_component.dart';
import '../dialogue/dialogue_data.dart';
import 'dialogue_manager.dart';
import 'menu_manager.dart';
import 'npc_manager.dart';

/// Routes raw input from the virtual controller (see `controls_config.dart`
/// and `VirtualControllerOverlay`) to whichever system currently owns it:
/// the player's movement, the active conversation, or the pause menu.
///
/// Pulled out of `RpgGame`, which now just forwards
/// `onDirectionPressed`/`onDirectionReleased`/`onAction` calls here - this
/// class is where the "what does the Interact/Cancel/Menu button do right
/// now" decision tree used to live inline.
class InputManager {
  InputManager({
    required this.player,
    required this.npcManager,
    required this.dialogueManager,
    required this.menuManager,
  });

  final PlayerComponent player;
  final NpcManager npcManager;
  final DialogueManager dialogueManager;
  final MenuManager menuManager;

  /// Sets the direction the virtual D-pad currently holds - read every
  /// frame by [PlayerComponent] to drive tile-to-tile movement.
  void onDirectionPressed(GameDirection direction) {
    player.heldDirection = direction;
  }

  /// Hold-to-run: the B button's press/release state. Ignored (and cleared)
  /// while UI is open so sprint can't stick on after a menu opens mid-hold.
  void onSprintChanged({required bool sprinting}) {
    player.isSprinting = sprinting;
  }

  void onDirectionReleased() {
    player.heldDirection = null;
  }

  /// Dispatches an Interact/Cancel/Menu button press. Priority order matches
  /// the original inline logic: an open conversation eats all three button
  /// meanings first, then an open pause-menu panel, then normal overworld
  /// behavior (talk to whatever NPC the player faces / open the menu).
  void onAction(ControllerAction action) {
    if (dialogueManager.isActive) {
      switch (action) {
        case ControllerAction.interact:
          dialogueManager.advance();
          break;
        case ControllerAction.cancel:
          dialogueManager.close();
          break;
        case ControllerAction.menu:
          // Menu is suppressed while a conversation is open.
          break;
      }
      return;
    }

    if (menuManager.isOpen) {
      switch (action) {
        case ControllerAction.cancel:
          menuManager.back();
          break;
        case ControllerAction.menu:
          // Pressing Menu again from anywhere inside it closes it entirely.
          menuManager.close();
          break;
        case ControllerAction.interact:
          // Menu options are tapped directly (see MenuOverlay); interact
          // has no separate "confirm selection" role here.
          break;
      }
      return;
    }

    switch (action) {
      case ControllerAction.interact:
        _tryStartDialogueWithFacingNpc();
        break;
      case ControllerAction.cancel:
        break;
      case ControllerAction.menu:
        menuManager.openMain();
        break;
    }
  }

  Future<void> _tryStartDialogueWithFacingNpc() async {
    final npc = npcManager.at(player.facingGridPosition);
    if (npc == null) {
      return;
    }

    final data = await DialogueLoader.load(npc.npcId);
    dialogueManager.start(data);
  }
}
