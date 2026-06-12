import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/services/student_notification_service.dart';

class StudentNotificationsView extends StatefulWidget {
  const StudentNotificationsView({super.key});

  @override
  State<StudentNotificationsView> createState() => _StudentNotificationsViewState();
}

class _StudentNotificationsViewState extends State<StudentNotificationsView> {
  late List<StudentNotificationRecord> notifications;

  @override
  void initState() {
    super.initState();
    notifications = StudentNotificationService.load();
  }

  Future<void> refresh() async {
    setState(() => notifications = StudentNotificationService.load());
  }

  Future<void> markAllRead() async {
    await StudentNotificationService.markAllRead();
    await refresh();
  }

  Future<void> clearAll() async {
    await StudentNotificationService.clearAll();
    await refresh();
  }

  @override
  Widget build(BuildContext context) {
    final unread = notifications.where((item) => !item.read).length;
    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: _Header(
                unread: unread,
                total: notifications.length,
                onMarkAllRead: markAllRead,
                onClear: clearAll,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: refresh,
                child: notifications.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                        children: const [_EmptyState()],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = notifications[index];
                          return _NotificationCard(
                            item: item,
                            onTap: () async {
                              await StudentNotificationService.markRead(item.id);
                              await refresh();
                              final route = item.route;
                              if (route != null && route.isNotEmpty) {
                                Get.toNamed(route);
                              }
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.unread,
    required this.total,
    required this.onMarkAllRead,
    required this.onClear,
  });

  final int unread;
  final int total;
  final VoidCallback onMarkAllRead;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton.filledTonal(
            onPressed: () => Get.back<void>(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Student Notifications',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
            ),
          ),
          const Icon(Icons.notifications_active_outlined, color: Colors.white),
        ]),
        const SizedBox(height: 10),
        Text(
          '$unread unread • $total total alerts',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.tonalIcon(
            onPressed: unread == 0 ? null : onMarkAllRead,
            icon: const Icon(Icons.done_all_rounded),
            label: const Text('Mark all read'),
          ),
          OutlinedButton.icon(
            onPressed: total == 0 ? null : onClear,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Clear'),
          ),
        ]),
      ]),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});
  final StudentNotificationRecord item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = item.read ? cs.onSurface.withValues(alpha: 0.55) : cs.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: item.read ? 0.08 : 0.20)),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, 10),
              color: cs.shadow.withValues(alpha: item.read ? 0.03 : 0.07),
            ),
          ],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(_iconFor(item.category), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(item.title, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 15))),
                if (!item.read)
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                  ),
              ]),
              const SizedBox(height: 5),
              Text(item.message, style: TextStyle(color: cs.onSurface.withValues(alpha: 0.70), fontWeight: FontWeight.w600, height: 1.30)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _Chip(label: item.category),
                _Chip(label: _formatDate(item.createdAt)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  IconData _iconFor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('exam')) return Icons.verified_user_outlined;
    if (lower.contains('assessment')) return Icons.fact_check_outlined;
    if (lower.contains('offline')) return Icons.cloud_off_outlined;
    if (lower.contains('live')) return Icons.live_tv_outlined;
    if (lower.contains('assignment')) return Icons.assignment_outlined;
    return Icons.notifications_none_outlined;
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900, fontSize: 11)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(children: [
        Icon(Icons.notifications_off_outlined, size: 46, color: cs.primary),
        const SizedBox(height: 12),
        const Text('No notification', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        const SizedBox(height: 8),
        Text(
          'Exam, assessment, live class, result, and offline alerts will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.70), fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}

String _formatDate(DateTime value) {
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  final hh = value.hour.toString().padLeft(2, '0');
  final mm = value.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}
