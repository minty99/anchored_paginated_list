import 'package:flutter/material.dart';
import 'package:anchored_paginated_list/anchored_paginated_list.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Reverse mode', () {
    testWidgets('enables reverse on CustomScrollView', (tester) async {
      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: generateFakeItems(20),
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            reverse: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollView = tester.widget<CustomScrollView>(
        find.byType(CustomScrollView),
      );
      expect(scrollView.reverse, isTrue);
    });

    testWidgets('is non-reversed by default', (tester) async {
      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: generateFakeItems(20),
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollView = tester.widget<CustomScrollView>(
        find.byType(CustomScrollView),
      );
      expect(scrollView.reverse, isFalse);
    });

    testWidgets('renders and scrolls in reverse mode', (tester) async {
      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: generateFakeItems(45),
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            reverse: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Item 0'),
        250,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      expect(find.text('Item 0'), findsOneWidget);
    });

    testWidgets('supports padding and physics in reverse mode', (tester) async {
      const padding = EdgeInsets.all(16);
      const physics = ClampingScrollPhysics();

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: generateFakeItems(25),
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            reverse: true,
            padding: padding,
            physics: physics,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sliverPadding = tester.widget<SliverPadding>(
        find.byType(SliverPadding),
      );
      final scrollView = tester.widget<CustomScrollView>(
        find.byType(CustomScrollView),
      );

      expect(sliverPadding.padding, padding);
      expect(scrollView.physics, same(physics));
    });
  });
}
