import 'package:flutter/material.dart';

import '../../copy/text.dart';
import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import 'controls.dart';

/// A scrolling paper screen with an optional step header and a primary
/// button pinned to the foot.
class PaperPage extends StatelessWidget {
  const PaperPage({
    super.key,
    required this.children,
    this.step,
    this.onBack,
    this.title,
    this.voice,
    this.primaryLabel,
    this.onPrimary,
    this.footer,
    this.padding = const EdgeInsets.fromLTRB(
      HsSpace.side,
      HsSpace.s,
      HsSpace.side,
      HsSpace.xl,
    ),
  });

  final List<Widget> children;
  final String? step;
  final VoidCallback? onBack;
  final String? title;
  final String? voice;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final Widget? footer;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (step != null || onBack != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    if (onBack != null)
                      Semantics(
                        button: true,
                        label: 'Back',
                        excludeSemantics: true,
                        child: InkWell(
                          onTap: onBack,
                          child: Container(
                            constraints: const BoxConstraints(
                              minHeight: HsSpace.target,
                              minWidth: HsSpace.target,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              CommonText.back.toUpperCase(),
                              style: HsText.eyebrow,
                            ),
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (step != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(step!.toUpperCase(), style: HsText.eyebrow),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (title != null)
                      Semantics(
                        header: true,
                        child: Text(title!, style: HsText.h1),
                      ),
                    if (voice != null) ...[
                      const SizedBox(height: 4),
                      Text(voice!, style: HsText.voice),
                    ],
                    if (title != null || voice != null)
                      const SizedBox(height: HsSpace.l),
                    ...children,
                  ],
                ),
              ),
            ),
            if (primaryLabel != null || footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  HsSpace.side,
                  HsSpace.s,
                  HsSpace.side,
                  HsSpace.l,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: HsSpace.m,
                  children: [
                    if (primaryLabel != null)
                      InkButton(label: primaryLabel!, onPressed: onPrimary),
                    ?footer,
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A labelled block separated by a hairline rule, used for form questions.
class QuestionBlock extends StatelessWidget {
  const QuestionBlock({super.key, this.question, required this.child});

  final String? question;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: HsColors.rule)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          if (question != null) Text(question!, style: HsText.body),
          child,
        ],
      ),
    );
  }
}
