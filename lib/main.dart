import 'package:material_ui/material_ui.dart';

import 'app_state.dart';
import 'screens/home_shell.dart';
import 'screens/welcome_consent_screen.dart';
import 'theme.dart';

void main() {
  runApp(const FitOrSkipApp());
}

class FitOrSkipApp extends StatefulWidget {
  const FitOrSkipApp({
    super.key,
    this.controller,
    this.themeMode,
    this.fontFamily,
  });

  /// Test seams: widget tests inject a preloaded controller, and the
  /// screenshot harness pins the theme mode and a bundled test font.
  final AppController? controller;
  final ThemeMode? themeMode;
  final String? fontFamily;

  @override
  State<FitOrSkipApp> createState() => _FitOrSkipAppState();
}

class _FitOrSkipAppState extends State<FitOrSkipApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AppController();
    if (widget.controller == null) {
      _controller.load();
    }
  }

  ThemeData _themed(ThemeData base) {
    final family = widget.fontFamily;
    if (family == null) return base;
    // Button labels in this UI fork resolve their text style outside the
    // text theme, so the family is applied to the button themes as well.
    // This path runs only when a test font family is injected.
    final buttonText = ButtonStyle(
      textStyle:
          WidgetStatePropertyAll(TextStyle(fontFamily: family)),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: family),
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle:
            base.appBarTheme.titleTextStyle?.copyWith(fontFamily: family),
      ),
      filledButtonTheme: FilledButtonThemeData(style: buttonText),
      outlinedButtonTheme: OutlinedButtonThemeData(style: buttonText),
      textButtonTheme: TextButtonThemeData(style: buttonText),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: MaterialApp(
        title: 'FitOrSkip',
        theme: _themed(FitTheme.light()),
        darkTheme: _themed(FitTheme.dark()),
        themeMode: widget.themeMode ?? ThemeMode.system,
        home: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (!_controller.isLoaded) return const SplashScreen();
            if (!_controller.consentGiven) {
              return const WelcomeConsentScreen();
            }
            return const HomeShell();
          },
        ),
      ),
    );
  }
}

/// Branded splash shown while local state loads. Carries the credit line,
/// per the app rules.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: FitColors.petrol,
                borderRadius: BorderRadius.circular(22),
              ),
              child:
                  const Icon(Icons.checkroom, color: Colors.white, size: 46),
            ),
            const SizedBox(height: 18),
            Text('FitOrSkip', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              'Snap a shirt. See it on you. Get the verdict.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.66),
              ),
            ),
            const SizedBox(height: 30),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 30),
            Text(
              'Made by Mohammad Sidique Ibrahim',
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
