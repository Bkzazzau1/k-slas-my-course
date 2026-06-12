import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/widgets/luxury_scaffold.dart';
import '../../../data/models/chat_models.dart';
import '../controller/chat_controller.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final _ = Theme.of(context).colorScheme;

    return Scaffold(
      body: LuxuryScaffold(
        safeArea: true,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: _HeroHeader(
                title: "Course AI",
                subtitle: controller.course.code,
                rule:
                    "Answers are ONLY from lecturer materials.\nIf not found: \"Not in your materials.\"",
                onBack: () => Get.back(),
                onOpenAnySources: () {
                  ChatMessageModel? lastAi;
                  for (final m in controller.messages.reversed) {
                    if (m.isAi) {
                      lastAi = m;
                      break;
                    }
                  }
                  if (lastAi != null && lastAi.citations.isNotEmpty) {
                    controller.openSources(lastAi);
                  } else {
                    Get.snackbar(
                      "No sources",
                      "No citations available yet.",
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
              ),
            ),

            Expanded(
              child: Obx(
                () => ListView.builder(
                  controller: controller.scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                  itemCount: controller.messages.length,
                  itemBuilder: (_, i) => _BubblePremium(
                    msg: controller.messages[i],
                    onOpenSources: controller.openSources,
                    onReport: controller.reportAnswer,
                  ),
                ),
              ),
            ),

            const _ComposerPremium(),
          ],
        ),
      ),
    );
  }
}

class _ComposerPremium extends GetView<ChatController> {
  const _ComposerPremium();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.06)),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 22,
                    offset: const Offset(0, 14),
                    color: cs.onSurface.withValues(alpha: 0.05),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller.inputCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => controller.send(),
                      minLines: 1,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: "Ask from your materials...",
                        filled: true,
                        fillColor: cs.onSurface.withValues(alpha: 0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: cs.onSurface.withValues(alpha: 0.08),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: cs.onSurface.withValues(alpha: 0.08),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Obx(
                    () => FilledButton(
                      onPressed: controller.isSending.value
                          ? null
                          : controller.send,
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: controller.isSending.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BubblePremium extends StatelessWidget {
  const _BubblePremium({
    required this.msg,
    required this.onOpenSources,
    required this.onReport,
  });

  final ChatMessageModel msg;
  final void Function(ChatMessageModel) onOpenSources;
  final void Function(ChatMessageModel) onReport;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final isAi = msg.isAi;
    final align = isAi ? Alignment.centerLeft : Alignment.centerRight;

    final bubbleColor = isAi ? cs.surface : cs.primary.withValues(alpha: 0.10);

    final labelColor = isAi ? cs.primary : cs.onSurface;

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: cs.onSurface.withValues(alpha: 0.06),
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
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: labelColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isAi ? "AI" : "You",
                            style: TextStyle(
                              color: labelColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (isAi)
                          InkWell(
                            onTap: () => onReport(msg),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: cs.onSurface.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: cs.onSurface.withValues(alpha: 0.06),
                                ),
                              ),
                              child: Icon(
                                Icons.report_problem_outlined,
                                size: 18,
                                color: cs.secondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Text(
                      msg.text,
                      style: TextStyle(
                        color: cs.onSurface,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    if (isAi) ...[
                      const SizedBox(height: 10),
                      if (msg.citations.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _pill(
                              context,
                              icon: Icons.menu_book_outlined,
                              label: "Open source (${msg.citations.length})",
                              color: cs.primary,
                              onTap: () => onOpenSources(msg),
                            ),
                            _pill(
                              context,
                              icon: Icons.verified_outlined,
                              label: "Cited",
                              color: cs.secondary,
                              onTap: () => onOpenSources(msg),
                            ),
                          ],
                        )
                      else
                        Text(
                          "No citation found in your materials.",
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
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
    required this.rule,
    required this.onBack,
    required this.onOpenAnySources,
  });

  final String title;
  final String subtitle;
  final String rule;
  final VoidCallback onBack;
  final VoidCallback onOpenAnySources;

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
        crossAxisAlignment: CrossAxisAlignment.start,
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
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$title - $subtitle",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  rule,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onOpenAnySources,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
              ),
              child: const Icon(Icons.menu_book_outlined, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
