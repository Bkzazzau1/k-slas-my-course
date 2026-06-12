import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/services/storage_service.dart';

class SettingsController extends GetxController {
  final targetGrade = StorageService.getTargetGrade().obs;
  final dailyStudyMin = StorageService.getDailyStudyMin().obs;
  final preferredTime = StorageService.getPreferredTime().obs;
  final examMode = StorageService.getExamMode().obs;

  final darkMode = StorageService.getDarkMode().obs;
  final dataSaver = StorageService.getDataSaver().obs;
  final offlineDownloads = StorageService.getOfflineDownloads().obs;
  final demoMode = StorageService.getDemoMode().obs;

  String get dailyStudyLabel {
    final m = dailyStudyMin.value;
    final h = m ~/ 60;
    final r = m % 60;
    if (h == 0) return "${r}m";
    if (r == 0) return "${h}h";
    return "${h}h ${r}m";
  }

  Future<void> setTargetGrade(String v) async {
    targetGrade.value = v;
    await StorageService.setTargetGrade(v);
  }

  Future<void> setDailyStudyMin(int v) async {
    dailyStudyMin.value = v;
    await StorageService.setDailyStudyMin(v);
  }

  Future<void> setPreferredTime(String v) async {
    preferredTime.value = v;
    await StorageService.setPreferredTime(v);
  }

  Future<void> setExamMode(String v) async {
    examMode.value = v;
    await StorageService.setExamMode(v);
  }

  Future<void> setDarkMode(bool v) async {
    darkMode.value = v;
    await StorageService.setDarkMode(v);
    Get.changeThemeMode(v ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setDataSaver(bool v) async {
    dataSaver.value = v;
    await StorageService.setDataSaver(v);
  }

  Future<void> setOfflineDownloads(bool v) async {
    offlineDownloads.value = v;
    await StorageService.setOfflineDownloads(v);
  }

  Future<void> setDemoMode(bool v) async {
    demoMode.value = v;
    await StorageService.setDemoMode(v);
  }

  Future<void> clearCache() async {
    await StorageService.clearCache();

    // reset in-memory to defaults after erase
    targetGrade.value = StorageService.getTargetGrade();
    dailyStudyMin.value = StorageService.getDailyStudyMin();
    preferredTime.value = StorageService.getPreferredTime();
    examMode.value = StorageService.getExamMode();
    darkMode.value = StorageService.getDarkMode();
    dataSaver.value = StorageService.getDataSaver();
    offlineDownloads.value = StorageService.getOfflineDownloads();
    demoMode.value = StorageService.getDemoMode();
  }
}
