class StudentFaceProfile {
  const StudentFaceProfile({
    required this.id,
    required this.studentId,
    required this.faceEmbedding,
    required this.modelVersion,
    required this.captureCount,
    required this.enrollmentStatus,
    required this.createdAt,
    required this.updatedAt,
    this.referenceImageUrl,
  });

  final String id;
  final String studentId;
  final List<double> faceEmbedding;
  final String modelVersion;
  final int captureCount;
  final String enrollmentStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? referenceImageUrl;

  bool get isActive => enrollmentStatus == 'active';

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'studentId': studentId,
        'faceEmbedding': faceEmbedding,
        'modelVersion': modelVersion,
        'captureCount': captureCount,
        'enrollmentStatus': enrollmentStatus,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'referenceImageUrl': referenceImageUrl,
      };

  factory StudentFaceProfile.fromJson(Map<String, Object?> json) {
    return StudentFaceProfile(
      id: '${json['id']}',
      studentId: '${json['studentId']}',
      faceEmbedding: (json['faceEmbedding'] as List? ?? const <Object?>[])
          .map((value) => (value as num).toDouble())
          .toList(),
      modelVersion: '${json['modelVersion']}',
      captureCount: (json['captureCount'] as num?)?.toInt() ?? 0,
      enrollmentStatus: '${json['enrollmentStatus']}',
      createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
      updatedAt: DateTime.tryParse('${json['updatedAt']}') ?? DateTime.now(),
      referenceImageUrl: json['referenceImageUrl'] as String?,
    );
  }
}
