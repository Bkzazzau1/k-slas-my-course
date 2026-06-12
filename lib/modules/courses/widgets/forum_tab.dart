import 'package:flutter/material.dart';

import '../../../data/models/course_forum_model.dart';
import '../../../data/models/course_model.dart';
import '../../../data/services/course_forum_service.dart';

class ForumTab extends StatefulWidget {
  const ForumTab({super.key, required this.course});

  final CourseModel course;

  @override
  State<ForumTab> createState() => _ForumTabState();
}

class _ForumTabState extends State<ForumTab> {
  late Future<List<CourseForumPostModel>> _future;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<List<CourseForumPostModel>> _load() {
    return CourseForumService.gateway.fetchPosts(
      courseId: widget.course.id,
      courseCode: widget.course.code,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _submit({String? parentId}) async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) return;
    await CourseForumService.gateway.createPost(
      courseId: widget.course.id,
      courseCode: widget.course.code,
      title: parentId == null ? _titleController.text.trim() : null,
      body: body,
      parentId: parentId,
    );
    _titleController.clear();
    _bodyController.clear();
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<CourseForumPostModel>>(
        future: _future,
        builder: (context, snapshot) {
          final posts = snapshot.data ?? const <CourseForumPostModel>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
            children: [
              _Composer(
                titleController: _titleController,
                bodyController: _bodyController,
                onSubmit: () => _submit(),
              ),
              const SizedBox(height: 14),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (posts.isEmpty)
                _EmptyForumCard(courseCode: widget.course.code)
              else
                for (final post in posts) ...[
                  _ForumPostCard(
                    post: post,
                    onReply: () => _showReplySheet(context, post),
                  ),
                  const SizedBox(height: 12),
                ],
              if (snapshot.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Forum is using the local demo cache for now.',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.62),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showReplySheet(
    BuildContext context,
    CourseForumPostModel post,
  ) async {
    _bodyController.clear();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final bottom = MediaQuery.viewInsetsOf(context).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reply to discussion',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Share your idea or answer',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: post.isLocked
                      ? null
                      : () async {
                          await _submit(parentId: post.id);
                          if (context.mounted) Navigator.pop(context);
                        },
                  icon: const Icon(Icons.reply_rounded),
                  label: Text(post.isLocked ? 'Locked' : 'Post reply'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.titleController,
    required this.bodyController,
    required this.onSubmit,
  });

  final TextEditingController titleController;
  final TextEditingController bodyController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Column(
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Topic title',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: bodyController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Share a question or idea with your course group',
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.forum_rounded),
              label: const Text('Post'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForumPostCard extends StatelessWidget {
  const _ForumPostCard({required this.post, required this.onReply});

  final CourseForumPostModel post;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurface.withValues(alpha: 0.68);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                post.isLecturer ? Icons.admin_panel_settings : Icons.person,
                color: post.isLecturer ? cs.primary : muted,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${post.authorDisplayName} · ${post.isLecturer ? 'Lecturer admin' : 'Student'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: muted, fontWeight: FontWeight.w800),
                ),
              ),
              if (post.isPinned)
                Icon(Icons.push_pin_rounded, color: cs.primary, size: 18),
              if (post.isLocked)
                Icon(Icons.lock_rounded, color: cs.error, size: 18),
            ],
          ),
          if ((post.title ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              post.title!,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
          const SizedBox(height: 8),
          Text(post.body, style: const TextStyle(height: 1.35)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                _timeLabel(post.createdAt),
                style: TextStyle(color: muted, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: post.isLocked ? null : onReply,
                icon: const Icon(Icons.reply_rounded),
                label: const Text('Reply'),
              ),
            ],
          ),
          for (final reply in post.replies)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _ReplyTile(reply: reply),
            ),
        ],
      ),
    );
  }

  String _timeLabel(DateTime value) {
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} hr ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }
}

class _ReplyTile extends StatelessWidget {
  const _ReplyTile({required this.reply});

  final CourseForumPostModel reply;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${reply.authorDisplayName} · ${reply.isLecturer ? 'Lecturer' : 'Student'}',
            style: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.66),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(reply.body),
        ],
      ),
    );
  }
}

class _EmptyForumCard extends StatelessWidget {
  const _EmptyForumCard({required this.courseCode});

  final String courseCode;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(Icons.forum_outlined, color: cs.primary, size: 34),
          const SizedBox(height: 10),
          Text(
            '$courseCode forum is quiet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Start the first discussion for your course group.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.68)),
          ),
        ],
      ),
    );
  }
}
