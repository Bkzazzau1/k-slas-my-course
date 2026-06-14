import 'package:flutter/material.dart';

import '../../../core/widgets/luxury_scaffold.dart';

class TranscriptServicesView extends StatefulWidget {
  const TranscriptServicesView({super.key});

  @override
  State<TranscriptServicesView> createState() => _TranscriptServicesViewState();
}

class _TranscriptServicesViewState extends State<TranscriptServicesView> {
  String _deliveryMethod = 'Electronic official copy';
  String _purpose = 'Admission';

  static const _requests = [
    _TranscriptRequest(
      requestNo: 'TRX-2026-0018',
      type: 'Official Transcript',
      destination: 'WorldQuant University Admissions',
      status: 'Awaiting Records Review',
      date: '14 Jun 2026',
    ),
    _TranscriptRequest(
      requestNo: 'TRX-2026-0011',
      type: 'Unofficial Transcript',
      destination: 'Student download',
      status: 'Ready',
      date: '03 Jun 2026',
    ),
  ];

  static const _courses = [
    _TranscriptCourse('SEN 201', 'Object-Oriented Programming', 3, 'A', 5.0),
    _TranscriptCourse('CSC 305', 'Data Structures', 3, 'B+', 4.0),
    _TranscriptCourse('CSC 309', 'Artificial Intelligence', 3, 'Pending', 0.0),
    _TranscriptCourse('SEN 399', 'SIWES II', 6, 'B', 4.0),
    _TranscriptCourse('GST 303', 'Communication in English', 2, 'A', 5.0),
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
                child: _OfficialTranscriptCard(
                  deliveryMethod: _deliveryMethod,
                  purpose: _purpose,
                  onDeliveryChanged: (value) => setState(() => _deliveryMethod = value ?? _deliveryMethod),
                  onPurposeChanged: (value) => setState(() => _purpose = value ?? _purpose),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              sliver: SliverToBoxAdapter(child: _UnofficialTranscriptPreview(courses: _courses)),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Text('Recent transcript requests', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: _requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _RequestTile(request: _requests[index]),
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
            child: Text('Transcript Services', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
          ),
        ]),
        const SizedBox(height: 10),
        Text(
          'Request official transcripts for institutions and preview/print your unofficial transcript for personal use.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w700, height: 1.25),
        ),
      ]),
    );
  }
}

class _OfficialTranscriptCard extends StatelessWidget {
  const _OfficialTranscriptCard({required this.deliveryMethod, required this.purpose, required this.onDeliveryChanged, required this.onPurposeChanged});

  final String deliveryMethod;
  final String purpose;
  final ValueChanged<String?> onDeliveryChanged;
  final ValueChanged<String?> onPurposeChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: cs.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(backgroundColor: cs.primary.withValues(alpha: 0.10), foregroundColor: cs.primary, child: const Icon(Icons.outgoing_mail)),
          const SizedBox(width: 12),
          Expanded(child: Text('Official transcript request', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16))),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          SizedBox(
            width: 250,
            child: DropdownButtonFormField<String>(
              value: deliveryMethod,
              items: const [
                DropdownMenuItem(value: 'Electronic official copy', child: Text('Electronic official copy')),
                DropdownMenuItem(value: 'Sealed physical copy', child: Text('Sealed physical copy')),
                DropdownMenuItem(value: 'Both electronic and sealed', child: Text('Both electronic and sealed')),
              ],
              onChanged: onDeliveryChanged,
              decoration: const InputDecoration(labelText: 'Delivery method'),
            ),
          ),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String>(
              value: purpose,
              items: const [
                DropdownMenuItem(value: 'Admission', child: Text('Admission')),
                DropdownMenuItem(value: 'Scholarship', child: Text('Scholarship')),
                DropdownMenuItem(value: 'Employment', child: Text('Employment')),
                DropdownMenuItem(value: 'Personal records', child: Text('Personal records')),
              ],
              onChanged: onPurposeChanged,
              decoration: const InputDecoration(labelText: 'Purpose'),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        const TextField(decoration: InputDecoration(labelText: 'Recipient institution / organization')),
        const SizedBox(height: 10),
        const TextField(decoration: InputDecoration(labelText: 'Recipient email or delivery address')),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.send_outlined), label: const Text('Submit request')),
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.history_outlined), label: const Text('Request history')),
        ]),
      ]),
    );
  }
}

