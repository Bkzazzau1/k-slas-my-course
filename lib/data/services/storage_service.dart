import 'package:get_storage/get_storage.dart';

class StorageService {
  StorageService._();
  static final box = GetStorage();

  // Keys
  static const kTargetGrade = "settings.targetGrade";
  static const kDailyStudyMin = "settings.dailyStudyMin";
  static const kPreferredTime = "settings.preferredTime";
  static const kExamMode = "settings.examMode";

  static const kDarkMode = "settings.darkMode";
  static const kDataSaver = "settings.dataSaver";
  static const kOfflineDownloads = "settings.offlineDownloads";
  static const kDemoMode = "settings.demoMode";

  static const bool _defaultDemoMode = bool.fromEnvironment(
    'APP_DEMO_MODE',
    defaultValue: true,
  );

  // Reads with defaults
  static String getTargetGrade() => box.read(kTargetGrade) ?? "B+";
  static int getDailyStudyMin() => box.read(kDailyStudyMin) ?? 90;
  static String getPreferredTime() => box.read(kPreferredTime) ?? "Evening";
  static String getExamMode() => box.read(kExamMode) ?? "Balanced";

  static bool getDarkMode() => box.read(kDarkMode) ?? true;
  static bool getDataSaver() => box.read(kDataSaver) ?? true;
  static bool getOfflineDownloads() => box.read(kOfflineDownloads) ?? false;
  static bool getDemoMode() => box.read(kDemoMode) ?? _defaultDemoMode;

  // Writes
  static Future<void> setTargetGrade(String v) => box.write(kTargetGrade, v);
  static Future<void> setDailyStudyMin(int v) => box.write(kDailyStudyMin, v);
  static Future<void> setPreferredTime(String v) =>
      box.write(kPreferredTime, v);
  static Future<void> setExamMode(String v) => box.write(kExamMode, v);

  static Future<void> setDarkMode(bool v) => box.write(kDarkMode, v);
  static Future<void> setDataSaver(bool v) => box.write(kDataSaver, v);
  static Future<void> setOfflineDownloads(bool v) =>
      box.write(kOfflineDownloads, v);
  static Future<void> setDemoMode(bool v) => box.write(kDemoMode, v);

  static Future<void> clearCache() async {
    // MVP: only clears storage keys
    await box.erase();
  }
}
