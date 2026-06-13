class CohortBackendPath {
  static const listCohorts = '/api/v1/cohorts';
  static const createCohort = '/api/v1/cohorts';
  static const cohortDetail = '/api/v1/cohorts/{cohortId}';
  static const updateCohort = '/api/v1/cohorts/{cohortId}';
  static const archiveCohort = '/api/v1/cohorts/{cohortId}/archive';
  static const assignStudents = '/api/v1/cohorts/{cohortId}/students';
  static const removeStudent = '/api/v1/cohorts/{cohortId}/students/{studentId}';
  static const cohortStudents = '/api/v1/cohorts/{cohortId}/students';
  static const studentCohorts = '/api/v1/students/{studentId}/cohorts';
}

class CohortBackendContract {
  const CohortBackendContract._();

  static const createPayloadExample = {
    'name': 'B.Sc Software Engineering 2023 Regular',
    'schoolId': 'school-kasu',
    'departmentId': 'dept-computing',
    'departmentName': 'Computing',
    'programmeId': 'bsc-software-engineering',
    'programmeName': 'B.Sc Software Engineering',
    'intakeYear': 2023,
    'mode': 'REGULAR',
    'level': 300,
    'semester': 1,
    'academicSession': '2025/2026',
    'status': 'ACTIVE',
  };

  static const responseExample = {
    'id': 'cohort-bsc-se-2023-regular',
    'name': 'B.Sc Software Engineering 2023 Regular',
    'schoolId': 'school-kasu',
    'departmentId': 'dept-computing',
    'departmentName': 'Computing',
    'programmeId': 'bsc-software-engineering',
    'programmeName': 'B.Sc Software Engineering',
    'intakeYear': 2023,
    'mode': 'REGULAR',
    'level': 300,
    'semester': 1,
    'academicSession': '2025/2026',
    'status': 'ACTIVE',
    'createdAt': '2026-06-13T10:00:00Z',
  };

  static const assignStudentsPayloadExample = {
    'studentIds': [
      'student-2023-c-seng-0400',
      'student-2023-c-seng-0401',
    ],
    'assignedBy': 'exam-officer-001',
  };

  static const noticeTargetPayloadExample = {
    'title': '300 Level software engineering briefing',
    'body': 'All 300 Level Software Engineering students should attend the briefing.',
    'scope': 'COHORT',
    'audience': 'STUDENTS',
    'departmentId': 'dept-computing',
    'programmeId': 'bsc-software-engineering',
    'targetLevel': 300,
    'targetSemester': 1,
    'targetCohortKey': 'cohort-bsc-se-2023-regular',
    'requiresAcknowledgement': true,
  };

  static const implementationNotes = [
    'Cohorts should be created by registrar, exam officer, department admin, or system admin roles only.',
    'A cohort represents a real academic group: intake year + programme + mode + level + semester/session.',
    'Students may belong to more than one cohort over time, but only one active current academic cohort should be used for current notices.',
    'Notice targeting should accept cohortId/targetCohortKey, departmentId, programmeId, level, semester, courseCode, and audience.',
    'The backend should always enforce role permissions; the frontend route separation is not security by itself.',
  ];
}
