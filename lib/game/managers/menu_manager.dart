import 'package:flutter/foundation.dart' show ValueNotifier;

import '../menu_screen.dart';

/// Owns which pause-menu panel (if any) is open, and the "back" navigation
/// between panels. Pulled out of `RpgGame`, which now just forwards
/// cancel/menu presses here while a panel is open.
class MenuManager {
  /// Published for the Flutter widget tree (see `main.dart`) to render
  /// [MenuOverlay] reactively.
  final ValueNotifier<MenuScreen> screen = ValueNotifier(MenuScreen.closed);

  bool get isOpen => screen.value != MenuScreen.closed;

  void openInventory() => screen.value = MenuScreen.inventory;

  void openQuests() => screen.value = MenuScreen.quests;

  void openRelationships() => screen.value = MenuScreen.relationships;

  void openMain() => screen.value = MenuScreen.main;

  void close() => screen.value = MenuScreen.closed;

  /// Steps one level back (sub-panel -> main -> closed), or does nothing if
  /// already closed.
  void back() {
    switch (screen.value) {
      case MenuScreen.closed:
        break;
      case MenuScreen.main:
        screen.value = MenuScreen.closed;
        break;
      case MenuScreen.inventory:
      case MenuScreen.quests:
      case MenuScreen.relationships:
        screen.value = MenuScreen.main;
        break;
    }
  }
}
