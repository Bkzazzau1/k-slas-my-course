import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/academic_admin_model.dart';
import '../../../data/models/course_model.dart';
import '../../../data/services/academic_admin_service.dart';

class AcademicAdminController extends GetxController {
  final role = AcademicAdminRole.hod.obs;
  final eligibleCourses = <CourseModel>[].obs;
  final selectedCourses = <CourseModel>[].obs;
  final registrations = <CourseRegistrationItem>[].obs;
  final isLoading = false.obs;

  String get providerLabel => AcademicAdminService.gateway.providerLabel;

  @override
  void onInit() {
    super.onInit();
    final rawRole = (Get.arguments as Map?)?['actorRole']?.toString();
    role.value = _roleFromRaw(rawRole);
    loadEligibleCourses();
  }

  void switchRole(AcademicAdminRole value) => role.value = value;

  Future<void> loadEligibleCourses() async {
    isLoading.value = true;
    try {
      eligibleCourses.assignAll(
        await AcademicAdminService.gateway.fetchEligibleCourses(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void toggleCourse(CourseModel course) {
    final exists = selectedCourses.any((item) => item.code == course.code);
    if (exists) {
      selectedCourses.removeWhere((item) => item.code == course.code);
    } else {
      selectedCourses.add(course);
    }
  }

  Future<void> createLecturer() async {
    await AcademicAdminService.gateway.createStaff(
      const AcademicStaffDraft(
        firstName: 'Amina',
        lastName: 'Musa',
        email: 'amina.musa@kslas.edu.ng',
        staffId: 'KSLAS/STAFF/045',
        roleCode: 'lecturer',
        departmentId: 1,
        password: 'Password123!',
      ),
    );
    _toast('Lecturer created and scoped to department.');
  }

  Future<void> createExamOfficer() async {
    await AcademicAdminService.gateway.createStaff(
      const AcademicStaffDraft(
        firstName: 'Ibrahim',
        lastName: 'Sule',
        email: 'ibrahim.sule@kslas.edu.ng',
        staffId: 'KSLAS/EXAM/011',
        roleCode: 'exam_officer',
        departmentId: 1,
        password: 'Password123!',
      ),
    );
    _toast('Exam officer created for exam operations.');
  }

  Future<void> createRegistryStudent() async {
    await AcademicAdminService.gateway.createStudent(
      const StudentRegistrationDraft(
        firstName: 'Zainab',
        lastName: 'Ibrahim',
        email: 'zainab.ibrahim@student.kslas.edu.ng',
        matricNo: 'KSLAS/CSC/23/1001',
        departmentId: 1,
        programmeId: 1,
        level: '300',
        semester: '1',
        academicSession: '2025/2026',
        password: 'Password123!',
      ),
    );
    _toast('Student registered with level and programme.');
  }

  Future<void> registerSelectedCourses() async {
    if (selectedCourses.isEmpty) {
      _toast('Choose at least one eligible course.');
      return;
    }
    final items = await AcademicAdminService.gateway.registerCourses(
      selectedCourses.toList(),
    );
    registrations.assignAll(items);
    _toast('Course registration submitted.');
  }

  AcademicAdminRole _roleFromRaw(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'registry':
      case 'registry_officer':
        return AcademicAdminRole.registry;
      case 'student':
        return AcademicAdminRole.student;
      case 'hod':
      default:
        return AcademicAdminRole.hod;
    }
  }

  void _toast(String message) {
    Get.snackbar(
      'Academic setup',
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }
}
