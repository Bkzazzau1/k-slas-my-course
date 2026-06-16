import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/services/student_auth_service.dart';
import '../controller/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: LuxuryScaffold(
        safeArea: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionTitle('Student goals'),
            const SizedBox(height: 8),

            Obx(
              () => _Tile(
                title: 'Target grade per course',
                value: controller.targetGrade.value,
                onTap: _openTargetGradeSheet,
              ),
            ),
            Obx(
              () => _Tile(
                title: 'Daily study time',
                value: controller.dailyStudyLabel,
                onTap: _openStudyTimeSheet,
              ),
            ),
            Obx(
              () => _Tile(
                title: 'Preferred study time',
                value: controller.preferredTime.value,
                onTap: _openPreferredTimeSheet,
              ),
            ),
            Obx(
              () => _Tile(
                title: 'Exam mode',
                value: controller.examMode.value,
                onTap: _openExamModeSheet,
              ),
            ),

            const SizedBox(height: 16),
            _SectionTitle('App preferences'),
            const SizedBox(height: 8),

            Obx(
              () => _Toggle(
                title: 'Dark mode',
                value: controller.darkMode.value,
                onChanged: controller.setDarkMode,
              ),
            ),
            Obx(
              () => _Toggle(
                title: 'Data saver mode',
                value: controller.dataSaver.value,
                onChanged: controller.setDataSaver,
              ),
            ),
            Obx(
              () => _Toggle(
                title: 'Offline downloads',
                value: controller.offlineDownloads.value,
                onChanged: controller.setOfflineDownloads,
              ),
            ),
            Obx(
              () => _Toggle(
                title: 'Demo mode',
                subtitle: 'Allows proctoring checks to be overridden.',
                value: controller.demoMode.value,
                onChanged: controller.setDemoMode,
              ),
            ),

            const SizedBox(height: 16),
            _SectionTitle('Storage'),
            const SizedBox(height: 8),

            _glassCard(
              context,
              child: ListTile(
                title: const Text(
                  'Clear saved settings/cache',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Resets goals & preferences',
                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                ),
                trailing: const Icon(Icons.delete_outline),
                onTap: () async {
                  final ok = await _confirm(
                    'Clear data?',
                    'This will reset your settings.',
                  );
                  if (ok) await controller.clearCache();
                },
              ),
            ),

            const SizedBox(height: 16),
            _SectionTitle('Account & security'),
            const SizedBox(height: 8),

            _Tile(
              title: 'Face enrollment',
              value: 'Register / update',
              onTap: () => Get.toNamed('/identity/face-enrollment'),
            ),
            _Tile(
              title: 'Student backend login',
              value: StudentAuthService.hasToken
                  ? 'Connected'
                  : 'Not connected',
              onTap: _openStudentLoginSheet,
            ),

            const SizedBox(height: 16),
            _SectionTitle('Subscription'),
            const SizedBox(height: 8),

            const _Tile(
              title: 'Plan status',
              value: 'Starter (renews in 12 days)',
              onTap: null,
            ),
            const _Tile(
              title: 'Renew subscription',
              value: 'Update billing',
              onTap: null,
            ),

            const SizedBox(height: 10),
            TextButton(
              onPressed: () async {
                await StudentAuthService.logout();
                Get.snackbar(
                  'Logout',
                  'Student session cleared.',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Bottom sheets ----------------

  void _openStudentLoginSheet() {
    final identityCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Student backend login',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: identityCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email, phone, or matric number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final ok = await StudentAuthService.login(
                      identity: identityCtrl.text,
                      password: passwordCtrl.text,
                    );
                    Get.back();
                    Get.snackbar(
                      'Student login',
                      ok
                          ? 'Connected to backend student account.'
                          : 'Login unavailable. Check production mode, API URL, and credentials.',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Login'),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      identityCtrl.dispose();
      passwordCtrl.dispose();
    });
  }

  void _openTargetGradeSheet() {
    final grades = ['A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'D', 'E', 'F'];

    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      builder: (_) => _SimpleSelectSheet(
        title: 'Target grade',
        options: grades,
        selected: controller.targetGrade.value,
        onPick: (v) async {
          await controller.setTargetGrade(v);
          Get.back();
        },
      ),
    );
  }

  void _openPreferredTimeSheet() {
    final options = ['Morning', 'Afternoon', 'Evening', 'Night'];

    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      builder: (_) => _SimpleSelectSheet(
        title: 'Preferred study time',
        options: options,
        selected: controller.preferredTime.value,
        onPick: (v) async {
          await controller.setPreferredTime(v);
          Get.back();
        },
      ),
    );
  }

  void _openExamModeSheet() {
    final options = ['Strict', 'Balanced', 'Chill'];

    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      builder: (_) => _SimpleSelectSheet(
        title: 'Exam mode',
        options: options,
        selected: controller.examMode.value,
        onPick: (v) async {
          await controller.setExamMode(v);
          Get.back();
        },
      ),
    );
  }

  void _openStudyTimeSheet() {
    // minutes options
    final mins = [30, 45, 60, 75, 90, 105, 120, 150, 180];

    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      builder: (_) => _SimpleSelectSheet(
        title: 'Daily study time',
        options: mins.map((m) => _fmtMin(m)).toList(),
        selected: _fmtMin(controller.dailyStudyMin.value),
        onPick: (label) async {
          final picked = mins.firstWhere(
            (m) => _fmtMin(m) == label,
            orElse: () => 90,
          );
          await controller.setDailyStudyMin(picked);
          Get.back();
        },
      ),
    );
  }

  static String _fmtMin(int m) {
    final h = m ~/ 60;
    final r = m % 60;
    if (h == 0) return '${r}m';
    if (r == 0) return '${h}h';
    return '${h}h ${r}m';
  }

  Future<bool> _confirm(String title, String body) async {
    final res = await showDialog<bool>(
      context: Get.context!,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return res ?? false;
  }
}

// ---------------- Reusable small widgets ----------------

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.title, required this.value, required this.onTap});

  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _glassCard(
      context,
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: Text(
          value,
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.65)),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _glassCard(
      context,
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: subtitle == null ? null : Text(subtitle!),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _SimpleSelectSheet extends StatelessWidget {
  const _SimpleSelectSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.onPick,
  });

  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final opt = options[i];
                  final isSel = opt == selected;
                  return _glassCard(
                    context,
                    child: ListTile(
                      title: Text(
                        opt,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      trailing: isSel
                          ? Icon(Icons.check_circle, color: cs.primary)
                          : null,
                      onTap: () => onPick(opt),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _glassCard(BuildContext context, {required Widget child}) {
  final cs = Theme.of(context).colorScheme;
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 10),
              color: cs.onSurface.withValues(alpha: 0.04),
            ),
          ],
        ),
        child: child,
      ),
    ),
  );
}
