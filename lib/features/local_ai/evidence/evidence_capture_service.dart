import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../core/local_ai_event.dart';

class EvidenceCaptureRequest {
  const EvidenceCaptureRequest({
    required this.sessionId,
    required this.studentId,
    required this.event,
    this.captureScreenshot = false,
    this.captureAudioClip = false,
    this.captureCameraClip = false,
    this.reason,
  });

  final String sessionId;
  final String studentId;
  final LocalAiEvent event;
  final bool captureScreenshot;
  final bool captureAudioClip;
  final bool captureCameraClip;
  final String? reason;
}

class EvidenceArtifact {
  const EvidenceArtifact({
    required this.id,
    required this.kind,
    required this.path,
    required this.status,
    this.mimeType,
    this.sizeBytes,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String kind;
  final String path;
  final String status;
  final String? mimeType;
  final int? sizeBytes;
  final Map<String, Object?> metadata;

  bool get isCaptured => status == 'captured';
  bool get isPending => status.startsWith('pending');

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'kind': kind,
    'path': path,
    'status': status,
    'mimeType': mimeType,
    'sizeBytes': sizeBytes,
    'metadata': metadata,
  };

  factory EvidenceArtifact.fromJson(Map<String, dynamic> json) {
    return EvidenceArtifact(
      id: (json['id'] as String?) ?? '',
      kind: (json['kind'] as String?) ?? 'unknown',
      path: (json['path'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'unknown',
      mimeType: json['mimeType'] as String?,
      sizeBytes: json['sizeBytes'] as int?,
      metadata: Map<String, Object?>.from(
        (json['metadata'] as Map?) ?? const <String, Object?>{},
      ),
    );
  }
}

class EvidenceManifest {
  const EvidenceManifest({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.eventType,
    required this.severity,
    required this.createdAt,
    required this.manifestPath,
    required this.artifacts,
    required this.sourceEvent,
    this.reason,
  });

  final String id;
  final String sessionId;
  final String studentId;
  final String eventType;
  final String severity;
  final DateTime createdAt;
  final String manifestPath;
  final List<EvidenceArtifact> artifacts;
  final Map<String, Object?> sourceEvent;
  final String? reason;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'sessionId': sessionId,
    'studentId': studentId,
    'eventType': eventType,
    'severity': severity,
    'createdAt': createdAt.toIso8601String(),
    'manifestPath': manifestPath,
    'artifacts': artifacts.map((artifact) => artifact.toJson()).toList(),
    'sourceEvent': sourceEvent,
    'reason': reason,
  };

  factory EvidenceManifest.fromJson(Map<String, dynamic> json) {
    return EvidenceManifest(
      id: (json['id'] as String?) ?? '',
      sessionId: (json['sessionId'] as String?) ?? 'local-session',
      studentId: (json['studentId'] as String?) ?? 'local-student',
      eventType: (json['eventType'] as String?) ?? 'unknown',
      severity: (json['severity'] as String?) ?? 'info',
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      manifestPath: (json['manifestPath'] as String?) ?? '',
      artifacts: ((json['artifacts'] as List?) ?? const <Object?>[])
          .whereType<Map>()
          .map(
            (artifact) =>
                EvidenceArtifact.fromJson(Map<String, dynamic>.from(artifact)),
          )
          .toList(),
      sourceEvent: Map<String, Object?>.from(
        (json['sourceEvent'] as Map?) ?? const <String, Object?>{},
      ),
      reason: json['reason'] as String?,
    );
  }
}

class EvidenceCaptureResult {
  const EvidenceCaptureResult({
    required this.event,
    this.evidenceId,
    this.manifestPath,
    this.screenshotPath,
    this.audioClipPath,
    this.cameraClipPath,
    this.manifest,
  });

  final LocalAiEvent event;
  final String? evidenceId;
  final String? manifestPath;
  final String? screenshotPath;
  final String? audioClipPath;
  final String? cameraClipPath;
  final EvidenceManifest? manifest;

  bool get hasEvidence =>
      manifestPath != null ||
      screenshotPath != null ||
      audioClipPath != null ||
      cameraClipPath != null;

  Map<String, Object?> toJson() => <String, Object?>{
    'evidenceId': evidenceId,
    'manifestPath': manifestPath,
    'screenshotPath': screenshotPath,
    'audioClipPath': audioClipPath,
    'cameraClipPath': cameraClipPath,
    'manifest': manifest?.toJson(),
  };

  LocalAiEvent toEvidenceEvent() {
    return LocalAiEvent(
      type: LocalAiEventType.evidenceCaptured,
      severity: LocalAiSeverity.info,
      timestamp: DateTime.now(),
      riskPoints: 0,
      sessionId: event.sessionId,
      studentId: event.studentId,
      message: 'Evidence captured for ${event.type.name}.',
      evidencePath: manifestPath,
      metadata: <String, Object?>{
        'sourceEvent': event.toJson(),
        'evidenceId': evidenceId,
        'manifestPath': manifestPath,
        'screenshotPath': screenshotPath,
        'audioClipPath': audioClipPath,
        'cameraClipPath': cameraClipPath,
        'manifest': manifest?.toJson(),
      },
    );
  }
}

class EvidenceArtifactRequest {
  const EvidenceArtifactRequest({
    required this.evidenceId,
    required this.kind,
    required this.mimeType,
    required this.studentId,
    required this.sessionId,
    required this.event,
    this.reason,
  });

  final String evidenceId;
  final String kind;
  final String mimeType;
  final String studentId;
  final String sessionId;
  final LocalAiEvent event;
  final String? reason;
}

abstract class EvidenceArtifactCaptureHook {
  Future<EvidenceArtifact?> captureArtifact(EvidenceArtifactRequest request);
}

class EvidenceCaptureService {
  EvidenceCaptureService({
    GetStorage? storage,
    EvidenceArtifactCaptureHook? artifactCaptureHook,
  }) : _storage = storage,
       _artifactCaptureHook = artifactCaptureHook;

  static const _vaultPrefix = 'evidence.vault';
  static const _maxManifestsPerStudent = 500;
  static final Map<String, List<Map<String, dynamic>>> _memoryVault =
      <String, List<Map<String, dynamic>>>{};

  final GetStorage? _storage;
  final EvidenceArtifactCaptureHook? _artifactCaptureHook;

  bool get _useMemoryStore => Get.testMode;

  Future<EvidenceCaptureResult> capture(EvidenceCaptureRequest request) async {
    if (!shouldCaptureEvidence(request.event)) {
      return EvidenceCaptureResult(event: request.event);
    }

    final studentId = _safeId(request.studentId, fallback: 'local-student');
    final sessionId = _safeId(request.sessionId, fallback: 'local-session');
    final evidenceId = _nextEvidenceId(request.event.type.name);
    final manifestPath = 'evidence://$studentId/$sessionId/$evidenceId.json';
    final artifacts = <EvidenceArtifact>[
      EvidenceArtifact(
        id: '$evidenceId-manifest',
        kind: 'manifest',
        path: manifestPath,
        status: 'captured',
        mimeType: 'application/json',
      ),
      if (request.captureScreenshot)
        await _captureOrMarkPending(
          evidenceId: evidenceId,
          kind: 'screenshot',
          mimeType: 'image/png',
          studentId: studentId,
          sessionId: sessionId,
          event: request.event,
          reason: request.reason,
        ),
      if (request.captureAudioClip)
        await _captureOrMarkPending(
          evidenceId: evidenceId,
          kind: 'audioClip',
          mimeType: 'audio/wav',
          studentId: studentId,
          sessionId: sessionId,
          event: request.event,
          reason: request.reason,
        ),
      if (request.captureCameraClip)
        await _captureOrMarkPending(
          evidenceId: evidenceId,
          kind: 'cameraClip',
          mimeType: 'video/mp4',
          studentId: studentId,
          sessionId: sessionId,
          event: request.event,
          reason: request.reason,
        ),
    ];

    final manifest = EvidenceManifest(
      id: evidenceId,
      sessionId: sessionId,
      studentId: studentId,
      eventType: request.event.type.name,
      severity: request.event.severity.name,
      createdAt: DateTime.now(),
      manifestPath: manifestPath,
      artifacts: artifacts,
      sourceEvent: request.event.toJson(),
      reason: request.reason,
    );

    await _saveManifest(manifest);

    return EvidenceCaptureResult(
      event: request.event,
      evidenceId: evidenceId,
      manifestPath: manifestPath,
      screenshotPath: _pathForKind(artifacts, 'screenshot'),
      audioClipPath: _pathForKind(artifacts, 'audioClip'),
      cameraClipPath: _pathForKind(artifacts, 'cameraClip'),
      manifest: manifest,
    );
  }

  bool shouldCaptureEvidence(LocalAiEvent event) {
    return event.severity == LocalAiSeverity.high ||
        event.severity == LocalAiSeverity.critical ||
        event.shouldAlertInvigilator;
  }

  List<EvidenceManifest> loadManifests(String studentId) {
    final safeStudentId = _safeId(studentId, fallback: 'local-student');
    final raw = _readVault(safeStudentId);
    return raw
        .whereType<Map>()
        .map(
          (entry) =>
              EvidenceManifest.fromJson(Map<String, dynamic>.from(entry)),
        )
        .where((manifest) => manifest.id.trim().isNotEmpty)
        .toList();
  }

  Future<void> clearAllForStudent(String studentId) async {
    final safeStudentId = _safeId(studentId, fallback: 'local-student');
    if (_useMemoryStore) {
      _memoryVault.remove(_vaultKey(safeStudentId));
      return;
    }
    await _box.remove(_vaultKey(safeStudentId));
  }

  Future<void> _saveManifest(EvidenceManifest manifest) async {
    final existing = loadManifests(manifest.studentId);
    final payload = <Map<String, dynamic>>[
      Map<String, dynamic>.from(manifest.toJson()),
      ...existing.map((entry) => Map<String, dynamic>.from(entry.toJson())),
    ].take(_maxManifestsPerStudent).toList();

    await _writeVault(manifest.studentId, payload);
  }

  Future<EvidenceArtifact> _captureOrMarkPending({
    required String evidenceId,
    required String kind,
    required String mimeType,
    required String studentId,
    required String sessionId,
    required LocalAiEvent event,
    required String? reason,
  }) async {
    final hook = _artifactCaptureHook;
    if (hook != null) {
      try {
        final artifact = await hook.captureArtifact(
          EvidenceArtifactRequest(
            evidenceId: evidenceId,
            kind: kind,
            mimeType: mimeType,
            studentId: studentId,
            sessionId: sessionId,
            event: event,
            reason: reason,
          ),
        );
        if (artifact != null) return artifact;
      } catch (error) {
        return _pendingArtifact(
          evidenceId,
          kind,
          mimeType,
          error: error.toString(),
        );
      }
    }

    return _pendingArtifact(evidenceId, kind, mimeType);
  }

  EvidenceArtifact _pendingArtifact(
    String evidenceId,
    String kind,
    String mimeType, {
    String? error,
  }) {
    final extension = switch (kind) {
      'screenshot' => 'png',
      'audioClip' => 'wav',
      'cameraClip' => 'mp4',
      _ => 'bin',
    };
    return EvidenceArtifact(
      id: '$evidenceId-$kind',
      kind: kind,
      path: 'evidence://pending/$evidenceId/$kind.$extension',
      status: error == null ? 'pendingPlatformCapture' : 'captureHookFailed',
      mimeType: mimeType,
      metadata: <String, Object?>{
        'note': 'Platform capture hook not attached yet.',
        if (error != null) 'error': error,
      },
    );
  }

  String? _pathForKind(List<EvidenceArtifact> artifacts, String kind) {
    for (final artifact in artifacts) {
      if (artifact.kind == kind) return artifact.path;
    }
    return null;
  }

  String _nextEvidenceId(String prefix) {
    final safePrefix = prefix.trim().isEmpty ? 'event' : prefix.trim();
    return 'evidence-$safePrefix-${DateTime.now().microsecondsSinceEpoch}';
  }

  String _safeId(String? value, {required String fallback}) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return fallback;
    return normalized;
  }

  String _vaultKey(String studentId) => '$_vaultPrefix.$studentId';

  List<dynamic> _readVault(String studentId) {
    final key = _vaultKey(studentId);
    if (_useMemoryStore) {
      return List<Map<String, dynamic>>.from(
        _memoryVault[key] ?? const <Map<String, dynamic>>[],
      );
    }
    return (_box.read(key) as List?) ?? const <dynamic>[];
  }

  Future<void> _writeVault(
    String studentId,
    List<Map<String, dynamic>> payload,
  ) async {
    final key = _vaultKey(studentId);
    if (_useMemoryStore) {
      _memoryVault[key] = payload
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
      return;
    }
    await _box.write(key, payload);
  }

  GetStorage get _box => _storage ?? GetStorage();
}
