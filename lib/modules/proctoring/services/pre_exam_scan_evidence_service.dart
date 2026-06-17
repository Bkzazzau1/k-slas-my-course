import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class PreExamScanEvidenceTarget {
  const PreExamScanEvidenceTarget({
    required this.target,
    required this.path,
    required this.labels,
    required this.lightingScore,
    required this.movementScore,
    required this.sceneDiversityScore,
    required this.capturedAt,
  });

  final String target;
  final String path;
  final List<String> labels;
  final double lightingScore;
  final double movementScore;
  final double sceneDiversityScore;
  final DateTime capturedAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'target': target,
    'path': path,
    'labels': labels,
    'lighting_score': lightingScore,
    'movement_score': movementScore,
    'scene_diversity_score': sceneDiversityScore,
    'captured_at': capturedAt.toIso8601String(),
  };
}

class PreExamScanCalibrationEntry {
  const PreExamScanCalibrationEntry({
    required this.target,
    required this.frameSourceMode,
    required this.lightingScore,
    required this.movementScore,
    required this.sceneDiversityScore,
    required this.detectedLabels,
    required this.forbiddenLabels,
    required this.environmentDecision,
    required this.timestamp,
    this.framePath,
    this.note,
  });

  final String target;
  final String frameSourceMode;
  final double lightingScore;
  final double movementScore;
  final double sceneDiversityScore;
  final List<String> detectedLabels;
  final List<String> forbiddenLabels;
  final String environmentDecision;
  final DateTime timestamp;
  final String? framePath;
  final String? note;

  Map<String, Object?> toJson() => <String, Object?>{
    'target': target,
    'frame_source_mode': frameSourceMode,
    'lighting_score': lightingScore,
    'movement_score': movementScore,
    'scene_diversity_score': sceneDiversityScore,
    'detected_labels': detectedLabels,
    'forbidden_labels': forbiddenLabels,
    'environment_decision': environmentDecision,
    'timestamp': timestamp.toIso8601String(),
    if (framePath != null) 'frame_path': framePath,
    if (note != null) 'note': note,
  };
}

class PreExamScanEvidenceManifest {
  const PreExamScanEvidenceManifest({
    required this.id,
    required this.path,
    required this.calibrationLogPath,
    required this.environmentType,
    required this.overallStatus,
    required this.targets,
    required this.createdAt,
  });

  final String id;
  final String path;
  final String calibrationLogPath;
  final String environmentType;
  final String overallStatus;
  final List<PreExamScanEvidenceTarget> targets;
  final DateTime createdAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'path': path,
    'calibration_log_path': calibrationLogPath,
    'environment_type': environmentType,
    'overall_status': overallStatus,
    'created_at': createdAt.toIso8601String(),
    'targets': targets.map((target) => target.toJson()).toList(),
  };
}

class PreExamScanEvidenceService {
  PreExamScanEvidenceService({Directory? outputDirectory})
    : _outputDirectory = outputDirectory;

  final Directory? _outputDirectory;
  final List<PreExamScanEvidenceTarget> _targets =
      <PreExamScanEvidenceTarget>[];
  final List<PreExamScanCalibrationEntry> _calibrationEntries =
      <PreExamScanCalibrationEntry>[];

  String? _scanId;
  Directory? _scanDirectory;

  List<PreExamScanEvidenceTarget> get targets =>
      List<PreExamScanEvidenceTarget>.unmodifiable(_targets);

  List<PreExamScanCalibrationEntry> get calibrationEntries =>
      List<PreExamScanCalibrationEntry>.unmodifiable(_calibrationEntries);

  Future<void> startScan() async {
    _targets.clear();
    _calibrationEntries.clear();
    _scanId = 'pre-exam-scan-${DateTime.now().microsecondsSinceEpoch}';
    final root =
        _outputDirectory ??
        Directory(
          '${Directory.systemTemp.path}${Platform.pathSeparator}k_slas_pre_exam_scan',
        );
    _scanDirectory = Directory(
      '${root.path}${Platform.pathSeparator}${_sanitize(_scanId!)}',
    );
    await _scanDirectory!.create(recursive: true);
  }

