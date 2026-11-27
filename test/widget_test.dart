import 'package:material_ui/material_ui.dart' show Size;

import 'package:fitorskip/app_state.dart';
import 'package:fitorskip/main.dart';
import 'package:fitorskip/models.dart';
import 'package:fitorskip/render/try_on_provider.dart';
import 'package:fitorskip/screens/result_screen.dart';
import 'package:fitorskip/verdict/heuristic_scorers.dart';
import 'package:fitorskip/verdict/verdict_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitorskip/widgets/share_verdict_sheet.dart';
import 'package:material_ui/material_ui.dart'
    show MaterialApp, Scrollable, Switch, SwitchListTile;
import 'package:shared_preferences/shared_preferences.dart';

Future<AppController> loadedController(
    {Map<String, Object> seed = const {}}) async {
  SharedPreferences.setMockInitialValues(seed);
  final controller = AppController();
  await controller.load();
  return controller;
}

void usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('first run shows consent, and agreeing enters the shell',
      (tester) async {
    usePhoneSurface(tester);
    final controller = await loadedController();
    await tester.pumpWidget(FitOrSkipApp(controller: controller));
    await tester.pump();

    expect(find.text('FitOrSkip'), findsWidgets);
    await tester.scrollUntilVisible(find.text('30-day auto-delete'), 200);
    expect(find.text('30-day auto-delete'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Agree and start'), 200);
    await tester.pump();
    // The button is disabled until the consent box is ticked, so tapping
    // it must not enter the shell.
    await tester.tap(find.text('Agree and start'));
    await tester.pump();
    expect(find.text('Try on'), findsNothing);
    expect(controller.consentGiven, isFalse);

    await tester.tap(find.textContaining('I agree to FitOrSkip'));
    await tester.pump();
    await tester.tap(find.text('Agree and start'));
    await tester.pump();
    await tester.pump();

    // Shell: bottom navigation with the five tabs.
    expect(find.text('Try on'), findsOneWidget);
    expect(find.text('Results'), findsOneWidget);
    expect(find.text('Wardrobe'), findsOneWidget);
    expect(find.text('Credits'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    // No profile photo yet, so the Try tab asks for one first.
    expect(find.text('One thing first'), findsOneWidget);
    expect(controller.consentGiven, isTrue);
  });

  testWidgets('returning user with consent skips the welcome screen',
      (tester) async {
    final controller = await loadedController(seed: {
      'fos.consent.v1': true,
      'fos.creditsUsed.v1': 1,
    });
    await tester.pumpWidget(FitOrSkipApp(controller: controller));
    await tester.pump();

    expect(find.text('Agree and start'), findsNothing);
    expect(find.text('Try on'), findsOneWidget);
    expect(controller.creditsRemaining, 2);
  });

  testWidgets('credits tab shows the plan model', (tester) async {
    usePhoneSurface(tester);
    final controller = await loadedController(seed: {
      'fos.consent.v1': true,
    });
    await tester.pumpWidget(FitOrSkipApp(controller: controller));
    await tester.pump();

    await tester.tap(find.text('Credits'));
    await tester.pump();
    expect(find.text('Your credits'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Free tier'), 200);
    expect(find.text('Free tier'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Consumer pack'), 200);
    expect(find.text('Consumer pack'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.textContaining('payments arrive'), 200);
    expect(find.textContaining('payments arrive'), findsWidgets);
  });

  testWidgets('about tab carries the credit line and delete all',
      (tester) async {
    usePhoneSurface(tester);
    final controller = await loadedController(seed: {
      'fos.consent.v1': true,
    });
    await tester.pumpWidget(FitOrSkipApp(controller: controller));
    await tester.pump();

    await tester.tap(find.text('About'));
    await tester.pump();
    expect(find.text('About FitOrSkip'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.textContaining('does not measure exact size'), 200);
    expect(find.textContaining('does not measure exact size'),
        findsOneWidget);
    await tester.scrollUntilVisible(find.text('Delete all my data'), 200);
    expect(find.text('Delete all my data'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.text('Made by Mohammad Sidique Ibrahim'), 200);
    expect(find.text('Made by Mohammad Sidique Ibrahim'), findsOneWidget);
  });

  testWidgets('share verdict sheet previews the card, render opt-in off',
      (tester) async {
    usePhoneSurface(tester);
    const garment = GarmentProfile(
      color: GarmentColor.navy,
      printScale: PrintScale.large,
      neckline: Neckline.turtleneck,
      fit: GarmentFit.slim,
      styles: {StyleTag.casual},
      occasions: {Occasion.everyday},
    );
    final verdict = buildHeuristicVerdictEngine().evaluate(
      const VerdictContext(
        wearer: WearerProfile.defaults,
        garment: garment,
        occasion: Occasion.everyday,
        sampledColor: GarmentColor.teal,
      ),
    );
    final record = TryOnRecord.fromVerdict(
      id: 'share1',
      createdAt: DateTime(2026, 11, 27, 12, 30),
      profilePhotoPath: 'test/fixtures/profile.png',
      garmentPhotoPath: 'test/fixtures/garment.png',
      renderPhotoPath: 'test/fixtures/garment.png',
      garment: garment,
      occasion: Occasion.everyday,
      verdict: verdict,
      cost: const RenderCostRecord(
        providerId: 'demo-composite',
        estimatedCostUsd: 0,
        isDemo: true,
        note: 'demo',
      ),
    );
    await tester.pumpWidget(MaterialApp(home: ResultScreen(record: record)));
    await tester.pump();

    // The verdict card states the color came from the photo.
    expect(find.textContaining('read from your garment photo'),
        findsOneWidget);

    await tester.scrollUntilVisible(find.text('Share verdict'), 200);
    await tester.tap(find.text('Share verdict'));
    await tester.pumpAndSettle();

    expect(find.text('Share your verdict'), findsOneWidget);
    expect(find.text('Include the demo render'), findsOneWidget);
    expect(find.text('FitOrSkip - Made by Mohammad Sidique Ibrahim'),
        findsOneWidget);
    final tile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile));
    expect(tile.value, isFalse);

    await tester.scrollUntilVisible(
      find.byType(SwitchListTile),
      120,
      scrollable: find.descendant(
        of: find.byType(ShareVerdictSheet),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(SwitchListTile),
      matching: find.byType(Switch),
    ));
    await tester.pump();
    final tileOn = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile));
    expect(tileOn.value, isTrue);
  });

  testWidgets('results gallery shows cards and opens the full result',
      (tester) async {
    usePhoneSurface(tester);
    final controller = await loadedController(seed: {
      'fos.consent.v1': true,
    });
    const garment = GarmentProfile(
      color: GarmentColor.navy,
      printScale: PrintScale.large,
      neckline: Neckline.turtleneck,
      fit: GarmentFit.slim,
      styles: {StyleTag.casual},
      occasions: {Occasion.everyday},
    );
    final verdict = buildHeuristicVerdictEngine().evaluate(
      const VerdictContext(
        wearer: WearerProfile.defaults,
        garment: garment,
        occasion: Occasion.everyday,
      ),
    );
    controller.history = [
      TryOnRecord.fromVerdict(
        id: 'gal1',
        createdAt: DateTime(2026, 11, 27, 9, 15),
        profilePhotoPath: 'test/fixtures/profile.png',
        garmentPhotoPath: 'test/fixtures/garment.png',
        renderPhotoPath: 'test/fixtures/garment.png',
        garment: garment,
        occasion: Occasion.everyday,
        verdict: verdict,
        cost: const RenderCostRecord(
          providerId: 'demo-composite',
          estimatedCostUsd: 0,
          isDemo: true,
          note: 'demo',
        ),
      ),
    ];
    await tester.pumpWidget(FitOrSkipApp(controller: controller));
    await tester.pump();

    await tester.tap(find.text('Results'));
    await tester.pump();
    // Gallery card: band chip, date, delete affordance.
    expect(find.textContaining('2026-11-27'), findsOneWidget);
    expect(find.byTooltip('Delete this result'), findsOneWidget);

    // Tapping the card opens the full result view.
    await tester.tap(find.textContaining('2026-11-27'));
    await tester.pumpAndSettle();
    expect(find.text('Your verdict'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.text('Save garment to wardrobe'), 200);
    expect(find.text('Save garment to wardrobe'), findsOneWidget);
  });

  testWidgets('wardrobe persists items and opens the item detail',
      (tester) async {
    usePhoneSurface(tester);
    final controller = await loadedController(seed: {
      'fos.consent.v1': true,
    });
    await controller.addWardrobeItem(WardrobeItem(
      id: 'wtest1',
      createdAt: DateTime(2026, 11, 27, 8, 0),
      photoPath: 'test/fixtures/garment.png',
      garment: GarmentProfile(
        color: GarmentColor.navy,
        printScale: PrintScale.none,
        neckline: Neckline.crew,
        fit: GarmentFit.regular,
        styles: {StyleTag.casual},
        occasions: {Occasion.everyday},
      ),
      sampledColor: GarmentColor.teal,
    ));

    // A fresh controller over the same store sees the item: it
    // persisted across an app restart.
    final reloaded = AppController();
    await reloaded.load();
    expect(reloaded.wardrobe, hasLength(1));
    expect(reloaded.wardrobe.single.sampledColor, GarmentColor.teal);
    expect(reloaded.wardrobe.single.displayColor, GarmentColor.teal);

    await tester.pumpWidget(FitOrSkipApp(controller: controller));
    await tester.pump();
    await tester.tap(find.text('Wardrobe'));
    await tester.pump();
    expect(find.text('Teal crew neck'), findsOneWidget);
    expect(find.text('Color read from its photo'), findsOneWidget);

    await tester.tap(find.text('Teal crew neck'));
    await tester.pumpAndSettle();
    expect(find.text('Wardrobe item'), findsOneWidget);
    expect(find.text('See it on me'), findsOneWidget);
    expect(find.textContaining('read from its photo'), findsWidgets);
  });

  test('credit model matches the plan numbers', () {
    expect(CreditModel.freeTierTryOns, 3);
    expect(CreditModel.packPriceUsd, 2.99);
    expect(CreditModel.packCredits, 30);
    expect(CreditModel.sellerStarterPriceUsd, 9.99);
    expect(CreditModel.sellerStarterTryOns, 100);
    expect(CreditModel.sellerProPriceUsd, 16.99);
    expect(CreditModel.sellerProTryOns, 200);
    expect(VerdictBandLabel.fromScore(75), VerdictBand.bagay);
  });
}
