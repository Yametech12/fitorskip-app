/// App-wide state for FitOrSkip v1.
///
/// Local only, on purpose: accounts and cloud sync are later plan phases.
/// Photos are copied into the app's own documents folder so history survives
/// the system cleaning the image-picker cache. Preferences and history
/// metadata live in shared_preferences as JSON.
library;

import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'render/demo_try_on_provider.dart';
import 'render/try_on_provider.dart';
import 'verdict/heuristic_scorers.dart';
import 'verdict/verdict_engine.dart';

/// The render provider factory. Swapping in the real fal.ai provider later
/// is this one line plus the implementation in fal_try_on_provider.dart.
TryOnProvider createTryOnProvider() => const DemoTryOnProvider();

/// Credit model from the GT-153 plan, as display logic only. Payments are
/// not integrated in v1.
class CreditModel {
  static const int freeTierTryOns = 3;
  static const int packPricePhp = 99;
  static const int packCredits = 30;
  static const int sellerStarterPricePhp = 499;
  static const int sellerStarterTryOns = 100;
  static const int sellerProPricePhp = 799;
  static const int sellerProTryOns = 200;
}

class AppController extends ChangeNotifier {
  AppController({this._prefs});

  static const String _kConsent = 'fos.consent.v1';
  static const String _kProfilePhoto = 'fos.profilePhoto.v1';
  static const String _kWearer = 'fos.wearer.v1';
  static const String _kCreditsUsed = 'fos.creditsUsed.v1';
  static const String _kHistory = 'fos.history.v1';

  SharedPreferences? _prefs;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  bool consentGiven = false;
  String? profilePhotoPath;
  WearerProfile wearer = WearerProfile.defaults;
  int creditsUsed = 0;
  List<TryOnRecord> history = [];

  final VerdictEngine verdictEngine = buildHeuristicVerdictEngine();
  final TryOnProvider renderProvider = createTryOnProvider();

  // Purchased packs join the total here in a later phase.
  int get creditsTotal => CreditModel.freeTierTryOns;
  int get creditsRemaining =>
      (creditsTotal - creditsUsed).clamp(0, creditsTotal).toInt();
  bool get hasCredits => creditsRemaining > 0;
  bool get hasProfilePhoto =>
      profilePhotoPath != null && File(profilePhotoPath!).existsSync();

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs!;
    consentGiven = prefs.getBool(_kConsent) ?? false;
    profilePhotoPath = prefs.getString(_kProfilePhoto);
    final wearerJson = prefs.getString(_kWearer);
    if (wearerJson != null) {
      wearer = WearerProfile.fromJson(
          (jsonDecode(wearerJson) as Map).cast<String, Object?>());
    }
    creditsUsed = prefs.getInt(_kCreditsUsed) ?? 0;
    final historyJson = prefs.getString(_kHistory);
    if (historyJson != null) {
      final decoded = jsonDecode(historyJson) as List<Object?>;
      history = decoded
          .map((e) =>
              TryOnRecord.fromJson((e as Map).cast<String, Object?>()))
          .toList();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> acceptConsent() async {
    consentGiven = true;
    await _prefs?.setBool(_kConsent, true);
    notifyListeners();
  }

  Future<void> saveWearer(WearerProfile value) async {
    wearer = value;
    await _prefs?.setString(_kWearer, jsonEncode(value.toJson()));
    notifyListeners();
  }

  /// Copies a picked photo into the app's photo folder and returns the
  /// stored path, so it survives cache cleaning.
  Future<String> storePhoto(String sourcePath, String prefix) async {
    final docs = await getApplicationDocumentsDirectory();
    final folder = Directory('${docs.path}/fitorskip_photos');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final ext = sourcePath.contains('.')
        ? sourcePath.substring(sourcePath.lastIndexOf('.'))
        : '.jpg';
    final name =
        '${prefix}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final target = File('${folder.path}/$name');
    await File(sourcePath).copy(target.path);
    return target.path;
  }

  Future<void> setProfilePhoto(String storedPath) async {
    profilePhotoPath = storedPath;
    await _prefs?.setString(_kProfilePhoto, storedPath);
    notifyListeners();
  }

  Future<File> writeRenderBytes(String id, List<int> bytes) async {
    final docs = await getApplicationDocumentsDirectory();
    final folder = Directory('${docs.path}/fitorskip_photos');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final file = File('${folder.path}/render_$id.png');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Records a completed try-on and consumes one credit. Called only after
  /// a render succeeds, so a timed-out render never costs a credit.
  Future<void> completeTryOn(TryOnRecord record) async {
    history = [record, ...history];
    creditsUsed += 1;
    await _prefs?.setString(
        _kHistory, jsonEncode(history.map((r) => r.toJson()).toList()));
    await _prefs?.setInt(_kCreditsUsed, creditsUsed);
    notifyListeners();
  }

  Future<void> deleteRecord(TryOnRecord record) async {
    history = history.where((r) => r.id != record.id).toList();
    for (final path in [record.garmentPhotoPath, record.renderPhotoPath]) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _prefs?.setString(
        _kHistory, jsonEncode(history.map((r) => r.toJson()).toList()));
    notifyListeners();
  }

  /// The plan's one-tap delete all: photos, history, consent, credits.
  Future<void> deleteAllData() async {
    final docs = await getApplicationDocumentsDirectory();
    final folder = Directory('${docs.path}/fitorskip_photos');
    if (await folder.exists()) {
      await folder.delete(recursive: true);
    }
    await _prefs?.remove(_kConsent);
    await _prefs?.remove(_kProfilePhoto);
    await _prefs?.remove(_kWearer);
    await _prefs?.remove(_kCreditsUsed);
    await _prefs?.remove(_kHistory);
    consentGiven = false;
    profilePhotoPath = null;
    wearer = WearerProfile.defaults;
    creditsUsed = 0;
    history = [];
    notifyListeners();
  }
}

/// Inherited access to the single [AppController].
class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope missing above this context');
    return scope!.notifier!;
  }
}
