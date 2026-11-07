import 'package:flutter/material.dart';

import '../../app/theme/text_styles.dart';
import '../../app/theme/tokens.dart';
import '../../app/widgets/widgets.dart';
import '../../copy/text.dart';
import 'particulars_screen.dart';

/// 1 · Welcome (DESIGN.md §6).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PaperPage(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 16),
      primaryLabel: WelcomeText.proceed,
      onPrimary: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ParticularsScreen()),
      ),
      footer: Text(
        WelcomeText.privacy,
        textAlign: TextAlign.center,
        style: HsText.courier(12),
      ),
      children: [
        const Center(child: TrayIllustration()),
        const SizedBox(height: 22),
        const Center(child: BrandLabel()),
        const SizedBox(height: 30),
        Semantics(
          header: true,
          child: Text(
            WelcomeText.greeting,
            textAlign: TextAlign.center,
            style: HsText.h2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          WelcomeText.intro,
          textAlign: TextAlign.center,
          style: HsText.caslon(16, italic: true, height: 1.6),
        ),
      ],
    );
  }
}

/// The "HYDRATE, Sir" label with its ornament.
class BrandLabel extends StatelessWidget {
  const BrandLabel({super.key, this.width = 280});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Hydrate, Sir. Hargreaves, butler.',
      excludeSemantics: true,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: HsColors.label,
          border: Border.all(color: HsColors.ink, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            border: Border.all(color: HsColors.ink),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Column(
            spacing: 8,
            children: [
              Text(
                WelcomeText.since.toUpperCase(),
                textAlign: TextAlign.center,
                style: HsText.courier(11, tracking: 0.24),
              ),
              const Ornament(),
              Text.rich(
                TextSpan(
                  text: '${WelcomeText.brandTop}\n',
                  children: [
                    TextSpan(
                      text: WelcomeText.brandSir,
                      style: HsText.caslon(34, italic: true),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: HsText.display.copyWith(letterSpacing: 1.4),
              ),
              Text(
                WelcomeText.role.toUpperCase(),
                style: HsText.courier(12, tracking: 0.12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
