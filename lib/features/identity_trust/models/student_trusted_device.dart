class StudentTrustedDevice {
  const StudentTrustedDevice({
    required this.id,
    required this.studentId,
    required this.deviceId,
    required this.deviceType,
    required this.osName,
    required this.appVersion,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.trustStatus,
    this.osVersion,
    this.lastFaceMatchScore,
  });

  final String id;
  final String studentId;
  final String deviceId;
  final String deviceType;
  final String osName;
  final String? osVersion;
  final String appVersion;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final String trustStatus;
  final double? lastFaceMatchScore;

  bool get isTrusted => trustStatus == 'trusted';
  bool get isPending => trustStatus == 'pending';
  bool get isBlocked => trustStatus == 'blocked';

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'studentId': studentId,
        'deviceId': deviceId,
        'deviceType': deviceType,
        'osName': osName,
        'osVersion': osVersion,
        'appVersion': appVersion,
        'firstSeenAt': firstSeenAt.toIso8601String(),
        'lastSeenAt': lastSeenAt.toIso8601String(),
        'trustStatus': trustStatus,
        'lastFaceMatchScore': lastFaceMatchScore,
      };

  factory StudentTrustedDevice.fromJson(Map<String, Object?> json) {
    return StudentTrustedDevice(
      id: '${json['id']}',
      studentId: '${json['studentId']}',
      deviceId: '${json['deviceId']}',
      deviceType: '${json['deviceType']}',
      osName: '${json['osName']}',
      osVersion: json['osVersion'] as String?,
      appVersion: '${json['appVersion']}',
      firstSeenAt: DateTime.tryParse('${json['firstSeenAt']}') ?? DateTime.now(),
      lastSeenAt: DateTime.tryParse('${json['lastSeenAt']}') ?? DateTime.now(),
      trustStatus: '${json['trustStatus']}',
      lastFaceMatchScore: (json['lastFaceMatchScore'] as num?)?.toDouble(),
    );
  }
}
