import 'package:flutter/material.dart';

import '../../../core/widgets/luxury_scaffold.dart';

class InternshipManagementView extends StatelessWidget {
  const InternshipManagementView({super.key});

  static const _placements = [
    _InternshipMilestone(
      title: 'Placement profile',
      status: 'Submitted',
      detail: 'Student bio-data, programme, level, preferred industry and contact details completed.',
      icon: Icons.person_outline,
    ),
    _InternshipMilestone(
      title: 'Institution approval',
      status: 'Under review',
      detail: 'Awaiting SIWES/department confirmation before placement letter is issued.',
      icon: Icons.verified_user_outlined,
    ),
    _InternshipMilestone(
      title: 'Employer confirmation',
      status: 'Pending',
      detail: 'Upload acceptance letter after organization confirms the placement.',
      icon: Icons.business_center_outlined,
    ),
    _InternshipMilestone(
      title: 'Logbook & reports',
      status: 'Not started',
      detail: 'Weekly activity logs, supervisor remarks and final report will appear here.',
      icon: Icons.fact_check_outlined,
    ),
  ];

  static const _documents = [
    _InternshipDocument('Placement letter request', 'Ready to request', Icons.description_outlined),
    _InternshipDocument('Employer acceptance letter', 'Upload required', Icons.upload_file_outlined),
    _InternshipDocument('Weekly logbook', 'Opens after start date', Icons.menu_book_outlined),
    _InternshipDocument('Supervisor evaluation', 'Pending employer access', Icons.assignment_ind_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              sliver: SliverToBoxAdapter(child: _Header(cs: cs)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(child: _PlacementCard(cs: cs)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Text('Internship progress', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverList.separated(
                itemCount: _placements.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _MilestoneTile(item: _placements[index]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Text('Documents & actions', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: _documents.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _DocumentTile(item: _documents[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
        boxShadow: [BoxShadow(blurRadius: 24, offset: const Offset(0, 14), color: cs.primary.withValues(alpha: 0.16))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton.filledTonal(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Internship / SIWES Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
          ),
        ]),
        const SizedBox(height: 10),
        Text(
          'Submit placement details, request institution letters, upload employer acceptance, track approvals and manage logbook requirements from your student app.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w700, height: 1.25),
        ),
      ]),
    );
  }
}

class _PlacementCard extends StatelessWidget {
  const _PlacementCard({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(backgroundColor: cs.primary.withValues(alpha: 0.10), foregroundColor: cs.primary, child: const Icon(Icons.work_outline)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Current internship status', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900)),
              Text('SIWES / Industrial Training profile is under department review.', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
            ]),
          ),
          Chip(label: const Text('Under review'), avatar: Icon(Icons.pending_actions_outlined, size: 18, color: cs.secondary)),
        ]),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: const [
          _InfoPill(label: 'Programme: Software Engineering'),
          _InfoPill(label: 'Level: 300'),
          _InfoPill(label: 'Duration: 6 months'),
          _InfoPill(label: 'Start: Pending approval'),
        ]),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.edit_outlined), label: const Text('Update profile')),
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.description_outlined), label: const Text('Request letter')),
        ]),
      ]),
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({required this.item});
  final _InternshipMilestone item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: cs.outlineVariant)),
      child: Row(children: [
        CircleAvatar(backgroundColor: cs.primary.withValues(alpha: 0.10), foregroundColor: cs.primary, child: Icon(item.icon)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.title, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            Text(item.detail, style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
          ]),
        ),
        Chip(label: Text(item.status)),
      ]),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.item});
  final _InternshipDocument item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: cs.outlineVariant)),
      tileColor: cs.surface,
      leading: CircleAvatar(backgroundColor: cs.secondary.withValues(alpha: 0.10), foregroundColor: cs.secondary, child: Icon(item.icon)),
      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text(item.status),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {},
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(999), border: Border.all(color: cs.primary.withValues(alpha: 0.12))),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), child: Text(label, style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800))),
    );
  }
}

class _InternshipMilestone {
  const _InternshipMilestone({required this.title, required this.status, required this.detail, required this.icon});
  final String title;
  final String status;
  final String detail;
  final IconData icon;
}

class _InternshipDocument {
  const _InternshipDocument(this.title, this.status, this.icon);
  final String title;
  final String status;
  final IconData icon;
}
