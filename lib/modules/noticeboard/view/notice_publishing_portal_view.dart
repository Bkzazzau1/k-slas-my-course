import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/notice_model.dart';
import '../../../data/services/notice_storage.dart';

class NoticePublishingPortalView extends StatefulWidget {
  const NoticePublishingPortalView({
    super.key,
    required this.roleName,
    required this.portalTitle,
    required this.defaultSource,
    required this.authorRole,
    this.allowSchoolScope = false,
    this.allowExamScope = false,
  });

  final String roleName;
  final String portalTitle;
  final String defaultSource;
  final String authorRole;
  final bool allowSchoolScope;
  final bool allowExamScope;

  @override
  State<NoticePublishingPortalView> createState() => _NoticePublishingPortalViewState();
}

class _NoticePublishingPortalViewState extends State<NoticePublishingPortalView> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _courseController = TextEditingController(text: 'CSC 305');
  final _referenceController = TextEditingController();

  String _scope = NoticeScope.course;
  String _audience = NoticeAudience.students;
  bool _important = false;
  bool _pinned = false;
  bool _requiresAcknowledgement = false;
  bool _expiresInSevenDays = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _courseController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  List<String> get _allowedScopes {
    return [
      if (widget.allowSchoolScope) NoticeScope.school,
      NoticeScope.course,
      if (widget.allowExamScope) NoticeScope.exam,
    ];
  }

  Future<void> _publish() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final course = _courseController.text.trim().toUpperCase();
    if (title.length < 5 || body.length < 15) {
      _snack('Incomplete notice', 'Add a clear title and enough notice details.');
      return;
    }
    if (_scope == NoticeScope.course && course.isEmpty) {
      _snack('Course required', 'Enter a course code for course notices.');
      return;
    }

    final notice = NoticeModel(
      id: 'notice-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      body: body,
      scope: _scope,
      courseCode: _scope == NoticeScope.course ? course : null,
      source: widget.defaultSource,
      createdAt: DateTime.now(),
      priority: _important ? 1 : 0,
      audience: _audience,
      status: NoticeStatus.published,
      authorId: widget.authorRole.toLowerCase().replaceAll(' ', '-'),
      authorName: widget.defaultSource,
      authorRole: widget.authorRole,
      expiresAt: _expiresInSevenDays ? DateTime.now().add(const Duration(days: 7)) : null,
      pinned: _pinned,
      requiresAcknowledgement: _requiresAcknowledgement,
      reference: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
    );

    await NoticeStorage.savePublishedNotice(notice);
    _titleController.clear();
    _bodyController.clear();
    _referenceController.clear();
    if (!mounted) return;
    setState(() {
      _important = false;
      _pinned = false;
      _requiresAcknowledgement = false;
      _expiresInSevenDays = false;
    });
    _snack('Notice published', 'The notice is now available to the selected audience.');
  }

  void _snack(String title, String message) {
    Get.snackbar(title, message, snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final notices = NoticeStorage.loadPublishedNotices()
        .where((notice) => notice.authorRole == widget.authorRole)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
          children: [
            _NoticePublisherHero(
              roleName: widget.roleName,
              title: widget.portalTitle,
              onBack: () => Get.back<void>(),
            ),
            const SizedBox(height: 14),
            _PublisherFormCard(
              titleController: _titleController,
              bodyController: _bodyController,
              courseController: _courseController,
              referenceController: _referenceController,
              allowedScopes: _allowedScopes,
              scope: _scope,
              audience: _audience,
              important: _important,
              pinned: _pinned,
              requiresAcknowledgement: _requiresAcknowledgement,
              expiresInSevenDays: _expiresInSevenDays,
              onScopeChanged: (value) => setState(() => _scope = value),
              onAudienceChanged: (value) => setState(() => _audience = value),
              onImportantChanged: (value) => setState(() => _important = value),
              onPinnedChanged: (value) => setState(() => _pinned = value),
              onAckChanged: (value) => setState(() => _requiresAcknowledgement = value),
              onExpiryChanged: (value) => setState(() => _expiresInSevenDays = value),
              onPublish: _publish,
            ),
            const SizedBox(height: 14),
            Text(
              'Recently published',
              style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900, fontSize: 17),
            ),
            const SizedBox(height: 10),
            if (notices.isEmpty)
              _EmptyPublisherState(colorScheme: cs)
            else
              ...notices.map(
                (notice) => _PublishedNoticeTile(
                  notice: notice,
                  onArchive: () async {
                    await NoticeStorage.archivePublishedNotice(notice.id);
                    if (mounted) setState(() {});
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoticePublisherHero extends StatelessWidget {
  const _NoticePublisherHero({
    required this.roleName,
    required this.title,
    required this.onBack,
  });

  final String roleName;
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(colors: [cs.primary, cs.secondary]),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 14),
            color: cs.primary.withValues(alpha: 0.18),
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
                ),
              ),
              const Icon(Icons.campaign_outlined, color: Colors.white),
            ],
          ),
          const SizedBox(height: 10),
          Text(roleName, style: TextStyle(color: Colors.white.withValues(alpha: 0.86), fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            'Publish official notices from this role portal only. Students will only read approved notices from their noticeboard.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.90), fontWeight: FontWeight.w700, height: 1.30),
          ),
        ],
      ),
    );
  }
}

