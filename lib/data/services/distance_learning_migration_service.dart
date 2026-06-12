import 'dart:convert';

import 'package:get_storage/get_storage.dart';

import '../models/exam_models.dart';
import 'timetable_storage.dart';

class DistanceLearningMigrationService {
  DistanceLearningMigrationService._();

  static final GetStorage _box = GetStorage();

  static const String _kVersion = 'migration.distanceLearningOnly.v1';
  static const String _kLectures = 'videoLectures.catalog';

  static const Set<String> _distanceAudienceKeys = {
    'distance_undergraduate',
    'distance_postgraduate',
  };

  static Future<void> run() async {
    if (_box.read(_kVersion) == true) return;

    await _migrateVideoLectureCatalog();
    await _migrateTimetableExams();
    await _box.write(_kVersion, true);
  }

  static Future<void> _migrateVideoLectureCatalog() async {
    final raw = _box.read(_kLectures);
    if (raw == null) return;

    try {
      final decoded = jsonDecode(raw) as List;
      final migrated = decoded.whereType<Map>().map((item) {
        final lecture = Map<String, dynamic>.from(item);
        final audienceKeys =
            (lecture['audienceKeys'] as List?)
                ?.map((value) => value.toString())
                .where(_distanceAudienceKeys.contains)
                .toList() ??
            <String>[];

        lecture['audienceKeys'] = audienceKeys.isEmpty
            ? <String>['distance_undergraduate']
            : audienceKeys;
        lecture['subtitle'] = _cleanStudentModeCopy(
          lecture['subtitle']?.toString(),
        );
        lecture['description'] = _cleanStudentModeCopy(
          lecture['description']?.toString(),
        );
        return lecture;
      }).toList();

      await _box.write(_kLectures, jsonEncode(migrated));
    } catch (_) {
      await _box.remove(_kLectures);
    }
  }

  static Future<void> _migrateTimetableExams() async {
    final exams = TimetableStorage.loadExams();
    if (exams.isEmpty) return;

    final migrated = exams
        .map(
          (event) => event.isReadOnly
              ? event.copyWith(
                  deliveryMode: ExamDeliveryMode.remoteProctored,
                  location: event.location.trim().isEmpty
                      ? 'Remote LMS'
                      : _cleanLocation(event.location),
                )
              : event,
        )
        .toList();

    await TimetableStorage.saveExams(migrated);
  }

  static String _cleanStudentModeCopy(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return text;

    return text
        .replaceAll(
          RegExp(r'\bpart[- ]time\b', caseSensitive: false),
          'distance',
        )
        .replaceAll(RegExp(r'\bregular\b', caseSensitive: false), 'distance')
        .replaceAll(
          RegExp(r'\bshort course\b', caseSensitive: false),
          'distance',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _cleanLocation(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('lt ') ||
        normalized.contains('lecture theatre') ||
        normalized.contains('cbt center') ||
        normalized.contains('invigilator')) {
      return 'Remote LMS';
    }
    return value;
  }
}
