import 'package:anchored_paginated_list/anchored_paginated_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaginationState', () {
    test('default constructor has all flags false and no errors', () {
      const state = PaginationState();
      expect(state.isLoadingForward, isFalse);
      expect(state.isLoadingBackward, isFalse);
      expect(state.forwardError, isNull);
      expect(state.backwardError, isNull);
    });

    test('isLoading returns correct value per direction', () {
      const state = PaginationState(isLoadingForward: true);
      expect(state.isLoading(LoadDirection.forward), isTrue);
      expect(state.isLoading(LoadDirection.backward), isFalse);
    });

    test('error returns correct value per direction', () {
      final state = PaginationState(
        forwardError: Exception('forward'),
      );
      expect(state.error(LoadDirection.forward), isA<Exception>());
      expect(state.error(LoadDirection.backward), isNull);
    });

    test('startLoading sets loading and clears error for direction', () {
      final state = PaginationState(
        forwardError: Exception('old'),
      ).startLoading(LoadDirection.forward);

      expect(state.isLoadingForward, isTrue);
      expect(state.forwardError, isNull);
    });

    test('startLoading does not affect other direction', () {
      final state = PaginationState(
        isLoadingBackward: true,
        backwardError: Exception('back'),
      ).startLoading(LoadDirection.forward);

      expect(state.isLoadingForward, isTrue);
      expect(state.isLoadingBackward, isTrue);
    });

    test('completeLoading clears loading flag for direction', () {
      const state = PaginationState(isLoadingBackward: true);
      final result = state.completeLoading(LoadDirection.backward);
      expect(result.isLoadingBackward, isFalse);
    });

    test('setError clears loading and sets error for direction', () {
      const state = PaginationState(isLoadingForward: true);
      final error = Exception('fail');
      final result = state.setError(LoadDirection.forward, error);

      expect(result.isLoadingForward, isFalse);
      expect(result.forwardError, error);
    });

    test('equality works correctly', () {
      const a = PaginationState(isLoadingForward: true);
      const b = PaginationState(isLoadingForward: true);
      const c = PaginationState(isLoadingBackward: true);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('copyWith preserves unset values', () {
      const state = PaginationState(
        isLoadingForward: true,
        isLoadingBackward: true,
      );
      final result = state.copyWith(isLoadingForward: false);
      expect(result.isLoadingForward, isFalse);
      expect(result.isLoadingBackward, isTrue);
    });
  });
}
