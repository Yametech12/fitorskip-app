/// Premium redesign directions for the owner's pick (GT-176 item 8).
///
/// Three directions, each a real theme variant over the real screens
/// plus a working prototype of its named engine. NOTHING here is wired
/// into the app: the Hang Tag design stays live until the owner picks.
///
/// Run with: flutter test test/redesign_directions_test.dart
///   --update-goldens
/// PNGs land in ../screenshots/directions/ at 1080x2400.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:fitorskip/app_state.dart';
import 'package:fitorskip/models.dart';
import 'package:fitorskip/render/try_on_provider.dart';
import 'package:fitorskip/screens/garment_intake_screen.dart';
import 'package:fitorskip/screens/wardrobe_screen.dart';
import 'package:fitorskip/theme.dart';
import 'package:fitorskip/verdict/heuristic_scorers.dart';
import 'package:fitorskip/verdict/verdict_engine.dart';
import 'package:fitorskip/widgets/verdict_card.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String profileFixture = 'test/fixtures/profile.png';
const String garmentFixture = 'test/fixtures/garment.png';

const String sansFamily = 'FOSFont';

const String serifFamily = 'FOSSerif';

Future<void> loadFonts() async {
  final sans = FontLoader(sansFamily);
  for (final path in [
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
  ]) {
    final bytes = await File(path).readAsBytes();
    sans.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await sans.load();

  final serif = FontLoader(serifFamily);
  for (final path in [
    '/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf',
  ]) {
    final bytes = await File(path).readAsBytes();
    serif.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await serif.load();

  final icons = FontLoader('MaterialIcons');
  final iconBytes = await File(
          '/home/hatch/workspace/flutter-sdk/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
      .readAsBytes();
  icons.addFont(Future.value(ByteData.view(iconBytes.buffer)));
  await icons.load();
}

void phoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Future<AppController> seeded() async {
  SharedPreferences.setMockInitialValues({'fos.consent.v1': true});
  final controller = AppController();
  await controller.load();
  controller.profilePhotoPath = profileFixture;
  controller.wardrobe = [
    WardrobeItem(
      id: 'dw1',
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
    ),
  ];
  return controller;
}

TryOnRecord sampleRecord() {
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
  return TryOnRecord.fromVerdict(
    id: 'dir1',
    createdAt: DateTime(2026, 11, 27, 12, 30),
    profilePhotoPath: profileFixture,
    garmentPhotoPath: garmentFixture,
    renderPhotoPath: garmentFixture,
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
}

ThemeData directionTheme({
  required bool dark,
  required ColorScheme scheme,
  required String family,
  required double cardRadius,
}) {
  final base = dark ? FitTheme.dark() : FitTheme.light();
  final buttonText = ButtonStyle(
    textStyle: WidgetStatePropertyAll(TextStyle(fontFamily: family)),
  );
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: base.textTheme.apply(
      fontFamily: family,
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      titleTextStyle:
          base.appBarTheme.titleTextStyle?.copyWith(fontFamily: family),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(style: buttonText),
    outlinedButtonTheme: OutlinedButtonThemeData(style: buttonText),
    textButtonTheme: TextButtonThemeData(style: buttonText),
  );
}

ColorScheme atelierScheme(bool dark) => dark
    ? const ColorScheme.dark(
        primary: Color(0xFFC9A35F),
        onPrimary: Color(0xFF241A0C),
        secondary: Color(0xFF8A6D3B),
        surface: Color(0xFF171310),
        onSurface: Color(0xFFEDE4D3),
        surfaceContainerLowest: Color(0xFF211B16),
      )
    : const ColorScheme.light(
        primary: Color(0xFF6B4226),
        onPrimary: Color(0xFFFFF8EC),
        secondary: Color(0xFFB08D3E),
        surface: Color(0xFFF7F1E5),
        onSurface: Color(0xFF2B2118),
        surfaceContainerLowest: Color(0xFFFFFDF8),
      );

ColorScheme rackScheme(bool dark) => dark
    ? const ColorScheme.dark(
        primary: Color(0xFFF5F5F5),
        onPrimary: Color(0xFF0C0C0C),
        secondary: Color(0xFFB7E01B),
        surface: Color(0xFF0C0C0C),
        onSurface: Color(0xFFF5F5F5),
        surfaceContainerLowest: Color(0xFF171717),
      )
    : const ColorScheme.light(
        primary: Color(0xFF111111),
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFF7FA600),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF111111),
        surfaceContainerLowest: Color(0xFFF4F4F2),
      );

ColorScheme counterScheme(bool dark) => dark
    ? const ColorScheme.dark(
        primary: Color(0xFF8FA2FF),
        onPrimary: Color(0xFF0E1220),
        secondary: Color(0xFFFF8C5A),
        surface: Color(0xFF0E1220),
        onSurface: Color(0xFFE6E9F5),
        surfaceContainerLowest: Color(0xFF171C30),
      )
    : const ColorScheme.light(
        primary: Color(0xFF2B3A8F),
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFFFF6B35),
        surface: Color(0xFFEEF0F6),
        onSurface: Color(0xFF1B2340),
        surfaceContainerLowest: Color(0xFFFFFFFF),
      );

/// Direction 1 engine prototype: drag a dimension along the tailor's
/// tape and the projected score moves with it.
class WhatIfTape extends StatefulWidget {
  const WhatIfTape({super.key, required this.baseScore});

  final int baseScore;

  @override
  State<WhatIfTape> createState() => _WhatIfTapeState();
}

class _WhatIfTapeState extends State<WhatIfTape> {
  final Map<String, double> _deltas = {
    'Fit on you': 0,
    'Print scale': 0,
    'Color harmony': 0,
  };

  int get _projected {
    final total = _deltas.values.fold<double>(0, (a, b) => a + b);
    return (widget.baseScore + total / _deltas.length)
        .round()
        .clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final band = VerdictBandLabel.fromScore(_projected);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('THE WHAT-IF TAPE',
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 4),
            Text(
              'Slide a fix along the tape. The projected score moves '
              'before you spend anything.',
              style: theme.textTheme.bodySmall,
            ),
            for (final entry in _deltas.entries) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 104,
                    child: Text(entry.key,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  Expanded(
                    child: Slider(
                      value: entry.value,
                      min: -20,
                      max: 20,
                      divisions: 40,
                      onChanged: (v) =>
                          setState(() => _deltas[entry.key] = v),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      entry.value >= 0
                          ? '+${entry.value.round()}'
                          : '${entry.value.round()}',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Projected: $_projected - ${band.label}',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

/// Direction 2 engine prototype: the wardrobe as a clothing rack you
/// slide along, with a rail position indicator.
class RackRail extends StatelessWidget {
  const RackRail({super.key, required this.items});

  final List<WardrobeItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text('THE RACK',
              style: theme.textTheme.labelLarge?.copyWith(
                letterSpacing: 1.6,
                fontWeight: FontWeight.w800,
              )),
        ),
        SizedBox(
          height: 178,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return SizedBox(
                width: 132,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Image.file(
                          File(item.photoPath),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          cacheWidth: 396,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          '${item.displayColor.label} '
                          '${item.garment.neckline.label.toLowerCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 4,
                color: theme.colorScheme.secondary,
              ),
              Expanded(
                child: Container(
                  height: 2,
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Direction 2, result side: the verdict travels as the garment's
/// own swing tag, the same tag the Rack shows on every card.
class SwingTag extends StatelessWidget {
  const SwingTag({super.key, required this.record});

  final TryOnRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.onSurface, width: 3),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('THE SWING TAG',
                      style: theme.textTheme.labelLarge?.copyWith(
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    '${record.band.label} ${record.overallScore} - '
                    '${record.garment.color.label} '
                    '${record.garment.neckline.label.toLowerCase()}, '
                    '${record.occasion.label.toLowerCase()}. '
                    'One tag, readable at arm\'s length on the rack.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Direction 3 engine prototype: the verdict meets the price tag.
/// Cost per wear and a value call, from the score and the price.
class WorthItMeter extends StatefulWidget {
  const WorthItMeter({super.key, required this.score});

  final int score;

  @override
  State<WorthItMeter> createState() => _WorthItMeterState();
}

class _WorthItMeterState extends State<WorthItMeter> {
  static const double _price = 24.99;
  double _wears = 24;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final perWear = _price / _wears;
    final call = widget.score >= 75
        ? 'Worth it'
        : widget.score >= 50
            ? 'Worth it, if the price feels right'
            : 'Skip it at this price';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('THE WORTH-IT METER',
                style: theme.textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 4),
            Text(
              'Priced at \$${_price.toStringAsFixed(2)}. Tell it how '
              'often you would wear it:',
              style: theme.textTheme.bodySmall,
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _wears,
                    min: 1,
                    max: 60,
                    divisions: 59,
                    onChanged: (v) => setState(() => _wears = v),
                  ),
                ),
                SizedBox(
                  width: 76,
                  child: Text(
                    '${_wears.round()} wears',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            Text(
              '\$${perWear.toStringAsFixed(2)} per wear - $call',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

Widget directionApp({
  required ThemeData theme,
  required AppController controller,
  required Widget home,
}) {
  return AppScope(
    controller: controller,
    child: MaterialApp(theme: theme, home: home),
  );
}

Widget resultComposition({
  required TryOnRecord record,
  required Widget engine,
  required String title,
}) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      children: [
        // The engine leads: it is what makes the direction different.
        // The full verdict card follows below it.
        engine,
        const SizedBox(height: 14),
        VerdictCard(verdict: record.toVerdictResult()),
      ],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadFonts();
    await Directory('screenshots/directions').create(recursive: true);
  });

  Future<void> capture(
    WidgetTester tester,
    AppController controller,
    ThemeData theme,
    Widget home,
    String golden,
  ) async {
    await tester.pumpWidget(directionApp(
      theme: theme,
      controller: controller,
      home: home,
    ));
    await tester.pump();
    await tester.runAsync(() async {
      final context = tester.element(find.byType(MaterialApp));
      await precacheImage(FileImage(File(garmentFixture)), context);
      await precacheImage(
        ResizeImage(FileImage(File(garmentFixture)), width: 540),
        context,
      );
      await precacheImage(
        ResizeImage(FileImage(File(garmentFixture)), width: 396),
        context,
      );
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await tester.pump();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../screenshots/directions/$golden'));
  }

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';

    testWidgets('atelier $mode', (tester) async {
      phoneSurface(tester);
      final controller = await seeded();
      final theme = directionTheme(
        dark: dark,
        scheme: atelierScheme(dark),
        family: serifFamily,
        cardRadius: 6,
      );
      final record = sampleRecord();
      await capture(
        tester,
        controller,
        theme,
        const Scaffold(body: GarmentIntakeScreen()),
        'atelier_${mode}_home.png',
      );
      await capture(
        tester,
        controller,
        theme,
        resultComposition(
          record: record,
          engine: WhatIfTape(baseScore: record.overallScore),
          title: 'Your verdict',
        ),
        'atelier_${mode}_result.png',
      );
      await capture(
        tester,
        controller,
        theme,
        const Scaffold(body: WardrobeScreen()),
        'atelier_${mode}_wardrobe.png',
      );
    });

    testWidgets('rack $mode', (tester) async {
      phoneSurface(tester);
      final controller = await seeded();
      final theme = directionTheme(
        dark: dark,
        scheme: rackScheme(dark),
        family: sansFamily,
        cardRadius: 2,
      );
      final record = sampleRecord();
      await capture(
        tester,
        controller,
        theme,
        const Scaffold(body: GarmentIntakeScreen()),
        'rack_${mode}_home.png',
      );
      await capture(
        tester,
        controller,
        theme,
        resultComposition(
          record: record,
          engine: SwingTag(record: record),
          title: 'Your verdict',
        ),
        'rack_${mode}_result.png',
      );
      await capture(
        tester,
        controller,
        theme,
        Scaffold(
          body: Column(
            children: [
              RackRail(items: [
                controller.wardrobe.single,
                controller.wardrobe.single,
                controller.wardrobe.single,
              ]),
              const Expanded(child: WardrobeScreen()),
            ],
          ),
        ),
        'rack_${mode}_wardrobe.png',
      );
    });

    testWidgets('counter $mode', (tester) async {
      phoneSurface(tester);
      final controller = await seeded();
      final theme = directionTheme(
        dark: dark,
        scheme: counterScheme(dark),
        family: sansFamily,
        cardRadius: 24,
      );
      final record = sampleRecord();
      await capture(
        tester,
        controller,
        theme,
        const Scaffold(body: GarmentIntakeScreen()),
        'counter_${mode}_home.png',
      );
      await capture(
        tester,
        controller,
        theme,
        resultComposition(
          record: record,
          engine: WorthItMeter(score: record.overallScore),
          title: 'Your verdict',
        ),
        'counter_${mode}_result.png',
      );
      await capture(
        tester,
        controller,
        theme,
        const Scaffold(body: WardrobeScreen()),
        'counter_${mode}_wardrobe.png',
      );
    });
  }
}
