import '../models/live_session_models.dart';

class AssignmentBackendContract {
  const AssignmentBackendContract._();

  static const List<LiveSessionBackendPath> paths = [
    LiveSessionBackendPath(
      method: 'GET',
      path: '/api/v1/assignments',
      description:
          'Load published assignments for a student, with filters for course, status, deadline, and programme.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/assignments',
      description:
          'Lecturer creates and publishes an assignment with text/file/whiteboard submission settings, rubric, deadline, and group configuration.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/assignments/{assignmentId}/drafts',
      description:
          'Save a student assignment draft before final submission, including text answer, whiteboard data, and attachment metadata.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/assignments/{assignmentId}/submissions',
      description:
          'Submit or resubmit an assignment, with validation for deadline, file type, file size, group submission, and required whiteboard work.',
    ),
    LiveSessionBackendPath(
      method: 'GET',
      path: '/api/v1/assignments/{assignmentId}/submissions',
      description:
          'Lecturer loads submissions for marking, including files, text answer, whiteboard data, similarity score, and late status.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/assignments/{assignmentId}/grades',
      description:
          'Lecturer saves score, feedback, rubric marks, grade status, and optional moderation comment.',
    ),
    LiveSessionBackendPath(
      method: 'POST',
      path: '/api/v1/assignments/{assignmentId}/peer-reviews/{reviewId}',
      description:
          'Student submits peer review score, feedback, and rubric checklist for a backend-assigned peer.',
    ),
    LiveSessionBackendPath(
      method: 'GET',
      path: '/api/v1/assignments/analytics/lecturer',
      description:
          'Lecturer dashboard summary: published assignments, submitted count, pending grading, late submissions, average score, and risk items.',
    ),
  ];

  static Map<String, dynamic> assignmentPayloadExample() => {
    'course_code': 'CSC 305',
    'title': 'Graph Algorithms Coursework',
    'description': 'Solve shortest path and MST problems with complexity analysis.',
    'instructions': 'Submit a report and draw the graph traversal on the whiteboard.',
    'assignment_type': 'group',
    'submission_mode': 'mixed',
    'max_score': 100,
    'due_at': '2026-06-30T23:59:00Z',
    'status': 'published',
    'allowed_extensions': ['pdf', 'docx', 'png'],
    'max_file_size_mb': 25,
    'whiteboard_enabled': true,
    'whiteboard_required': true,
    'whiteboard_prompt': 'Draw your graph and annotate the traversal path.',
    'peer_review_enabled': true,
    'peer_review_rubric': [
      'Algorithm choice is justified',
      'Complexity analysis is clear',
      'Graph diagram matches the solution',
    ],
    'late_policy': {
      'allow_late_submission': false,
      'penalty_per_day_percent': 0,
    },
  };

  static Map<String, dynamic> submissionPayloadExample() => {
    'assignment_id': 'asmt-csc305-graphs',
    'student_id': 'KASU/CSC/21/001',
    'group_id': 'grp-csc305-a',
    'text_answer': 'We solved the graph using Dijkstra and Kruskal...',
    'whiteboard_data': [],
    'files': [
      {
        'storage_path': 'wasabi/assignments/csc305/report.pdf',
        'original_file_name': 'CSC305_Group_A_Report.pdf',
        'mime_type': 'application/pdf',
        'size_bytes': 412000,
      },
    ],
    'submitted_at': '2026-06-13T12:30:00Z',
    'status': 'submitted',
    'late': false,
  };
}
