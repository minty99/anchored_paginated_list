import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import 'anchored_paginated_list_controller.dart';
import 'load_direction.dart';
import 'pagination_state.dart';
import 'scroll_anchor_manager.dart';
import 'typedefs.dart';

/// A high-performance paginated list widget that supports variable-height
/// items, bidirectional pagination, and jumping to arbitrary positions.
///
/// Built on top of [SuperSliverList] for efficient O(log n) extent queries,
/// this widget handles:
/// - **Bidirectional pagination**: Load items before or after the current set
/// - **Jump to index**: Instantly scroll to any loaded item with configurable
///   alignment (top, center, bottom)
/// - **Scroll anchoring**: When items are prepended, the viewport stays on
///   the same visual items
/// - **Loading/error/empty states**: Built-in builders for each state
/// - **Reverse mode**: For chat-like UIs where newest items appear at the
///   bottom
///
/// {@tool snippet}
/// ```dart
/// AnchoredPaginatedList<Message>(
///   items: messages,
///   itemBuilder: (context, message, index) => MessageBubble(message),
///   itemKey: (message) => message.id,
///   onLoadMore: (direction) async {
///     if (direction == LoadDirection.backward) {
///       await loadOlderMessages();
///     }
///   },
///   hasMoreBackward: hasOlderMessages,
///   reverse: true,
/// )
/// ```
/// {@end-tool}
class AnchoredPaginatedList<T> extends StatefulWidget {
  /// Creates a [AnchoredPaginatedList].
  const AnchoredPaginatedList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.itemKey,
    this.onLoadMore,
    this.hasMoreForward = false,
    this.hasMoreBackward = false,
    this.loadMoreThreshold = 250.0,
    this.bottomThreshold = 150.0,
    this.controller,
    this.scrollController,
    this.reverse = false,
    this.padding,
    this.physics,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.estimateExtent,
    this.onIsAtBottomChanged,
  });

  /// The list of items to display.
  ///
  /// When this list changes (items added/removed), the widget automatically
  /// detects prepends and performs scroll anchoring.
  final List<T> items;

  /// Builds a widget for the item at the given index.
  final ItemWidgetBuilder<T> itemBuilder;

  /// Returns a stable, unique key for the given item.
  ///
  /// This is used for scroll anchoring. The key must be:
  /// - **Unique**: No two items in the list should return the same key
  /// - **Stable**: An item's key must not change across list mutations
  final ItemKeyProvider<T> itemKey;

  /// Called when the list needs more items in the given direction.
  ///
  /// This is triggered when the user scrolls within [loadMoreThreshold]
  /// pixels of the edge in the corresponding direction and `hasMoreForward`
  /// or `hasMoreBackward` is `true`.
  final LoadCallback? onLoadMore;

  /// Whether there are more items available in the forward direction.
  final bool hasMoreForward;

  /// Whether there are more items available in the backward direction.
  final bool hasMoreBackward;

  /// The distance in pixels from the edge at which to trigger loading.
  ///
  /// Defaults to 250.0 pixels.
  final double loadMoreThreshold;

  /// The distance in pixels from the bottom edge at which the list is
  /// considered "at the bottom".
  ///
  /// For reversed lists, this is measured from `offset == 0` (the visual
  /// bottom). For non-reversed lists, from `maxScrollExtent`.
  ///
  /// Defaults to 150.0 pixels.
  final double bottomThreshold;

  /// An optional controller for programmatic scrolling (jump/animate).
  final AnchoredPaginatedListController? controller;

  /// An optional scroll controller.
  ///
  /// If not provided, the widget creates its own. If provided, the caller
  /// is responsible for disposing it.
  final ScrollController? scrollController;

  /// Whether the list is reversed.
  ///
  /// In reverse mode, the list scrolls from bottom to top. This is common
  /// for chat UIs where the newest item appears at the bottom.
  ///
  /// When `reverse` is `true`, [LoadDirection] values correspond to the
  /// **scroll position**, not to data ordering:
  /// - [LoadDirection.forward] fires when scrolling toward the visual **top**
  ///   (high scroll offset) — e.g., loading older messages in a chat.
  /// - [LoadDirection.backward] fires when scrolling toward the visual
  ///   **bottom** (low scroll offset) — e.g., loading newer messages in a chat.
  /// - Items at index 0 appear at the bottom of the viewport.
  final bool reverse;

  /// Padding around the list content.
  final EdgeInsetsGeometry? padding;

  /// Custom scroll physics.
  final ScrollPhysics? physics;

  /// Builds a widget to display while loading more items.
  final LoadingWidgetBuilder? loadingBuilder;

  /// Builds a widget to display when loading fails.
  final PaginationErrorWidgetBuilder? errorBuilder;

  /// Builds a widget to display when the list is empty.
  final EmptyWidgetBuilder? emptyBuilder;

  /// Optional estimator for item extents.
  ///
  /// Providing a good estimate improves scroll position accuracy before
  /// items are laid out.
  final double Function(int index)? estimateExtent;

  /// Called when the list crosses the [bottomThreshold] boundary.
  ///
  /// For reversed lists, "at bottom" means the scroll offset is near 0
  /// (the visual bottom showing newest items). For non-reversed lists,
  /// "at bottom" means near `maxScrollExtent`.
  ///
  /// Also updates [AnchoredPaginatedListController.isAtBottom] when
  /// a controller is attached.
  final ValueChanged<bool>? onIsAtBottomChanged;

  @override
  State<AnchoredPaginatedList<T>> createState() =>
      _AnchoredPaginatedListState<T>();
}

