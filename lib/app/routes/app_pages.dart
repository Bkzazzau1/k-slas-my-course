import 'package:get/get.dart';
import 'package:my_courses/modules/fill_blank/binding/fill_blank_binding.dart';
import 'package:my_courses/modules/fill_blank/view/fill_blank_view.dart';
import 'package:my_courses/modules/assignments/binding/assignments_binding.dart';
import 'package:my_courses/modules/assignments/view/assignments_pro_view.dart';
import 'package:my_courses/modules/assignments/view/lecturer_assignments_portal_view.dart';

import '../../modules/cbt/binding/cbt_binding.dart';
import '../../modules/cbt/view/cbt_result_view.dart';
import '../../modules/cbt/view/cbt_setup_view.dart';
import '../../modules/cbt/view/cbt_take_view.dart';
import '../../modules/chat/binding/chat_binding.dart';
import '../../modules/chat/view/chat_view.dart';
import '../../modules/courses/binding/courses_binding.dart';
import '../../modules/courses/view/course_detail_view.dart';
import '../../modules/courses/view/courses_list_view.dart';
import '../../features/dashboard/binding/dashboard_binding.dart';
import '../../features/dashboard/controller/dashboard_controller.dart';
import '../../features/dashboard/view/dashboard_view.dart';
import '../../modules/demo_walkthrough/view/demo_walkthrough_view.dart';
import '../../modules/exam/binding/exam_binding.dart';
import '../../modules/exam/view/exam_result_view.dart';
import '../../modules/exam/view/exam_run_view.dart';
import '../../modules/exam/view/exam_setup_view.dart';
import '../../modules/notifications/view/student_notifications_view.dart';
import '../../modules/noticeboard/binding/noticeboard_binding.dart';
import '../../modules/noticeboard/view/noticeboard_view.dart';
import '../../modules/practice/binding/practice_binding.dart';
import '../../modules/practice/view/practice_result_view.dart';
import '../../modules/practice/view/practice_session_view.dart';
import '../../modules/practice/view/practice_setup_view.dart';
import '../../modules/revision/binding/revision_binding.dart';
import '../../modules/revision/controller/revision_controller.dart';
import '../../modules/revision/view/revision_view.dart';
import '../../modules/results/binding/results_binding.dart';
import '../../modules/results/view/results_view.dart';
import '../../modules/settings/binding/settings_binding.dart';
import '../../modules/settings/controller/settings_controller.dart';
import '../../modules/settings/view/settings_view.dart';
import '../../modules/theory/binding/theory_binding.dart';
import '../../modules/theory/view/theory_practice_view.dart';
import '../../modules/theory_rewrite/binding/theory_rewrite_binding.dart';
import '../../modules/theory_rewrite/view/theory_rewrite_view.dart';
import '../../modules/live_sessions/binding/live_sessions_binding.dart';
import '../../modules/live_sessions/view/chief_invigilator_live_overview_view.dart';
import '../../modules/live_sessions/view/live_class_history_with_replay_view.dart';
import '../../modules/live_sessions/view/live_class_replay_view.dart';
import '../../modules/live_sessions/view/live_sessions_hub_view.dart';
import '../../modules/live_sessions/view/live_session_room_view.dart';
import '../../modules/role_portals/view/role_portal_placeholder_view.dart';
import '../../modules/timetable/binding/timetable_binding.dart';
import '../../modules/timetable/controller/timetable_controller.dart';
import '../../modules/timetable/view/timetable_view.dart';
import '../../modules/weak_areas/binding/weak_areas_binding.dart';
import '../../modules/weak_areas/view/weak_areas_view.dart';
import '../main_nav/main_nav_view.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = <GetPage>[
    GetPage(
      name: Routes.main,
      page: () => const MainNavView(),
      binding: BindingsBuilder(() {
        Get.put(RevisionPlanController(), permanent: true);
        Get.put(TimetableController(), permanent: true);
        Get.put(SettingsController(), permanent: true);
        Get.put(DashboardController(), permanent: true);
        CoursesBinding().dependencies();
      }),
    ),
    GetPage(
      name: Routes.mainNav,
      page: () => const MainNavView(),
      binding: BindingsBuilder(() {
        Get.put(RevisionPlanController(), permanent: true);
        Get.put(TimetableController(), permanent: true);
        Get.put(SettingsController(), permanent: true);
        Get.put(DashboardController(), permanent: true);
        CoursesBinding().dependencies();
      }),
    ),
    GetPage(
      name: Routes.dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
    ),
    GetPage(
      name: Routes.demoWalkthrough,
      page: () => const DemoWalkthroughView(),
    ),
    GetPage(
      name: Routes.courses,
      page: () => const CoursesListView(),
      binding: CoursesBinding(),
    ),
    GetPage(
      name: Routes.courseDetail,
      page: () => const CourseDetailView(),
      binding: CoursesBinding(),
    ),
    GetPage(
      name: Routes.chat,
      page: () => const ChatView(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: Routes.practiceSetup,
      page: () => const PracticeSetupView(),
      binding: PracticeBinding(),
    ),
    GetPage(
      name: Routes.practiceSession,
      page: () => const PracticeSessionView(),
      binding: PracticeBinding(),
    ),
    GetPage(
      name: Routes.practiceResult,
      page: () => const PracticeResultView(),
      binding: PracticeBinding(),
    ),
    GetPage(
      name: Routes.revision,
      page: () => const RevisionView(),
      binding: RevisionBinding(),
    ),
    GetPage(
      name: Routes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: Routes.timetable,
      page: () => const TimetableView(),
      binding: TimetableBinding(),
    ),
    GetPage(
      name: Routes.noticeboard,
      page: () => const NoticeboardView(),
      binding: NoticeboardBinding(),
    ),
    GetPage(
      name: Routes.weakAreas,
      page: () => const WeakAreasView(),
      binding: WeakAreasBinding(),
    ),
    GetPage(
      name: Routes.assignments,
      page: () => const AssignmentsProView(),
      binding: AssignmentsBinding(),
    ),
    GetPage(
      name: Routes.lecturerAssignments,
      page: () => const LecturerAssignmentsPortalView(),
      binding: AssignmentsBinding(),
    ),
    GetPage(
      name: Routes.results,
      page: () => const ResultsView(),
      binding: ResultsBinding(),
    ),
    GetPage(
      name: Routes.notifications,
      page: () => const StudentNotificationsView(),
    ),
    GetPage(
      name: '/fillblank/start',
      page: () => const FillBlankView(),
      binding: FillBlankBinding(),
    ),
    GetPage(
      name: Routes.cbtSetup,
      page: () {
        final args = Get.arguments as Map?;
        final code = args?['courseCode'] as String? ?? '';
        return CBTSetupView(courseCode: code);
      },
      binding: CBTBinding(),
    ),
    GetPage(
      name: Routes.cbtTake,
      page: () => const CBTTakeView(),
      binding: CBTBinding(),
    ),
    GetPage(name: Routes.cbtResult, page: CBTResultView.new),
    GetPage(
      name: Routes.theoryPractice,
      page: () => const TheoryPracticeView(),
      binding: TheoryBinding(),
    ),
    GetPage(
      name: Routes.theoryRewrite,
      page: () => const TheoryRewriteView(),
      binding: TheoryRewriteBinding(),
    ),
    GetPage(
      name: Routes.examSetup,
      page: () => const ExamSetupView(),
      binding: ExamBinding(),
    ),
    GetPage(name: Routes.examRun, page: () => const ExamRunView()),
    GetPage(name: Routes.examResult, page: () => const ExamResultView()),
    GetPage(
      name: Routes.liveSessions,
      page: () => const LiveSessionsHubView(),
      binding: LiveSessionsBinding(),
    ),
    GetPage(
      name: Routes.liveSessionRoom,
      page: () => const LiveSessionRoomView(),
      binding: LiveSessionsBinding(),
    ),
    GetPage(
      name: Routes.liveClassHistory,
      page: () => const LiveClassHistoryWithReplayView(),
      binding: LiveSessionsBinding(),
    ),
    GetPage(
      name: Routes.liveSessionReplay,
      page: () => const LiveClassReplayView(),
      binding: LiveSessionsBinding(),
    ),
    GetPage(
      name: Routes.liveChiefOverview,
      page: () => const ChiefInvigilatorLiveOverviewView(),
      binding: LiveSessionsBinding(),
    ),
    ..._roleSeparatedPortalPages,
  ];

  static final List<GetPage> _roleSeparatedPortalPages = [
    GetPage(
      name: Routes.lecturerLiveSessions,
      page: () => const RolePortalPlaceholderView(
        roleName: 'LECTURER PORTAL',
        portalTitle: 'Lecturer Live Classes',
        description:
            'A lecturer-only space for creating, hosting, managing attendance, sharing materials, and reviewing live-class engagement.',
        features: [
          'Create and publish live classes for assigned courses.',
          'Start or join class as the course lecturer, not as a student.',
          'Manage attendance, questions, materials, recordings, and replay settings.',
          'Escalate classroom issues to exam officers or chief invigilators where required.',
        ],
      ),
      binding: LiveSessionsBinding(),
    ),
    GetPage(
      name: Routes.lecturerExams,
      page: () => const RolePortalPlaceholderView(
        roleName: 'LECTURER PORTAL',
        portalTitle: 'Lecturer Exams',
        description:
            'A lecturer-only exam workspace for question preparation, marking, moderation responses, and result recommendations.',
        features: [
          'Prepare objective, essay, fill-in-blank, image-based, drag-and-drop, and whiteboard questions.',
          'Submit questions to moderator and exam officer workflow.',
          'Mark essays and review AI-assisted marking suggestions.',
          'Respond to moderation queries without accessing student exam-taking screens.',
        ],
      ),
      binding: ExamBinding(),
    ),
    GetPage(
      name: Routes.lecturerResults,
      page: () => const RolePortalPlaceholderView(
        roleName: 'LECTURER PORTAL',
        portalTitle: 'Lecturer Results',
        description:
            'A lecturer-only result workspace for grading review, feedback entry, and result submission to exam officers.',
        features: [
          'View submissions and grade summaries for assigned courses only.',
          'Enter feedback and recommended marks.',
          'Submit results for moderation and approval.',
          'Avoid exposing student-only transcript or personal result screens.',
        ],
      ),
      binding: ResultsBinding(),
    ),
    GetPage(
      name: Routes.lecturerNotifications,
      page: () => const RolePortalPlaceholderView(
        roleName: 'LECTURER PORTAL',
        portalTitle: 'Lecturer Notifications',
        description:
            'A lecturer-only notification center for class, assignment, moderation, and exam workflow alerts.',
        features: [
          'Receive moderation requests and result approval feedback.',
          'Receive live-class and assignment alerts for assigned courses.',
          'Communicate official updates to students through controlled channels.',
        ],
      ),
    ),
    GetPage(
      name: Routes.examOfficerLiveSessions,
      page: () => const RolePortalPlaceholderView(
        roleName: 'EXAM OFFICER PORTAL',
        portalTitle: 'Exam Officer Live Classes',
        description:
            'A supervisory live-class view for monitoring class compliance, attendance policy, incidents, and escalations.',
        features: [
          'Monitor live-class compliance without joining as a student.',
          'Review attendance thresholds and risk alerts.',
          'Track escalated incidents from lecturers and invigilators.',
          'Use chief overview where broad supervision is required.',
        ],
        primaryActionLabel: 'Open chief live overview',
        primaryActionRoute: Routes.liveChiefOverview,
      ),
      binding: LiveSessionsBinding(),
    ),
    GetPage(
      name: Routes.examOfficerExams,
      page: () => const RolePortalPlaceholderView(
        roleName: 'EXAM OFFICER PORTAL',
        portalTitle: 'Exam Officer Exams',
        description:
            'A dedicated exam officer workspace for exam scheduling, question approval, hall setup, and invigilation oversight.',
        features: [
          'Approve exams after lecturer and moderator workflow.',
          'Schedule CBT center, distance-learning, and graded assessment exams.',
          'Assign invigilators and configure exam security rules.',
          'Monitor exam readiness without using the student exam-taking screen.',
        ],
      ),
      binding: ExamBinding(),
    ),
    GetPage(
      name: Routes.examOfficerResults,
      page: () => const RolePortalPlaceholderView(
        roleName: 'EXAM OFFICER PORTAL',
        portalTitle: 'Exam Officer Results',
        description:
            'A result approval and release workspace for exam officers, separate from lecturer and student result screens.',
        features: [
          'Review lecturer-submitted marks and moderation outcomes.',
          'Approve, hold, or query result batches.',
          'Control final student result release.',
          'Track audit trail for result changes.',
        ],
      ),
      binding: ResultsBinding(),
    ),
    GetPage(
      name: Routes.examOfficerNotifications,
      page: () => const RolePortalPlaceholderView(
        roleName: 'EXAM OFFICER PORTAL',
        portalTitle: 'Exam Officer Notifications',
        description:
            'A workflow alert center for exam approvals, invigilation issues, result queries, and system compliance events.',
        features: [
          'Receive lecturer, moderator, and invigilator escalations.',
          'Track unresolved exam and result workflow alerts.',
          'Send official administrative notices without using student notification screens.',
        ],
      ),
    ),
    GetPage(
      name: Routes.invigilatorLiveSessions,
      page: () => const RolePortalPlaceholderView(
        roleName: 'INVIGILATOR PORTAL',
        portalTitle: 'Invigilator Live Monitoring',
        description:
            'An invigilator-only view for monitoring distance-learning live assessments, attendance risk, and incident reports.',
        features: [
          'Monitor assigned live assessment sessions only.',
          'Review automatic alerts and suspicious behaviour reports.',
          'Escalate serious issues to chief invigilator or exam officer.',
        ],
      ),
      binding: LiveSessionsBinding(),
    ),
    GetPage(
      name: Routes.invigilatorExams,
      page: () => const RolePortalPlaceholderView(
        roleName: 'INVIGILATOR PORTAL',
        portalTitle: 'Invigilator Exams',
        description:
            'A dedicated invigilation workspace for candidate verification, workstation monitoring, malpractice reports, and hall control.',
        features: [
          'View assigned exam halls and active exam sessions.',
          'Verify candidates and workstation status.',
          'Create malpractice reports and escalate incidents.',
          'Avoid access to lecturer grading and student exam-answer screens.',
        ],
      ),
      binding: ExamBinding(),
    ),
    GetPage(
      name: Routes.invigilatorResults,
      page: () => const RolePortalPlaceholderView(
        roleName: 'INVIGILATOR PORTAL',
        portalTitle: 'Invigilator Result Access',
        description:
            'A restricted result-related view for incident context only. Invigilators should not approve or release academic results.',
        features: [
          'View only result-related incident references where authorized.',
          'No grading, approval, or result release capability.',
          'Maintain separation from lecturer and exam officer result portals.',
        ],
      ),
    ),
    GetPage(
      name: Routes.invigilatorNotifications,
      page: () => const RolePortalPlaceholderView(
        roleName: 'INVIGILATOR PORTAL',
        portalTitle: 'Invigilator Notifications',
        description:
            'A focused notification center for assigned exams, hall instructions, escalations, and incident feedback.',
        features: [
          'Receive assigned exam and hall instructions.',
          'Receive escalation feedback from chief invigilator or exam officer.',
          'Keep invigilator notices separate from student notifications.',
        ],
      ),
    ),
  ];
}
