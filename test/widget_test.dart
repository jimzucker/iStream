import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:istream/main.dart';

void main() {
  testWidgets('form renders and generates a design', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const IStreamApp());

    expect(find.text('iStream'), findsOneWidget);
    expect(find.text('Schema'), findsOneWidget);
    expect(find.text('Throughput & Latency Targets'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Generate Pipeline Design'));
    await tester.pumpAndSettle();

    expect(find.text('Pipeline Design'), findsOneWidget);
    expect(find.text('Kafka Topic'), findsOneWidget);
    expect(find.text('Flink Job'), findsOneWidget);
  });
}
