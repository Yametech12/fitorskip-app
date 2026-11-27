import 'dart:io';
import 'dart:ui' as ui;

import 'package:fitorskip/render/demo_try_on_provider.dart';
import 'package:fitorskip/render/try_on_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo provider composites a labelled PNG at zero cost',
      (tester) async {
    const provider = DemoTryOnProvider();
    // Real file IO and the image codec need the real async zone.
    final outcome = await tester.runAsync(() async {
      final result = await provider.render(const TryOnRequest(
        id: 'test1',
        profilePhotoPath: 'test/fixtures/profile.png',
        garmentPhotoPath: 'test/fixtures/garment.png',
      ));
      final codec =
          await ui.instantiateImageCodec(result.renderPngBytes);
      final frame = await codec.getNextFrame();
      final size = (frame.image.width, frame.image.height);
      frame.image.dispose();
      return (result, size);
    });
    expect(outcome, isNotNull);
    final (result, size) = outcome!;

    expect(result.isDemo, isTrue);
    expect(result.cost.estimatedCostUsd, 0);
    expect(result.cost.providerId, 'demo-composite');
    expect(result.renderPngBytes.length, greaterThan(10000));
    // PNG magic bytes.
    expect(result.renderPngBytes.sublist(0, 4),
        equals([0x89, 0x50, 0x4E, 0x47]));
    expect(size, (900, 1200));
  });

  test('fixture photos exist and are PNGs', () {
    for (final path in [
      'test/fixtures/profile.png',
      'test/fixtures/garment.png',
    ]) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: path);
      final bytes = file.readAsBytesSync();
      expect(bytes.sublist(0, 4), equals([0x89, 0x50, 0x4E, 0x47]));
    }
  });
}
