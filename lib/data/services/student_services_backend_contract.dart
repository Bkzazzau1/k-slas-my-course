class StudentInternshipBackendPath {
  static const profile = '/api/v1/student/internship/profile';
  static const updateProfile = '/api/v1/student/internship/profile';
  static const requestPlacementLetter = '/api/v1/student/internship/placement-letter/request';
  static const uploadAcceptanceLetter = '/api/v1/student/internship/acceptance-letter';
  static const weeklyLogbook = '/api/v1/student/internship/logbook';
  static const submitWeeklyLog = '/api/v1/student/internship/logbook/submit';
  static const supervisorEvaluationStatus = '/api/v1/student/internship/supervisor-evaluation/status';
}

class StudentTranscriptBackendPath {
  static const unofficialPreview = '/api/v1/student/transcripts/unofficial-preview';
  static const unofficialPdf = '/api/v1/student/transcripts/unofficial-pdf';
  static const officialRequests = '/api/v1/student/transcripts/official-requests';
  static const createOfficialRequest = '/api/v1/student/transcripts/official-requests';
  static const requestDetail = '/api/v1/student/transcripts/official-requests/{requestId}';
  static const cancelPendingRequest = '/api/v1/student/transcripts/official-requests/{requestId}/cancel';
}

class StudentServicesWorkflowContract {
  const StudentServicesWorkflowContract._();

  static const ownershipRules = [
    'Internship and transcript request screens in k-slas-my-course are student-facing only.',
    'Students may submit internship profile updates, placement letter requests, acceptance letters, logbook entries and transcript requests.',
    'Official transcript approval, records review, dispatch and institutional verification belong to the admin/staff backend workflow, not the student app.',
    'Unofficial transcript preview and print must be clearly marked as student copy and not official.',
    'Student app must only show records belonging to the authenticated student.',
  ];
}
