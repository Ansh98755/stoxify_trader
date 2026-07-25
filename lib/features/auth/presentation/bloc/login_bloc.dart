import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/auth_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const LoginState()) {
    on<LoginPhoneChanged>(_onPhoneChanged);
    on<LoginSubmitted>(_onSubmitted);
    on<LoginOtpSubmitted>(_onOtpSubmitted);
    on<LoginOtpResendRequested>(_onOtpResendRequested);
  }

  final AuthRepository _authRepository;

  void _onPhoneChanged(LoginPhoneChanged event, Emitter<LoginState> emit) {
    emit(
      state.copyWith(
        phoneNumber: event.phoneNumber,
        clearError: true,
      ),
    );
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (!state.isPhoneValid || state.isSubmitting) return;

    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _authRepository.requestOtp(state.e164Phone);
      emit(
        state.copyWith(
          isSubmitting: false,
          otpSentCount: state.otpSentCount + 1,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: _messageOf(e),
        ),
      );
    }
  }

  Future<void> _onOtpSubmitted(
    LoginOtpSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    if (state.isSubmitting) return;

    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      final user = await _authRepository.verifyOtp(
        phoneE164: state.e164Phone,
        otp: event.otp,
      );
      emit(
        state.copyWith(
          isSubmitting: false,
          verifySuccessCount: state.verifySuccessCount + 1,
          isNewUser: user.isNewUser,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: _messageOf(e),
        ),
      );
    }
  }

  Future<void> _onOtpResendRequested(
    LoginOtpResendRequested event,
    Emitter<LoginState> emit,
  ) async {
    if (!state.isPhoneValid || state.isSubmitting) return;

    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _authRepository.requestOtp(state.e164Phone);
      emit(
        state.copyWith(
          isSubmitting: false,
          otpSentCount: state.otpSentCount + 1,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: _messageOf(e),
        ),
      );
    }
  }

  String _messageOf(Object e) {
    if (e is AuthException) return e.message;
    final raw = e.toString();
    return raw.replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}