class _PublisherFormCard extends StatelessWidget {
  const _PublisherFormCard({
    required this.titleController,
    required this.bodyController,
    required this.courseController,
    required this.referenceController,
    required this.allowedScopes,
    required this.scope,
    required this.audience,
    required this.important,
    required this.pinned,
    required this.requiresAcknowledgement,
    required this.expiresInSevenDays,
    required this.onScopeChanged,
    required this.onAudienceChanged,
    required this.onImportantChanged,
    required this.onPinnedChanged,
    required this.onAckChanged,
    required this.onExpiryChanged,
    required this.onPublish,
  });

  final TextEditingController titleController;
  final TextEditingController bodyController;
  final TextEditingController courseController;
  final TextEditingController referenceController;
  final List<String> allowedScopes;
  final String scope;
  final String audience;
  final bool important;
  final bool pinned;
  final bool requiresAcknowledgement;
  final bool expiresInSevenDays;
  final ValueChanged<String> onScopeChanged;
  final ValueChanged<String> onAudienceChanged;
  final ValueChanged<bool> onImportantChanged;
  final ValueChanged<bool> onPinnedChanged;
  final ValueChanged<bool> onAckChanged;
  final ValueChanged<bool> onExpiryChanged;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Notice title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: bodyController,
            minLines: 5,
            maxLines: 8,
            decoration: const InputDecoration(labelText: 'Notice details', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: scope,
                  decoration: const InputDecoration(labelText: 'Scope', border: OutlineInputBorder()),
                  items: allowedScopes
                      .map((item) => DropdownMenuItem(value: item, child: Text(_label(item))))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onScopeChanged(value);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: audience,
                  decoration: const InputDecoration(labelText: 'Audience', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: NoticeAudience.students, child: Text('Students')),
                    DropdownMenuItem(value: NoticeAudience.all, child: Text('All')),
                  ],
                  onChanged: (value) {
                    if (value != null) onAudienceChanged(value);
                  },
                ),
              ),
            ],
          ),
          if (scope == NoticeScope.course) ...[
            const SizedBox(height: 10),
            TextField(
              controller: courseController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Course code', border: OutlineInputBorder()),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: referenceController,
            decoration: const InputDecoration(
              labelText: 'Reference / circular number (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: important,
            onChanged: onImportantChanged,
            title: const Text('Mark as important'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: pinned,
            onChanged: onPinnedChanged,
            title: const Text('Pin to top'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: requiresAcknowledgement,
            onChanged: onAckChanged,
            title: const Text('Require student acknowledgement'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: expiresInSevenDays,
            onChanged: onExpiryChanged,
            title: const Text('Expire after 7 days'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPublish,
              icon: const Icon(Icons.publish_rounded),
              label: const Text('Publish notice'),
            ),
          ),
        ],
      ),
    );
  }

  static String _label(String value) {
    switch (value) {
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
}

class _PublishedNoticeTile extends StatelessWidget {
  const _PublishedNoticeTile({required this.notice, required this.onArchive});

  final NoticeModel notice;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(notice.isPublished ? Icons.campaign_rounded : Icons.archive_outlined, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notice.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  '${notice.scope}${notice.courseCode == null ? '' : ' • ${notice.courseCode}'} • ${notice.status}',
                  style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ],
            ),
          ),
          if (notice.isPublished)
            TextButton(onPressed: onArchive, child: const Text('Archive')),
        ],
      ),
    );
  }
}

class _EmptyPublisherState extends StatelessWidget {
  const _EmptyPublisherState({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.campaign_outlined, size: 42),
          SizedBox(height: 8),
          Text('No notice has been published from this portal yet.'),
        ],
      ),
    );
  }
}
