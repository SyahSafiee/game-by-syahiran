import 'package:flutter/material.dart';

import '../game/dialogue/dialogue_view_state.dart';

/// Classic GBA-style dialogue box: name tag, line of text, and a small
/// indicator showing whether pressing A advances the conversation or closes
/// it. Purely presentational — [RpgGame] owns line-advancement state.
class DialogueBox extends StatelessWidget {
  const DialogueBox({super.key, required this.state});

  final DialogueViewState state;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white70, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      state.npcName,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          state.line,
                          style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        state.isLastLine ? Icons.check_circle_outline : Icons.expand_more,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
