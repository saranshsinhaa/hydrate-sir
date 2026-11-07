import 'package:flutter/material.dart';

import '../theme/text_styles.dart';
import '../theme/tokens.dart';
import 'controls.dart';

/// A square label-card dialog. Returns true for [confirm], false otherwise.
Future<bool> showHsDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirm,
  String? cancel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: HsColors.inkDeep.withValues(alpha: 0.55),
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: HsColors.ink)),
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          // Scrolls when long text or large font sizes outgrow the screen.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: HsText.caslon(22, weight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                Text(body, style: HsText.voice),
                const SizedBox(height: 20),
                if (destructive)
                  Material(
                    color: HsColors.stamp,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(true),
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        child: Text(
                          confirm.toUpperCase(),
                          style: HsText.button.copyWith(color: HsColors.label),
                        ),
                      ),
                    ),
                  )
                else
                  InkButton(
                    label: confirm,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                if (cancel != null)
                  Center(
                    child: InkLink(
                      text: cancel,
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  return result ?? false;
}
