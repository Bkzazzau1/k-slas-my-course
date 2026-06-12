import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/result_model.dart';
import '../../../data/services/result_service.dart';

enum ResultsRole { student, lecturer, officer }

extension ResultsRoleX on ResultsRole {
  String get label {
    switch (this) {
      case ResultsRole.student:
        return 'Student';
      case ResultsRole.lecturer:
        return 'Lecturer';
      case ResultsRole.officer:
        return 'Exam officer';
    }
  }
}

class ResultsController extends GetxController {
  final role = ResultsRole.student.obs;
  final results = <ResultModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final rawRole = (Get.arguments as Map?)?['actorRole']?.toString();
    role.value = _roleFromArgument(rawRole);
    refreshResults();
  }

  List<ResultModel> get studentResults =>
      results.where((item) => item.visibleToStudent).toList();

  List<ResultModel> get lecturerResults => results.toList();

  List<ResultModel> get officerResults => results
      .where((item) => item.status != ResultWorkflowStatus.published)
      .toList();

  int get pendingApprovalCount => results
      .where((item) => item.status == ResultWorkflowStatus.submitted)
      .length;

  int get readyToPublishCount => results
      .where((item) => item.status == ResultWorkflowStatus.approved)
      .length;

  String get providerLabel => ResultService.gateway.providerLabel;

  void switchRole(ResultsRole value) => role.value = value;

  Future<void> refreshResults() async {
    isLoading.value = true;
    try {
      results.assignAll(await ResultService.fetchResults());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveLecturerComment(ResultModel result, String comment) async {
    if (result.status == ResultWorkflowStatus.published) {
      _toast('Published result is locked; add officer-visible comments only.');
      return;
    }
    final updated = await ResultService.saveMark(
      result.copyWith(remark: comment.trim()),
    );
    _replace(result, updated);
    _toast('Result sent for officer approval.');
  }

  Future<void> approve(ResultModel result) async {
    final updated = await ResultService.approve(result);
    _replace(result, updated);
    _toast('Result approved.');
  }

  Future<void> publish(ResultModel result) async {
    final updated = await ResultService.publish(result);
    _replace(result, updated);
    _toast('Result published to students.');
  }

  void _replace(ResultModel oldResult, ResultModel updated) {
    final index = results.indexWhere((item) => item.id == oldResult.id);
    if (index == -1) return;
    results[index] = _mergeDisplayFields(oldResult, updated);
  }

  ResultModel _mergeDisplayFields(ResultModel oldResult, ResultModel updated) {
    return updated.copyWith(
      courseCode: updated.courseCode.isEmpty
          ? oldResult.courseCode
          : updated.courseCode,
      courseTitle: updated.courseTitle.isEmpty
          ? oldResult.courseTitle
          : updated.courseTitle,
      studentName: updated.studentName.startsWith('Student ')
          ? oldResult.studentName
          : updated.studentName,
      title: updated.title.trim().isEmpty ? oldResult.title : updated.title,
      maxScore: updated.maxScore <= 0 ? oldResult.maxScore : updated.maxScore,
    );
  }

  ResultsRole _roleFromArgument(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'lecturer':
        return ResultsRole.lecturer;
      case 'officer':
      case 'exam_officer':
        return ResultsRole.officer;
      case 'student':
      default:
        return ResultsRole.student;
    }
  }

  void _toast(String message) {
    Get.snackbar(
      'Results',
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }
}
