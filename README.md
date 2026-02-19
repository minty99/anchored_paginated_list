# anchored\_paginated\_list

[![pub.dev](https://img.shields.io/pub/v/anchored_paginated_list.svg)](https://pub.dev/packages/anchored_paginated_list)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android%20%7C%20macOS-lightgrey.svg)](https://pub.dev/packages/anchored_paginated_list)

A high-performance paginated list widget for Flutter with support for jumping to arbitrary positions, bidirectional pagination, variable-height items, and scroll anchoring.

---

## Features

- Bidirectional pagination — load items in both forward and backward directions
- Jump to any loaded item by index or key with configurable alignment (top, center, bottom)
- Animated scrolling to items with custom duration and curve
- Key-based navigation (`jumpToKey` / `animateToKey`) — no index calculation needed
- Automatic scroll anchoring when items are prepended — the viewport stays stable
- Variable-height items via `SuperSliverList` with O(log n) extent queries
- Reverse mode for chat-like UIs
- Built-in loading, error, and empty state builders
- Custom scroll physics and padding support
- Works with any data type via generic `T`

---

## Getting Started

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  anchored_paginated_list: ^0.1.0
```

Then import it:

```dart
import 'package:anchored_paginated_list/anchored_paginated_list.dart';
```

---

## Usage

### Basic example

```dart
AnchoredPaginatedList<String>(
  items: items,
  itemBuilder: (context, item, index) => ListTile(title: Text(item)),
  itemKey: (item) => item,
  onLoadMore: (direction) async {
    if (direction == LoadDirection.forward) {
      await loadMoreItems();
    }
  },
  hasMoreForward: hasMore,
)
```

### Chat UI (reverse mode)

In reverse mode (`reverse: true`), `LoadDirection` values map to **scroll position**, not data age:

| Direction | Scroll position | Typical action |
|-----------|----------------|----------------|
| `forward` | Near the top (high offset) | Load older messages |
| `backward` | Near the bottom (low offset) | Load newer messages |

```dart
AnchoredPaginatedList<Message>(
  items: messages,
  itemBuilder: (context, message, index) => ChatBubble(message: message),
  itemKey: (message) => message.id,
  onLoadMore: (direction) async {
    if (direction == LoadDirection.forward) {
      await loadOlderMessages(); // user scrolled toward the top
    } else {
      await loadNewerMessages(); // user scrolled toward the bottom
    }
  },
  hasMoreForward: hasOlderMessages,
  hasMoreBackward: hasNewerMessages,
  reverse: true,
  controller: listController,
)
```

### Jump to item

```dart
final controller = AnchoredPaginatedListController();

// Jump by index
controller.jumpTo(index: 42, alignment: ListItemAlignment.center);

// Jump by key — resolves the key to an index internally
controller.jumpToKey(key: messageId, alignment: ListItemAlignment.center);

// Animated scroll by index
controller.animateTo(
  index: 0,
  alignment: ListItemAlignment.bottom,
  duration: (distance) => const Duration(milliseconds: 300),
  curve: (distance) => Curves.easeInOut,
);

// Animated scroll by key
controller.animateToKey(key: messageId, alignment: ListItemAlignment.center);
```

### Windowed loading (search / deep-link)

For large datasets, you can maintain a sliding window of items instead of accumulating everything. When the user searches or follows a deep-link, replace the entire window and jump by key:

```dart
// 1. Load a window of items around the target
final window = await database.loadWindow(targetId, radius: 100);

// 2. Replace the current items
setState(() {
  items = window;
  hasMoreForward = /* more items before window */;
  hasMoreBackward = /* more items after window */;
});

// 3. Jump to the target after layout
WidgetsBinding.instance.addPostFrameCallback((_) {
  final found = controller.jumpToKey(
    key: targetId,
    alignment: ListItemAlignment.center,
  );
  // found == false if targetId is not in the current items
});
```

`jumpToKey` and `animateToKey` return `bool` — `true` if the key was found and the operation was performed, `false` otherwise.

---

## API Reference

### AnchoredPaginatedList&lt;T&gt;

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `items` | `List<T>` | Items to display | required |
| `itemBuilder` | `ItemWidgetBuilder<T>` | Builds widget per item | required |
| `itemKey` | `ItemKeyProvider<T>` | Stable unique key per item | required |
| `onLoadMore` | `LoadCallback?` | Called when more items are needed | `null` |
| `hasMoreForward` | `bool` | More items available in forward direction | `false` |
| `hasMoreBackward` | `bool` | More items available in backward direction | `false` |
| `loadMoreThreshold` | `double` | Pixel distance from edge to trigger load | `250.0` |
| `controller` | `AnchoredPaginatedListController?` | For jump and animate operations | `null` |
| `scrollController` | `ScrollController?` | Custom scroll controller | `null` |
| `reverse` | `bool` | Reverse scroll direction for chat UIs | `false` |
| `padding` | `EdgeInsetsGeometry?` | List padding | `null` |
| `physics` | `ScrollPhysics?` | Custom scroll physics | `null` |
| `loadingBuilder` | `LoadingWidgetBuilder?` | Custom loading indicator | `null` |
| `errorBuilder` | `PaginationErrorWidgetBuilder?` | Custom error widget | `null` |
| `emptyBuilder` | `EmptyWidgetBuilder?` | Custom empty state widget | `null` |
| `estimateExtent` | `double Function(int)?` | Extent estimator for items | `null` |

### AnchoredPaginatedListController

| Member | Description |
|--------|-------------|
| `jumpTo({required int index, ListItemAlignment alignment})` | Instantly scrolls to the item at `index` |
| `jumpToKey({required dynamic key, ListItemAlignment alignment})` | Instantly scrolls to the item matching `key`. Returns `bool` |
| `animateTo({required int index, ListItemAlignment alignment, ...})` | Animates to the item at `index` with custom duration and curve |
| `animateToKey({required dynamic key, ListItemAlignment alignment, ...})` | Animates to the item matching `key`. Returns `bool` |
| `visibleRange` | Returns `(int, int)?` of the currently visible index range |
| `isAttached` | Whether the controller is connected to a list |

### Enums

**`LoadDirection`**
- `forward` — toward the end of the list
- `backward` — toward the beginning of the list

**`ListItemAlignment`**
- `top` — aligns item to the top of the viewport (0.0)
- `center` — aligns item to the center (0.5)
- `bottom` — aligns item to the bottom (1.0)

---

## How It Works

The package is built on [`super_sliver_list`](https://pub.dev/packages/super_sliver_list), which uses a Fenwick tree internally to answer extent queries in O(log n) time. This makes jumping to arbitrary positions fast even with thousands of variable-height items.

**Scroll anchoring** prevents the viewport from jumping when items are prepended (backward pagination). It works in two phases:

1. **Phase 1 — immediate**: `ScrollPosition.correctBy()` is called synchronously in `didUpdateWidget`, before the next layout, to shift the scroll offset by an estimated item height. This prevents any visual flash.
2. **Phase 2 — pixel-perfect**: A post-frame callback fires `jumpToItem` using the actual laid-out extents to fine-tune the position.

The widget itself is a `CustomScrollView` composed of slivers, so it integrates cleanly with other sliver-based layouts if needed.

---

## Example App

The `example/` directory contains a realistic chat simulator (10k messages) that demonstrates:

- Bidirectional pagination with simulated network delays
- Reverse mode layout
- Incoming messages and send message flow
- Windowed search with `jumpToKey` — replaces the item window and jumps to target
- Scroll-to-bottom FAB with an unread message badge
- Visible range overlay for debugging

To run it:

```sh
cd example && flutter run
```

---

## Platform Support

| Platform | Supported |
|----------|-----------|
| iOS | Yes |
| Android | Yes |
| macOS | Yes |
| Web | Untested |
| Windows | Untested |
| Linux | Untested |

---

## License

MIT. See [LICENSE](LICENSE) for details.
