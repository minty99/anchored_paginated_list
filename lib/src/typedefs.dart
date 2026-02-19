import 'package:flutter/widgets.dart';

import 'load_direction.dart';

/// Builds a widget for the item at the given [index] in the list.
typedef ItemWidgetBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  int index,
);

/// Returns a stable key for the given [item].
///
/// This key is used for scroll anchoring when items are prepended.
/// It must be unique and stable across list mutations.
typedef ItemKeyProvider<T> = dynamic Function(T item);

/// Called when the list needs to load more items in the given [direction].
typedef LoadCallback = Future<void> Function(LoadDirection direction);

/// Builds a widget to display while items are being loaded in the given
/// [direction].
typedef LoadingWidgetBuilder = Widget Function(
  BuildContext context,
  LoadDirection direction,
);

/// Builds a widget to display when loading fails in the given [direction].
typedef PaginationErrorWidgetBuilder = Widget Function(
  BuildContext context,
  Object error,
  LoadDirection direction,
);

/// Builds a widget to display when the list has no items.
typedef EmptyWidgetBuilder = Widget Function(BuildContext context);
