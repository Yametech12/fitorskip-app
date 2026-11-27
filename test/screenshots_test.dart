/// Phone-size screenshot capture for the owner's verdict.
///
/// Run with: flutter test test/screenshots_test.dart --update-goldens
/// PNGs land in ../screenshots/ at 1080x2400 (Redmi-class logical
/// 360x800 at 3x). This file is deliberately NOT part of the CI test step:
/// golden bytes are environment-specific. The test environment renders
/// text with a block test font, so DejaVu is loaded as the family
/// 'FOSFont' and the Material Icons font is registered, purely so the
/// captures are legible. On a phone the platform fonts are used instead.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:fitorskip/app_state.dart';
import 'package:fitorskip/main.dart';
import 'package:fitorskip/models.dart';
import 'package:fitorskip/render/try_on_provider.dart';
import 'package:fitorskip/screens/result_screen.dart';
import 'package:fitorskip/theme.dart';
import 'package:fitorskip/verdict/heuristic_scorers.dart';
import 'package:fitorskip/verdict/verdict_engine.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String profileFixture = 'test/fixtures/profile.png';
const String garmentFixture = 'test/fixtures/garment.png';

const String testFontFamily = 'FOSFont';


Future<void> loadTestFonts() async {
  final textLoader = FontLoader(testFontFamily);
  for (final path in [
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
  ]) {
    final bytes = await File(path).readAsBytes();
    textLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await textLoader.load();

  final iconLoader = FontLoader('MaterialIcons');
  final iconBytes = await File(
          '/home/hatch/workspace/flutter-sdk/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
      .readAsBytes();
  iconLoader.addFont(Future.value(ByteData.view(iconBytes.buffer)));
  await iconLoader.load();
}

ThemeData withTestFont(ThemeData base) => base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: testFontFamily),
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle:
            base.appBarTheme.titleTextStyle?.copyWith(fontFamily: testFontFamily),
      ),
    );

void phoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Future<AppController> seededController({
  bool consent = true,
  bool withPhoto = false,
  List<TryOnRecord> history = const [],
  List<WardrobeItem> wardrobe = const [],
  int creditsUsed = 0,
}) async {
  SharedPreferences.setMockInitialValues({
    'fos.consent.v1': consent,
    'fos.creditsUsed.v1': creditsUsed,
  });
  final controller = AppController();
  await controller.load();
  if (withPhoto) controller.profilePhotoPath = profileFixture;
  controller.history = history;
  controller.wardrobe = wardrobe;
  return controller;
}

final sampleWardrobeItem = WardrobeItem(
  id: 'wshot1',
  createdAt: DateTime(2026, 11, 25, 9, 0),
  photoPath: garmentFixture,
  garment: const GarmentProfile(
    color: GarmentColor.navy,
    printScale: PrintScale.none,
    neckline: Neckline.crew,
    fit: GarmentFit.regular,
    styles: {StyleTag.casual},
    occasions: {Occasion.everyday},
  ),
  sampledColor: GarmentColor.teal,
);

TryOnRecord sampleRecord({
  required String id,
  required GarmentProfile garment,
  required Occasion occasion,
  required DateTime at,
  GarmentColor? sampledColor,
}) {
  final verdict = buildHeuristicVerdictEngine().evaluate(VerdictContext(
    wearer: WearerProfile.defaults,
    garment: garment,
    occasion: occasion,
    sampledColor: sampledColor,
  ));
  return TryOnRecord.fromVerdict(
    id: id,
    createdAt: at,
    profilePhotoPath: profileFixture,
    garmentPhotoPath: garmentFixture,
    renderPhotoPath: garmentFixture,
    garment: garment,
    occasion: occasion,
    verdict: verdict,
    cost: const RenderCostRecord(
      providerId: 'demo-composite',
      estimatedCostUsd: 0,
      isDemo: true,
      note: 'demo',
    ),
  );
}

const pwedeGarment = GarmentProfile(
  color: GarmentColor.navy,
  printScale: PrintScale.large,
  neckline: Neckline.turtleneck,
  fit: GarmentFit.slim,
  styles: {StyleTag.casual},
  occasions: {Occasion.everyday},
);

const bagayGarment = GarmentProfile(
  color: GarmentColor.red,
  printScale: PrintScale.medium,
  neckline: Neckline.collared,
  fit: GarmentFit.regular,
  styles: {StyleTag.casual, StyleTag.street},
  occasions: {Occasion.everyday},
);

