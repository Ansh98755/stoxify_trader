import 'package:equatable/equatable.dart';

sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class OnboardingPageChanged extends OnboardingEvent {
  const OnboardingPageChanged(this.page);

  final int page;

  @override
  List<Object?> get props => <Object?>[page];
}

final class OnboardingNextPressed extends OnboardingEvent {
  const OnboardingNextPressed();
}

final class OnboardingSkipped extends OnboardingEvent {
  const OnboardingSkipped();
}
