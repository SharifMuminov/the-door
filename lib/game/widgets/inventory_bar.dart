import 'package:flutter/material.dart';

import '../../app/settings_cubit.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/ui_text.dart';
import '../data/game_data.dart';
import '../models/inventory_item.dart';

/// Three small slots at the bottom. Tap an item to look at it again.
class InventoryBar extends StatelessWidget {
  const InventoryBar({super.key, required this.items, required this.onItemTap});

  static const slots = 3;

  final Set<ItemId> items;
  final ValueChanged<ItemId> onItemTap;

  @override
  Widget build(BuildContext context) {
    final ordered = ItemId.values
        .where(items.contains)
        .map(GameData.item)
        .toList();
    return Container(
      padding: EdgeInsets.only(
        top: 10,
        bottom: MediaQuery.paddingOf(context).bottom + 12,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF060505), AppColors.black],
        ),
        border: Border(top: BorderSide(color: AppColors.soot)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < slots; i++)
            _Slot(
              item: i < ordered.length ? ordered[i] : null,
              onTap: onItemTap,
            ),
        ],
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.item, required this.onTap});

  final InventoryItem? item;
  final ValueChanged<ItemId> onTap;

  @override
  Widget build(BuildContext context) {
    final item = this.item;
    return Semantics(
      button: item != null,
      label: context.tr(item?.name ?? UiText.emptySlot),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: item == null ? null : () => onTap(item.id),
        child: Container(
          width: 54,
          height: 54,
          margin: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: const Color(0xFF0B0909),
            border: Border.all(
              color: item == null ? AppColors.soot : AppColors.smoke,
            ),
          ),
          child: item == null
              ? null
              : TweenAnimationBuilder<double>(
                  key: ValueKey(item.id),
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                  builder: (context, t, child) => Opacity(
                    opacity: t.clamp(0, 1),
                    child: Transform.scale(scale: .6 + .4 * t, child: child),
                  ),
                  child: Icon(
                    item.icon,
                    size: 24,
                    color: AppColors.bone.withValues(alpha: .85),
                  ),
                ),
        ),
      ),
    );
  }
}
