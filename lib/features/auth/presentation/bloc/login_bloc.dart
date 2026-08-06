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
    on<LoginOtpEntryClosed>(_onOtpEntryClosed);
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
    if (!state.isPhoneValid || state.isSubmitting || state.isOtpEntryActive) return;

    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _authRepository.requestOtp(state.e164Phone);
      emit(
        state.copyWith(
          isSubmitting: false,
          isOtpEntryActive: true,
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

    // Dialog already closed — clear the entry flag and show network progress
    // only while verify is in flight.
    emit(
      state.copyWith(
        isSubmitting: true,
        isOtpEntryActive: false,
        clearError: true,
      ),
    );
    try {
      final user = await _authRepository.verifyOtp(
        phoneE164: state.e164Phone,
        otp: event.otp,
      );
      emit(
        state.copyWith(
          isSubmitting: false,
          isOtpEntryActive: false,
          verifySuccessCount: state.verifySuccessCount + 1,
          isNewUser: user.isNewUser,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          isOtpEntryActive: false,
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

    // Do not flip isSubmitting for resend — the OTP dialog stays open and
    // a full-screen loader on the page beneath would look like a hang.
    try {
      await _authRepository.requestOtp(state.e164Phone);
      emit(
        state.copyWith(
          otpSentCount: state.otpSentCount + 1,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: _messageOf(e),
        ),
      );
    }
  }

  void _onOtpEntryClosed(LoginOtpEntryClosed event, Emitter<LoginState> emit) {
    emit(
      state.copyWith(
        isSubmitting: false,
        isOtpEntryActive: false,
      ),
    );
  }

  String _messageOf(Object e) {
    if (e is AuthException) return e.message;
    final raw = e.toString();
    return raw.replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}
