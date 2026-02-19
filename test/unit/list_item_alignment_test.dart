import 'package:anchored_paginated_list/anchored_paginated_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ListItemAlignment', () {
    test('top has value 0.0', () {
      expect(ListItemAlignment.top.value, 0.0);
    });

    test('center has value 0.5', () {
      expect(ListItemAlignment.center.value, 0.5);
    });

    test('bottom has value 1.0', () {
      expect(ListItemAlignment.bottom.value, 1.0);
    });

    test('has exactly three values', () {
      expect(ListItemAlignment.values, hasLength(3));
    });
  });
}
