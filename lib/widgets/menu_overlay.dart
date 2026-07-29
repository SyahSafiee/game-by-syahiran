import 'package:flutter/material.dart';

import '../game/inventory/inventory_model.dart';
import '../game/inventory/item_data.dart';
import '../game/menu_screen.dart';
import '../game/quest/quest_data.dart';
import '../game/quest/quest_model.dart';

/// Renders whichever pause-menu panel [screen] points at (or nothing, when
/// [MenuScreen.closed]) as a centered card - deliberately not full-screen,
/// so the virtual controller's A/B/Menu buttons stay visible and usable
/// underneath (B backs out/closes, same as the dialogue box).
///
/// Purely presentational: [RpgGame] owns `screen`/[inventory]/[quests] and
/// reacts to the on-tap callbacks by updating its own `menuScreen` notifier.
class MenuOverlay extends StatelessWidget {
  const MenuOverlay({
    super.key,
    required this.screen,
    required this.inventory,
    required this.quests,
    required this.onOpenInventory,
    required this.onOpenQuests,
    required this.onClose,
    required this.onBack,
  });

  final MenuScreen screen;
  final InventoryModel inventory;
  final QuestModel quests;
  final VoidCallback onOpenInventory;
  final VoidCallback onOpenQuests;
  final VoidCallback onClose;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    if (screen == MenuScreen.closed) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 420),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white70, width: 2),
              ),
              child: switch (screen) {
                MenuScreen.closed => const SizedBox.shrink(),
                MenuScreen.main => _MainMenuPanel(
                  onOpenInventory: onOpenInventory,
                  onOpenQuests: onOpenQuests,
                  onClose: onClose,
                ),
                MenuScreen.inventory => _InventoryPanel(inventory: inventory, onBack: onBack),
                MenuScreen.quests => _QuestLogPanel(quests: quests, onBack: onBack),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null)
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBack,
            visualDensity: VisualDensity.compact,
          ),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _MainMenuPanel extends StatelessWidget {
  const _MainMenuPanel({
    required this.onOpenInventory,
    required this.onOpenQuests,
    required this.onClose,
  });

  final VoidCallback onOpenInventory;
  final VoidCallback onOpenQuests;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _PanelHeader(title: 'Menu'),
        const SizedBox(height: 12),
        _MenuOptionButton(label: 'Inventory', onTap: onOpenInventory),
        const SizedBox(height: 8),
        _MenuOptionButton(label: 'Quests', onTap: onOpenQuests),
        const SizedBox(height: 8),
        _MenuOptionButton(label: 'Close', onTap: onClose),
      ],
    );
  }
}

class _MenuOptionButton extends StatelessWidget {
  const _MenuOptionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
        ),
      ),
    );
  }
}

class _InventoryPanel extends StatelessWidget {
  const _InventoryPanel({required this.inventory, required this.onBack});

  final InventoryModel inventory;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final entries = inventory.entries;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PanelHeader(title: 'Inventory', onBack: onBack),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No items yet.', style: TextStyle(color: Colors.white54)),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: entries.length,
              separatorBuilder: (_, _) => const Divider(color: Colors.white24, height: 12),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final item = ItemCatalog.byId(entry.itemId);
                return Row(
                  children: [
                    if (item != null)
                      Image.asset(item.icon, width: 28, height: 28, filterQuality: FilterQuality.none)
                    else
                      const SizedBox(width: 28, height: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item?.name ?? entry.itemId,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    Text('x${entry.quantity}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

class _QuestLogPanel extends StatelessWidget {
  const _QuestLogPanel({required this.quests, required this.onBack});

  final QuestModel quests;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final activeIds = quests.activeQuestIds;
    final completedIds = quests.completedQuestIds;
    final hasAny = activeIds.isNotEmpty || completedIds.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PanelHeader(title: 'Quest Log', onBack: onBack),
        const SizedBox(height: 8),
        if (!hasAny)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No quests yet.', style: TextStyle(color: Colors.white54)),
          )
        else
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final id in activeIds) _QuestEntry(quest: QuestCatalog.byId(id), quests: quests),
                for (final id in completedIds)
                  _QuestEntry(quest: QuestCatalog.byId(id), quests: quests, forceComplete: true),
              ],
            ),
          ),
      ],
    );
  }
}

class _QuestEntry extends StatelessWidget {
  const _QuestEntry({required this.quest, required this.quests, this.forceComplete = false});

  final QuestData? quest;
  final QuestModel quests;
  final bool forceComplete;

  @override
  Widget build(BuildContext context) {
    final quest = this.quest;
    if (quest == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quest.title,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(quest.description, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          for (final objective in quest.objectives)
            Row(
              children: [
                Icon(
                  forceComplete || quests.isObjectiveComplete(quest.id, objective)
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(objective, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
