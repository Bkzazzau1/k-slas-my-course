import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/live_session_models.dart';
import '../../../data/services/live_class_control_room_service.dart';
import '../controller/live_sessions_controller.dart';
import '../live_session_utils.dart';

class ChiefInvigilatorLiveOverviewView extends StatefulWidget {
  const ChiefInvigilatorLiveOverviewView({super.key});

  @override
  State<ChiefInvigilatorLiveOverviewView> createState() =>
      _ChiefInvigilatorLiveOverviewViewState();
}

class _ChiefInvigilatorLiveOverviewViewState
    extends State<ChiefInvigilatorLiveOverviewView> {
  final LiveSessionsController controller = Get.find<LiveSessionsController>();
  final snapshots = <LiveClassControlRoomSnapshot>[].obs;
  final isLoading = false.obs;
  final selectedFilter = 'All'.obs;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshControlRoom());
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(_refreshControlRoom(silent: true));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshControlRoom({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      await controller.loadSessions();
      final rooms = <LiveSessionRoomState>[];
      for (final session in controller.sessions) {
        rooms.add(await controller.gatewayRoomPreview(session.id));
      }
      snapshots.assignAll(
        LiveClassControlRoomService.sortByRisk(
          rooms.map(LiveClassControlRoomService.snapshotForRoom).toList(),
        ),
      );
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: _ControlRoomHero(
                onBack: () => Get.back<void>(),
                onRefresh: () => _refreshControlRoom(),
              ),
            ),
            Expanded(
              child: Obx(() {
                final filtered = _filteredSnapshots();
                final summary = LiveClassControlRoomService.summaryFor(snapshots);
                if (isLoading.value && snapshots.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                return RefreshIndicator(
                  onRefresh: _refreshControlRoom,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    children: [
                      _SummaryGrid(summary: summary),
                      const SizedBox(height: 12),
                      _FilterBar(
                        selected: selectedFilter.value,
                        onChanged: (value) => selectedFilter.value = value,
                      ),
                      const SizedBox(height: 12),
                      if (filtered.isEmpty)
                        const _EmptyControlRoomState()
                      else
                        ...filtered.map(
                          (snapshot) => _ControlRoomClassCard(
                            snapshot: snapshot,
                            onOpen: () => _openAsChiefInvigilator(snapshot),
                            onDetails: () => _showDetails(snapshot),
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

  List<LiveClassControlRoomSnapshot> _filteredSnapshots() {
    final now = DateTime.now();
    final items = snapshots.toList();
    return switch (selectedFilter.value) {
      'Live' => items.where((item) => item.session.isLiveAt(now)).toList(),
      'Risk' => items.where((item) => item.hasRisk).toList(),
      'Incidents' => items.where((item) => item.openIncidents > 0).toList(),
      'Attendance' => items.where((item) => item.attendanceRisk > 0).toList(),
      _ => items,
    };
  }

  void _openAsChiefInvigilator(LiveClassControlRoomSnapshot snapshot) {
    Get.toNamed(
      Routes.liveSessionRoom,
      arguments: {
        'sessionId': snapshot.session.id,
        'role': LiveSessionRole.lecturer,
        'displayName': 'Chief Invigilator',
      },
    );
  }

  void _showDetails(LiveClassControlRoomSnapshot snapshot) {
    Get.bottomSheet<void>(
      _ControlRoomDetailsSheet(snapshot: snapshot),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }
}

class _ControlRoomHero extends StatelessWidget {
  const _ControlRoomHero({required this.onBack, required this.onRefresh});

  final VoidCallback onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [Colors.indigo.shade800, cs.primary]),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 14),
            color: cs.primary.withValues(alpha: 0.16),
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
                  'Chief Invigilator Control Room',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 21,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Monitor all live classes, attendance risk, incidents, screen-share requests, and automatic alerts from one place.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.90),
              fontWeight: FontWeight.w700,
              height: 1.30,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final LiveClassControlRoomSummary summary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _SummaryTile(label: 'Classes', value: '${summary.totalClasses}', icon: Icons.live_tv_rounded),
        _SummaryTile(label: 'Live now', value: '${summary.liveClasses}', icon: Icons.radio_button_checked_rounded),
        _SummaryTile(label: 'Students', value: '${summary.activeStudents}', icon: Icons.groups_rounded),
        _SummaryTile(label: 'Incidents', value: '${summary.openIncidents}', icon: Icons.gpp_maybe_rounded),
        _SummaryTile(label: 'Auto alerts', value: '${summary.autoAlerts}', icon: Icons.auto_awesome_rounded),
        _SummaryTile(label: 'Attendance risk', value: '${summary.attendanceRiskStudents}', icon: Icons.warning_amber_rounded),
        _SummaryTile(label: 'Share requests', value: '${summary.pendingScreenShareRequests}', icon: Icons.screen_share_rounded),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

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
          Icon(icon, color: cs.primary),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const filters = ['All', 'Live', 'Risk', 'Incidents', 'Attendance'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter),
                selected: selected == filter,
                onSelected: (_) => onChanged(filter),
              ),
            ),
        ],
      ),
    );
  }
}

