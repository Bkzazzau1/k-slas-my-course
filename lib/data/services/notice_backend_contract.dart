class NoticeBackendPath {
  static const listMyNotices = '/api/v1/notices/me';
  static const noticeDetail = '/api/v1/notices/{noticeId}';
  static const acknowledgeNotice = '/api/v1/notices/{noticeId}/acknowledge';
}

class NoticeBackendContract {
  const NoticeBackendContract._();

  static const studentVisibleNoticeResponseExample = {
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
}
