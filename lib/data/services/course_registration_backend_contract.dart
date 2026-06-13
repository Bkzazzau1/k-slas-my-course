class CourseRegistrationBackendPath {
  static const myRegistrationRules = '/api/v1/students/me/course-registration/rules';
  static const myAvailableCourses = '/api/v1/students/me/course-registration/available-courses';
  static const submitRegistration = '/api/v1/students/me/course-registration/submit';
  static const myRegistrationStatus = '/api/v1/students/me/course-registration/status';
  static const withdrawRegistration = '/api/v1/students/me/course-registration/withdraw';
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
        'registrationKind': 'NORMAL',
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
        'registrationKind': 'NORMAL',
        'requiresApproval': false,
      }
    ],
    'availableCarryovers': [
      {
        'courseCode': 'CSC 209',
        'courseTitle': 'Computer Architecture',
        'creditUnits': 3,
        'type': 'CORE',
        'level': 200,
        'semester': 2,
        'registrationKind': 'CARRYOVER',
        'previousGrade': 'F',
        'repeatReason': 'Failed previous attempt',
        'requiresApproval': true,
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
      'CSC 209',
    ],
    'selectedCarryoverCourseCodes': [
      'CSC 209',
    ],
  };

  static const submitResponseExample = {
    'registrationId': 'reg-2025-2026-300-1-0400',
    'status': 'SUBMITTED',
    'totalCreditUnits': 19,
    'carryoverCreditUnits': 3,
    'approvalRequired': true,
    'submittedAt': '2026-06-13T12:00:00Z',
    'message': 'Course registration submitted for academic office approval.',
  };

  static const studentValidationRules = [
    'The backend must derive the student from the authenticated token only.',
    'The student app may submit selected elective and carryover course codes, but cannot approve them.',
    'Core courses must come from the student programme curriculum and cannot be removed by the client.',
    'Elective courses must be available to the authenticated student programme, cohort, level, and semester.',
    'Carryover/repeat courses returned to the student app must belong to the authenticated student records only.',
  ];

  static const studentVisibleStatuses = [
    'DRAFT',
    'SUBMITTED',
    'CARRYOVER_REVIEW',
    'APPROVED',
    'REJECTED',
    'WITHDRAWN',
    'LOCKED',
  ];
}
