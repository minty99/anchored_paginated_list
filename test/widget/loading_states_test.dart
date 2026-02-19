import 'dart:async';

import 'package:flutter/material.dart';
import 'package:anchored_paginated_list/anchored_paginated_list.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Loading and state indicators', () {
    testWidgets('shows emptyBuilder when list is empty', (tester) async {
      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: const [],
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            emptyBuilder: (_) => const Text('Nothing here'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nothing here'), findsOneWidget);
      expect(find.byType(CustomScrollView), findsNothing);
    });

    testWidgets('shows default empty placeholder when emptyBuilder is absent',
        (tester) async {
      await tester.pumpWidget(
        pumpApp(
          const AnchoredPaginatedList<FakeItem>(
            items: [],
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomScrollView), findsNothing);
      expect(find.byType(SizedBox), findsAtLeastNWidgets(1));
    });

    testWidgets('shows custom forward loading indicator while loading',
        (tester) async {
      final completer = Completer<void>();

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: generateFakeItems(60),
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            hasMoreForward: true,
            onLoadMore: (_) => completer.future,
            loadingBuilder: (_, direction) => Text('Loading $direction'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Item 59'),
        300,
        scrollable: find.byType(Scrollable),
      );
      await tester.pump();

      expect(find.text('Loading LoadDirection.forward'), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets(
        'shows default loading indicator when no loadingBuilder provided',
        (tester) async {
      final completer = Completer<void>();

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: generateFakeItems(55),
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            hasMoreForward: true,
            onLoadMore: (_) => completer.future,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Item 54'),
        300,
        scrollable: find.byType(Scrollable),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('hides loading indicator after load completes', (tester) async {
      final completer = Completer<void>();

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: generateFakeItems(55),
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            hasMoreForward: true,
            onLoadMore: (_) => completer.future,
            loadingBuilder: (_, __) => const Text('Loading more...'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Item 54'),
        300,
        scrollable: find.byType(Scrollable),
      );
      await tester.pump();
      expect(find.text('Loading more...'), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();

      expect(find.text('Loading more...'), findsNothing);
    });

    testWidgets('shows custom error widget when forward load fails',
        (tester) async {
      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: generateFakeItems(50),
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            hasMoreForward: true,
            onLoadMore: (_) async => throw StateError('failed to load'),
            errorBuilder: (_, error, direction) {
              return Text('Error $direction: $error');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Item 49'),
        300,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      expect(
          find.textContaining('Error LoadDirection.forward'), findsOneWidget);
    });

    testWidgets('clears error and retries successfully on next trigger',
        (tester) async {
      final secondCompleter = Completer<void>();

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: generateFakeItems(60),
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            hasMoreForward: true,
            onLoadMore: (_) => Future<void>.error(StateError('first failure')),
            loadingBuilder: (_, __) => const Text('Retry loading...'),
            errorBuilder: (_, error, __) => Text('Load failed: $error'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Item 59'),
        300,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Load failed:'), findsOneWidget);

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: generateFakeItems(60),
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            hasMoreForward: true,
            onLoadMore: (_) => secondCompleter.future,
            loadingBuilder: (_, __) => const Text('Retry loading...'),
            errorBuilder: (_, error, __) => Text('Load failed: $error'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Scrollable), const Offset(0, 250));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable), const Offset(0, -350));
      await tester.pump();

      expect(find.textContaining('Load failed:'), findsNothing);
      expect(find.text('Retry loading...'), findsOneWidget);

      secondCompleter.complete();
      await tester.pumpAndSettle();

      expect(find.text('Retry loading...'), findsNothing);
    });

    testWidgets('shows custom backward loading indicator while loading',
        (tester) async {
      final completer = Completer<void>();

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: generateFakeItems(30),
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            hasMoreBackward: true,
            onLoadMore: (_) => completer.future,
            loadingBuilder: (_, direction) => Text('Loading $direction'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Scrollable), const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable), const Offset(0, 700));
      await tester.pump();

      expect(find.text('Loading LoadDirection.backward'), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();
    });
  });
}
