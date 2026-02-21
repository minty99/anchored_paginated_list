import 'package:flutter/scheduler.dart';
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
  bool _disposed = false;

  /// Whether the list is currently scrolled to the bottom.
  ///
  /// For reversed lists (e.g., chat), "bottom" means the visual bottom
  /// (lowest scroll offset — newest messages). For non-reversed lists,
  /// "bottom" means the visual bottom (highest scroll offset).
  ///
  /// Updated automatically by the [AnchoredPaginatedList] widget's
  /// scroll listener based on the configured `bottomThreshold`.
  ///
  /// Defaults to `true` (assumes the list starts at the bottom).
  bool _isAtBottom = true;

  /// Whether the list is currently scrolled to the bottom.
  ///
  /// See [_isAtBottom] for details on what "bottom" means in reversed
  /// vs. non-reversed lists.
  bool get isAtBottom => _isAtBottom;

  /// Internally maintained by the widget — items + key provider for
  /// key-based lookups.
  List<dynamic> _items = const [];
  ItemKeyProvider<dynamic>? _itemKeyProvider;

  // ── Pending jump state ──────────────────────────────────────────────
  //
  // When [jumpToKey] or [animateToKey] is called with `retryIfMissing`
  // and the key is not found, a pending jump is stored. On the next
  // [updateItems] call that contains the key, the jump is automatically
  // executed. A new [jumpToKey] / [animateToKey] / [cancelPendingJump]
  // call cancels any previous pending jump via the sequence counter.
  dynamic _pendingKey;
  ListItemAlignment _pendingAlignment = ListItemAlignment.top;
  bool _pendingAnimate = false;
  Duration Function(double)? _pendingAnimateDuration;
  Curve Function(double)? _pendingAnimateCurve;
  int _pendingSequence = 0;

  /// Whether this controller is currently attached to a
  /// [AnchoredPaginatedList].
  bool get isAttached => _listController != null && _scrollController != null;

  /// Whether there is a pending jump waiting for items to update.
  bool get hasPendingJump => _pendingKey != null;

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
    _clearPending();
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
  /// When [retryIfMissing] is `true` and the key is not found, the jump
  /// is stored as pending and resolved automatically when:
  /// - The widget rebuilds with new items containing the key
  ///   (via [updateItems]), or
  /// - The key appears in the items within the next two frames
  ///   (for same-cycle state changes).
  ///
  /// A new [jumpToKey] or [animateToKey] call cancels any previously
  /// pending jump.
  ///
  /// Example — paginated search:
  /// ```dart
  /// // 1. Start loading the target item in the background.
  /// cubit.loadUntilFound(targetId);
  ///
  /// // 2. Jump by key — resolves automatically when the item is loaded.
  /// controller.jumpToKey(
  ///   key: targetId,
  ///   alignment: ListItemAlignment.center,
  ///   retryIfMissing: true,
  /// );
  /// ```
  bool jumpToKey({
    required dynamic key,
    ListItemAlignment alignment = ListItemAlignment.top,
    bool retryIfMissing = false,
  }) {
    _assertAttached();
    _clearPending();

    final index = _findIndexByKey(key);
    if (index == -1) {
      if (retryIfMissing) {
        _setPendingJump(key: key, alignment: alignment);
        _scheduleRetry(() {
          if (_pendingKey != key) return;
          final retryIndex = _findIndexByKey(key);
          if (retryIndex == -1) return;
          _clearPending();
          _listController?.jumpToItem(
            index: retryIndex,
            scrollController: _scrollController!,
            alignment: alignment.value,
          );
        });
      }
      return false;
    }
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
    _clearPending();
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
  ///
  /// When [retryIfMissing] is `true` and the key is not found, the
  /// animation is stored as pending and resolved on the next
  /// [updateItems] call that contains the key. See [jumpToKey] for
  /// details on the pending mechanism.
  bool animateToKey({
    required dynamic key,
    ListItemAlignment alignment = ListItemAlignment.top,
    Duration Function(double estimatedDistance)? duration,
    Curve Function(double estimatedDistance)? curve,
    bool retryIfMissing = false,
  }) {
    _assertAttached();
    _clearPending();

    final index = _findIndexByKey(key);
    if (index == -1) {
      if (retryIfMissing) {
        _setPendingAnimate(
          key: key,
          alignment: alignment,
          duration: duration,
          curve: curve,
        );
        _scheduleRetry(() {
          if (_pendingKey != key) return;
          final retryIndex = _findIndexByKey(key);
          if (retryIndex == -1) return;
          final d = _pendingAnimateDuration;
          final c = _pendingAnimateCurve;
          _clearPending();
          _listController?.animateToItem(
            index: retryIndex,
            scrollController: _scrollController!,
            alignment: alignment.value,
            duration: d ?? (_) => const Duration(milliseconds: 300),
            curve: c ?? (_) => Curves.easeInOut,
          );
        });
      }
      return false;
    }
    _listController!.animateToItem(
      index: index,
      scrollController: _scrollController!,
      alignment: alignment.value,
      duration: duration ?? (_) => const Duration(milliseconds: 300),
      curve: curve ?? (_) => Curves.easeInOut,
    );
    return true;
  }

  /// Cancels any pending jump or animation that was scheduled via
  /// [jumpToKey] or [animateToKey] with `retryIfMissing: true`.
  void cancelPendingJump() {
    _clearPending();
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
  ///
  /// If a pending jump is active and the new items contain the target
  /// key, the jump is resolved automatically after the current frame.
  ///
  /// Returns `true` if a pending jump was resolved by this call, meaning
  /// the caller should skip automatic scroll anchoring (the explicit jump
  /// takes priority).
  bool updateItems(List<dynamic> items, ItemKeyProvider<dynamic> keyProvider) {
    _items = items;
    _itemKeyProvider = keyProvider;
    return _tryResolvePending();
  }

  /// Called internally by the widget to detach controllers.
  ///
  /// Safe to call even after [dispose] — the call is silently ignored
  /// if the controller has already been disposed.
  void detach() {
    _listController = null;
    _scrollController = null;
    _items = const [];
    _itemKeyProvider = null;
    _clearPending();
    if (!_disposed) {
      notifyListeners();
    }
  }

  // ── isAtBottom (updated by widget) ─────────────────────────────────

  /// Called internally by the widget to update the [isAtBottom] flag.
  ///
  /// Returns `true` if the value changed.
  bool setIsAtBottom(bool value) {
    if (_isAtBottom == value) return false;
    _isAtBottom = value;
    notifyListeners();
    return true;
  }

  // ── Pending jump internals ────────────────────────────────────────

  void _setPendingJump({
    required dynamic key,
    required ListItemAlignment alignment,
  }) {
    _pendingKey = key;
    _pendingAlignment = alignment;
    _pendingAnimate = false;
    _pendingAnimateDuration = null;
    _pendingAnimateCurve = null;
    _pendingSequence++;
  }

  void _setPendingAnimate({
    required dynamic key,
    required ListItemAlignment alignment,
    Duration Function(double)? duration,
    Curve Function(double)? curve,
  }) {
    _pendingKey = key;
    _pendingAlignment = alignment;
    _pendingAnimate = true;
    _pendingAnimateDuration = duration;
    _pendingAnimateCurve = curve;
    _pendingSequence++;
  }

  void _clearPending() {
    _pendingKey = null;
    _pendingSequence++;
  }

  /// Called from [updateItems] — if a pending key is found in the
  /// updated items, schedules the jump/animation for the next frame
  /// (after layout is complete).
  ///
  /// Returns `true` if a pending jump was resolved.
  bool _tryResolvePending() {
    final key = _pendingKey;
    if (key == null || !isAttached) return false;

    final index = _findIndexByKey(key);
    if (index == -1) return false;

    final alignment = _pendingAlignment;
    final animate = _pendingAnimate;
    final duration = _pendingAnimateDuration;
    final curve = _pendingAnimateCurve;
    final seq = _pendingSequence;
    _clearPending();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_disposed || !isAttached) return;
      // Bail if a newer jump was requested during the frame.
      if (_pendingSequence != seq + 1) return;

      final currentIndex = _findIndexByKey(key);
      if (currentIndex == -1) return;

      if (animate) {
        _listController!.animateToItem(
          index: currentIndex,
          scrollController: _scrollController!,
          alignment: alignment.value,
          duration: duration ?? (_) => const Duration(milliseconds: 300),
          curve: curve ?? (_) => Curves.easeInOut,
        );
      } else {
        _listController!.jumpToItem(
          index: currentIndex,
          scrollController: _scrollController!,
          alignment: alignment.value,
        );
      }
    });
    return true;
  }

  /// Schedules [action] to run after two frames, giving the widget tree time
  /// to rebuild (frame 1 — `didUpdateWidget` calls `updateItems`) and lay out
  /// (frame 2 — items are fully rendered and scrollable).
  void _scheduleRetry(VoidCallback action) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_disposed || !isAttached) return;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (_disposed || !isAttached) return;
        action();
      });
    });
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
    _disposed = true;
    _listController = null;
    _scrollController = null;
    _items = const [];
    _itemKeyProvider = null;
    _pendingKey = null;
    super.dispose();
  }
}
