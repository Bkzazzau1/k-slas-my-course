class RevisionTask {
  RevisionTask({
    required this.title,
    required this.minutes,
    required this.type, // "REVISION" | "PRACTICE" | "FLASHCARDS"
    this.meta = const {},
  });

  final String title;
  final int minutes;
  final String type;
  final Map<String, dynamic> meta;
}

class DailyRevisionPlan {
  DailyRevisionPlan({
    required this.courseCode,
    required this.focusTopic,
    required this.reason,
    required this.tasks,
  });

  final String courseCode;
  final String focusTopic;
  final String reason;
  final List<RevisionTask> tasks;

  int get totalMinutes => tasks.fold(0, (a, b) => a + b.minutes);
}
