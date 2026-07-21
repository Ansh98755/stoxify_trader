import 'package:flutter_bloc/flutter_bloc.dart';

import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(const LoginState()) {
    on<LoginPhoneChanged>(_onPhoneChanged);
    on<LoginSubmitted>(_onSubmitted);
  }

  void _onPhoneChanged(LoginPhoneChanged event, Emitter<LoginState> emit) {
    emit(state.copyWith(phoneNumber: event.phoneNumber));
  }

  void _onSubmitted(LoginSubmitted event, Emitter<LoginState> emit) {
    if (!state.isPhoneValid) return;
    emit(state.copyWith(submissionCount: state.submissionCount + 1));
  }
}
