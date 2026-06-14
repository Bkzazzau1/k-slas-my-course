import 'package:flutter/material.dart';

import '../../../core/widgets/luxury_scaffold.dart';

class StudentSupportView extends StatefulWidget {
  const StudentSupportView({super.key});

  @override
  State<StudentSupportView> createState() => _StudentSupportViewState();
}

class _StudentSupportViewState extends State<StudentSupportView> {
  String _category = 'Missing Result';
  String _priority = 'Normal';

  static const _tickets = [
    _SupportTicket(
      ticketNo: 'KSLAS-SUP-1042',
      category: 'Missing Result',
      title: 'CSC 309 exam grade is missing',
      status: 'Assigned to Records',
      lastUpdate: 'Today, 12:08',
      summary: 'Records is reviewing the result batch and course attempt history.',
      priority: 'High',
    ),
    _SupportTicket(
      ticketNo: 'KSLAS-SUP-1037',
      category: 'Course Registration',
      title: 'Elective course not showing',
      status: 'Open',
      lastUpdate: 'Yesterday, 09:40',
      summary: 'Department admin will review programme curriculum and cohort rules.',
      priority: 'Normal',
    ),
    _SupportTicket(
      ticketNo: 'KSLAS-SUP-1029',
      category: 'Assignment',
      title: 'Uploaded assignment not reflected',
      status: 'Resolved',
      lastUpdate: '03 Jun 2026',
      summary: 'Submission receipt was verified and the lecturer has received the file.',
      priority: 'Low',
    ),
  ];

  static const _updates = [
    _SupportUpdate(
      title: 'Records requested result audit',
      ticketNo: 'KSLAS-SUP-1042',
      detail: 'Your missing result complaint has been linked to CSC 309 result review.',
      time: 'Today, 12:08',
    ),
    _SupportUpdate(
      title: 'Support desk acknowledged complaint',
      ticketNo: 'KSLAS-SUP-1042',
      detail: 'A staff member has been assigned to follow up with Records Department.',
      time: 'Today, 11:41',
    ),
    _SupportUpdate(
      title: 'Assignment issue resolved',
      ticketNo: 'KSLAS-SUP-1029',
      detail: 'Your submission receipt is now visible in your assignment history.',
      time: '03 Jun 2026',
    ),
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
              sliver: SliverToBoxAdapter(
                child: _NewTicketCard(
                  category: _category,
                  priority: _priority,
                  onCategoryChanged: (value) => setState(() => _category = value ?? _category),
                  onPriorityChanged: (value) => setState(() => _priority = value ?? _priority),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Text('My support tickets', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverList.separated(
                itemCount: _tickets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _TicketTile(ticket: _tickets[index]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Text('Recent updates', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: _updates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _UpdateTile(update: _updates[index]),
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
            child: Text('Student Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
          ),
        ]),
        const SizedBox(height: 10),
        Text(
          'Submit complaints, missing-result issues, course registration problems, exam follow-up, assignment concerns and general support requests.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w700, height: 1.25),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: const [
          _HeaderPill(label: 'Missing Result'),
          _HeaderPill(label: 'Registration'),
          _HeaderPill(label: 'Exam Issue'),
          _HeaderPill(label: 'Assignment'),
        ]),
      ]),
    );
  }
}

class _NewTicketCard extends StatelessWidget {
  const _NewTicketCard({
    required this.category,
    required this.priority,
    required this.onCategoryChanged,
    required this.onPriorityChanged,
  });

  final String category;
  final String priority;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String?> onPriorityChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: cs.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(backgroundColor: cs.primary.withValues(alpha: 0.10), foregroundColor: cs.primary, child: const Icon(Icons.add_comment_outlined)),
          const SizedBox(width: 12),
          Expanded(child: Text('Create new support ticket', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16))),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          SizedBox(
            width: 250,
            child: DropdownButtonFormField<String>(
              value: category,
              items: const [
                DropdownMenuItem(value: 'Missing Result', child: Text('Missing Result')),
                DropdownMenuItem(value: 'Course Registration', child: Text('Course Registration')),
                DropdownMenuItem(value: 'Exam Issue', child: Text('Exam Issue')),
                DropdownMenuItem(value: 'Assignment', child: Text('Assignment')),
                DropdownMenuItem(value: 'General Complaint', child: Text('General Complaint')),
              ],
              onChanged: onCategoryChanged,
              decoration: const InputDecoration(labelText: 'Issue type'),
            ),
          ),
          SizedBox(
            width: 190,
            child: DropdownButtonFormField<String>(
              value: priority,
              items: const [
                DropdownMenuItem(value: 'Low', child: Text('Low')),
                DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                DropdownMenuItem(value: 'High', child: Text('High')),
              ],
              onChanged: onPriorityChanged,
              decoration: const InputDecoration(labelText: 'Priority'),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        const TextField(decoration: InputDecoration(labelText: 'Subject')),
        const SizedBox(height: 10),
        const TextField(
          minLines: 4,
          maxLines: 6,
          decoration: InputDecoration(labelText: 'Describe the issue clearly'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.attach_file_outlined), label: const Text('Attach evidence / screenshot')),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.send_outlined), label: const Text('Submit ticket')),
      ]),
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket});
  final _SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final priorityColor = ticket.priority == 'High' ? cs.error : ticket.priority == 'Normal' ? cs.secondary : cs.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: cs.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(backgroundColor: priorityColor.withValues(alpha: 0.10), foregroundColor: priorityColor, child: const Icon(Icons.support_agent_outlined)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${ticket.ticketNo} • ${ticket.category}', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(ticket.title, style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
            ]),
          ),
          Chip(label: Text(ticket.priority)),
        ]),
        const SizedBox(height: 10),
        Text(ticket.summary, style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _InfoPill(label: ticket.status),
          _InfoPill(label: ticket.lastUpdate),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline), label: const Text('Reply')),
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.history_outlined), label: const Text('History')),
        ]),
      ]),
    );
  }
}

class _UpdateTile extends StatelessWidget {
  const _UpdateTile({required this.update});
  final _SupportUpdate update;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: cs.outlineVariant)),
      tileColor: cs.surface,
      leading: CircleAvatar(backgroundColor: cs.secondary.withValues(alpha: 0.10), foregroundColor: cs.secondary, child: const Icon(Icons.notifications_active_outlined)),
      title: Text('${update.title} • ${update.ticketNo}', style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text('${update.detail} • ${update.time}'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {},
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.17), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withValues(alpha: 0.22))),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
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

class _SupportTicket {
  const _SupportTicket({required this.ticketNo, required this.category, required this.title, required this.status, required this.lastUpdate, required this.summary, required this.priority});
  final String ticketNo;
  final String category;
  final String title;
  final String status;
  final String lastUpdate;
  final String summary;
  final String priority;
}

class _SupportUpdate {
  const _SupportUpdate({required this.title, required this.ticketNo, required this.detail, required this.time});
  final String title;
  final String ticketNo;
  final String detail;
  final String time;
}
