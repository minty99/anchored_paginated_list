/// Describes where a target item should be positioned within the viewport
/// after a jump or scroll animation.
enum ListItemAlignment {
  /// The item's leading edge is aligned with the top of the viewport.
  top(0.0),

  /// The item is centered within the viewport.
  center(0.5),

  /// The item's trailing edge is aligned with the bottom of the viewport.
  bottom(1.0);

  const ListItemAlignment(this.value);

  /// The alignment value used by the underlying scroll system.
  ///
  /// - `0.0` positions the item at the top of the viewport.
  /// - `0.5` positions the item at the center.
  /// - `1.0` positions the item at the bottom.
  final double value;
}
