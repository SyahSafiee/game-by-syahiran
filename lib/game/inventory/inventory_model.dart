/// One held stack: an item id plus how many the player has.
class InventoryEntry {
  InventoryEntry({required this.itemId, required this.quantity});

  final String itemId;
  int quantity;

  Map<String, dynamic> toJson() => {'itemId': itemId, 'quantity': quantity};

  factory InventoryEntry.fromJson(Map<String, dynamic> json) {
    return InventoryEntry(
      itemId: json['itemId'] as String,
      quantity: json['quantity'] as int,
    );
  }
}

/// The player's held items: a list of `{itemId, quantity}` pairs.
///
/// Deliberately plain Dart - no Flame or Flutter imports - so it stays easy
/// to unit test and to serialize later (see [toJson]/[loadFromJson]) once
/// save/load exists. `RpgGame` owns the single instance of this and is what
/// wires it up to the UI.
class InventoryModel {
  final List<InventoryEntry> _entries = [];

  List<InventoryEntry> get entries => List.unmodifiable(_entries);

  void addItem(String itemId, {int quantity = 1}) {
    if (quantity <= 0) {
      return;
    }
    final index = _entries.indexWhere((entry) => entry.itemId == itemId);
    if (index == -1) {
      _entries.add(InventoryEntry(itemId: itemId, quantity: quantity));
    } else {
      _entries[index].quantity += quantity;
    }
  }

  /// Removes up to [quantity] of [itemId]. Returns `false` (and changes
  /// nothing) if fewer than [quantity] are held.
  bool removeItem(String itemId, {int quantity = 1}) {
    final index = _entries.indexWhere((entry) => entry.itemId == itemId);
    if (index == -1 || _entries[index].quantity < quantity) {
      return false;
    }
    _entries[index].quantity -= quantity;
    if (_entries[index].quantity == 0) {
      _entries.removeAt(index);
    }
    return true;
  }

  bool hasItem(String itemId) => getQuantity(itemId) > 0;

  int getQuantity(String itemId) {
    final index = _entries.indexWhere((entry) => entry.itemId == itemId);
    return index == -1 ? 0 : _entries[index].quantity;
  }

  List<Map<String, dynamic>> toJson() => _entries.map((entry) => entry.toJson()).toList();

  void loadFromJson(List<dynamic> json) {
    _entries
      ..clear()
      ..addAll(json.map((entry) => InventoryEntry.fromJson(entry as Map<String, dynamic>)));
  }
}