class _UnofficialTranscriptPreview extends StatelessWidget {
  const _UnofficialTranscriptPreview({required this.courses});
  final List<_TranscriptCourse> courses;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: cs.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(backgroundColor: cs.secondary.withValues(alpha: 0.10), foregroundColor: cs.secondary, child: const Icon(Icons.print_outlined)),
          const SizedBox(width: 12),
          Expanded(child: Text('Unofficial transcript preview', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 16))),
          Chip(label: Text('Student copy', style: TextStyle(color: cs.secondary, fontWeight: FontWeight.w900))),
        ]),
        const SizedBox(height: 10),
        Text('This is not an official transcript. It is for student preview and personal printing only.', style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        const _TranscriptStudentSummary(),
        const SizedBox(height: 12),
        Table(
          columnWidths: const {0: FlexColumnWidth(1.2), 1: FlexColumnWidth(2.4), 2: FlexColumnWidth(0.7), 3: FlexColumnWidth(0.8)},
          border: TableBorder.all(color: cs.outlineVariant),
          children: [
            _tableRow(['Code', 'Course', 'CU', 'Grade'], header: true),
            for (final course in courses) _tableRow([course.code, course.title, '${course.credits}', course.grade]),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.print_outlined), label: const Text('Print unofficial')),
          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download_outlined), label: const Text('Download PDF')),
        ]),
      ]),
    );
  }

  TableRow _tableRow(List<String> cells, {bool header = false}) {
    return TableRow(
      children: cells
          .map(
            (cell) => Padding(
              padding: const EdgeInsets.all(8),
              child: Text(cell, style: TextStyle(fontWeight: header ? FontWeight.w900 : FontWeight.w700, fontSize: 12)),
            ),
          )
          .toList(),
    );
  }
}

class _TranscriptStudentSummary extends StatelessWidget {
  const _TranscriptStudentSummary();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(spacing: 8, runSpacing: 8, children: [
      _InfoPill(label: 'Name: Ibrahim Bashir Yahaya'),
      _InfoPill(label: 'Matric: 2023/C/SENG/0400'),
      _InfoPill(label: 'Programme: B.Sc Software Engineering'),
      _InfoPill(label: 'CGPA: 4.42'),
      DecoratedBox(
        decoration: BoxDecoration(color: cs.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(999), border: Border.all(color: cs.error.withValues(alpha: 0.12))),
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), child: Text('Unofficial copy', style: TextStyle(color: cs.error, fontWeight: FontWeight.w900))),
      ),
    ]);
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request});
  final _TranscriptRequest request;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: cs.outlineVariant)),
      tileColor: cs.surface,
      leading: CircleAvatar(backgroundColor: cs.primary.withValues(alpha: 0.10), foregroundColor: cs.primary, child: const Icon(Icons.receipt_long_outlined)),
      title: Text('${request.requestNo} • ${request.type}', style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: Text('${request.destination} • ${request.date}'),
      trailing: Chip(label: Text(request.status)),
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

class _TranscriptRequest {
  const _TranscriptRequest({required this.requestNo, required this.type, required this.destination, required this.status, required this.date});
  final String requestNo;
  final String type;
  final String destination;
  final String status;
  final String date;
}

class _TranscriptCourse {
  const _TranscriptCourse(this.code, this.title, this.credits, this.grade, this.points);
  final String code;
  final String title;
  final int credits;
  final String grade;
  final double points;
}
