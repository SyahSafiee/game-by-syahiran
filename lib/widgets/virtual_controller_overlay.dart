import 'package:flutter/material.dart';

import '../config/controls_config.dart';

/// Semi-transparent on-screen controller layered over the game canvas,
/// laid out for landscape play like a classic mobile emulator: a 4-way
/// D-pad on the bottom-left, A/B buttons on the bottom-right, and the Menu
/// button centered at the bottom in between.
///
/// This widget only reports input via callbacks — it has no game logic of
/// its own, so it can be reused unchanged as menus/dialogue (Phase 2) start
/// listening to the same [onAction] callback.
class VirtualControllerOverlay extends StatelessWidget {
  const VirtualControllerOverlay({
    super.key,
    required this.onDirectionPressed,
    required this.onDirectionReleased,
    required this.onAction,
  });

  final DirectionCallback onDirectionPressed;
  final DirectionStopCallback onDirectionReleased;
  final ActionCallback onAction;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              bottom: 0,
              child: _DPad(onPressed: onDirectionPressed, onReleased: onDirectionReleased),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: _ActionButtonCluster(onAction: onAction),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _MenuButton(onAction: onAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _overlayOpacity = 0.45;
const _overlayColor = Colors.black;
const _iconColor = Colors.white;

class _DPad extends StatelessWidget {
  const _DPad({required this.onPressed, required this.onReleased});

  final DirectionCallback onPressed;
  final DirectionStopCallback onReleased;

  static const _buttonSize = 56.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _buttonSize * 3,
      height: _buttonSize * 3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: _DPadButton(
              icon: Icons.keyboard_arrow_up,
              direction: GameDirection.up,
              onPressed: onPressed,
              onReleased: onReleased,
              size: _buttonSize,
            ),
          ),
          Positioned(
            bottom: 0,
            child: _DPadButton(
              icon: Icons.keyboard_arrow_down,
              direction: GameDirection.down,
              onPressed: onPressed,
              onReleased: onReleased,
              size: _buttonSize,
            ),
          ),
          Positioned(
            left: 0,
            child: _DPadButton(
              icon: Icons.keyboard_arrow_left,
              direction: GameDirection.left,
              onPressed: onPressed,
              onReleased: onReleased,
              size: _buttonSize,
            ),
          ),
          Positioned(
            right: 0,
            child: _DPadButton(
              icon: Icons.keyboard_arrow_right,
              direction: GameDirection.right,
              onPressed: onPressed,
              onReleased: onReleased,
              size: _buttonSize,
            ),
          ),
        ],
      ),
    );
  }
}

class _DPadButton extends StatelessWidget {
  const _DPadButton({
    required this.icon,
    required this.direction,
    required this.onPressed,
    required this.onReleased,
    required this.size,
  });

  final IconData icon;
  final GameDirection direction;
  final DirectionCallback onPressed;
  final DirectionStopCallback onReleased;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onPressed(direction),
      onTapUp: (_) => onReleased(),
      onTapCancel: onReleased,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _overlayColor.withValues(alpha: _overlayOpacity),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: _iconColor, size: size * 0.6),
      ),
    );
  }
}

class _ActionButtonCluster extends StatelessWidget {
  const _ActionButtonCluster({required this.onAction});

  final ActionCallback onAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      height: 90,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: _RoundButton(
              label: 'A',
              onTap: () => onAction(ControllerAction.interact),
            ),
          ),
          Positioned(
            left: 0,
            top: 30,
            child: _RoundButton(
              label: 'B',
              onTap: () => onAction(ControllerAction.cancel),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _overlayColor.withValues(alpha: _overlayOpacity),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: _iconColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onAction});

  final ActionCallback onAction;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onAction(ControllerAction.menu),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _overlayColor.withValues(alpha: _overlayOpacity),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'MENU',
          style: TextStyle(color: _iconColor, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
