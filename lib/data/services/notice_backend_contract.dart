class NoticeBackendPath {
  static const listMyNotices = '/api/v1/notices/me';
  static const listPublishedNotices = '/api/v1/notices';
  static const createNotice = '/api/v1/notices';
  static const noticeDetail = '/api/v1/notices/{noticeId}';
  static const updateNotice = '/api/v1/notices/{noticeId}';
  static const publishNotice = '/api/v1/notices/{noticeId}/publish';
  static const archiveNotice = '/api/v1/notices/{noticeId}/archive';
  static const acknowledgeNotice = '/api/v1/notices/{noticeId}/acknowledge';
  static const noticeAcknowledgements = '/api/v1/notices/{noticeId}/acknowledgements';
  static const noticeAuditLogs = '/api/v1/notices/{noticeId}/audit-logs';
}

class NoticeBackendContract {
  const NoticeBackendContract._();

  static const createPayloadExample = {
    'title': '300 Level Software Engineering briefing',
    'body': 'All concerned students should attend the briefing by 10:00am.',
    'scope': 'COHORT',
    'audience': 'STUDENTS',
    'courseCode': null,
    'schoolId': 'school-kasu',
    'departmentId': 'dept-computing',
    'programmeId': 'bsc-software-engineering',
    'targetLevel': 300,
    'targetSemester': 1,
    'targetCohortKey': 'cohort-bsc-se-2023-regular',
    'priority': 1,
    'pinned': true,
    'requiresAcknowledgement': true,
    'reference': 'EXAM-OFFICE/2026/001',
    'expiresAt': '2026-06-20T23:59:59Z',
  };

  static const responseExample = {
    'id': 'notice-001',
    'title': '300 Level Software Engineering briefing',
    'body': 'All concerned students should attend the briefing by 10:00am.',
    'scope': 'COHORT',
    'audience': 'STUDENTS',
    'courseCode': null,
    'source': 'Exam Office',
    'createdAt': '2026-06-13T10:00:00Z',
    'priority': 1,
    'status': 'PUBLISHED',
    'authorId': 'exam-officer-001',
    'authorName': 'Exam Office',
    'authorRole': 'EXAM_OFFICER',
    'expiresAt': '2026-06-20T23:59:59Z',
    'pinned': true,
    'requiresAcknowledgement': true,
    'reference': 'EXAM-OFFICE/2026/001',
    'schoolId': 'school-kasu',
    'departmentId': 'dept-computing',
    'programmeId': 'bsc-software-engineering',
    'targetLevel': 300,
    'targetSemester': 1,
    'targetCohortKey': 'cohort-bsc-se-2023-regular',
    'acknowledged': false,
  };

  static const acknowledgePayloadExample = {
    'studentId': 'student-2023-c-seng-0400',
    'acknowledgedAt': '2026-06-13T11:15:00Z',
    'deviceId': 'optional-device-id',
  };

  static const strictVisibilityRule = [
    'The backend must never return every published notice to a student.',
    'GET /api/v1/notices/me must derive the student profile from the authenticated token, not from query parameters supplied by the client.',
    'A notice is GENERAL only when it has no schoolId, departmentId, programmeId, targetLevel, targetSemester, targetCohortKey, or courseCode and its scope is SCHOOL or EXAM.',
    'A GENERAL notice is visible to all students in the permitted audience.',
    'A targeted notice is visible only when every non-null target field matches the authenticated student profile.',
    'For course notices, courseCode must be in the student active registered courses.',
    'For cohort notices, targetCohortKey must match one of the student active cohort IDs or accepted temporary cohort keys.',
    'Archived, draft, expired, or wrong-audience notices must not be returned to students.',
  ];

  static const backendQueryPseudoSql = '''
SELECT n.*
FROM notices n
LEFT JOIN student_course_registrations scr
  ON scr.student_id = :student_id
 AND scr.course_code = n.course_code
LEFT JOIN student_cohorts sc
  ON sc.student_id = :student_id
 AND sc.cohort_id = n.target_cohort_key
WHERE n.status = 'PUBLISHED'
  AND (n.expires_at IS NULL OR n.expires_at > NOW())
  AND n.audience IN ('STUDENTS', 'ALL')
  AND (
    -- General notices for all students.
    (
      n.scope IN ('SCHOOL', 'EXAM')
      AND n.school_id IS NULL
      AND n.department_id IS NULL
      AND n.programme_id IS NULL
      AND n.target_level IS NULL
      AND n.target_semester IS NULL
      AND n.target_cohort_key IS NULL
      AND n.course_code IS NULL
    )
    OR
    -- Targeted notices: every non-null target must match.
    (
      (n.school_id IS NULL OR n.school_id = :student_school_id)
      AND (n.department_id IS NULL OR n.department_id = :student_department_id)
      AND (n.programme_id IS NULL OR n.programme_id = :student_programme_id)
      AND (n.target_level IS NULL OR n.target_level = :student_level)
      AND (n.target_semester IS NULL OR n.target_semester = :student_semester)
      AND (n.target_cohort_key IS NULL OR sc.cohort_id IS NOT NULL)
      AND (n.course_code IS NULL OR scr.course_code IS NOT NULL)
    )
  )
ORDER BY n.pinned DESC, n.priority DESC, n.created_at DESC;
''';

  static const rolePermissions = {
    'LECTURER': [
      'Create and publish course notices for assigned courses only.',
      'Target notices by course, level, semester, department, programme, or cohort only where the lecturer is authorized.',
      'Archive own notices subject to institution policy.',
    ],
    'EXAM_OFFICER': [
      'Create and publish school, exam, department, programme, level, cohort, and course notices.',
      'View acknowledgement reports for notices created by the exam office.',
      'Archive or update official exam notices.',
    ],
    'ADMIN': [
      'Manage all notice scopes and audit logs.',
      'Override or archive notices according to institutional policy.',
    ],
    'STUDENT': [
      'Read only notices visible to their authenticated profile.',
      'Acknowledge notices that require acknowledgement.',
      'Cannot create or publish notices.',
    ],
  };

  static const auditEvents = [
    'NOTICE_CREATED',
    'NOTICE_UPDATED',
    'NOTICE_PUBLISHED',
    'NOTICE_ARCHIVED',
    'NOTICE_ACKNOWLEDGED',
    'NOTICE_VISIBILITY_QUERY',
  ];
}
