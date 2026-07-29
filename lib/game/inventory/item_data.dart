import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Static definition of one item type, loaded from `lib/config/items/items.json`.
///
/// No equip/use effects yet - this phase is possession + display only.
/// [stackable] is informational for the UI (whether to show a quantity
/// badge); [InventoryModel] itself always tracks a quantity per item.
class ItemData {
  const ItemData({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.stackable,
  });

  factory ItemData.fromJson(Map<String, dynamic> json) {
    return ItemData(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      stackable: json['stackable'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final String description;

  /// Asset path to this item's icon.
  final String icon;
  final bool stackable;
}

/// Loads and caches every item definition from `lib/config/items/items.json`.
///
/// Adding a new item is purely data: append an entry to that one JSON file,
/// no Dart changes needed. [RpgGame] calls [ensureLoaded] once during
/// startup, before any dialogue effect could reference an item id.
class ItemCatalog {
  ItemCatalog._();

  static Map<String, ItemData>? _itemsById;

  static Future<void> ensureLoaded() async {
    if (_itemsById != null) {
      return;
    }
    final raw = await rootBundle.loadString('lib/config/items/items.json');
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final entries = (decoded['items'] as List).cast<Map<String, dynamic>>();
    _itemsById = {
      for (final entry in entries) entry['id'] as String: ItemData.fromJson(entry),
    };
  }

  static ItemData? byId(String id) => _itemsById?[id];

  static List<ItemData> get all => List.unmodifiable(_itemsById?.values ?? const <ItemData>[]);
}
