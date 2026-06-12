import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/proctoring_controller.dart';

enum _CheckStepState { pending, running, passed, failed }

class ExamStartDialog extends StatefulWidget {
  const ExamStartDialog({
    super.key,
    required this.examId,
    this.sessionLabel = 'Exam',
  });

  final String examId;
  final String sessionLabel;

  @override
  State<ExamStartDialog> createState() => _ExamStartDialogState();
}

class _ExamStartDialogState extends State<ExamStartDialog> {
  late final ProctoringController _proctoring;

  _CheckStepState _fortress = _CheckStepState.pending;
  _CheckStepState _acoustic = _CheckStepState.pending;
  _CheckStepState _identity = _CheckStepState.pending;
  bool _running = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _proctoring = Get.find<ProctoringController>();
  }

  Future<void> _runChecks() async {
    if (_running) return;

    setState(() {
      _running = true;
      _errorText = null;
      _fortress = _CheckStepState.running;
      _identity = _CheckStepState.pending;
      _acoustic = _CheckStepState.pending;
    });

    final fortressOk = await _proctoring.ensureFortressReady();
    if (!mounted) return;
    if (!fortressOk) {
      setState(() {
        _fortress = _CheckStepState.failed;
        _running = false;
        _errorText = "Security fortress could not be activated.";
      });
      return;
    }

    setState(() {
      _fortress = _CheckStepState.passed;
      _identity = _CheckStepState.running;
    });

    final identityOk = await _proctoring.verifyIdentityAndEnvironment();
    if (!mounted) return;
    if (!identityOk) {
      setState(() {
        _identity = _CheckStepState.failed;
        _running = false;
        _errorText = "Identity/environment checks failed.";
      });
      return;
    }

    setState(() {
      _identity = _CheckStepState.passed;
      _acoustic = _CheckStepState.running;
    });

    final acousticOk = await _proctoring.verifyAcousticTether();
    if (!mounted) return;
    if (!acousticOk) {
      setState(() {
        _acoustic = _CheckStepState.failed;
        _running = false;
        _errorText =
            "Acoustic tether is unstable. Adjust the room/device audio and retry. The ${widget.sessionLabel.toLowerCase()} has not started.";
      });
      return;
    }

    setState(() {
      _acoustic = _CheckStepState.passed;
      _running = false;
    });

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Text(
          "K-SLAS ${widget.sessionLabel} Gateway",
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${widget.sessionLabel} ID: ${widget.examId}",
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.65),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _CheckRow(label: "OS fortress (anti-capture)", state: _fortress),
            _CheckRow(label: "Identity + environment check", state: _identity),
            _CheckRow(label: "Acoustic tether (background)", state: _acoustic),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: TextStyle(color: cs.error, fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _running ? null : () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          FilledButton.icon(
            onPressed: _running ? null : _runChecks,
            icon: _running
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified_user_outlined),
            label: Text(_running ? "Verifying..." : "Verify and start"),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.label, required this.state});

  final String label;
  final _CheckStepState state;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (IconData icon, Color color) = switch (state) {
      _CheckStepState.pending => (
        Icons.radio_button_unchecked_rounded,
        cs.onSurface.withValues(alpha: 0.5),
      ),
      _CheckStepState.running => (Icons.hourglass_bottom_rounded, cs.primary),
      _CheckStepState.passed => (Icons.check_circle_rounded, Colors.green),
      _CheckStepState.failed => (Icons.error_rounded, cs.error),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
