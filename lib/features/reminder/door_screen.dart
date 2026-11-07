import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/reminders.dart';
import '../../app/theme/text_styles.dart';
import '../../app/theme/tokens.dart';
import '../../app/widgets/widgets.dart';
import '../../copy/hargreaves.dart';
import '../../core/format.dart';
import '../../core/hydration.dart';
import '../../services/notifications.dart';

/// "At the door": the full-screen reminder shown over the lock screen
/// (DESIGN.md §9).
class DoorScreen extends ConsumerStatefulWidget {
  const DoorScreen({super.key, required this.payload});

  final ReminderPayload payload;

  @override
  ConsumerState<DoorScreen> createState() => _DoorScreenState();
}

class _DoorScreenState extends ConsumerState<DoorScreen> {
  bool _closing = false;

  Future<void> _close({required bool toLockScreen}) async {
    if (_closing) return;
    _closing = true;
    final nav = Navigator.of(context);
    // Answered here, so it needn't linger in the notification shade.
    await ref.read(notificationsProvider).dismiss(widget.payload.id);
    await LockScreen.release(moveToBack: toLockScreen);
    if (nav.canPop()) nav.pop();
  }

  Future<void> _took() async {
    unawaited(HapticFeedback.mediumImpact());
    final p = ref.read(profileProvider);
    await ref.read(intakeActionsProvider).log(p.glassSizeMl);
    await _close(toLockScreen: true);
  }

  Future<void> _snooze() async {
    await ref
        .read(notificationsProvider)
        .snooze(
          profile: ref.read(profileProvider),
          slot: widget.payload.slot,
          now: ref.read(clockProvider)(),
        );
    await _close(toLockScreen: true);
  }

  Future<void> _notNow() async {
    await ref.read(notificationsProvider).cancelFollowUp(widget.payload.slot);
    await _close(toLockScreen: true);
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileProvider);
    final h = Hargreaves.of(p);
    final now = ref.watch(nowProvider).value ?? ref.read(clockProvider)();
    final count = p.glassCount;
    final slot = widget.payload.slot.clamp(0, count - 1);
    final rehearsal = widget.payload.rehearsal;
    final g = Hargreaves.garnish(
      ref.watch(householdDayProvider),
      rehearsal ? now.minute : slot,
      count,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close(toLockScreen: false);
      },
      child: Scaffold(
        backgroundColor: HsColors.inkDeep,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  hm(now.hour * 60 + now.minute),
                  textAlign: TextAlign.center,
                  style: HsText.caslon(64, color: HsColors.label, height: 1),
                ),
                Text(
                  proseDate(now),
                  textAlign: TextAlign.center,
                  style: HsText.caslon(16, italic: true, color: HsColors.label),
                ),
                Expanded(
                  // Scrolls if a long curiosity meets a small screen.
                  child: LayoutBuilder(
                    builder: (context, box) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: box.maxHeight),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),
                            const Center(
                              child: TrayIllustration(width: 180, onDark: true),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              rehearsal
                                  ? 'A REHEARSAL · ${p.glassSizeMl} ml'
                                  : 'GLASS ${slot + 1} OF $count · '
                                        '${p.glassSizeMl} ml',
                              textAlign: TextAlign.center,
                              style: HsText.courier(
                                12,
                                tracking: 0.16,
                                color: HsColors.label,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                h.reminderTitle(p.glassSizeMl),
                                textAlign: TextAlign.center,
                                style: HsText.caslon(
                                  26,
                                  weight: FontWeight.w700,
                                  color: HsColors.label,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${rehearsal ? Hargreaves.rehearsalBody : h.reminderBody(index: slot, count: count, minutes: p.glassTimes[slot])} '
                              '${g.kind}',
                              textAlign: TextAlign.center,
                              style: HsText.caslon(
                                18,
                                italic: true,
                                color: HsColors.label,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 22),
                            _Curiosity(fact: g.fact),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Material(
                  color: HsColors.label,
                  child: InkWell(
                    onTap: _took,
                    child: Container(
                      height: 64,
                      alignment: Alignment.center,
                      child: Text(
                        "I'VE HAD MY GLASS",
                        style: HsText.button.copyWith(color: HsColors.ink),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _snooze,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: const RoundedRectangleBorder(),
                    side: const BorderSide(color: HsColors.label, width: 1.5),
                    foregroundColor: HsColors.label,
                  ),
                  child: Text(
                    'IN 15 MINUTES',
                    style: HsText.button.copyWith(color: HsColors.label),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: _notNow,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: HsColors.label,
                    ),
                    child: Text(
                      'Not now',
                      style:
                          HsText.caslon(
                            15,
                            italic: true,
                            color: HsColors.label,
                          ).copyWith(
                            decoration: TextDecoration.underline,
                            decorationColor: HsColors.label,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "A curiosity", set off by two hairlines like a footnote.
class _Curiosity extends StatelessWidget {
  const _Curiosity({required this.fact});

  final String fact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: HsColors.label.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        spacing: 6,
        children: [
          Text(
            'A CURIOSITY',
            style: HsText.courier(11, tracking: 0.2, color: HsColors.label),
          ),
          Text(
            fact,
            textAlign: TextAlign.center,
            style: HsText.caslon(15, color: HsColors.label, height: 1.45),
          ),
        ],
      ),
    );
  }
}
