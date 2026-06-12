class Course {
  const Course({
    required this.code,
    required this.title,
    this.notes = false,
    this.pastQuestions = false,
    this.progress = 0,
  });

  final String code;
  final String title;
  final bool notes;
  final bool pastQuestions;
  final int progress;
}
