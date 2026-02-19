/// The direction in which to load more items.
///
/// Both values refer to the scroll position, not to data ordering:
///
/// - [forward] fires when the scroll position approaches the **trailing** edge
///   (high scroll offset). In a normal list this is the visual bottom. In a
///   reversed list (`reverse: true`) this is the visual **top**.
/// - [backward] fires when the scroll position approaches the **leading** edge
///   (low scroll offset). In a normal list this is the visual top. In a
///   reversed list this is the visual **bottom**.
///
/// Chat UI example (`reverse: true`):
/// ```dart
/// onLoadMore: (direction) async {
///   if (direction == LoadDirection.forward) {
///     await loadOlderMessages(); // user scrolled toward the top
///   } else {
///     await loadNewerMessages(); // user scrolled toward the bottom
///   }
/// },
/// hasMoreForward: hasOlderMessages,
/// hasMoreBackward: hasNewerMessages,
/// ```
enum LoadDirection {
  /// Triggered when the scroll position approaches the leading edge (low
  /// scroll offset). In a reversed list, this is the visual bottom.
  backward,

  /// Triggered when the scroll position approaches the trailing edge (high
  /// scroll offset). In a reversed list, this is the visual top.
  forward,
}
