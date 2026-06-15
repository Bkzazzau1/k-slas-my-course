import '../../../data/services/student_profile_storage.dart';
import '../models/student_face_profile.dart';
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
  });

  final String studentId;
  final int requiredSamples;
  final int capturedSamples;
  final bool isComplete;
  final String statusText;
  final StudentFaceProfile? profile;
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

  StudentFaceEnrollmentSnapshot get snapshot => StudentFaceEnrollmentSnapshot(
        studentId: _studentId,
        requiredSamples: requiredSamples,
        capturedSamples: _samples.length,
        isComplete: _profile?.isActive ?? false,
        statusText: _statusText,
        profile: _profile,
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

    _samples.add(const <double>[1, 0, 0]);
    _statusText = 'Sample ${_samples.length} of $requiredSamples captured.';

    if (_samples.length >= requiredSamples) {
      final profile = _enrollmentService.enroll(
        FaceEnrollmentInput(
          studentId: studentId,
          embeddings: List<List<double>>.from(_samples),
          modelVersion: _connector.modelVersion,
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
