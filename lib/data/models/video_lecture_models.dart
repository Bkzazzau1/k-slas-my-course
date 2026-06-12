import 'student_category.dart';

class VideoLectureModel {
  const VideoLectureModel({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.lecturerName,
    required this.videoUrl,
    required this.durationMinutes,
    required this.audienceKeys,
    this.tags = const [],
    this.allowDownloads = true,
    this.requireWatchedMark = true,
    this.publishedAt,
    this.updatedAt,
    this.watchedBy = const <String, String>{},
  });

  final String id;
  final String courseCode;
  final String courseTitle;
  final String title;
  final String subtitle;
  final String description;
  final String lecturerName;
  final String videoUrl;
  final int durationMinutes;
  final List<String> audienceKeys;
  final List<String> tags;
  final bool allowDownloads;
  final bool requireWatchedMark;
  final DateTime? publishedAt;
  final DateTime? updatedAt;
  final Map<String, String> watchedBy;

  List<StudentCategory> get audiences {
    return audienceKeys.map(studentCategoryFromStorage).toList();
  }

  bool isVisibleTo(StudentCategory category) {
    if (audienceKeys.isEmpty) return true;
    return audienceKeys.contains(category.storageKey);
  }

  bool isWatchedBy(String studentId) {
    final key = studentId.trim().toLowerCase();
    if (key.isEmpty) return false;
    return watchedBy.containsKey(key);
  }

  DateTime? watchedAtFor(String studentId) {
    final value = watchedBy[studentId.trim().toLowerCase()];
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  VideoLectureModel copyWith({
    String? id,
    String? courseCode,
    String? courseTitle,
    String? title,
    String? subtitle,
    String? description,
    String? lecturerName,
    String? videoUrl,
    int? durationMinutes,
    List<String>? audienceKeys,
    List<String>? tags,
    bool? allowDownloads,
    bool? requireWatchedMark,
    DateTime? publishedAt,
    DateTime? updatedAt,
    Map<String, String>? watchedBy,
  }) {
    return VideoLectureModel(
      id: id ?? this.id,
      courseCode: courseCode ?? this.courseCode,
      courseTitle: courseTitle ?? this.courseTitle,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      lecturerName: lecturerName ?? this.lecturerName,
      videoUrl: videoUrl ?? this.videoUrl,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      audienceKeys: audienceKeys ?? this.audienceKeys,
      tags: tags ?? this.tags,
      allowDownloads: allowDownloads ?? this.allowDownloads,
      requireWatchedMark: requireWatchedMark ?? this.requireWatchedMark,
      publishedAt: publishedAt ?? this.publishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      watchedBy: watchedBy ?? this.watchedBy,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'courseCode': courseCode,
    'courseTitle': courseTitle,
    'title': title,
    'subtitle': subtitle,
    'description': description,
    'lecturerName': lecturerName,
    'videoUrl': videoUrl,
    'durationMinutes': durationMinutes,
    'audienceKeys': audienceKeys,
    'tags': tags,
    'allowDownloads': allowDownloads,
    'requireWatchedMark': requireWatchedMark,
    'publishedAt': publishedAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'watchedBy': watchedBy,
  };

  factory VideoLectureModel.fromJson(Map<String, dynamic> json) {
    final watchedMap = json['watchedBy'] as Map? ?? const {};

    return VideoLectureModel(
      id: json['id']?.toString() ?? '',
      courseCode: json['courseCode']?.toString() ?? '',
      courseTitle: json['courseTitle']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      lecturerName: json['lecturerName']?.toString() ?? '',
      videoUrl: json['videoUrl']?.toString() ?? '',
      durationMinutes: json['durationMinutes'] is int
          ? json['durationMinutes'] as int
          : int.tryParse(json['durationMinutes']?.toString() ?? '') ?? 0,
      audienceKeys: (json['audienceKeys'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      tags: (json['tags'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      allowDownloads: json['allowDownloads'] != false,
      requireWatchedMark: json['requireWatchedMark'] != false,
      publishedAt: DateTime.tryParse(json['publishedAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      watchedBy: watchedMap.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
    );
  }
}
