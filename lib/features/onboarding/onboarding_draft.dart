import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/profile.dart';

/// The particulars being gathered during the first visit. Nothing is saved
/// until the user accepts The Arrangements.
class OnboardingDraft extends Notifier<Profile> {
  @override
  Profile build() => ref.read(profileProvider);

  void update(Profile Function(Profile) change) => state = change(state);
}

final onboardingDraftProvider = NotifierProvider<OnboardingDraft, Profile>(
  OnboardingDraft.new,
);
