import 'package:uuid/uuid.dart';

import '../models/student_face_profile.dart';

class FaceEnrollmentInput {
  const FaceEnrollmentInput({
    required this.studentId,
    required this.embeddings,
    required this.modelVersion,
    this.referenceImageUrl,
  });

  final String studentId;
  final List<List<double>> embeddings;
  final String modelVersion;
  final String? referenceImageUrl;
}

class FaceEnrollmentService {
  FaceEnrollmentService({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  StudentFaceProfile enroll(FaceEnrollmentInput input) {
    if (input.embeddings.length < 3) {
      throw ArgumentError('At least 3 face captures are required for enrollment.');
    }

    final embedding = _averageEmbedding(input.embeddings);
    final now = DateTime.now();

    return StudentFaceProfile(
      id: _uuid.v4(),
      studentId: input.studentId,
      faceEmbedding: embedding,
      modelVersion: input.modelVersion,
      captureCount: input.embeddings.length,
      enrollmentStatus: 'active',
      createdAt: now,
      updatedAt: now,
      referenceImageUrl: input.referenceImageUrl,
    );
  }

  List<double> _averageEmbedding(List<List<double>> embeddings) {
    final length = embeddings.first.length;
    if (length == 0) return const <double>[];

    for (final embedding in embeddings) {
      if (embedding.length != length) {
        throw ArgumentError('All embeddings must have the same length.');
      }
    }

    final output = List<double>.filled(length, 0);
    for (final embedding in embeddings) {
      for (var i = 0; i < length; i++) {
        output[i] += embedding[i];
      }
    }

    for (var i = 0; i < length; i++) {
      output[i] = output[i] / embeddings.length;
    }

    return output;
  }
}
