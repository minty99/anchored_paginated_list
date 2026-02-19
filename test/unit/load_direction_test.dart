import 'package:anchored_paginated_list/anchored_paginated_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoadDirection', () {
    test('has forward and backward values', () {
      expect(LoadDirection.values, hasLength(2));
      expect(LoadDirection.values, contains(LoadDirection.forward));
      expect(LoadDirection.values, contains(LoadDirection.backward));
    });

    test('forward and backward are distinct', () {
      expect(LoadDirection.forward, isNot(LoadDirection.backward));
    });
  });
}
