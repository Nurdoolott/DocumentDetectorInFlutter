// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:documentdetector/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Create a mock CameraDescription (empty for test purposes)
    final cameraDescription = CameraDescription(
      name: 'Test Camera',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 0,
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(camera: cameraDescription));

    // Verify that the app launches successfully by checking for CardDetectorScreen.
    expect(find.byType(CardDetectorScreen), findsOneWidget);
  });
}
