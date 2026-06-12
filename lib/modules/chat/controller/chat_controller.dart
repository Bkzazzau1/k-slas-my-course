import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/chat_models.dart';
import '../../../data/models/course_model.dart';

class ChatController extends GetxController {
  final messages = <ChatMessageModel>[].obs;
  final isSending = false.obs;

  final inputCtrl = TextEditingController();
  final scrollCtrl = ScrollController();

  late CourseModel course;

  @override
  void onInit() {
    super.onInit();
    final args = (Get.arguments ?? {}) as Map;
    course = args['course'] as CourseModel;

    // seed first AI guidance message
    messages.add(
      ChatMessageModel(
        id: _id(),
        role: "ai",
        text:
            "Ask anything from ${course.code}. I will answer using ONLY your uploaded lecturer materials. "
            "Every answer includes citations. If it’s not in your materials, I will say: “Not in your materials.”",
        citations: const [],
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  void onClose() {
    inputCtrl.dispose();
    scrollCtrl.dispose();
    super.onClose();
  }

  void send() async {
    final text = inputCtrl.text.trim();
    if (text.isEmpty || isSending.value) return;

    isSending.value = true;

    // push user message
    messages.add(
      ChatMessageModel(
        id: _id(),
        role: "user",
        text: text,
        createdAt: DateTime.now(),
      ),
    );
    inputCtrl.clear();
    _scrollToBottom();

    // ✅ MVP placeholder logic:
    // Later: call API (RAG over lecturer materials)
    await Future.delayed(const Duration(milliseconds: 700));

    final ai = _mockAnswer(text);

    messages.add(ai);
    isSending.value = false;

    _scrollToBottom();
  }

  ChatMessageModel _mockAnswer(String question) {
    // Simple placeholder:
    // If question contains some known keywords => return cited answer; else "not in materials"
    final q = question.toLowerCase();

    final known =
        q.contains("avl") || q.contains("tree") || q.contains("graph");
    if (!known) {
      return ChatMessageModel(
        id: _id(),
        role: "ai",
        text: "Not in your materials.",
        citations: const [],
        createdAt: DateTime.now(),
      );
    }

    return ChatMessageModel(
      id: _id(),
      role: "ai",
      text:
          "AVL rotations keep the tree height-balanced by re-structuring nodes after insertion/deletion. "
          "Use single rotation (LL/RR) or double rotation (LR/RL) depending on the imbalance direction.",
      citations: [
        CitationModel(
          title: "Lecture 5: Trees",
          pageLabel: "p.12",
          snippet:
              "Rotations restore balance by adjusting subtree heights after updates.",
        ),
        CitationModel(
          title: "Course Pack",
          pageLabel: "p.18",
          snippet:
              "LL, RR, LR, RL cases determine whether to use single or double rotation.",
        ),
      ],
      createdAt: DateTime.now(),
    );
  }

  void openSources(ChatMessageModel msg) {
    if (msg.citations.isEmpty) return;

    Get.bottomSheet(
      _SourcesSheet(citations: msg.citations),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void reportAnswer(ChatMessageModel msg) {
    // MVP: just show snackbar (later save to backend)
    Get.snackbar(
      "Reported",
      "Thanks. We’ll review this answer.",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollCtrl.hasClients) return;
      scrollCtrl.animateTo(
        scrollCtrl.position.maxScrollExtent + 240,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _id() {
    final r = Random().nextInt(999999);
    return "${DateTime.now().millisecondsSinceEpoch}_$r";
  }
}

class _SourcesSheet extends StatelessWidget {
  const _SourcesSheet({required this.citations});
  final List<CitationModel> citations;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.menu_book_outlined),
                const SizedBox(width: 10),
                Text(
                  "Sources",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: citations.length,
                itemBuilder: (_, i) {
                  final c = citations[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${c.title} • ${c.pageLabel}",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c.snippet,
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
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
