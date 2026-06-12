import 'exam_models.dart';

class TimetableType {
  static const String classes = "CLASSES";
  static const String exams = "EXAMS";
}

class TimetableEventModel {
  TimetableEventModel({
    required this.id,
    required this.type,
    required this.courseCode,
    required this.title,
    required this.start,
    required this.end,
    required this.location,
    this.deliveryMode = ExamDeliveryMode.remoteProctored,
    this.dayOfWeek, // 1=Mon ... 7=Sun (for classes)
    this.isReadOnly = true, // curated vs student-created
  });

  final String id;
  final String type; // CLASSES or EXAMS
  final String courseCode;
  final String title;

  final DateTime start;
  final DateTime end;

  final String location;
  final ExamDeliveryMode deliveryMode;

  // For weekly class timetable (recurring)
  final int? dayOfWeek;

  // curated by school (read-only) OR student custom event (editable)
  final bool isReadOnly;

  bool get isExam => type == TimetableType.exams;
  bool get isRemoteProctored =>
      deliveryMode == ExamDeliveryMode.remoteProctored;

  int get minutes => end.difference(start).inMinutes;

  TimetableEventModel copyWith({
    String? id,
    String? type,
    String? courseCode,
    String? title,
    DateTime? start,
    DateTime? end,
    String? location,
    ExamDeliveryMode? deliveryMode,
    int? dayOfWeek,
    bool? isReadOnly,
  }) {
    return TimetableEventModel(
      id: id ?? this.id,
      type: type ?? this.type,
      courseCode: courseCode ?? this.courseCode,
      title: title ?? this.title,
      start: start ?? this.start,
      end: end ?? this.end,
      location: location ?? this.location,
      deliveryMode: deliveryMode ?? this.deliveryMode,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isReadOnly: isReadOnly ?? this.isReadOnly,
    );
  }
}
