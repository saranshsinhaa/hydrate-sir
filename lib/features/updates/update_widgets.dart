import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/text_styles.dart';
import '../../app/theme/tokens.dart';
import '../../app/widgets/widgets.dart';
import '../../copy/hargreaves.dart';
import '../../copy/text.dart';
import 'update_controller.dart';

/// What Hargreaves says about the current state of updates.
String updateLine(UpdateState s, Hargreaves h) => switch (s) {
  UpdateIdle() => '',
  UpdateChecking() => UpdateText.checking,
  UpdateCurrent(:final version) => h.upToDate(version),
  UpdateAvailable(:final release) => h.newEdition(release.version),
  UpdateDownloading(:final progress) => Hargreaves.fetching(progress),
  UpdateNeedsPermission() => UpdateText.permission,
  UpdateInstalling() => UpdateText.installing,
  UpdateFailed(:final reason) =>
    reason == UpdateFailure.checksum ? UpdateText.checksum : UpdateText.failed,
};

bool _canFetch(UpdateState s) =>
    s is UpdateAvailable ||
    s is UpdateNeedsPermission ||
    (s is UpdateFailed && s.release != null);

/// The "New editions" section of Standing Instructions.
class UpdateSection extends ConsumerWidget {
  const UpdateSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    final s = ref.watch(updateControllerProvider);
    final c = ref.read(updateControllerProvider.notifier);
    final h = Hargreaves.of(p);
    final line = updateLine(s, h);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (line.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(
              liveRegion: true,
              child: Text(line, style: HsText.caslon(15, italic: true)),
            ),
          ),
        if (s is UpdateDownloading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ProgressRule(fraction: s.progress),
          ),
        Wrap(
          spacing: 16,
          children: [
            if (s is UpdateNeedsPermission)
              InkLink(
                text: UpdateText.openSettings,
                onTap: c.openInstallSettings,
              )
            else if (_canFetch(s))
              InkLink(text: UpdateText.fetch, onTap: c.fetch)
            else if (s is! UpdateChecking && s is! UpdateDownloading)
              InkLink(text: UpdateText.checkNow, onTap: c.check),
          ],
        ),
        ToggleRow(
          label: UpdateText.daily,
          hint: UpdateText.dailyHint,
          value: p.lookForUpdates,
          onChanged: (v) => ref
              .read(profileProvider.notifier)
              .update((x) => x.copyWith(lookForUpdates: v)),
        ),
      ],
    );
  }
}

/// Mentions a new edition on Today, once, until fetched or put off.
class UpdateNote extends ConsumerWidget {
  const UpdateNote({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(updateControllerProvider);
    final c = ref.read(updateControllerProvider.notifier);
    if (!c.announce) return const SizedBox.shrink();
    final h = Hargreaves.of(ref.watch(profileProvider));
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DashedBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(updateLine(s, h), style: HsText.caslon(15, italic: true)),
            if (s is UpdateDownloading)
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: ProgressRule(fraction: s.progress),
              )
            else
              Wrap(
                spacing: 16,
                children: [
                  if (s is UpdateNeedsPermission)
                    InkLink(
                      text: UpdateText.openSettings,
                      onTap: c.openInstallSettings,
                    )
                  else
                    InkLink(text: UpdateText.fetch, onTap: c.fetch),
                  InkLink(text: UpdateText.later, onTap: c.dismiss),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Section heading used in Standing Instructions.
class UpdateHeading extends StatelessWidget {
  const UpdateHeading({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 24, bottom: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: HsColors.ink)),
      ),
      child: const Eyebrow(UpdateText.section),
    );
  }
}
