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
                  title: 'Noticeboard',
                  subtitle: 'Official school, exam, and course updates.',
                  onBack: () => Get.back<void>(),
                  rightPill: controller.showBookmarkedOnly.value ? 'Bookmarked' : 'All',
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
                  final pendingAck = items
                      .where(
                        (notice) => notice.requiresAcknowledgement &&
                            !controller.isAcknowledged(notice.id),
                      )
                      .length;
                  final pinnedCount = items.where((notice) => notice.pinned).length;

                  return RefreshIndicator(
                    onRefresh: () async {
                      controller.load();
                      controller.update();
                    },
                    child: ListView(
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
                        _NoticeStatsStrip(
                          total: items.length,
                          pinned: pinnedCount,
                          pendingAcknowledgement: pendingAck,
                        ),
                        if (pendingAck > 0) ...[
                          const SizedBox(height: 12),
                          _AcknowledgementBanner(count: pendingAck),
                        ],
                        const SizedBox(height: 12),
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Center(
                              child: Text(
                                'No notices yet.',
                                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7)),
                              ),
                            ),
                          ),
                        ...items.map((n) => _NoticeCardPremium(notice: n)),
                      ],
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
              const Text('Course', style: TextStyle(fontWeight: FontWeight.w900)),
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
                        const DropdownMenuItem(value: null, child: Text('All')),
                        ...courses.map((c) => DropdownMenuItem(value: c, child: Text(c))),
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
                    'Bookmarked',
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

class _NoticeStatsStrip extends StatelessWidget {
  const _NoticeStatsStrip({
    required this.total,
    required this.pinned,
    required this.pendingAcknowledgement,
  });

  final int total;
  final int pinned;
  final int pendingAcknowledgement;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatPill(text: '$total notices', icon: Icons.campaign_outlined, color: cs.primary),
        _StatPill(text: '$pinned pinned', icon: Icons.push_pin_outlined, color: cs.secondary),
        _StatPill(
          text: '$pendingAcknowledgement pending acknowledgement',
          icon: Icons.verified_user_outlined,
          color: pendingAcknowledgement > 0 ? cs.error : cs.tertiary,
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.text, required this.icon, required this.color});

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
        ],
      ),
    );
  }
}

class _AcknowledgementBanner extends StatelessWidget {
  const _AcknowledgementBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.error.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.priority_high_rounded, color: cs.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count notice(s) require your acknowledgement. Open the notice and tap Acknowledge after reading.',
              style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800, height: 1.25),
            ),
          ),
        ],
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
    final acknowledged = c.isAcknowledged(notice.id);
    final muted = cs.onSurface.withValues(alpha: 0.68);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: notice.pinned ? cs.primary.withValues(alpha: 0.05) : cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: notice.requiresAcknowledgement && !acknowledged
                  ? cs.error.withValues(alpha: 0.30)
                  : cs.onSurface.withValues(alpha: 0.06),
            ),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      notice.title,
                      style: TextStyle(
                        fontWeight: notice.isImportant || notice.pinned ? FontWeight.w900 : FontWeight.w800,
                        decoration: isRead ? TextDecoration.lineThrough : null,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (notice.pinned)
                    _pill(text: 'Pinned', color: cs.primary, icon: Icons.push_pin_rounded),
                  if (notice.isImportant) ...[
                    const SizedBox(width: 6),
                    _pill(text: 'Important', color: cs.error, icon: Icons.priority_high_rounded),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(notice.body, style: TextStyle(color: cs.onSurface, height: 1.25)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _pill(
                    text: notice.scope == NoticeScope.course ? (notice.courseCode ?? 'Course') : _scopeLabel(notice.scope),
                    color: cs.secondary,
                    icon: Icons.label_outline_rounded,
                  ),
                  _pill(text: notice.source, color: cs.primary, icon: Icons.account_balance_outlined),
                  if (notice.reference != null)
                    _pill(text: notice.reference!, color: cs.tertiary, icon: Icons.confirmation_number_outlined),
                  if (notice.requiresAcknowledgement)
                    _pill(
                      text: acknowledged ? 'Acknowledged' : 'Ack required',
                      color: acknowledged ? cs.tertiary : cs.error,
                      icon: acknowledged ? Icons.verified_rounded : Icons.assignment_late_outlined,
                    ),
                  _pill(text: _timeAgo(notice.createdAt), color: muted, icon: Icons.schedule_rounded),
                ],
              ),
              const SizedBox(height: 10),
              Divider(color: cs.onSurface.withValues(alpha: 0.08)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _iconAction(
                    context,
                    tooltip: isBm ? 'Unbookmark' : 'Bookmark',
                    icon: isBm ? Icons.bookmark : Icons.bookmark_outline,
                    color: cs.primary,
                    onTap: () => c.toggleBookmark(notice.id),
                  ),
                  const SizedBox(width: 6),
                  _iconAction(
                    context,
                    tooltip: isRead ? 'Mark unread' : 'Mark read',
                    icon: isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                    color: cs.secondary,
                    onTap: () => c.toggleRead(notice.id),
                  ),
                  const Spacer(),
                  if (notice.requiresAcknowledgement)
                    OutlinedButton.icon(
                      onPressed: acknowledged ? null : () => c.acknowledge(notice.id),
                      icon: Icon(acknowledged ? Icons.verified_rounded : Icons.check_circle_outline_rounded),
                      label: Text(acknowledged ? 'Acknowledged' : 'Acknowledge'),
                    )
                  else
                    _iconAction(
                      context,
                      tooltip: 'Share',
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

  Widget _pill({required String text, required Color color, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12),
          ),
        ],
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

  String _scopeLabel(String scope) {
    switch (scope) {
      case NoticeScope.school:
        return 'School';
      case NoticeScope.exam:
        return 'Exam';
      case NoticeScope.department:
        return 'Department';
      case NoticeScope.programme:
        return 'Programme';
      case NoticeScope.course:
      default:
        return 'Course';
    }
  }

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
