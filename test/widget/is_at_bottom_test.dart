import 'package:flutter/material.dart';
import 'package:anchored_paginated_list/anchored_paginated_list.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('AnchoredPaginatedList isAtBottom tracking', () {
    testWidgets('onIsAtBottomChanged fires when scrolling past bottomThreshold',
        (tester) async {
      final items = generateFakeItems(40);
      var isAtBottomValues = <bool>[];

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: items,
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            reverse: true,
            bottomThreshold: 100,
            onIsAtBottomChanged: (isAtBottom) {
              isAtBottomValues.add(isAtBottom);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll up (away from bottom)
      await tester.drag(find.byType(Scrollable), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Should have fired with false
      expect(isAtBottomValues, [false]);
    });

    testWidgets('onIsAtBottomChanged does NOT fire on same-value scroll',
        (tester) async {
      final items = generateFakeItems(40);
      var callCount = 0;

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: items,
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            reverse: true,
            bottomThreshold: 100,
            onIsAtBottomChanged: (isAtBottom) {
              callCount++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialCallCount = callCount;

      // Scroll up significantly (away from bottom)
      await tester.drag(find.byType(Scrollable), const Offset(0, 300));
      await tester.pumpAndSettle();

      final afterFirstScroll = callCount;
      expect(afterFirstScroll, greaterThan(initialCallCount));

      // Scroll up a bit more (still not at bottom)
      await tester.drag(find.byType(Scrollable), const Offset(0, 50));
      await tester.pumpAndSettle();

      // Should NOT have fired again (still not at bottom)
      expect(callCount, equals(afterFirstScroll));
    });

    testWidgets('controller isAtBottom updates when user scrolls',
        (tester) async {
      final controller = AnchoredPaginatedListController();
      final items = generateFakeItems(40);

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: items,
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            reverse: true,
            bottomThreshold: 100,
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially at bottom
      expect(controller.isAtBottom, isTrue);

      // Scroll up (away from bottom)
      await tester.drag(find.byType(Scrollable), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Controller should reflect not at bottom
      expect(controller.isAtBottom, isFalse);

      // Scroll back down to bottom
      await tester.drag(find.byType(Scrollable), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Controller should reflect at bottom again
      expect(controller.isAtBottom, isTrue);

      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });

    testWidgets('onIsAtBottomChanged fires with correct sequence',
        (tester) async {
      final items = generateFakeItems(40);
      var isAtBottomValues = <bool>[];

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: items,
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            reverse: true,
            bottomThreshold: 100,
            onIsAtBottomChanged: (isAtBottom) {
              isAtBottomValues.add(isAtBottom);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clear initial values
      isAtBottomValues.clear();

      // Scroll away from bottom
      await tester.drag(find.byType(Scrollable), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(isAtBottomValues, [false]);

      // Scroll back to bottom
      await tester.drag(find.byType(Scrollable), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(isAtBottomValues, [false, true]);
    });

    testWidgets('controller notifies listeners when isAtBottom changes',
        (tester) async {
      final controller = AnchoredPaginatedListController();
      final items = generateFakeItems(40);
      var notifyCount = 0;

      controller.addListener(() => notifyCount++);

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: items,
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            reverse: true,
            bottomThreshold: 100,
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialNotifyCount = notifyCount;

      // Scroll away from bottom
      await tester.drag(find.byType(Scrollable), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Should have notified
      expect(notifyCount, greaterThan(initialNotifyCount));

      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });

    testWidgets('bottomThreshold affects isAtBottom calculation',
        (tester) async {
      final controller = AnchoredPaginatedListController();
      final items = generateFakeItems(40);

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: items,
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            reverse: true,
            bottomThreshold: 500, // Large threshold
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially at bottom
      expect(controller.isAtBottom, isTrue);

      // Small scroll should still be considered "at bottom" due to large threshold
      await tester.drag(find.byType(Scrollable), const Offset(0, 50));
      await tester.pumpAndSettle();

      // Should still be at bottom (within threshold)
      expect(controller.isAtBottom, isTrue);

      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });
  });
}