class _AnchoredPaginatedListState<T> extends State<AnchoredPaginatedList<T>> {
  late final ListController _listController;
  late final ScrollController _scrollController;
  late final ScrollAnchorManager<T> _anchorManager;

  bool _ownsScrollController = false;
  bool _anchorRestorePending = false;
  bool _wasAtBottom = true;

  PaginationState _paginationState = const PaginationState();

  /// Tracks previous items for prepend detection.
  List<T> _previousItems = const [];

  @override
  void initState() {
    super.initState();
    _listController = ListController();
    _anchorManager = ScrollAnchorManager<T>();

    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _ownsScrollController = true;
    }

    _scrollController.addListener(_onScroll);

    widget.controller?.attach(_listController, _scrollController);
    widget.controller?.updateItems(
      widget.items,
      (dynamic item) => widget.itemKey(item as T),
    );

    _previousItems = List.of(widget.items);
  }

  @override
  void didUpdateWidget(covariant AnchoredPaginatedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle controller changes
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detach();
      widget.controller?.attach(_listController, _scrollController);
    }

    // Keep controller's item snapshot current for jumpToKey / animateToKey.
    // If a pending jump was resolved, skip scroll anchoring below — the
    // explicit jump takes priority over automatic anchor preservation.
    final pendingJumpResolved = widget.controller?.updateItems(
          widget.items,
          (dynamic item) => widget.itemKey(item as T),
        ) ??
        false;

    // Handle scroll controller changes
    if (widget.scrollController != oldWidget.scrollController) {
      _scrollController.removeListener(_onScroll);
      if (_ownsScrollController) {
        _scrollController.dispose();
        _ownsScrollController = false;
      }
      if (widget.scrollController != null) {
        _scrollController = widget.scrollController!;
      } else {
        _scrollController = ScrollController();
        _ownsScrollController = true;
      }
      _scrollController.addListener(_onScroll);
      widget.controller?.attach(_listController, _scrollController);
    }

    // Detect prepend and perform scroll anchoring (skipped when an
    // explicit pending jump was just resolved).
    if (!pendingJumpResolved &&
        !identical(widget.items, oldWidget.items) &&
        widget.items.length != _previousItems.length) {
      final prependCount = _anchorManager.detectPrependCount(
        oldItems: _previousItems,
        newItems: widget.items,
        keyProvider: widget.itemKey,
      );

      if (prependCount > 0) {
        // Phase 1: Immediately correct scroll offset BEFORE layout to
        // prevent a visual flash. This uses an estimated item height
        // which may be slightly off, but prevents the viewport from
        // jumping to the wrong content for even a single frame.
        if (_scrollController.hasClients && _previousItems.isNotEmpty) {
          final position = _scrollController.position;
          final totalExtent =
              position.maxScrollExtent + position.viewportDimension;
          final estimatedItemExtent = totalExtent / _previousItems.length;
          position.correctBy(prependCount * estimatedItemExtent);
        }

        // Phase 2: Fine-tune with jumpToItem after layout for pixel-perfect
        // alignment, using the actual laid-out extents.
        if (_anchorManager.hasAnchor) {
          _anchorRestorePending = true;
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _anchorRestorePending = false;
            _anchorManager.restoreAnchor(
              newItems: widget.items,
              keyProvider: widget.itemKey,
              listController: _listController,
              scrollController: _scrollController,
            );
          });
        }
      } else if (prependCount == 0 &&
          _previousItems.isNotEmpty &&
          widget.items.isNotEmpty) {
        // Window replacement: old first item not found in new items.
        // Reset stale pagination state from the old window.
        final oldFirstKey = widget.itemKey(_previousItems.first);
        final foundInNew = widget.items.any(
          (item) => widget.itemKey(item) == oldFirstKey,
        );
        if (!foundInNew) {
          _paginationState = const PaginationState();
        }
      }
    }

    // Capture anchor for next potential prepend, but only if we're not
    // waiting for a pending restore — otherwise we'd overwrite the anchor
    // that the post-frame callback needs.
    if (!_anchorRestorePending &&
        _listController.isAttached &&
        widget.items.isNotEmpty) {
      _anchorManager.captureAnchor(
        currentItems: widget.items,
        keyProvider: widget.itemKey,
        listController: _listController,
      );
    }

    _previousItems = List.of(widget.items);
  }

  @override
  void dispose() {
    widget.controller?.detach();
    _scrollController.removeListener(_onScroll);
    if (_ownsScrollController) {
      _scrollController.dispose();
    }
    // Dispose _listController after super.dispose() so that SuperSliverList
    // can deregister from it during the child unmount cascade.
    super.dispose();
    _listController.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final pixels = position.pixels;
    final maxExtent = position.maxScrollExtent;
    final minExtent = position.minScrollExtent;

    // ── isAtBottom tracking ──────────────────────────────────────────
    final isAtBottom = widget.reverse
        ? pixels <= minExtent + widget.bottomThreshold
        : pixels >= maxExtent - widget.bottomThreshold;

    if (isAtBottom != _wasAtBottom) {
      _wasAtBottom = isAtBottom;
      widget.controller?.setIsAtBottom(isAtBottom);
      widget.onIsAtBottomChanged?.call(isAtBottom);
    }

    // ── Pagination ───────────────────────────────────────────────────
    if (widget.onLoadMore == null) return;

    final loadThreshold = widget.loadMoreThreshold;

    // Forward: near the end of the list
    if (widget.hasMoreForward &&
        !_paginationState.isLoadingForward &&
        pixels >= maxExtent - loadThreshold) {
      _triggerLoad(LoadDirection.forward);
    }

    // Backward: near the start of the list
    if (widget.hasMoreBackward &&
        !_paginationState.isLoadingBackward &&
        pixels <= minExtent + loadThreshold) {
      _triggerLoad(LoadDirection.backward);
    }
  }

  Future<void> _triggerLoad(LoadDirection direction) async {
    if (widget.onLoadMore == null) return;
    if (_paginationState.isLoading(direction)) return;

    setState(() {
      _paginationState = _paginationState.startLoading(direction);
    });

    // Capture anchor before backward load (prepend)
    if (direction == LoadDirection.backward &&
        _listController.isAttached &&
        widget.items.isNotEmpty) {
      _anchorManager.captureAnchor(
        currentItems: widget.items,
        keyProvider: widget.itemKey,
        listController: _listController,
      );
    }

    try {
      await widget.onLoadMore!(direction);
      if (!mounted) return;
      setState(() {
        _paginationState = _paginationState.completeLoading(direction);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _paginationState = _paginationState.setError(direction, error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Empty state — still render inside CustomScrollView so that
    // the scrollController remains attached and usable by callers.
    if (widget.items.isEmpty &&
        !_paginationState.isLoadingForward &&
        !_paginationState.isLoadingBackward) {
      return CustomScrollView(
        controller: _scrollController,
        reverse: widget.reverse,
        physics: widget.physics,
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child:
                widget.emptyBuilder?.call(context) ?? const SizedBox.shrink(),
          ),
        ],
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      reverse: widget.reverse,
      physics: widget.physics,
      slivers: _buildSlivers(),
    );
  }

  List<Widget> _buildSlivers() {
    final slivers = <Widget>[];

    // Backward indicator (loading or error at the start)
    final backwardWidget = _buildStateIndicator(LoadDirection.backward);
    if (backwardWidget != null) {
      slivers.add(SliverToBoxAdapter(child: backwardWidget));
    }

    // Main list
    slivers.add(_buildMainList());

    // Forward indicator (loading or error at the end)
    final forwardWidget = _buildStateIndicator(LoadDirection.forward);
    if (forwardWidget != null) {
      slivers.add(SliverToBoxAdapter(child: forwardWidget));
    }

    return slivers;
  }

  Widget _buildMainList() {
    Widget sliver = SuperSliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index < 0 || index >= widget.items.length) return null;
          return widget.itemBuilder(context, widget.items[index], index);
        },
        childCount: widget.items.length,
        findChildIndexCallback: (key) {
          if (key is! ValueKey) return null;
          for (var i = 0; i < widget.items.length; i++) {
            if (widget.itemKey(widget.items[i]) == key.value) return i;
          }
          return null;
        },
      ),
      listController: _listController,
      extentEstimation: widget.estimateExtent != null
          ? (index, _) {
              if (index == null) return 100.0;
              return widget.estimateExtent!(index);
            }
          : null,
    );

    if (widget.padding != null) {
      sliver = SliverPadding(
        padding: widget.padding!,
        sliver: sliver,
      );
    }

    return sliver;
  }

  Widget? _buildStateIndicator(LoadDirection direction) {
    final error = _paginationState.error(direction);
    final isLoading = _paginationState.isLoading(direction);
    final hasMore = direction == LoadDirection.forward
        ? widget.hasMoreForward
        : widget.hasMoreBackward;

    if (error != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(context, error, direction);
    }

    if (isLoading && widget.loadingBuilder != null) {
      return widget.loadingBuilder!(context, direction);
    }

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Show nothing if no more items and not loading
    if (!hasMore) return null;

    return null;
  }
}
