import 'dart:async';

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
  bool _permissionNoticeAccepted = false;
  String? _errorText;

  bool get _isExam => widget.sessionLabel.toLowerCase().contains('exam');

  @override
  void initState() {
    super.initState();
    _proctoring = Get.find<ProctoringController>();
  }

  Future<bool> _showPermissionNotice() async {
    final allowed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return AlertDialog(
          title: Text('Allow ${widget.sessionLabel.toLowerCase()} verification permissions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'K-SLAS needs these checks before the ${widget.sessionLabel.toLowerCase()} can start:',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const _PermissionLine(
                icon: Icons.camera_alt_rounded,
                label: 'Camera for live identity and environment scan',
              ),
              const _PermissionLine(
                icon: Icons.mic_rounded,
                label: 'Microphone for acoustic integrity checks',
              ),
              const _PermissionLine(
                icon: Icons.screen_lock_portrait_rounded,
                label: 'Screen, motion, and app-focus monitoring',
              ),
              const _PermissionLine(
                icon: Icons.devices_other_rounded,
                label: 'Network and connected-device safety checks',
              ),
              const SizedBox(height: 10),
              Text(
                'Your browser or operating system may show its own permission popup next. Choose Allow to continue.',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(false),
              icon: const Icon(Icons.dashboard_rounded),
              label: const Text('Return to dashboard'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.verified_user_rounded),
              label: const Text('Allow and continue'),
            ),
          ],
        );
      },
    );
    return allowed == true;
  }

  Future<void> _returnToDashboard() async {
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(false);
    }
    Get.offAllNamed('/main');
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await _proctoring.stopSession(silent: true);
  }

  Future<bool> _runCameraEnvironmentScan() async {
    await _proctoring.verifyNetworkIntegrity();

    if (_proctoring.examStartupScanCompleted.value &&
        !_proctoring.scanRequired.value) {
      return true;
    }

    _proctoring.requestEnvironmentScan(
      _isExam
          ? 'Complete a live camera environment scan before this high-stakes exam can begin.'
          : 'Complete a live camera environment scan before this graded assessment can begin.',
    );

    final timeout = DateTime.now().add(const Duration(minutes: 3));
    while (mounted && DateTime.now().isBefore(timeout)) {
      if (_proctoring.sessionTerminated.value) return false;
      if (_proctoring.examStartupScanCompleted.value &&
          !_proctoring.scanRequired.value &&
          !_proctoring.scanInProgress.value) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    return false;
  }

  Future<void> _runChecks() async {
    if (_running) return;

    if (!_permissionNoticeAccepted) {
      final accepted = await _showPermissionNotice();
      if (!mounted) return;
      if (!accepted) {
        await _returnToDashboard();
        return;
      }
      _permissionNoticeAccepted = true;
    }

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
        _errorText = 'Security fortress could not be activated.';
      });
      return;
    }

    setState(() {
      _fortress = _CheckStepState.passed;
      _identity = _CheckStepState.running;
    });

    final identityOk = await _runCameraEnvironmentScan();
    if (!mounted) return;
    if (!identityOk) {
      setState(() {
        _identity = _CheckStepState.failed;
        _running = false;
        _errorText =
            'Camera/environment verification failed. Allow camera access, complete the scan, or return to the dashboard.';
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
            'Microphone/audio verification failed. Allow microphone access, check your audio, then retry.';
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
          'K-SLAS ${widget.sessionLabel} Gateway',
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.sessionLabel} ID: ${widget.examId}',
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.65),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _CheckRow(label: 'OS fortress anti-capture', state: _fortress),
            _CheckRow(label: 'Live camera identity and room scan', state: _identity),
            _CheckRow(label: 'Microphone acoustic tether', state: _acoustic),
            if (!_permissionNoticeAccepted) ...[
              const SizedBox(height: 10),
              Text(
                'You will be asked to allow camera, microphone, and integrity permissions before verification starts.',
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
          TextButton.icon(
            onPressed: _running ? null : _returnToDashboard,
            icon: const Icon(Icons.dashboard_rounded),
            label: const Text('Dashboard'),
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
            label: Text(_running ? 'Verifying...' : 'Verify and start'),
          ),
        ],
      ),
    );
  }
}

class _PermissionLine extends StatelessWidget {
  const _PermissionLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
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
