import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../modules/settings/controller/settings_controller.dart';

class DashboardLowDataOfflineLux extends StatelessWidget {
  const DashboardLowDataOfflineLux({
    super.key,
    required this.cs,
    required this.settings,
  });

  final ColorScheme cs;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final muted = cs.onSurface.withValues(alpha: 0.70);

    return Obx(() {
      final dataSaver = settings.dataSaver.value;
      final offline = settings.offlineDownloads.value;

      // MVP "estimated savings"
      final est = _estimateSavings(dataSaver: dataSaver, offline: offline);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium toggles row (responsive)
          LayoutBuilder(
            builder: (_, c) {
              final wide = c.maxWidth >= 520;
              if (!wide) {
                return Column(
                  children: [
                    _LuxToggleCard(
                      cs: cs,
                      title: "Data Saver",
                      subtitle: "Reduce image quality & background sync",
                      icon: Icons.data_saver_on_outlined,
                      value: dataSaver,
                      onChanged: (v) => settings.setDataSaver(v),
                    ),
                    const SizedBox(height: 10),
                    _LuxToggleCard(
                      cs: cs,
                      title: "Offline mode",
                      subtitle: "Keep selected content available offline",
                      icon: Icons.download_outlined,
                      value: offline,
                      onChanged: (v) => settings.setOfflineDownloads(v),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _LuxToggleCard(
                      cs: cs,
                      title: "Data Saver",
                      subtitle: "Reduce image quality & background sync",
                      icon: Icons.data_saver_on_outlined,
                      value: dataSaver,
                      onChanged: (v) => settings.setDataSaver(v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LuxToggleCard(
                      cs: cs,
                      title: "Offline mode",
                      subtitle: "Keep selected content available offline",
                      icon: Icons.download_outlined,
                      value: offline,
                      onChanged: (v) => settings.setOfflineDownloads(v),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          // Mini stats row (lux)
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  cs: cs,
                  title: "Estimated savings",
                  value: est,
                  icon: Icons.bolt_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  cs: cs,
                  title: "Offline items",
                  value: offline ? "3 saved" : "0 saved",
                  icon: Icons.inventory_2_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Premium CTA area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
                  ),
                  child: Icon(Icons.save_alt_outlined, color: cs.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    offline
                        ? "Save notes & past questions for offline use."
                        : "Turn on Offline mode to save content.",
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: offline ? () {} : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: cs.onSurface.withValues(alpha: 0.10),
                    disabledForegroundColor: cs.onSurface.withValues(alpha: 0.50),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text("Save"),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Tip: Offline is best for lecture notes and past questions.",
            style: TextStyle(color: muted, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      );
    });
  }

  static String _estimateSavings({required bool dataSaver, required bool offline}) {
    if (dataSaver && offline) return "High";
    if (dataSaver || offline) return "Medium";
    return "Low";
  }
}

class _LuxToggleCard extends StatelessWidget {
  const _LuxToggleCard({
    required this.cs,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final ColorScheme cs;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final muted = cs.onSurface.withValues(alpha: 0.70);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withValues(alpha: 0.06),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: (value ? cs.secondary : cs.primary).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (value ? cs.secondary : cs.primary).withValues(alpha: 0.16),
              ),
            ),
            child: Icon(icon, color: value ? cs.secondary : cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.cs,
    required this.title,
    required this.value,
    required this.icon,
  });

  final ColorScheme cs;
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final muted = cs.onSurface.withValues(alpha: 0.70);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.primary.withValues(alpha: 0.16)),
            ),
            child: Icon(icon, color: cs.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: muted, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
