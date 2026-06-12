import 'package:get_storage/get_storage.dart';

enum LiveSessionRuntimeMode { demo, production }

extension LiveSessionRuntimeModeX on LiveSessionRuntimeMode {
  String get label {
    switch (this) {
      case LiveSessionRuntimeMode.demo:
        return 'Demo';
      case LiveSessionRuntimeMode.production:
        return 'Production';
    }
  }

  String get storageValue {
    switch (this) {
      case LiveSessionRuntimeMode.demo:
        return 'demo';
      case LiveSessionRuntimeMode.production:
        return 'production';
    }
  }
}

class LiveSessionRuntimeModeStore {
  LiveSessionRuntimeModeStore._();

  static const String _kMode = 'liveSessions.runtimeMode';

  static LiveSessionRuntimeMode load() {
    final box = GetStorage();
    final raw = box.read(_kMode)?.toString().trim().toLowerCase();
    switch (raw) {
      case 'production':
        return LiveSessionRuntimeMode.production;
      case 'demo':
      default:
        return LiveSessionRuntimeMode.demo;
    }
  }

  static Future<void> save(LiveSessionRuntimeMode mode) async {
    await GetStorage().write(_kMode, mode.storageValue);
  }
}