class _ControlRoomClassCard extends StatelessWidget {
  const _ControlRoomClassCard({
    required this.snapshot,
    required this.onOpen,
    required this.onDetails,
  });

  final LiveClassControlRoomSnapshot snapshot;
  final VoidCallback onOpen;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final session = snapshot.session;
    final tone = _riskColor(snapshot.riskScore, cs);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tone.withValues(alpha: 0.30)),
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
                child: Icon(Icons.admin_panel_settings_rounded, color: tone),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${session.courseCode} • ${session.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              _MiniPill(text: snapshot.riskLabel, tone: tone),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(text: snapshot.statusLabelAt(now), tone: cs.primary),
              _MiniPill(text: '${snapshot.activeStudents} active students', tone: cs.secondary),
              _MiniPill(text: '${snapshot.openIncidents} open incidents', tone: Colors.deepOrange),
              _MiniPill(text: '${snapshot.autoAlerts.length} alerts', tone: Colors.indigo),
              _MiniPill(text: '${snapshot.attendanceRisk} attendance risk', tone: Colors.orange),
              _MiniPill(text: '${snapshot.pendingScreenShareRequests} share pending', tone: Colors.teal),
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.person_outline_rounded, text: 'Lecturer: ${session.lecturerName}'),
          _InfoRow(icon: Icons.schedule_rounded, text: liveSessionDayTimeRange(session.startTime, session.endTime)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open class'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDetails,
                  icon: const Icon(Icons.analytics_rounded),
                  label: const Text('Details'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _riskColor(int risk, ColorScheme cs) {
    if (risk >= 12) return Colors.redAccent;
    if (risk >= 7) return Colors.deepOrangeAccent;
    if (risk >= 3) return Colors.orangeAccent;
    return cs.primary;
  }
}

class _ControlRoomDetailsSheet extends StatelessWidget {
  const _ControlRoomDetailsSheet({required this.snapshot});

  final LiveClassControlRoomSnapshot snapshot;

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
            Text(
              '${snapshot.session.courseCode} Control Details',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              snapshot.session.title,
              style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            _DetailLine(label: 'Risk level', value: '${snapshot.riskLabel} (${snapshot.riskScore})'),
            _DetailLine(label: 'Active students', value: '${snapshot.activeStudents}'),
            _DetailLine(label: 'Active lecturers', value: '${snapshot.activeLecturers}'),
            _DetailLine(label: 'Qualified attendance', value: '${snapshot.attendanceSummary.qualifiedStudents}/${snapshot.attendanceSummary.totalStudents}'),
            _DetailLine(label: 'Below attendance minimum', value: '${snapshot.attendanceRisk}'),
            _DetailLine(label: 'Open incidents', value: '${snapshot.openIncidents}'),
            _DetailLine(label: 'Critical incidents', value: '${snapshot.incidentSummary.critical}'),
            _DetailLine(label: 'Automatic alerts', value: '${snapshot.autoAlerts.length}'),
            _DetailLine(label: 'Pending screen-share requests', value: '${snapshot.pendingScreenShareRequests}'),
            _DetailLine(label: 'Active screen-share sessions', value: '${snapshot.activeScreenShareRequests}'),
          ],
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: cs.onSurfaceVariant))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 17, color: cs.primary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
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
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: tone, fontWeight: FontWeight.w900, fontSize: 12),
      ),
    );
  }
}

class _EmptyControlRoomState extends StatelessWidget {
  const _EmptyControlRoomState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(Icons.admin_panel_settings_rounded, size: 44),
          SizedBox(height: 10),
          Text('No class matches this control room filter.'),
        ],
      ),
    );
  }
}
