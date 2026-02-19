import 'package:flutter/widgets.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import 'list_item_alignment.dart';
import 'typedefs.dart';

/// Controls a [AnchoredPaginatedList] and provides methods to jump or
/// animate to specific items.
///
/// Attach this controller to a [AnchoredPaginatedList] via the `controller`
/// parameter. The controller must be attached before calling [jumpTo] or
/// [animateTo].
///
/// Example:
/// ```dart
/// final controller = AnchoredPaginatedListController();
///
/// AnchoredPaginatedList<MyItem>(
///   controller: controller,
///   // ...
/// );
///
/// // Later:
/// controller.jumpTo(index: 42, alignment: ListItemAlignment.center);
/// controller.jumpToKey(key: 'msg-42', alignment: ListItemAlignment.center);
/// ```
class AnchoredPaginatedListController extends ChangeNotifier {
  ListController? _listController;
  ScrollController? _scrollController;

  /// Internally maintained by the widget — items + key provider for
  /// key-based lookups.
  List<dynamic> _items = const [];
  ItemKeyProvider<dynamic>? _itemKeyProvider;

  /// Whether this controller is currently attached to a
  /// [AnchoredPaginatedList].
  bool get isAttached => _listController != null && _scrollController != null;

  /// Immediately jumps to the item at [index].
  ///
  /// The [alignment] controls where the item is positioned in the viewport:
  /// - [ListItemAlignment.top]: item at the leading edge (default)
  /// - [ListItemAlignment.center]: item centered in viewport
  /// - [ListItemAlignment.bottom]: item at the trailing edge
  ///
  /// Boundary clamping is handled automatically — if the target position
  /// would scroll past the end of the list, the list scrolls as far as
  /// possible.
  void jumpTo({
    required int index,
    ListItemAlignment alignment = ListItemAlignment.top,
  }) {
    _assertAttached();
    _listController!.jumpToItem(
      index: index,
      scrollController: _scrollController!,
      alignment: alignment.value,
    );
  }

  /// Immediately jumps to the item identified by [key].
  ///
  /// The [key] is matched against the values produced by the `itemKey`
  /// provider passed to [AnchoredPaginatedList]. This is the recommended
  /// way to jump after a windowed load (search / deep-link), because
  /// the caller doesn't need to know the item's index.
  ///
  /// Returns `true` if the item was found and the jump was performed,
  /// `false` if the key was not found in the current items list.
  ///
  /// Example — windowed search:
  /// ```dart
  /// // 1. Replace items with a window around the target.
  /// setState(() { items = await loadWindow(targetId); });
  ///
  /// // 2. Jump by key — no index calculation needed.
  /// WidgetsBinding.instance.addPostFrameCallback((_) {
  ///   controller.jumpToKey(
  ///     key: targetId,
  ///     alignment: ListItemAlignment.center,
  ///   );
  /// });
  /// ```
  bool jumpToKey({
    required dynamic key,
    ListItemAlignment alignment = ListItemAlignment.top,
  }) {
    _assertAttached();
    final index = _findIndexByKey(key);
    if (index == -1) return false;
    _listController!.jumpToItem(
      index: index,
      scrollController: _scrollController!,
      alignment: alignment.value,
    );
    return true;
  }

  /// Animates to the item at [index].
  ///
  /// The [alignment] controls where the item is positioned in the viewport.
  /// See [jumpTo] for details.
  ///
  /// [duration] and [curve] are optional functions that receive the estimated
  /// distance to the target and return the animation parameters. Defaults to
  /// 300ms and [Curves.easeInOut].
  void animateTo({
    required int index,
    ListItemAlignment alignment = ListItemAlignment.top,
    Duration Function(double estimatedDistance)? duration,
    Curve Function(double estimatedDistance)? curve,
  }) {
    _assertAttached();
    _listController!.animateToItem(
      index: index,
      scrollController: _scrollController!,
      alignment: alignment.value,
      duration: duration ?? (_) => const Duration(milliseconds: 300),
      curve: curve ?? (_) => Curves.easeInOut,
    );
  }

  /// Animates to the item identified by [key].
  ///
  /// Returns `true` if the item was found and the animation started,
  /// `false` if the key was not found.
  bool animateToKey({
    required dynamic key,
    ListItemAlignment alignment = ListItemAlignment.top,
    Duration Function(double estimatedDistance)? duration,
    Curve Function(double estimatedDistance)? curve,
  }) {
    _assertAttached();
    final index = _findIndexByKey(key);
    if (index == -1) return false;
    _listController!.animateToItem(
      index: index,
      scrollController: _scrollController!,
      alignment: alignment.value,
      duration: duration ?? (_) => const Duration(milliseconds: 300),
      curve: curve ?? (_) => Curves.easeInOut,
    );
    return true;
  }

  /// Returns the range of currently visible item indices, or `null` if
  /// the list has not been laid out yet.
  (int, int)? get visibleRange {
    if (!isAttached) return null;
    return _listController!.visibleRange;
  }

  /// Called internally by the widget to attach controllers.
  void attach(
    ListController listController,
    ScrollController scrollController,
  ) {
    _listController = listController;
    _scrollController = scrollController;
    notifyListeners();
  }

  /// Called internally by the widget to update the items snapshot and
  /// key provider, so that [jumpToKey] / [animateToKey] can resolve keys.
  void updateItems(List<dynamic> items, ItemKeyProvider<dynamic> keyProvider) {
    _items = items;
    _itemKeyProvider = keyProvider;
  }

  /// Called internally by the widget to detach controllers.
  void detach() {
    _listController = null;
    _scrollController = null;
    _items = const [];
    _itemKeyProvider = null;
    notifyListeners();
  }

  int _findIndexByKey(dynamic key) {
    final keyProvider = _itemKeyProvider;
    if (keyProvider == null) return -1;
    for (var i = 0; i < _items.length; i++) {
      if (keyProvider(_items[i]) == key) return i;
    }
    return -1;
  }

  void _assertAttached() {
    assert(
      isAttached,
      'AnchoredPaginatedListController is not attached to a '
      'AnchoredPaginatedList. Did you forget to pass it to the widget?',
    );
    if (!isAttached) {
      throw StateError(
        'AnchoredPaginatedListController is not attached to a '
        'AnchoredPaginatedList.',
      );
    }
  }

  @override
  void dispose() {
    _listController = null;
    _scrollController = null;
    _items = const [];
    _itemKeyProvider = null;
    super.dispose();
  }
}
