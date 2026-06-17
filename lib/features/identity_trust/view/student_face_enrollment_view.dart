import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/camera_face_enrollment_sampler.dart';
import '../services/demo_identity_trust_repository.dart';
import '../services/face_embedding_connector.dart';
import '../services/identity_trust_repository.dart';
import '../services/static_face_embedding_connector.dart';
import '../services/student_face_enrollment_controller.dart';

class StudentFaceEnrollmentView extends StatefulWidget {
  const StudentFaceEnrollmentView({super.key});

  @override
  State<StudentFaceEnrollmentView> createState() =>
      _StudentFaceEnrollmentViewState();
}

class _StudentFaceEnrollmentViewState extends State<StudentFaceEnrollmentView> {
  late final StudentFaceEnrollmentController controller;
  late final FaceEmbeddingConnector connector;
  StudentFaceEnrollmentSnapshot? snapshot;
  CameraController? cameraController;
  bool loading = true;
  bool cameraLoading = true;
  bool cameraAvailable = false;
  bool capturing = false;
  String? cameraError;

  @override
  void initState() {
    super.initState();
    connector = Get.isRegistered<FaceEmbeddingConnector>()
        ? Get.find<FaceEmbeddingConnector>()
        : StaticFaceEmbeddingConnector(
            embedding: const <double>[1, 0, 0],
            version: 'demo-static-face-v1',
          );
    final repository = Get.isRegistered<IdentityTrustRepository>()
        ? Get.find<IdentityTrustRepository>()
        : DemoIdentityTrustRepository();
    controller = StudentFaceEnrollmentController(
      repository: repository,
      connector: connector,
    );
    _load();
    _openCamera();
  }

  Future<void> _load() async {
    final next = await controller.load();
    if (!mounted) return;
    setState(() {
      snapshot = next;
      loading = false;
    });
  }

  Future<void> _openCamera() async {
    setState(() {
      cameraLoading = true;
      cameraAvailable = false;
      cameraError = null;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          cameraLoading = false;
          cameraAvailable = false;
          cameraError = 'No camera found on this device.';
        });
        return;
      }

      final front = cameras
          .where((camera) => camera.lensDirection == CameraLensDirection.front)
          .toList();
      final selected = front.isNotEmpty ? front.first : cameras.first;
      final controller = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        cameraController = controller;
        cameraLoading = false;
        cameraAvailable = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        cameraLoading = false;
        cameraAvailable = false;
        cameraError = e.toString();
      });
    }
  }

  Future<void> _captureSample() async {
    if (capturing) return;
    setState(() => capturing = true);

    try {
      final camera = cameraController;
      StudentFaceEnrollmentSnapshot next;
      if (cameraAvailable && camera != null && camera.value.isInitialized) {
        next = await controller.addCameraSample(
          CameraFaceEnrollmentSampler(
            cameraController: camera,
            connector: connector,
          ),
        );
      } else {
        next = await controller.addDemoSample();
      }

      if (!mounted) return;
      setState(() {
        snapshot = next;
        capturing = false;
      });
    } catch (e) {
      final next = await controller.addDemoSample();
      if (!mounted) return;
      setState(() {
        snapshot = next;
        capturing = false;
        cameraError = 'Camera capture failed, so a demo sample was used: $e';
      });
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = snapshot;

    return Scaffold(
      appBar: AppBar(title: const Text('Face Enrollment')),
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
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        data.statusText,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      _cameraCard(context),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _row(
                                'Student ID',
                                data.studentId.isEmpty
                                    ? 'Not found'
                                    : data.studentId,
                              ),
                              _row(
                                'Required samples',
                                '${data.requiredSamples}',
                              ),
                              _row(
                                'Captured samples',
                                '${data.capturedSamples}',
                              ),
                              _row(
                                'Enrollment status',
                                data.isComplete ? 'Active' : 'Pending',
                              ),
                              if (data.lastQualityScore != null)
                                _row(
                                  'Last sample quality',
                                  '${(data.lastQualityScore! * 100).round()}%',
                                ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: data.requiredSamples == 0
                                    ? 0
                                    : (data.capturedSamples /
                                              data.requiredSamples)
                                          .clamp(0.0, 1.0),
                                minHeight: 10,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: data.isComplete || capturing
                            ? null
                            : _captureSample,
                        icon: capturing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.camera_alt_rounded),
                        label: Text(
                          data.isComplete
                              ? 'Enrollment completed'
                              : capturing
                              ? 'Capturing sample...'
                              : 'Capture face sample',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        cameraAvailable
                            ? 'Camera enrollment is active. Keep your face centered, use good lighting, and capture each sample clearly.'
                            : 'Camera is not available, so demo samples will be used for frontend testing.',
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

  Widget _cameraCard(BuildContext context) {
    final camera = cameraController;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: cameraLoading
            ? const Center(child: CircularProgressIndicator())
            : cameraAvailable && camera != null && camera.value.isInitialized
            ? Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(camera),
                  Center(
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    cameraError ?? 'Camera preview is not available.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
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
