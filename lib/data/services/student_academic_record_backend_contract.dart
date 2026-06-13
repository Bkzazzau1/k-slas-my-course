class StudentAcademicRecordBackendPath {
  static const myAcademicRecord = '/api/v1/students/me/academic-record';
  static const myCourseRegistrations = '/api/v1/students/me/course-registrations';
  static const myCompletedCourses = '/api/v1/students/me/completed-courses';
  static const myCgpa = '/api/v1/students/me/cgpa';
  static const myTranscriptPreview = '/api/v1/students/me/transcript-preview';
}

class StudentAcademicRecordBackendContract {
  const StudentAcademicRecordBackendContract._();

  static const academicRecordResponseExample = {
    'student': {
      'id': 'student-2023-c-seng-0400',
      'fullName': 'Ibrahim Bashir Yahaya',
      'matricNo': '2023/C/SENG/0400',
      'schoolId': 'school-kasu',
      'departmentId': 'dept-computing',
      'programmeId': 'bsc-software-engineering',
      'level': 300,
      'semester': 1,
      'cohortId': 'cohort-bsc-se-2023-regular',
    },
    'summary': {
      'currentCredits': 18,
      'completedCredits': 72,
      'coreCourses': 24,
      'electiveCourses': 6,
      'currentGpa': 4.25,
      'cgpa': 4.18,
      'classOfDegree': 'Second Class Upper',
      'progressPercent': 62,
    },
    'enrolled': [
      {
        'courseCode': 'CSC 305',
        'courseTitle': 'Data Structures',
        'creditUnits': 3,
        'type': 'CORE',
        'status': 'ENROLLED',
        'level': 300,
        'semester': 1,
        'academicSession': '2025/2026',
        'progress': 72,
      }
    ],
    'completed': [
      {
        'courseCode': 'CSC 201',
        'courseTitle': 'Object Oriented Programming',
        'creditUnits': 3,
        'type': 'CORE',
        'status': 'COMPLETED',
        'level': 200,
        'semester': 1,
        'academicSession': '2024/2025',
        'score': 78,
        'grade': 'A',
        'gradePoint': 5.0,
        'qualityPoints': 15.0,
      }
    ],
  };

  static const backendRules = [
    'GET /api/v1/students/me/academic-record must derive the student from the authenticated token only.',
    'Enrolled courses should be active course registrations for the current academic session/semester.',
    'Completed courses should include only approved/released results.',
    'Core/elective classification must come from the programme curriculum, not from the frontend.',
    'CGPA must be calculated from released completed courses using credit units and grade points.',
    'Current GPA should be calculated only when current semester grades are officially released; otherwise return null or 0 with status.',
    'Students must never see another student academic record through query parameters.',
    'Transcript preview must not replace official transcript unless institution policy allows it.',
  ];

  static const gpaFormula = {
    'qualityPoints': 'creditUnits * gradePoint',
    'gpa': 'sum(qualityPoints for semester) / sum(creditUnits for semester)',
    'cgpa': 'sum(all released qualityPoints) / sum(all released creditUnits)',
  };
}
