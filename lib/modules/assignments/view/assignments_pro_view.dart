import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/whiteboard/whiteboard_editor_sheet.dart';
import '../../../core/whiteboard/whiteboard_models.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/assignment_model.dart';
import '../../../data/services/assignment_lecturer_analytics_service.dart';
import '../../../data/services/assignment_quality_service.dart';
import '../../../data/services/assignment_receipt_service.dart';
import '../../../data/services/assignment_submission_storage.dart';
import '../controller/assignments_controller.dart';
import 'assignments_view.dart';

class AssignmentsProView extends GetView<AssignmentsController> {
  const AssignmentsProView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Obx(
                () => _AssignmentsProHeader(
                  providerLabel: controller.providerLabel.value,
                  isLecturerMode: controller.isLecturerMode.value,
                  onBack: () => Get.back<void>(),
                  onClassic: () => Get.to<void>(() => const AssignmentsView()),
                  onRoleChanged: (lecturer) {
                    controller.switchDemoRole(lecturer: lecturer);
                  },
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                final assignments = controller.visibleAssignments;
                final courses = controller.assignments
                    .map((item) => item.courseCode)
                    .toSet()
                    .toList()
                  ..sort();

                if (controller.isLoading.value && assignments.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return RefreshIndicator(
                  onRefresh: controller.loadAssignments,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                    children: [
                      if (controller.isLecturerMode.value)
                        _LecturerAssignmentDashboard(controller: controller)
                      else
                        _StudentAssignmentDashboard(controller: controller),
                      const SizedBox(height: 12),
                      _CourseFilterBar(
                        courses: courses,
                        selected: controller.filterCourseCode.value,
                        onChanged: (value) => controller.filterCourseCode.value = value,
                      ),
                      const SizedBox(height: 12),
                      if (assignments.isEmpty)
                        const _EmptyAssignmentsProState()
                      else
                        ...assignments.map(
                          (assignment) => _AssignmentProCard(
                            assignment: assignment,
                            controller: controller,
                            onSubmit: () => _openSubmitSheet(context, assignment),
                            onReceipt: () => _openReceipt(context, assignment),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _openSubmitSheet(BuildContext context, AssignmentModel assignment) {
    Get.bottomSheet<void>(
      _AssignmentProSubmitSheet(assignment: assignment, controller: controller),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }

  void _openReceipt(BuildContext context, AssignmentModel assignment) {
    final submission = controller.submissionFor(assignment.id);
    if (submission == null) return;
    Get.bottomSheet<void>(
      _AssignmentReceiptSheet(
        receipt: AssignmentReceiptService.buildReceipt(
          assignment: assignment,
          submission: submission,
        ),
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }
}

class _AssignmentsProHeader extends StatelessWidget {
  const _AssignmentsProHeader({
    required this.providerLabel,
    required this.isLecturerMode,
    required this.onBack,
    required this.onClassic,
    required this.onRoleChanged,
  });

  final String providerLabel;
  final bool isLecturerMode;
  final VoidCallback onBack;
  final VoidCallback onClassic;
  final ValueChanged<bool> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 14),
            color: cs.primary.withValues(alpha: 0.18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Assignments Pro',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Classic lecturer tools',
                onPressed: onClassic,
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isLecturerMode
                ? 'Review coursework, monitor submissions, and use classic tools for publishing and grading.'
                : 'Submit work with draft autosave, readiness checks, and official receipt evidence.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.90),
              fontWeight: FontWeight.w700,
              height: 1.28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            providerLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? cs.primary
                      : Colors.white,
                ),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.12),
                ),
                side: WidgetStateProperty.all(
                  BorderSide(color: Colors.white.withValues(alpha: 0.24)),
                ),
              ),
              segments: const [
                ButtonSegment(
                  value: false,
                  icon: Icon(Icons.school_outlined, size: 18),
                  label: Text('Student'),
                ),
                ButtonSegment(
                  value: true,
                  icon: Icon(Icons.co_present_outlined, size: 18),
                  label: Text('Lecturer'),
                ),
              ],
              selected: {isLecturerMode},
              onSelectionChanged: (values) {
                if (values.isNotEmpty) onRoleChanged(values.first);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentAssignmentDashboard extends StatelessWidget {
  const _StudentAssignmentDashboard({required this.controller});

  final AssignmentsController controller;

  @override
  Widget build(BuildContext context) {
    final assignments = controller.visibleAssignments;
    final status = [
      for (final assignment in assignments)
        AssignmentQualityService.statusFor(
          assignment: assignment,
          submission: controller.submissionFor(assignment.id),
        ),
    ];
    final dueSoon = status.where((item) => item.isDueSoon && !item.isSubmitted).length;
    final overdue = status.where((item) => item.isOverdue && !item.isSubmitted).length;
    final submitted = status.where((item) => item.isSubmitted).length;
    return _MetricWrap(
      items: [
        _MetricData('Assignments', assignments.length.toString(), Icons.assignment_rounded),
        _MetricData('Submitted', submitted.toString(), Icons.verified_rounded),
        _MetricData('Due soon', dueSoon.toString(), Icons.schedule_rounded),
        _MetricData('Overdue', overdue.toString(), Icons.warning_amber_rounded),
      ],
    );
  }
}

class _LecturerAssignmentDashboard extends StatelessWidget {
  const _LecturerAssignmentDashboard({required this.controller});

  final AssignmentsController controller;

  @override
  Widget build(BuildContext context) {
    final snapshot = AssignmentLecturerAnalyticsService.buildSnapshot(
      assignments: controller.visibleAssignments,
      submissions: controller.submissions,
      grades: controller.grades.values.toList(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetricWrap(
          items: [
            _MetricData('Published', snapshot.totalAssignments.toString(), Icons.post_add_rounded),
            _MetricData('Submissions', snapshot.totalSubmissions.toString(), Icons.cloud_done_rounded),
            _MetricData('Pending grading', snapshot.pendingGrading.toString(), Icons.pending_actions_rounded),
            _MetricData('Average', '${snapshot.averageScore}%', Icons.analytics_rounded),
          ],
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () => Get.to<void>(() => const AssignmentsView()),
          icon: const Icon(Icons.add_task_outlined),
          label: const Text('Open classic lecturer publishing and grading tools'),
        ),
      ],
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
}

class _MetricWrap extends StatelessWidget {
  const _MetricWrap({required this.items});

  final List<_MetricData> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((item) => _MetricTile(item: item)).toList(),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.item});

  final _MetricData item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 154,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: cs.primary),
          const SizedBox(height: 8),
          Text(item.value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _CourseFilterBar extends StatelessWidget {
  const _CourseFilterBar({
    required this.courses,
    required this.selected,
    required this.onChanged,
  });

  final List<String> courses;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt_outlined, color: cs.primary),
          const SizedBox(width: 10),
          const Text('Course', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: selected,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All courses')),
                  ...courses.map((course) => DropdownMenuItem(value: course, child: Text(course))),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentProCard extends StatelessWidget {
  const _AssignmentProCard({
    required this.assignment,
    required this.controller,
    required this.onSubmit,
    required this.onReceipt,
  });

  final AssignmentModel assignment;
  final AssignmentsController controller;
  final VoidCallback onSubmit;
  final VoidCallback onReceipt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final submission = controller.submissionFor(assignment.id);
    final draft = AssignmentSubmissionStorage.loadDraft(assignment.id);
    final status = AssignmentQualityService.statusFor(
      assignment: assignment,
      submission: submission,
    );
    final tone = status.isSubmitted
        ? cs.primary
        : status.isOverdue
            ? Colors.redAccent
            : status.isDueSoon
                ? Colors.orangeAccent
                : cs.secondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tone.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.assignment_turned_in_rounded, color: tone),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${assignment.courseCode} • ${assignment.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      assignment.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              _MiniPill(text: status.label, tone: tone),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: status.completionScore / 100,
              minHeight: 6,
              backgroundColor: cs.onSurface.withValues(alpha: 0.06),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(text: status.detail, tone: tone),
              _MiniPill(text: assignment.allowTextSubmission ? 'Text allowed' : 'No text', tone: cs.primary),
              if (assignment.allowFileSubmission)
                _MiniPill(text: assignment.allowedExtensions.join(', '), tone: cs.secondary),
              if (assignment.whiteboardEnabled)
                _MiniPill(
                  text: assignment.whiteboardRequired ? 'Whiteboard required' : 'Whiteboard optional',
                  tone: cs.tertiary,
                ),
              if (draft != null && submission == null)
                _MiniPill(text: 'Draft saved', tone: Colors.indigo),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: status.canSubmit ? onSubmit : null,
                  icon: Icon(submission == null ? Icons.cloud_upload_outlined : Icons.edit_note_rounded),
                  label: Text(submission == null ? 'Submit' : 'Resubmit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: submission == null ? null : onReceipt,
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('Receipt'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssignmentProSubmitSheet extends StatefulWidget {
  const _AssignmentProSubmitSheet({
    required this.assignment,
    required this.controller,
  });

  final AssignmentModel assignment;
  final AssignmentsController controller;

  @override
  State<_AssignmentProSubmitSheet> createState() => _AssignmentProSubmitSheetState();
}

class _AssignmentProSubmitSheetState extends State<_AssignmentProSubmitSheet> {
  late final TextEditingController _textController;
  final _files = <AssignmentUploadFile>[];
  List<WhiteboardStroke> _whiteboardStrokes = <WhiteboardStroke>[];
  Timer? _autosaveTimer;
  bool _submitting = false;
  DateTime? _lastDraftSavedAt;

  @override
  void initState() {
    super.initState();
    final existing = widget.controller.submissionFor(widget.assignment.id) ??
        AssignmentSubmissionStorage.loadDraft(widget.assignment.id);
    _textController = TextEditingController(text: existing?.textAnswer ?? '');
    _files.addAll(existing?.files ?? const []);
    _whiteboardStrokes = List<WhiteboardStroke>.from(existing?.whiteboardStrokes ?? const []);
    _textController.addListener(_scheduleAutosave);
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _textController.removeListener(_scheduleAutosave);
    _textController.dispose();
    super.dispose();
  }

  AssignmentSubmissionChecklist get _checklist => AssignmentQualityService.checklistFor(
        assignment: widget.assignment,
        textAnswer: _textController.text,
        files: _files,
        whiteboardStrokes: _whiteboardStrokes,
      );

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 700), () {
      unawaited(_saveDraft(silent: true));
    });
    setState(() {});
  }

  Future<void> _saveDraft({bool silent = false}) async {
    final text = _textController.text.trim();
    if (text.isEmpty && _files.isEmpty && _whiteboardStrokes.isEmpty) return;
    final draft = AssignmentSubmissionModel(
      assignmentId: widget.assignment.id,
      submittedAt: DateTime.now(),
      textAnswer: text.isEmpty ? null : text,
      files: List<AssignmentUploadFile>.from(_files),
      whiteboardStrokes: List<WhiteboardStroke>.from(_whiteboardStrokes),
      groupId: widget.assignment.isGroupAssignment ? widget.assignment.groupId : null,
      submittedById: widget.controller.currentActorId.value,
      submittedByName: widget.controller.currentActorName.value,
    );
    await AssignmentSubmissionStorage.saveDraft(draft);
    if (!mounted) return;
    setState(() => _lastDraftSavedAt = DateTime.now());
    if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved on this device.')),
      );
    }
  }

  Future<void> _pickFiles() async {
    final picked = await widget.controller.pickAllowedFiles(widget.assignment);
    if (picked.isEmpty) return;
    final existingPaths = _files.map((file) => file.path).toSet();
    for (final file in picked) {
      if (!existingPaths.contains(file.path)) _files.add(file);
    }
    await _saveDraft(silent: true);
    if (mounted) setState(() {});
  }

  Future<void> _openWhiteboard() async {
    if (!widget.assignment.whiteboardEnabled) return;
    final result = await Get.bottomSheet<List<WhiteboardStroke>>(
      WhiteboardEditorSheet(
        title: 'Assignment whiteboard',
        prompt: widget.assignment.whiteboardPrompt,
        initialStrokes: _whiteboardStrokes,
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
    if (result == null) return;
    setState(() => _whiteboardStrokes = result);
    await _saveDraft(silent: true);
  }

  Future<void> _submit() async {
    final checklist = _checklist;
    if (!checklist.ready) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(checklist.blockers.first)),
      );
      return;
    }
    setState(() => _submitting = true);
    final ok = await widget.controller.submitAssignment(
      assignment: widget.assignment,
      textAnswer: _textController.text,
      files: List<AssignmentUploadFile>.from(_files),
      whiteboardStrokes: List<WhiteboardStroke>.from(_whiteboardStrokes),
    );
    if (mounted) setState(() => _submitting = false);
    if (!ok) return;
    await AssignmentSubmissionStorage.clearDraft(widget.assignment.id);
    final submission = widget.controller.submissionFor(widget.assignment.id);
    if (!mounted || submission == null) return;
    await Get.bottomSheet<void>(
      _AssignmentReceiptSheet(
        receipt: AssignmentReceiptService.buildReceipt(
          assignment: widget.assignment,
          submission: submission,
        ),
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
    if (mounted) Get.back<void>();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final checklist = _checklist;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.90,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Submit • ${widget.assignment.courseCode}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                widget.assignment.title,
                style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _ChecklistPanel(checklist: checklist),
              const SizedBox(height: 12),
              if (widget.assignment.allowTextSubmission) ...[
                TextField(
                  controller: _textController,
                  minLines: 7,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    labelText: 'Text answer',
                    hintText: 'Write your assignment answer here...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (widget.assignment.whiteboardEnabled) ...[
                _WhiteboardPanel(
                  assignment: widget.assignment,
                  strokeCount: _whiteboardStrokes.length,
                  onOpen: _openWhiteboard,
                ),
                const SizedBox(height: 10),
              ],
              if (widget.assignment.allowFileSubmission) ...[
                _FilePanel(
                  assignment: widget.assignment,
                  files: _files,
                  onPick: _pickFiles,
                  onRemove: (index) {
                    setState(() => _files.removeAt(index));
                    unawaited(_saveDraft(silent: true));
                  },
                ),
                const SizedBox(height: 10),
              ],
              if (_lastDraftSavedAt != null)
                Text(
                  'Draft autosaved ${_fmtTime(_lastDraftSavedAt!)}',
                  style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _saveDraft(),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save draft'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.cloud_upload_outlined),
                      label: Text(_submitting ? 'Submitting...' : 'Submit now'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ChecklistPanel extends StatelessWidget {
  const _ChecklistPanel({required this.checklist});

  final AssignmentSubmissionChecklist checklist;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (checklist.ready ? cs.primary : Colors.orangeAccent).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (checklist.ready ? cs.primary : Colors.orangeAccent).withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(checklist.ready ? Icons.verified_rounded : Icons.rule_rounded, color: checklist.ready ? cs.primary : Colors.orangeAccent),
              const SizedBox(width: 8),
              Text(
                checklist.ready ? 'Ready to submit' : 'Submission checklist',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...checklist.blockers.map((item) => _ChecklistLine(icon: Icons.error_outline_rounded, text: item, tone: Colors.redAccent)),
          ...checklist.warnings.map((item) => _ChecklistLine(icon: Icons.info_outline_rounded, text: item, tone: Colors.orangeAccent)),
          ...checklist.items.map((item) => _ChecklistLine(icon: Icons.check_circle_outline_rounded, text: item, tone: cs.primary)),
        ],
      ),
    );
  }
}

class _ChecklistLine extends StatelessWidget {
  const _ChecklistLine({required this.icon, required this.text, required this.tone});

  final IconData icon;
  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tone),
          const SizedBox(width: 7),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _WhiteboardPanel extends StatelessWidget {
  const _WhiteboardPanel({
    required this.assignment,
    required this.strokeCount,
    required this.onOpen,
  });

  final AssignmentModel assignment;
  final int strokeCount;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.tertiary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.draw_outlined, color: cs.tertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              strokeCount == 0 ? 'No whiteboard diagram added' : '$strokeCount whiteboard stroke(s) added',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          OutlinedButton(onPressed: onOpen, child: Text(strokeCount == 0 ? 'Open' : 'Edit')),
        ],
      ),
    );
  }
}

class _FilePanel extends StatelessWidget {
  const _FilePanel({
    required this.assignment,
    required this.files,
    required this.onPick,
    required this.onRemove,
  });

  final AssignmentModel assignment;
  final List<AssignmentUploadFile> files;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file_rounded, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Allowed: ${assignment.allowedExtensions.join(', ')}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add'),
              ),
            ],
          ),
          if (files.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: files.asMap().entries.map((entry) {
                return Chip(
                  label: Text(entry.value.name),
                  onDeleted: () => onRemove(entry.key),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _AssignmentReceiptSheet extends StatelessWidget {
  const _AssignmentReceiptSheet({required this.receipt});

  final AssignmentSubmissionReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_rounded, color: cs.primary),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Assignment submission receipt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ReceiptLine(label: 'Receipt number', value: receipt.receiptNumber),
            _ReceiptLine(label: 'Course', value: receipt.courseCode),
            _ReceiptLine(label: 'Submitted by', value: receipt.submittedBy),
            _ReceiptLine(label: 'Mode', value: receipt.submissionModeLabel),
            _ReceiptLine(label: 'Submitted at', value: _fmtDateTime(receipt.submittedAt)),
            if (receipt.groupId != null) _ReceiptLine(label: 'Group ID', value: receipt.groupId!),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Get.back<void>(),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _ReceiptLine extends StatelessWidget {
  const _ReceiptLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700))),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.text, required this.tone});

  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(color: tone, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}

class _EmptyAssignmentsProState extends StatelessWidget {
  const _EmptyAssignmentsProState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(22)),
      child: const Column(
        children: [
          Icon(Icons.assignment_outlined, size: 46),
          SizedBox(height: 10),
          Text('No assignment matches this filter.'),
        ],
      ),
    );
  }
}
