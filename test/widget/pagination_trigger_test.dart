import 'dart:async';

import 'package:flutter/material.dart';
import 'package:anchored_paginated_list/anchored_paginated_list.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('Pagination triggers', () {
    testWidgets('triggers forward load near end of list', (tester) async {
      final calls = <LoadDirection>[];
      final completer = Completer<void>();

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: generateFakeItems(60),
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            hasMoreForward: true,
            onLoadMore: (direction) {
              calls.add(direction);
              return completer.future;
            },
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

      expect(calls, [LoadDirection.forward]);

      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('triggers backward load near start of list', (tester) async {
      final calls = <LoadDirection>[];
      final completer = Completer<void>();

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: generateFakeItems(30),
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            hasMoreBackward: true,
            onLoadMore: (direction) {
              calls.add(direction);
              return completer.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Scrollable), const Offset(0, -500));
      await tester.pump();
      await tester.drag(find.byType(Scrollable), const Offset(0, 700));
      await tester.pump();

      expect(calls, [LoadDirection.backward]);

      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('does not trigger forward load when hasMoreForward is false',
        (tester) async {
      var callCount = 0;

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: generateFakeItems(60),
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            hasMoreForward: false,
            onLoadMore: (_) async => callCount++,
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

      expect(callCount, 0);
    });

    testWidgets('does not trigger backward load when hasMoreBackward is false',
        (tester) async {
      var callCount = 0;

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: generateFakeItems(30),
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            hasMoreBackward: false,
            onLoadMore: (_) async => callCount++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Scrollable), const Offset(0, 350));
      await tester.pumpAndSettle();

      expect(callCount, 0);
    });

    testWidgets('does not trigger when onLoadMore is null', (tester) async {
      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: generateFakeItems(60),
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            hasMoreForward: true,
            hasMoreBackward: true,
            onLoadMore: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Item 59'),
        300,
        scrollable: find.byType(Scrollable),
      );
      await tester.drag(find.byType(Scrollable), const Offset(0, 400));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('does not duplicate forward requests while loading',
        (tester) async {
      var callCount = 0;
      final completer = Completer<void>();

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: generateFakeItems(70),
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            hasMoreForward: true,
            onLoadMore: (_) {
              callCount++;
              return completer.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Item 69'),
        320,
        scrollable: find.byType(Scrollable),
      );
      await tester.pump();

      await tester.drag(find.byType(Scrollable), const Offset(0, -250));
      await tester.pump();
      await tester.drag(find.byType(Scrollable), const Offset(0, -250));
      await tester.pump();

      expect(callCount, 1);

      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('allows forward retrigger after previous load completes',
        (tester) async {
      final calls = <LoadDirection>[];
      final first = Completer<void>();
      final second = Completer<void>();
      var callNumber = 0;

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: generateFakeItems(70),
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            hasMoreForward: true,
            onLoadMore: (direction) {
              calls.add(direction);
              callNumber++;
              if (callNumber == 1) return first.future;
              return second.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Item 69'),
        320,
        scrollable: find.byType(Scrollable),
      );
      await tester.pump();

      expect(calls, [LoadDirection.forward]);

      first.complete();
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Scrollable), const Offset(0, 250));
      await tester.pump();
      await tester.drag(find.byType(Scrollable), const Offset(0, -350));
      await tester.pump();

      expect(calls, [LoadDirection.forward, LoadDirection.forward]);

      second.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('does not duplicate backward requests while loading',
        (tester) async {
      var callCount = 0;
      final completer = Completer<void>();

      await tester.pumpWidget(
        pumpApp(
          AnchoredPaginatedList<FakeItem>(
            items: generateFakeItems(30),
            itemBuilder: fakeItemBuilder,
            itemKey: fakeItemKey,
            hasMoreBackward: true,
            onLoadMore: (_) {
              callCount++;
              return completer.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Scrollable), const Offset(0, -500));
      await tester.pump();
      await tester.drag(find.byType(Scrollable), const Offset(0, 700));
      await tester.pump();
      await tester.drag(find.byType(Scrollable), const Offset(0, 700));
      await tester.pump();

      expect(callCount, 1);

      completer.complete();
      await tester.pumpAndSettle();
    });
  });
}
