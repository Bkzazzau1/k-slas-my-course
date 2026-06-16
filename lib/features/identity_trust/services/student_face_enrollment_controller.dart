import '../../../data/services/student_profile_storage.dart';
import '../models/student_face_profile.dart';
import 'camera_face_enrollment_sampler.dart';
import 'face_embedding_connector.dart';
import 'face_enrollment_service.dart';
import 'identity_trust_repository.dart';
import 'static_face_embedding_connector.dart';

class StudentFaceEnrollmentSnapshot {
  const StudentFaceEnrollmentSnapshot({
    required this.studentId,
    required this.requiredSamples,
    required this.capturedSamples,
    required this.isComplete,
    required this.statusText,
    this.profile,
    this.lastQualityScore,
  });

  final String studentId;
  final int requiredSamples;
  final int capturedSamples;
  final bool isComplete;
  final String statusText;
  final StudentFaceProfile? profile;
  final double? lastQualityScore;
}

class StudentFaceEnrollmentController {
  StudentFaceEnrollmentController({
    required IdentityTrustRepository repository,
    FaceEnrollmentService? enrollmentService,
    FaceEmbeddingConnector? connector,
    this.requiredSamples = 3,
  })  : _repository = repository,
        _enrollmentService = enrollmentService ?? FaceEnrollmentService(),
        _connector = connector ??
            StaticFaceEmbeddingConnector(
              embedding: const <double>[1, 0, 0],
              version: 'demo-static-face-v1',
            );

  final IdentityTrustRepository _repository;
  final FaceEnrollmentService _enrollmentService;
  final FaceEmbeddingConnector _connector;
  final int requiredSamples;
  final List<List<double>> _samples = <List<double>>[];

  StudentFaceProfile? _profile;
  String _statusText = 'Ready to start face enrollment.';
  double? _lastQualityScore;
  String? _lastModelVersion;

  StudentFaceEnrollmentSnapshot get snapshot => StudentFaceEnrollmentSnapshot(
        studentId: _studentId,
        requiredSamples: requiredSamples,
        capturedSamples: _samples.length,
        isComplete: _profile?.isActive ?? false,
        statusText: _statusText,
        profile: _profile,
        lastQualityScore: _lastQualityScore,
      );

  Future<StudentFaceEnrollmentSnapshot> load() async {
    final studentId = _studentId;
    if (studentId.isEmpty) {
      _statusText = 'Student profile is missing. Please login again.';
      return snapshot;
    }

    _profile = await _repository.getFaceProfile(studentId);
    if (_profile?.isActive ?? false) {
      _statusText = 'Face enrollment is already active.';
    }
    return snapshot;
  }

  Future<StudentFaceEnrollmentSnapshot> addDemoSample() async {
    final studentId = _studentId;
    if (studentId.isEmpty) {
      _statusText = 'Student profile is missing. Please login again.';
      return snapshot;
    }

    if (!_connector.isReady) {
      await _connector.load();
    }

    _lastModelVersion = _connector.modelVersion;
    _lastQualityScore = 1.0;
    return _addEmbeddingSample(
      studentId: studentId,
      embedding: const <double>[1, 0, 0],
      modelVersion: _connector.modelVersion,
      qualityScore: 1.0,
    );
  }

  Future<StudentFaceEnrollmentSnapshot> addCameraSample(
    CameraFaceEnrollmentSampler sampler,
  ) async {
    final studentId = _studentId;
    if (studentId.isEmpty) {
      _statusText = 'Student profile is missing. Please login again.';
      return snapshot;
    }

    try {
      final sample = await sampler.captureSample(studentId: studentId);
      _lastModelVersion = sample.modelVersion;
      _lastQualityScore = sample.qualityScore;
      return _addEmbeddingSample(
        studentId: studentId,
        embedding: sample.embedding,
        modelVersion: sample.modelVersion,
        qualityScore: sample.qualityScore,
      );
    } catch (e) {
      _statusText = 'Face sample could not be captured: $e';
      return snapshot;
    }
  }

  Future<StudentFaceEnrollmentSnapshot> _addEmbeddingSample({
    required String studentId,
    required List<double> embedding,
    required String modelVersion,
    double? qualityScore,
  }) async {
    if (embedding.isEmpty) {
      _statusText = 'Face sample rejected because the embedding was empty.';
      return snapshot;
    }

    _samples.add(embedding);
    _statusText = 'Sample ${_samples.length} of $requiredSamples captured.';
    if (qualityScore != null) {
      _statusText = 'Sample ${_samples.length} of $requiredSamples captured. Quality ${(qualityScore * 100).round()}%.';
    }

    if (_samples.length >= requiredSamples) {
      final profile = _enrollmentService.enroll(
        FaceEnrollmentInput(
          studentId: studentId,
          embeddings: List<List<double>>.from(_samples),
          modelVersion: _lastModelVersion ?? modelVersion,
        ),
      );
      await _repository.saveFaceProfile(profile);
      _profile = profile;
      _statusText = 'Face enrollment completed successfully.';
    }

    return snapshot;
  }

  void reset() {
    _samples.clear();
    _profile = null;
    _lastQualityScore = null;
    _lastModelVersion = null;
    _statusText = 'Ready to start face enrollment.';
  }

  String get _studentId {
    final profile = StudentProfileStorage.load();
    final matricNo = profile?.matricNo?.trim() ?? '';
    if (matricNo.isNotEmpty) return matricNo;
    final email = profile?.email?.trim() ?? '';
    if (email.isNotEmpty) return email;
    return '';
  }
}
