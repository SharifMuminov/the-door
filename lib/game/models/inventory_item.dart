import 'package:flutter/widgets.dart';

import '../../core/l10n/l_text.dart';
import 'clue.dart';

enum ItemId {
  drawerCode,
  paintingKey,
  ironKey,
  dollKey,
  portraitKey,
  diary,
  studyKey,
  key,
}

@immutable
class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.clue,
  });

  final ItemId id;
  final LText name;
  final LText description;
  final IconData icon;

  /// If set, tapping the item in the inventory shows this clue again.
  final ClueId? clue;
}
