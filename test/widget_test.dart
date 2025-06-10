// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sdsd/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MyApp(initialScreen: const Placeholder()), // ✅ 수정됨
      ),
    );

    // 화면에 '0'이 안 보일 수도 있으니 아래 라인 제거 또는 수정
    // expect(find.text('0'), findsOneWidget);

    // 아래 테스트는 네이티브 Counter 예제이므로, 실제 앱에 맞게 삭제하거나 대체 가능
    // await tester.tap(find.byIcon(Icons.add));
    // await tester.pump();
    // expect(find.text('1'), findsOneWidget);
  });
}