Future<void> settleImages(WidgetTester tester) async {
  final context = tester.element(find.byType(MaterialApp));
  await tester.runAsync(() async {
    await precacheImage(FileImage(File(profileFixture)), context);
    await precacheImage(FileImage(File(garmentFixture)), context);
    // The Results and Wardrobe grids decode at tile width (cacheWidth
    // 540): precache that resized variant too, or the capture can
    // snap before the resized decode lands.
    await precacheImage(
      ResizeImage(FileImage(File(garmentFixture)), width: 540),
      context,
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
  });
  await tester.pump();
}

Widget appWith(AppController controller, {ThemeMode mode = ThemeMode.light}) {
  // A fresh key per pump: in this UI fork a re-pumped MaterialApp keeps
  // its first theme mode unless the widget identity changes.
  return FitOrSkipApp(
    key: UniqueKey(),
    controller: controller,
    themeMode: mode,
    fontFamily: testFontFamily,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadTestFonts();
  });

  testWidgets('welcome light and dark', (tester) async {
    phoneSurface(tester);
    final controller = await seededController(consent: false);
    await tester.pumpWidget(appWith(controller));
    await tester.pump();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../screenshots/light_welcome.png'));

    await tester.pumpWidget(appWith(controller, mode: ThemeMode.dark));
    await tester.pump();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../screenshots/dark_welcome.png'));
  });

  testWidgets('intake light', (tester) async {
    phoneSurface(tester);
    final controller = await seededController(withPhoto: true);
    await tester.pumpWidget(appWith(controller));
    await tester.pump();
    await settleImages(tester);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../screenshots/light_intake.png'));
  });

  testWidgets('result light and dark', (tester) async {
    phoneSurface(tester);
    final record = sampleRecord(
      id: 'shot1',
      garment: pwedeGarment,
      occasion: Occasion.everyday,
      at: DateTime(2026, 11, 27, 12, 30),
    );
    final controller = await seededController();
    await tester.pumpWidget(AppScope(
      controller: controller,
      child: MaterialApp(
        theme: withTestFont(FitTheme.light()),
        home: ResultScreen(record: record),
      ),
    ));
    await tester.pump();
    await settleImages(tester);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../screenshots/light_result.png'));

    await tester.pumpWidget(AppScope(
      controller: controller,
      child: MaterialApp(
        key: UniqueKey(),
        theme: withTestFont(FitTheme.dark()),
        home: ResultScreen(record: record),
      ),
    ));
    await tester.pump();
    await settleImages(tester);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../screenshots/dark_result.png'));
  });

  testWidgets('result photo-sampled light and dark', (tester) async {
    phoneSurface(tester);
    final record = sampleRecord(
      id: 'shot2',
      garment: pwedeGarment,
      occasion: Occasion.everyday,
      at: DateTime(2026, 11, 27, 15, 5),
      sampledColor: GarmentColor.teal,
    );
    final controller = await seededController();
    await tester.pumpWidget(AppScope(
      controller: controller,
      child: MaterialApp(
        theme: withTestFont(FitTheme.light()),
        home: ResultScreen(record: record),
      ),
    ));
    await tester.pump();
    await settleImages(tester);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../screenshots/light_result_sampled.png'));

    await tester.pumpWidget(AppScope(
      controller: controller,
      child: MaterialApp(
        key: UniqueKey(),
        theme: withTestFont(FitTheme.dark()),
        home: ResultScreen(record: record),
      ),
    ));
    await tester.pump();
    await settleImages(tester);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../screenshots/dark_result_sampled.png'));
  });

  testWidgets('results empty light', (tester) async {
    phoneSurface(tester);
    final controller = await seededController(withPhoto: true);
    await tester.pumpWidget(appWith(controller));
    await tester.pump();
    await tester.tap(find.text('Results'));
    await tester.pump();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../screenshots/light_results_empty.png'));
  });

  testWidgets('credits out dark', (tester) async {
    phoneSurface(tester);
    final controller =
        await seededController(withPhoto: true, creditsUsed: 3);
    await tester.pumpWidget(appWith(controller, mode: ThemeMode.dark));
    await tester.pump();
    await tester.tap(find.text('Credits'));
    await tester.pump();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../screenshots/dark_credits_empty.png'));
  });

  testWidgets('results gallery light and dark', (tester) async {
    phoneSurface(tester);
    final records = [
      sampleRecord(
        id: 'h1',
        garment: bagayGarment,
        occasion: Occasion.everyday,
        at: DateTime(2026, 11, 27, 11, 5),
      ),
      sampleRecord(
        id: 'h2',
        garment: pwedeGarment,
        occasion: Occasion.school,
        at: DateTime(2026, 11, 26, 18, 40),
      ),
    ];
    final controller = await seededController(
        withPhoto: true, history: records, creditsUsed: 2);
    await tester.pumpWidget(appWith(controller));
    await tester.pump();
    await tester.tap(find.text('Results'));
    await tester.pump();
    await settleImages(tester);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../screenshots/light_results.png'));

    await tester.pumpWidget(appWith(controller, mode: ThemeMode.dark));
    await tester.pump();
    await tester.tap(find.text('Results'));
    await tester.pump();
    await settleImages(tester);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../screenshots/dark_results.png'));
  });

  testWidgets('wardrobe light and dark', (tester) async {
    phoneSurface(tester);
    final controller = await seededController(
        withPhoto: true, wardrobe: [sampleWardrobeItem]);
    await tester.pumpWidget(appWith(controller));
    await tester.pump();
    await tester.tap(find.text('Wardrobe'));
    await tester.pump();
    await settleImages(tester);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../screenshots/light_wardrobe.png'));

    await tester.pumpWidget(appWith(controller, mode: ThemeMode.dark));
    await tester.pump();
    await tester.tap(find.text('Wardrobe'));
    await tester.pump();
    await settleImages(tester);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../screenshots/dark_wardrobe.png'));
  });

  testWidgets('wardrobe item try-on start light', (tester) async {
    phoneSurface(tester);
    final controller = await seededController(
        withPhoto: true, wardrobe: [sampleWardrobeItem]);
    await tester.pumpWidget(appWith(controller));
    await tester.pump();
    await tester.tap(find.text('Wardrobe'));
    await tester.pump();
    await settleImages(tester);
    await tester.tap(find.text('Teal crew neck'));
    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../screenshots/light_wardrobe_item.png'));
  });

  testWidgets('credits light and dark', (tester) async {
    phoneSurface(tester);
    final controller =
        await seededController(withPhoto: true, creditsUsed: 1);
    await tester.pumpWidget(appWith(controller));
    await tester.pump();
    await tester.tap(find.text('Credits'));
    await tester.pump();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../screenshots/light_credits.png'));

    await tester.pumpWidget(appWith(controller, mode: ThemeMode.dark));
    await tester.pump();
    await tester.tap(find.text('Credits'));
    await tester.pump();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../screenshots/dark_credits.png'));
  });
}
