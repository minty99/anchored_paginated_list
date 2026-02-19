import 'package:flutter/material.dart';

/// Wraps a widget in a [MaterialApp] for widget testing.
Widget pumpApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

/// Generates a list of fake items with string IDs.
List<FakeItem> generateFakeItems(int count, {int startId = 0}) {
  return List.generate(
    count,
    (i) => FakeItem(
      id: '${startId + i}',
      height: 50.0 + (i % 5) * 20.0, // Variable heights: 50, 70, 90, 110, 130
    ),
  );
}

/// A simple data model for tests.
class FakeItem {
  const FakeItem({required this.id, this.height = 50.0});

  final String id;
  final double height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FakeItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'FakeItem(id: $id, height: $height)';
}

/// Default item key provider for tests.
String fakeItemKey(FakeItem item) => item.id;

/// Default item builder for tests.
Widget fakeItemBuilder(BuildContext context, FakeItem item, int index) {
  return SizedBox(
    height: item.height,
    child: Text('Item ${item.id}', key: ValueKey(item.id)),
  );
}
