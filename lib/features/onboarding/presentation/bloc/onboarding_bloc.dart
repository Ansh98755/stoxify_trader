import 'package:flutter_bloc/flutter_bloc.dart';

import 'onboarding_event.dart';
import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(const OnboardingState()) {
    on<OnboardingPageChanged>(_onPageChanged);
    on<OnboardingNextPressed>(_onNextPressed);
    on<OnboardingSkipped>(_onSkipped);
  }

  void _onPageChanged(
    OnboardingPageChanged event,
    Emitter<OnboardingState> emit,
  ) {
    if (event.page < 0 || event.page >= OnboardingState.pageCount) return;
    emit(state.copyWith(currentPage: event.page, isCompleted: false));
  }

  void _onNextPressed(
    OnboardingNextPressed event,
    Emitter<OnboardingState> emit,
  ) {
    if (state.isLastPage) {
      emit(state.copyWith(isCompleted: true));
      return;
    }

    emit(state.copyWith(currentPage: state.currentPage + 1));
  }

  void _onSkipped(OnboardingSkipped event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(isCompleted: true));
  }
}
