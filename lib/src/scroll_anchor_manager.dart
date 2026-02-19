import 'package:flutter/widgets.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import 'typedefs.dart';

/// Manages scroll anchoring when items are prepended to the list.
///
/// When older items are loaded (prepended), the visible items should stay
/// in place visually. This manager captures the currently visible anchor
/// item before prepend and restores the scroll position after.
class ScrollAnchorManager<T> {
  dynamic _anchorKey;
  double _anchorAlignment = 0.0;

  /// Whether an anchor has been captured and is ready to restore.
  bool get hasAnchor => _anchorKey != null;

  /// Captures the first visible item as the scroll anchor.
  ///
  /// Call this **before** the item list changes (e.g., in `didUpdateWidget`
  /// before the rebuild that adds prepended items).
  void captureAnchor({
    required List<T> currentItems,
    required ItemKeyProvider<T> keyProvider,
    required ListController listController,
  }) {
    if (currentItems.isEmpty) return;

    final range = listController.visibleRange;
    if (range == null) return;

    final (firstVisible, _) = range;
    final clampedIndex = firstVisible.clamp(0, currentItems.length - 1);
    _anchorKey = keyProvider(currentItems[clampedIndex]);
    _anchorAlignment = 0.0;
  }

  /// Restores the scroll position to the previously captured anchor item.
  ///
  /// Call this **after** the item list has been updated with prepended items,
  /// typically in a `addPostFrameCallback`.
  ///
  /// Returns `true` if the anchor was restored successfully.
  bool restoreAnchor({
    required List<T> newItems,
    required ItemKeyProvider<T> keyProvider,
    required ListController listController,
    required ScrollController scrollController,
  }) {
    if (_anchorKey == null || newItems.isEmpty) {
      _anchorKey = null;
      return false;
    }

    final newIndex = _findIndexByKey(newItems, keyProvider, _anchorKey);
    _anchorKey = null;

    if (newIndex == -1) return false;

    listController.jumpToItem(
      index: newIndex,
      scrollController: scrollController,
      alignment: _anchorAlignment,
    );
    return true;
  }

  /// Checks if items were prepended by comparing old and new lists.
  ///
  /// Returns the number of prepended items (0 if no prepend detected).
  /// The first item of [oldItems] is located in [newItems] — if it moved
  /// to a later index, items were prepended before it.
  int detectPrependCount({
    required List<T> oldItems,
    required List<T> newItems,
    required ItemKeyProvider<T> keyProvider,
  }) {
    if (oldItems.isEmpty || newItems.isEmpty) return 0;
    final oldFirstKey = keyProvider(oldItems.first);
    final indexInNew = _findIndexByKey(newItems, keyProvider, oldFirstKey);
    return indexInNew > 0 ? indexInNew : 0;
  }

  /// Clears any captured anchor.
  void clear() {
    _anchorKey = null;
  }

  int _findIndexByKey(
    List<T> items,
    ItemKeyProvider<T> keyProvider,
    dynamic key,
  ) {
    for (var i = 0; i < items.length; i++) {
      if (keyProvider(items[i]) == key) return i;
    }
    return -1;
  }
}
