// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('主页能正常渲染', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // 檢查主頁標題是否存在
    expect(find.text('IP智慧解答专家'), findsOneWidget);
  });
}
