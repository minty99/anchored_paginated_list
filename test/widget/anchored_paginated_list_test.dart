import 'package:flutter/material.dart';
import 'package:anchored_paginated_list/anchored_paginated_list.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('AnchoredPaginatedList core rendering', () {
    testWidgets('renders provided items', (tester) async {
      final items = generateFakeItems(10);

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: items,
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 1'), findsOneWidget);
    });

    testWidgets('renders offscreen items after scrolling', (tester) async {
      final items = generateFakeItems(40);

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: items,
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Item 35'),
        250,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      expect(find.text('Item 35'), findsOneWidget);
    });

    testWidgets('uses itemBuilder output', (tester) async {
      final items = generateFakeItems(5);

      Widget customBuilder(BuildContext context, FakeItem item, int index) {
        return SizedBox(
          height: item.height,
          child: Text('Row $index - ${item.id}', key: ValueKey('row-$index')),
        );
      }

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: items,
            itemBuilder: customBuilder,
            itemKey: fakeItemKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Row 0 - 0'), findsOneWidget);
      expect(find.byKey(const ValueKey('row-0')), findsOneWidget);
    });

    testWidgets('updates when item list changes', (tester) async {
      final initialItems = generateFakeItems(3);

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: initialItems,
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Item 3'), findsNothing);

      final updatedItems = generateFakeItems(4);
      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: updatedItems,
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Item 3'), findsOneWidget);
    });

    testWidgets('applies sliver padding when provided', (tester) async {
      const padding = EdgeInsets.symmetric(horizontal: 12, vertical: 24);

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: generateFakeItems(8),
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            padding: padding,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sliverPadding = tester.widget<SliverPadding>(
        find.byType(SliverPadding),
      );
      expect(sliverPadding.padding, padding);
    });

    testWidgets('uses provided scroll physics', (tester) async {
      const physics = BouncingScrollPhysics();

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: generateFakeItems(12),
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            physics: physics,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollView = tester.widget<CustomScrollView>(
        find.byType(CustomScrollView),
      );
      expect(scrollView.physics, same(physics));
    });

    testWidgets('attaches to a provided scrollController', (tester) async {
      final scrollController = ScrollController();
      addTearDown(scrollController.dispose);

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: generateFakeItems(30),
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            scrollController: scrollController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(scrollController.hasClients, isTrue);
    });

    testWidgets('passes reverse to CustomScrollView', (tester) async {
      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: generateFakeItems(10),
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
  });
}
