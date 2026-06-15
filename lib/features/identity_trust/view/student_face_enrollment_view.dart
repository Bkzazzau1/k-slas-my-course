import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/face_embedding_connector.dart';
import '../services/identity_trust_repository.dart';
import '../services/student_face_enrollment_controller.dart';

class StudentFaceEnrollmentView extends StatefulWidget {
  const StudentFaceEnrollmentView({super.key});

  @override
  State<StudentFaceEnrollmentView> createState() => _StudentFaceEnrollmentViewState();
}

class _StudentFaceEnrollmentViewState extends State<StudentFaceEnrollmentView> {
  late final StudentFaceEnrollmentController controller;
  StudentFaceEnrollmentSnapshot? snapshot;
  bool loading = true;
  bool capturing = false;

  @override
  void initState() {
    super.initState();
    controller = StudentFaceEnrollmentController(
      repository: Get.find<IdentityTrustRepository>(),
      connector: Get.isRegistered<FaceEmbeddingConnector>()
          ? Get.find<FaceEmbeddingConnector>()
          : null,
    );
    _load();
  }

  Future<void> _load() async {
    final next = await controller.load();
    if (!mounted) return;
    setState(() {
      snapshot = next;
      loading = false;
    });
  }

  Future<void> _captureSample() async {
    if (capturing) return;
    setState(() => capturing = true);
    final next = await controller.addDemoSample();
    if (!mounted) return;
    setState(() {
      snapshot = next;
      capturing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = snapshot;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Enrollment'),
      ),
      body: loading || data == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        data.isComplete
                            ? Icons.verified_user_rounded
                            : Icons.face_retouching_natural_rounded,
                        size: 72,
                        color: data.isComplete ? Colors.green : cs.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        data.isComplete
                            ? 'Face enrollment active'
                            : 'Register your face for secure exams',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        data.statusText,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _row('Student ID', data.studentId.isEmpty ? 'Not found' : data.studentId),
                              _row('Required samples', '${data.requiredSamples}'),
                              _row('Captured samples', '${data.capturedSamples}'),
                              _row('Enrollment status', data.isComplete ? 'Active' : 'Pending'),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: data.requiredSamples == 0
                                    ? 0
                                    : (data.capturedSamples / data.requiredSamples).clamp(0.0, 1.0),
                                minHeight: 10,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: data.isComplete || capturing ? null : _captureSample,
                        icon: capturing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.camera_alt_rounded),
                        label: Text(
                          data.isComplete
                              ? 'Enrollment completed'
                              : capturing
                                  ? 'Capturing sample...'
                                  : 'Capture sample',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Demo mode uses a static local embedding. The next step will replace this button with live camera capture and real local model inference.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Flexible(
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
