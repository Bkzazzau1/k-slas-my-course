class CourseRegistrationBackendPath {
  static const myRegistrationRules = '/api/v1/students/me/course-registration/rules';
  static const myAvailableCourses = '/api/v1/students/me/course-registration/available-courses';
  static const submitRegistration = '/api/v1/students/me/course-registration/submit';
  static const myRegistrationStatus = '/api/v1/students/me/course-registration/status';
  static const withdrawRegistration = '/api/v1/students/me/course-registration/withdraw';
  static const approveRegistration = '/api/v1/course-registrations/{registrationId}/approve';
  static const rejectRegistration = '/api/v1/course-registrations/{registrationId}/reject';
}

class CourseRegistrationBackendContract {
  const CourseRegistrationBackendContract._();

  static const rulesResponseExample = {
    'student': {
      'id': 'student-2023-c-seng-0400',
      'programmeId': 'bsc-software-engineering',
      'departmentId': 'dept-computing',
      'level': 300,
      'semester': 1,
      'cohortId': 'cohort-bsc-se-2023-regular',
    },
    'academicSession': '2025/2026',
    'minCreditUnits': 15,
    'maxCreditUnits': 24,
    'requiredCoreCourses': [
      {
        'courseCode': 'CSC 305',
        'courseTitle': 'Data Structures',
        'creditUnits': 3,
        'type': 'CORE',
        'level': 300,
        'semester': 1,
        'compulsory': true,
      }
    ],
    'availableElectives': [
      {
        'courseCode': 'CSC 311',
        'courseTitle': 'Mobile Application Development',
        'creditUnits': 2,
        'type': 'ELECTIVE',
        'level': 300,
        'semester': 1,
        'requiresApproval': false,
      }
    ],
  };

  static const submitPayloadExample = {
    'academicSession': '2025/2026',
    'selectedCourseCodes': [
      'CSC 305',
      'CSC 309',
      'MTH 301',
      'SEN 301',
      'CSC 311',
      'ENT 301',
    ],
  };

  static const submitResponseExample = {
    'registrationId': 'reg-2025-2026-300-1-0400',
    'status': 'SUBMITTED',
    'totalCreditUnits': 16,
    'submittedAt': '2026-06-13T12:00:00Z',
    'message': 'Course registration submitted for approval.',
  };

  static const validationRules = [
    'The backend must derive the student from the authenticated token only.',
    'Core courses from the student programme curriculum must be automatically required and cannot be removed by the client.',
    'Elective courses must be selected only from electives available to the student programme, cohort, level, and semester.',
    'Selected credit units must be greater than or equal to minCreditUnits and less than or equal to maxCreditUnits.',
    'The backend must reject courses outside the student programme curriculum unless explicitly approved as carryover, spillover, or approved special registration.',
    'The backend must prevent duplicate registration for the same course/session unless policy allows course repeat.',
    'The backend must block registration after the registration deadline unless exam officer/admin override is recorded.',
    'Submitted registration should enter SUBMITTED or APPROVED depending on institution policy.',
    'Students must not register for another student by supplying studentId in the payload.',
  ];

  static const approvalStatuses = [
    'DRAFT',
    'SUBMITTED',
    'APPROVED',
    'REJECTED',
    'WITHDRAWN',
    'LOCKED',
  ];

  static const auditEvents = [
    'COURSE_REGISTRATION_DRAFT_SAVED',
    'COURSE_REGISTRATION_SUBMITTED',
    'COURSE_REGISTRATION_APPROVED',
    'COURSE_REGISTRATION_REJECTED',
    'COURSE_REGISTRATION_WITHDRAWN',
    'COURSE_REGISTRATION_LOCKED',
  ];
}
