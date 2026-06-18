import 'package:get/get.dart';
import 'package:my_courses/modules/fill_blank/binding/fill_blank_binding.dart';
import 'package:my_courses/modules/fill_blank/view/fill_blank_view.dart';
import 'package:my_courses/modules/assignments/binding/assignments_binding.dart';
import 'package:my_courses/modules/assignments/view/assignments_pro_view.dart';

import '../../features/identity_trust/services/identity_trust_bootstrap.dart';
import '../../features/identity_trust/view/student_face_enrollment_view.dart';
import '../../modules/cbt/binding/cbt_binding.dart';
import '../../modules/cbt/view/cbt_result_view.dart';
import '../../modules/cbt/view/cbt_setup_view.dart';
import '../../modules/cbt/view/cbt_take_view.dart';
import '../../modules/chat/binding/chat_binding.dart';
import '../../modules/chat/view/chat_view.dart';
import '../../modules/courses/binding/courses_binding.dart';
import '../../modules/courses/view/course_detail_view.dart';
import '../../modules/courses/view/course_registration_view.dart';
import '../../modules/courses/view/courses_list_view.dart';
import '../../modules/courses/view/student_academic_record_view.dart';
import '../../features/dashboard/binding/dashboard_binding.dart';
import '../../features/dashboard/controller/dashboard_controller.dart';
import '../../features/dashboard/view/dashboard_view.dart';
import '../../modules/demo_exam_face/view/demo_exam_face_only_view.dart';
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
import '../../modules/student_services/view/graduation_mapping_view.dart';
import '../../modules/student_services/view/internship_management_view.dart';
import '../../modules/student_services/view/student_support_view.dart';
import '../../modules/student_services/view/transcript_services_view.dart';
import '../../modules/theory/binding/theory_binding.dart';
import '../../modules/theory/view/theory_practice_view.dart';
import '../../modules/theory_rewrite/binding/theory_rewrite_binding.dart';
import '../../modules/theory_rewrite/view/theory_rewrite_view.dart';
import '../../modules/live_sessions/binding/live_sessions_binding.dart';
import '../../modules/live_sessions/view/live_class_history_with_replay_view.dart';
import '../../modules/live_sessions/view/live_class_replay_view.dart';
import '../../modules/live_sessions/view/live_chief_overview_view.dart';
import '../../modules/live_sessions/view/live_sessions_hub_view.dart';
import '../../modules/live_sessions/view/live_session_room_view.dart';
import '../../modules/timetable/binding/timetable_binding.dart';
import '../../modules/timetable/controller/timetable_controller.dart';
import '../../modules/timetable/view/timetable_view.dart';
import '../../modules/weak_areas/binding/weak_areas_binding.dart';
import '../../modules/weak_areas/controller/weak_areas_controller.dart';
import '../../modules/weak_areas/view/weak_areas_view.dart';
import '../main_nav/main_nav_view.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = <GetPage>[
    GetPage(
      name: Routes.main,
      page: () => const MainNavView(),
      binding: _mainBinding(),
    ),
    GetPage(
      name: Routes.mainNav,
      page: () => const MainNavView(),
      binding: _mainBinding(),
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
      name: Routes.demoExamFaceOnly,
      page: () => const DemoExamFaceOnlyView(),
      binding: BindingsBuilder(() {
        ExamBinding().dependencies();
        IdentityTrustBootstrap.register();
      }),
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
      name: Routes.academicRecord,
      page: () => const StudentAcademicRecordView(),
      binding: CoursesBinding(),
    ),
    GetPage(
      name: Routes.courseRegistration,
      page: () => const CourseRegistrationView(),
      binding: CoursesBinding(),
    ),
    GetPage(
      name: Routes.internshipManagement,
      page: () => const InternshipManagementView(),
    ),
    GetPage(
      name: Routes.transcriptServices,
      page: () => const TranscriptServicesView(),
    ),
    GetPage(
      name: Routes.studentSupport,
      page: () => const StudentSupportView(),
    ),
    GetPage(
      name: Routes.graduationMapping,
      page: () => const GraduationMappingView(),
    ),
    GetPage(
      name: Routes.faceEnrollment,
      page: () => const StudentFaceEnrollmentView(),
      binding: BindingsBuilder(() {
        IdentityTrustBootstrap.register();
      }),
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
      page: () => const LiveChiefOverviewView(),
      binding: LiveSessionsBinding(),
    ),
  ];

  static BindingsBuilder _mainBinding() {
    return BindingsBuilder(() {
      Get.put(RevisionPlanController(), permanent: true);
      Get.put(TimetableController(), permanent: true);
      Get.put(SettingsController(), permanent: true);
      Get.put(WeakAreasController(), permanent: true);
      Get.put(DashboardController(), permanent: true);
      CoursesBinding().dependencies();
    });
  }
}
