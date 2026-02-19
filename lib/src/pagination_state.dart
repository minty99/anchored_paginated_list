import 'load_direction.dart';

/// Tracks the loading state for each pagination direction independently.
///
/// This is an immutable value type; use [copyWith] or the convenience
/// methods [startLoading], [completeLoading], and [setError] to create
/// new instances.
class PaginationState {
  const PaginationState({
    this.isLoadingForward = false,
    this.isLoadingBackward = false,
    this.forwardError,
    this.backwardError,
  });

  /// Whether items are currently being loaded in the forward direction.
  final bool isLoadingForward;

  /// Whether items are currently being loaded in the backward direction.
  final bool isLoadingBackward;

  /// The error that occurred while loading forward items, if any.
  final Object? forwardError;

  /// The error that occurred while loading backward items, if any.
  final Object? backwardError;

  /// Returns `true` if items are currently being loaded in [direction].
  bool isLoading(LoadDirection direction) {
    return switch (direction) {
      LoadDirection.forward => isLoadingForward,
      LoadDirection.backward => isLoadingBackward,
    };
  }

  /// Returns the error for [direction], or `null` if no error.
  Object? error(LoadDirection direction) {
    return switch (direction) {
      LoadDirection.forward => forwardError,
      LoadDirection.backward => backwardError,
    };
  }

  /// Returns a new state with the loading flag set for [direction].
  PaginationState startLoading(LoadDirection direction) {
    return switch (direction) {
      LoadDirection.forward => copyWith(
          isLoadingForward: true,
          clearForwardError: true,
        ),
      LoadDirection.backward => copyWith(
          isLoadingBackward: true,
          clearBackwardError: true,
        ),
    };
  }

  /// Returns a new state with the loading flag cleared for [direction].
  PaginationState completeLoading(LoadDirection direction) {
    return switch (direction) {
      LoadDirection.forward => copyWith(isLoadingForward: false),
      LoadDirection.backward => copyWith(isLoadingBackward: false),
    };
  }

  /// Returns a new state with an error set for [direction].
  PaginationState setError(LoadDirection direction, Object error) {
    return switch (direction) {
      LoadDirection.forward => copyWith(
          isLoadingForward: false,
          forwardError: error,
        ),
      LoadDirection.backward => copyWith(
          isLoadingBackward: false,
          backwardError: error,
        ),
    };
  }

  /// Creates a copy with the given fields replaced.
  PaginationState copyWith({
    bool? isLoadingForward,
    bool? isLoadingBackward,
    Object? forwardError,
    Object? backwardError,
    bool clearForwardError = false,
    bool clearBackwardError = false,
  }) {
    return PaginationState(
      isLoadingForward: isLoadingForward ?? this.isLoadingForward,
      isLoadingBackward: isLoadingBackward ?? this.isLoadingBackward,
      forwardError:
          clearForwardError ? null : (forwardError ?? this.forwardError),
      backwardError:
          clearBackwardError ? null : (backwardError ?? this.backwardError),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaginationState &&
          runtimeType == other.runtimeType &&
          isLoadingForward == other.isLoadingForward &&
          isLoadingBackward == other.isLoadingBackward &&
          forwardError == other.forwardError &&
          backwardError == other.backwardError;

  @override
  int get hashCode => Object.hash(
        isLoadingForward,
        isLoadingBackward,
        forwardError,
        backwardError,
      );

  @override
  String toString() => 'PaginationState('
      'isLoadingForward: $isLoadingForward, '
      'isLoadingBackward: $isLoadingBackward, '
      'forwardError: $forwardError, '
      'backwardError: $backwardError)';
}
