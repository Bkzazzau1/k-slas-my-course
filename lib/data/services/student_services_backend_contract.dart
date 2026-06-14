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

class StudentSupportBackendPath {
  static const myTickets = '/api/v1/student/support/tickets';
  static const createTicket = '/api/v1/student/support/tickets';
  static const ticketDetail = '/api/v1/student/support/tickets/{ticketId}';
  static const addReply = '/api/v1/student/support/tickets/{ticketId}/replies';
  static const uploadEvidence = '/api/v1/student/support/tickets/{ticketId}/evidence';
  static const closeResolvedTicket = '/api/v1/student/support/tickets/{ticketId}/close';
  static const ticketUpdates = '/api/v1/student/support/tickets/{ticketId}/updates';
}

class StudentServicesWorkflowContract {
  const StudentServicesWorkflowContract._();

  static const ownershipRules = [
    'Internship, transcript request and support screens in k-slas-my-course are student-facing only.',
    'Students may submit internship profile updates, placement letter requests, acceptance letters, logbook entries, transcript requests and support tickets.',
    'Students may view only their own support tickets and may reply or upload evidence to their own tickets.',
    'Support ticket assignment, escalation, staff investigation, resolution and SLA audit belong to kslas-admin-ui.',
    'Official transcript approval, records review, dispatch and institutional verification belong to the admin/staff backend workflow, not the student app.',
    'Unofficial transcript preview and print must be clearly marked as student copy and not official.',
    'Student app must only show records belonging to the authenticated student.',
  ];
}