  Future<PreExamScanEvidenceTarget> saveDecodedTarget({
    required String target,
    required img.Image image,
    required List<String> labels,
    required double lightingScore,
    required double movementScore,
    required double sceneDiversityScore,
  }) async {
    await _ensureStarted();
    final file = _targetFile(target);
    await file.writeAsBytes(img.encodeJpg(image, quality: 84), flush: true);
    return _upsertTarget(
      target: target,
      path: file.uri.toString(),
      labels: labels,
      lightingScore: lightingScore,
      movementScore: movementScore,
      sceneDiversityScore: sceneDiversityScore,
    );
  }

  Future<PreExamScanEvidenceTarget?> saveCameraImageTarget({
    required String target,
    required CameraImage image,
    required List<String> labels,
    required double lightingScore,
    required double movementScore,
    required double sceneDiversityScore,
  }) async {
    if (image.planes.isEmpty) return null;
    await _ensureStarted();
    final file = _targetFile(target);
    final decoded = _grayscaleImage(image);
    await file.writeAsBytes(img.encodeJpg(decoded, quality: 84), flush: true);
    return _upsertTarget(
      target: target,
      path: file.uri.toString(),
      labels: labels,
      lightingScore: lightingScore,
      movementScore: movementScore,
      sceneDiversityScore: sceneDiversityScore,
    );
  }

  Future<PreExamScanEvidenceManifest> saveManifest({
    required String environmentType,
    required String overallStatus,
  }) async {
    await _ensureStarted();
    final now = DateTime.now();
    final calibrationLogFile = File(
      '${_scanDirectory!.path}${Platform.pathSeparator}calibration-log.json',
    );
    await calibrationLogFile.writeAsString(
      jsonEncode(_calibrationEntries.map((entry) => entry.toJson()).toList()),
      flush: true,
    );
    final file = File(
      '${_scanDirectory!.path}${Platform.pathSeparator}manifest.json',
    );
    final manifest = PreExamScanEvidenceManifest(
      id: _scanId!,
      path: file.uri.toString(),
      calibrationLogPath: calibrationLogFile.uri.toString(),
      environmentType: environmentType,
      overallStatus: overallStatus,
      targets: targets,
      createdAt: now,
    );
    await file.writeAsString(jsonEncode(manifest.toJson()), flush: true);
    return manifest;
  }

  Future<void> logCalibrationEntry({
    required String target,
    required String frameSourceMode,
    required double lightingScore,
    required double movementScore,
    required double sceneDiversityScore,
    required List<String> detectedLabels,
    required List<String> forbiddenLabels,
    required String environmentDecision,
    String? framePath,
    String? note,
  }) async {
    await _ensureStarted();
    _calibrationEntries.add(
      PreExamScanCalibrationEntry(
        target: target,
        frameSourceMode: frameSourceMode,
        lightingScore: lightingScore,
        movementScore: movementScore,
        sceneDiversityScore: sceneDiversityScore,
        detectedLabels: List<String>.from(detectedLabels),
        forbiddenLabels: List<String>.from(forbiddenLabels),
        environmentDecision: environmentDecision,
        timestamp: DateTime.now(),
        framePath: framePath,
        note: note,
      ),
    );
  }

  Future<void> _ensureStarted() async {
    if (_scanId != null && _scanDirectory != null) return;
    await startScan();
  }

  File _targetFile(String target) {
    return File(
      '${_scanDirectory!.path}${Platform.pathSeparator}${_sanitize(target)}.jpg',
    );
  }

  PreExamScanEvidenceTarget _upsertTarget({
    required String target,
    required String path,
    required List<String> labels,
    required double lightingScore,
    required double movementScore,
    required double sceneDiversityScore,
  }) {
    _targets.removeWhere((entry) => entry.target == target);
    final entry = PreExamScanEvidenceTarget(
      target: target,
      path: path,
      labels: List<String>.from(labels),
      lightingScore: lightingScore,
      movementScore: movementScore,
      sceneDiversityScore: sceneDiversityScore,
      capturedAt: DateTime.now(),
    );
    _targets.add(entry);
    return entry;
  }

  img.Image _grayscaleImage(CameraImage cameraImage) {
    final plane = cameraImage.planes.first;
    final image = img.Image(
      width: cameraImage.width,
      height: cameraImage.height,
    );
    for (var y = 0; y < cameraImage.height; y++) {
      final rowOffset = y * plane.bytesPerRow;
      for (var x = 0; x < cameraImage.width; x++) {
        final index = (rowOffset + x).clamp(0, plane.bytes.length - 1);
        final value = plane.bytes[index];
        image.setPixelRgb(x, y, value, value, value);
      }
    }
    return image;
  }

  String _sanitize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}
