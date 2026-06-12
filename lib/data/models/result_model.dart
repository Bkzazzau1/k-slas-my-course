enum ResultWorkflowStatus { submitted, approved, published }

extension ResultWorkflowStatusX on ResultWorkflowStatus {
  String get apiValue {
    switch (this) {
      case ResultWorkflowStatus.submitted:
        return 'submitted';
      case ResultWorkflowStatus.approved:
        return 'approved';
      case ResultWorkflowStatus.published:
        return 'published';
    }
  }

  String get label {
    switch (this) {
      case ResultWorkflowStatus.submitted:
        return 'Awaiting approval';
      case ResultWorkflowStatus.approved:
        return 'Approved';
      case ResultWorkflowStatus.published:
        return 'Published';
    }
  }

  static ResultWorkflowStatus fromApi(String value) {
    switch (value.trim().toLowerCase()) {
      case 'published':
        return ResultWorkflowStatus.published;
      case 'approved':
        return ResultWorkflowStatus.approved;
      case 'submitted':
      case 'draft':
      default:
        return ResultWorkflowStatus.submitted;
    }
  }
}

class ResultModel {
  const ResultModel({
    required this.id,
    required this.courseCode,
    required this.courseTitle,
    required this.studentId,
    required this.studentName,
    required this.assessmentType,
    required this.title,
    required this.score,
    required this.maxScore,
    this.gradedAssessmentScore = 0,
    this.assignmentScore = 0,
    this.groupAssignmentScore = 0,
    this.peerReviewScore = 0,
    this.examinationScore = 0,
    this.totalScore = 0,
    required this.grade,
    required this.remark,
    required this.status,
    this.courseId,
    this.referenceId,
    this.publishedAt,
  });

  final String id;
  final int? courseId;
  final String courseCode;
  final String courseTitle;
  final int studentId;
  final String studentName;
  final String assessmentType;
  final int? referenceId;
  final String title;
  final double score;
  final double maxScore;
  final double gradedAssessmentScore;
  final double assignmentScore;
  final double groupAssignmentScore;
  final double peerReviewScore;
  final double examinationScore;
  final double totalScore;
  final String grade;
  final String remark;
  final ResultWorkflowStatus status;
  final DateTime? publishedAt;

  bool get isRemoteId => int.tryParse(id) != null;
  bool get visibleToStudent => status == ResultWorkflowStatus.published;
  double get effectiveTotalScore => totalScore > 0 ? totalScore : score;
  String get passFailRemark => effectiveTotalScore >= 40 ? 'Passed' : 'Failed';
  double get percentage =>
      maxScore <= 0 ? 0 : (effectiveTotalScore / maxScore) * 100;

  ResultModel copyWith({
    String? id,
    int? courseId,
    String? courseCode,
    String? courseTitle,
    int? studentId,
    String? studentName,
    String? assessmentType,
    int? referenceId,
    String? title,
    double? score,
    double? maxScore,
    double? gradedAssessmentScore,
    double? assignmentScore,
    double? groupAssignmentScore,
    double? peerReviewScore,
    double? examinationScore,
    double? totalScore,
    String? grade,
    String? remark,
    ResultWorkflowStatus? status,
    DateTime? publishedAt,
  }) {
    return ResultModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      courseCode: courseCode ?? this.courseCode,
      courseTitle: courseTitle ?? this.courseTitle,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      assessmentType: assessmentType ?? this.assessmentType,
      referenceId: referenceId ?? this.referenceId,
      title: title ?? this.title,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      gradedAssessmentScore:
          gradedAssessmentScore ?? this.gradedAssessmentScore,
      assignmentScore: assignmentScore ?? this.assignmentScore,
      groupAssignmentScore: groupAssignmentScore ?? this.groupAssignmentScore,
      peerReviewScore: peerReviewScore ?? this.peerReviewScore,
      examinationScore: examinationScore ?? this.examinationScore,
      totalScore: totalScore ?? this.totalScore,
      grade: grade ?? this.grade,
      remark: remark ?? this.remark,
      status: status ?? this.status,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  factory ResultModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? json['uuid']?.toString() ?? '';
    final courseCode = json['course_code']?.toString() ?? '';
    final courseTitle = json['course_title']?.toString() ?? '';
    final studentId = int.tryParse(json['student_id']?.toString() ?? '') ?? 0;
    final score = double.tryParse(json['score']?.toString() ?? '') ?? 0;
    final totalScore =
        double.tryParse(json['total_score']?.toString() ?? '') ?? score;
    final publishedRaw = json['published_at']?.toString();
    return ResultModel(
      id: id,
      courseId: int.tryParse(json['course_id']?.toString() ?? ''),
      courseCode: courseCode,
      courseTitle: courseTitle,
      studentId: studentId,
      studentName: json['student_name']?.toString() ?? 'Student $studentId',
      assessmentType: json['assessment_type']?.toString() ?? 'manual',
      referenceId: int.tryParse(json['reference_id']?.toString() ?? ''),
      title: json['title']?.toString() ?? '$courseCode result',
      score: score,
      maxScore: double.tryParse(json['max_score']?.toString() ?? '') ?? 100,
      gradedAssessmentScore:
          double.tryParse(json['graded_assessment_score']?.toString() ?? '') ??
          0,
      assignmentScore:
          double.tryParse(json['assignment_score']?.toString() ?? '') ?? 0,
      groupAssignmentScore:
          double.tryParse(json['group_assignment_score']?.toString() ?? '') ??
          0,
      peerReviewScore:
          double.tryParse(json['peer_review_score']?.toString() ?? '') ?? 0,
      examinationScore:
          double.tryParse(json['examination_score']?.toString() ?? '') ?? 0,
      totalScore: totalScore,
      grade: json['grade']?.toString() ?? '',
      remark: json['remark']?.toString() ?? '',
      status: ResultWorkflowStatusX.fromApi(json['status']?.toString() ?? ''),
      publishedAt: publishedRaw == null
          ? null
          : DateTime.tryParse(publishedRaw),
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      if (courseId != null) 'course_id': courseId,
      'course_code': courseCode,
      'student_id': studentId,
      'assessment_type': assessmentType,
      'reference_id': referenceId ?? 0,
      'score': score,
      'graded_assessment_score': gradedAssessmentScore,
      'assignment_score': assignmentScore,
      'group_assignment_score': groupAssignmentScore,
      'peer_review_score': peerReviewScore,
      'examination_score': examinationScore,
      'total_score': effectiveTotalScore,
      'grade': grade,
      'remark': remark,
      'status': status.apiValue,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'score': score,
      'graded_assessment_score': gradedAssessmentScore,
      'assignment_score': assignmentScore,
      'group_assignment_score': groupAssignmentScore,
      'peer_review_score': peerReviewScore,
      'examination_score': examinationScore,
      'total_score': effectiveTotalScore,
      'grade': grade,
      'remark': remark,
      'status': status.apiValue,
    };
  }
}
