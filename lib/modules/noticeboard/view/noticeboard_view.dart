import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/notice_model.dart';
import '../../../data/services/student_profile_storage.dart';
import '../controller/noticeboard_controller.dart';

class NoticeboardView extends StatefulWidget {
  const NoticeboardView({super.key});

  @override
  State<NoticeboardView> createState() => _NoticeboardViewState();
}

class _NoticeboardViewState extends State<NoticeboardView> {
  late final NoticeboardController controller;
  late final List<String> courses;

  @override
  void initState() {
    super.initState();
    controller = Get.find<NoticeboardController>();
    final profile = StudentProfileStorage.load();
    courses = profile?.selectedCourses ?? const <String>[];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: GetBuilder<NoticeboardController>(
                builder: (_) => _HeroHeader(
                  title: "Noticeboard",
                  subtitle: "School & course updates from lecturers/admin.",
                  onBack: () => Get.back(),
                  rightPill: controller.showBookmarkedOnly.value ? "Bookmarked" : "All",
                  onToggleBookmarkMode: () {
                    controller.showBookmarkedOnly.toggle();
                    controller.update();
                  },
                  bookmarked: controller.showBookmarkedOnly.value,
                ),
              ),
            ),

            Expanded(
              child: GetBuilder<NoticeboardController>(
                builder: (_) {
                  final items = controller.visible;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      _GlassFilterBar(
                        courses: courses,
                        value: controller.filterCourseCode.value,
                        onChanged: (v) {
                          controller.filterCourseCode.value = v;
                          controller.update();
                        },
                        showBookmarkedOnly: controller.showBookmarkedOnly.value,
                      ),
                      const SizedBox(height: 12),

                      if (items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text(
                              "No notices yet.",
                              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                            ),
                          ),
                        ),

                      ...items.map((n) => _NoticeCardPremium(notice: n)),
                    ],
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

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.rightPill,
    required this.onToggleBookmarkMode,
    required this.bookmarked,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final String rightPill;
  final VoidCallback onToggleBookmarkMode;
  final bool bookmarked;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.95),
            cs.secondary.withValues(alpha: 0.80),
          ],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 14),
            color: cs.primary.withValues(alpha: 0.18),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.92), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              InkWell(
                onTap: onToggleBookmarkMode,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                  ),
                  child: Icon(
                    bookmarked ? Icons.bookmark : Icons.bookmark_outline,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                ),
                child: Text(
                  rightPill,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassFilterBar extends StatelessWidget {
  const _GlassFilterBar({
    required this.courses,
    required this.value,
    required this.onChanged,
    required this.showBookmarkedOnly,
  });

  final List<String> courses;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool showBookmarkedOnly;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              const Icon(Icons.filter_alt_outlined),
              const SizedBox(width: 10),
              const Text("Course", style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: value,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text("All")),
                        ...courses.map(
                          (c) => DropdownMenuItem(value: c, child: Text(c)),
                        ),
                      ],
                      onChanged: onChanged,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (showBookmarkedOnly)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    "Bookmarked",
                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeCardPremium extends StatelessWidget {
  const _NoticeCardPremium({required this.notice});
  final NoticeModel notice;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = Get.find<NoticeboardController>();

    final isRead = c.isRead(notice.id);
    final isBm = c.isBookmarked(notice.id);
    final muted = cs.onSurface.withValues(alpha: 0.68);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      notice.title,
                      style: TextStyle(
                        fontWeight: notice.priority == 1 ? FontWeight.w900 : FontWeight.w800,
                        decoration: isRead ? TextDecoration.lineThrough : null,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (notice.priority == 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        "Important",
                        style: TextStyle(
                          color: cs.error,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              Text(notice.body, style: TextStyle(color: cs.onSurface, height: 1.25)),
              const SizedBox(height: 10),

              // Pills row
              Row(
                children: [
                  _pill(
                    text: notice.scope == NoticeScope.course ? (notice.courseCode ?? "Course") : "School",
                    color: cs.secondary,
                  ),
                  const SizedBox(width: 6),
                  _pill(text: notice.source, color: cs.primary),
                  const Spacer(),
                  Text(_timeAgo(notice.createdAt), style: TextStyle(color: muted, fontWeight: FontWeight.w600)),
                ],
              ),

              const SizedBox(height: 10),
              Divider(color: cs.onSurface.withValues(alpha: 0.08)),
              const SizedBox(height: 6),

              // Actions
              Row(
                children: [
                  _iconAction(
                    context,
                    tooltip: isBm ? "Unbookmark" : "Bookmark",
                    icon: isBm ? Icons.bookmark : Icons.bookmark_outline,
                    color: cs.primary,
                    onTap: () => c.toggleBookmark(notice.id),
                  ),
                  const SizedBox(width: 6),
                  _iconAction(
                    context,
                    tooltip: isRead ? "Mark unread" : "Mark read",
                    icon: isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                    color: cs.secondary,
                    onTap: () => c.toggleRead(notice.id),
                  ),
                  const Spacer(),
                  _iconAction(
                    context,
                    tooltip: "Share",
                    icon: Icons.ios_share_outlined,
                    color: cs.primary,
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill({required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }

  Widget _iconAction(
    BuildContext context, {
    required String tooltip,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }
}
