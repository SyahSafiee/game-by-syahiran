/// Immutable snapshot of "what the dialogue box should show right now",
/// published by [RpgGame] via a [ValueNotifier] so the Flutter widget tree
/// can render it without reaching into game internals.
class DialogueViewState {
  const DialogueViewState({
    required this.npcName,
    required this.line,
    required this.isLastLine,
  });

  final String npcName;
  final String line;
  final bool isLastLine;
}
