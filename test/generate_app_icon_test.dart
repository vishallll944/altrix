import 'dart:io';
import 'dart:ui' as ui;

import 'package:altrix/widgets/altrix_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('generate app icon assets', (tester) async {
    const canvasSize = 1024.0;
    const logoSize = 896.0;

    await tester.binding.setSurfaceSize(const Size(canvasSize, canvasSize));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: RepaintBoundary(
              child: AltrixLogo(size: logoSize, showShadow: false),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byType(RepaintBoundary),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    final iconDir = Directory('assets/icon');
    await iconDir.create(recursive: true);

    final bytes = byteData!.buffer.asUint8List();
    await File('assets/icon/app_icon.png').writeAsBytes(bytes);
    await File('assets/icon/app_icon_foreground.png').writeAsBytes(bytes);
  });
}
