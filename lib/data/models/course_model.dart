class CourseModel {
  const CourseModel(
    this.code,
    this.title, {
    this.id,
    this.notes = false,
    this.pastQuestions = false,
    this.progress = 0,
  });

  final int? id;
  final String code;
  final String title;
  final bool notes;
  final bool pastQuestions;
  final int progress;
}
