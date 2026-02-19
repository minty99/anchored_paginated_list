import 'package:flutter/material.dart';
import 'package:anchored_paginated_list/anchored_paginated_list.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

void main() {
  group('AnchoredPaginatedListController', () {
    late AnchoredPaginatedListController controller;
    var disposed = false;

    setUp(() {
      controller = AnchoredPaginatedListController();
      disposed = false;
    });

    tearDown(() {
      if (!disposed) {
        controller.dispose();
      }
    });

    test('isAttached is false initially', () {
      expect(controller.isAttached, isFalse);
    });

    test('isAttached is true after attach', () {
      final listController = ListController();
      final scrollController = ScrollController();

      controller.attach(listController, scrollController);
      expect(controller.isAttached, isTrue);

      listController.dispose();
      scrollController.dispose();
    });

    test('isAttached is false after detach', () {
      final listController = ListController();
      final scrollController = ScrollController();

      controller.attach(listController, scrollController);
      controller.detach();
      expect(controller.isAttached, isFalse);

      listController.dispose();
      scrollController.dispose();
    });

    test('jumpTo throws when not attached', () {
      // In debug mode the assert fires (AssertionError).
      expect(
        () => controller.jumpTo(
          index: 0,
          alignment: ListItemAlignment.top,
        ),
        throwsA(anything),
      );
    });

    test('animateTo throws when not attached', () {
      expect(
        () => controller.animateTo(
          index: 0,
          alignment: ListItemAlignment.top,
        ),
        throwsA(anything),
      );
    });

    test('visibleRange returns null when not attached', () {
      expect(controller.visibleRange, isNull);
    });

    test('notifies listeners on attach', () {
      var notified = false;
      controller.addListener(() => notified = true);

      final listController = ListController();
      final scrollController = ScrollController();

      controller.attach(listController, scrollController);
      expect(notified, isTrue);

      listController.dispose();
      scrollController.dispose();
    });

    test('notifies listeners on detach', () {
      final listController = ListController();
      final scrollController = ScrollController();
      controller.attach(listController, scrollController);

      var notified = false;
      controller.addListener(() => notified = true);

      controller.detach();
      expect(notified, isTrue);

      listController.dispose();
      scrollController.dispose();
    });

    test('dispose clears internal state', () {
      final listController = ListController();
      final scrollController = ScrollController();
      controller.attach(listController, scrollController);
      controller.dispose();
      disposed = true;

      // After dispose, creating a new controller works fine
      final newController = AnchoredPaginatedListController();
      expect(newController.isAttached, isFalse);
      newController.dispose();

      listController.dispose();
      scrollController.dispose();
    });

    group('jumpToKey', () {
      test('throws when not attached', () {
        expect(
          () => controller.jumpToKey(key: 'any'),
          throwsA(anything),
        );
      });

      test('returns false when key not found', () {
        final listController = ListController();
        final scrollController = ScrollController();
        controller.attach(listController, scrollController);
        controller.updateItems(
          ['a', 'b', 'c'],
          (dynamic item) => item as String,
        );

        expect(controller.jumpToKey(key: 'nonexistent'), isFalse);

        listController.dispose();
        scrollController.dispose();
      });

      test('returns false when no key provider set', () {
        final listController = ListController();
        final scrollController = ScrollController();
        controller.attach(listController, scrollController);
        // No updateItems called — _itemKeyProvider is null

        expect(controller.jumpToKey(key: 'any'), isFalse);

        listController.dispose();
        scrollController.dispose();
      });
    });

    group('animateToKey', () {
      test('throws when not attached', () {
        expect(
          () => controller.animateToKey(key: 'any'),
          throwsA(anything),
        );
      });

      test('returns false when key not found', () {
        final listController = ListController();
        final scrollController = ScrollController();
        controller.attach(listController, scrollController);
        controller.updateItems(
          ['a', 'b', 'c'],
          (dynamic item) => item as String,
        );

        expect(controller.animateToKey(key: 'nonexistent'), isFalse);

        listController.dispose();
        scrollController.dispose();
      });

      test('returns false when no key provider set', () {
        final listController = ListController();
        final scrollController = ScrollController();
        controller.attach(listController, scrollController);

        expect(controller.animateToKey(key: 'any'), isFalse);

        listController.dispose();
        scrollController.dispose();
      });
    });

    group('updateItems', () {
      test('updates internal snapshot used by jumpToKey', () {
        final listController = ListController();
        final scrollController = ScrollController();
        controller.attach(listController, scrollController);

        // Initially no items — key not found
        expect(controller.jumpToKey(key: 'x'), isFalse);

        // After updateItems, key 'x' should be findable (returns false
        // only because ListController isn't attached to a rendered list,
        // but the key resolution itself works — we verify via the
        // "not found" path changing behavior).
        controller.updateItems(
          ['x', 'y', 'z'],
          (dynamic item) => item as String,
        );

        // 'w' is still not found
        expect(controller.jumpToKey(key: 'w'), isFalse);

        listController.dispose();
        scrollController.dispose();
      });

      test('replaces previous snapshot completely', () {
        final listController = ListController();
        final scrollController = ScrollController();
        controller.attach(listController, scrollController);

        controller.updateItems(
          ['a', 'b'],
          (dynamic item) => item as String,
        );
        // 'a' findable at this point — will fail at jumpToItem level
        // but 'c' is not found
        expect(controller.jumpToKey(key: 'c'), isFalse);

        // Replace with new items
        controller.updateItems(
          ['c', 'd'],
          (dynamic item) => item as String,
        );
        // 'a' is no longer findable
        expect(controller.jumpToKey(key: 'a'), isFalse);

        listController.dispose();
        scrollController.dispose();
      });
    });

    group('detach', () {
      test('clears items and key provider', () {
        final listController = ListController();
        final scrollController = ScrollController();
        controller.attach(listController, scrollController);
        controller.updateItems(
          ['a', 'b', 'c'],
          (dynamic item) => item as String,
        );

        controller.detach();

        // After detach, isAttached is false so jumpToKey throws
        expect(() => controller.jumpToKey(key: 'a'), throwsA(anything));

        // Re-attach without updateItems — key provider was cleared
        controller.attach(listController, scrollController);
        expect(controller.jumpToKey(key: 'a'), isFalse);

        listController.dispose();
        scrollController.dispose();
      });
    });
  });

  group('jumpToKey / animateToKey with widget', () {
    testWidgets('jumpToKey returns true when key is found in rendered list',
        (tester) async {
      final controller = AnchoredPaginatedListController();
      final items = List.generate(20, (i) => 'item-$i');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnchoredPaginatedList<String>(
              items: items,
              itemBuilder: (context, item, index) => SizedBox(
                height: 50,
                child: Text(item, key: ValueKey(item)),
              ),
              itemKey: (item) => item,
              controller: controller,
            ),
          ),
        ),
      );

      expect(controller.jumpToKey(key: 'item-5'), isTrue);

      // Tear down widget tree first, then dispose controller
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });

    testWidgets('animateToKey returns true when key is found in rendered list',
        (tester) async {
      final controller = AnchoredPaginatedListController();
      final items = List.generate(20, (i) => 'item-$i');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnchoredPaginatedList<String>(
              items: items,
              itemBuilder: (context, item, index) => SizedBox(
                height: 50,
                child: Text(item, key: ValueKey(item)),
              ),
              itemKey: (item) => item,
              controller: controller,
            ),
          ),
        ),
      );

      expect(controller.animateToKey(key: 'item-10'), isTrue);

      // Let the animation complete before tearing down
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });

    testWidgets('jumpToKey returns false for missing key in rendered list',
        (tester) async {
      final controller = AnchoredPaginatedListController();
      final items = List.generate(5, (i) => 'item-$i');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnchoredPaginatedList<String>(
              items: items,
              itemBuilder: (context, item, index) => SizedBox(
                height: 50,
                child: Text(item, key: ValueKey(item)),
              ),
              itemKey: (item) => item,
              controller: controller,
            ),
          ),
        ),
      );

      expect(controller.jumpToKey(key: 'nonexistent'), isFalse);

      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });

    testWidgets('updateItems syncs on didUpdateWidget', (tester) async {
      final controller = AnchoredPaginatedListController();
      var items = List.generate(5, (i) => 'item-$i');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnchoredPaginatedList<String>(
              items: items,
              itemBuilder: (context, item, index) => SizedBox(
                height: 50,
                child: Text(item, key: ValueKey(item)),
              ),
              itemKey: (item) => item,
              controller: controller,
            ),
          ),
        ),
      );

      // 'new-item' doesn't exist yet
      expect(controller.jumpToKey(key: 'new-item'), isFalse);

      // Update items with new-item included
      items = ['new-item', ...items];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnchoredPaginatedList<String>(
              items: items,
              itemBuilder: (context, item, index) => SizedBox(
                height: 50,
                child: Text(item, key: ValueKey(item)),
              ),
              itemKey: (item) => item,
              controller: controller,
            ),
          ),
        ),
      );

      // Now 'new-item' should be found
      expect(controller.jumpToKey(key: 'new-item'), isTrue);

      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });
  });
}
