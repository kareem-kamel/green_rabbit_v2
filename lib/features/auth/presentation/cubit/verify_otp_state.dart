abstract class VerifyOtpState {}

class VerifyOtpInitial extends VerifyOtpState {}

class VerifyOtpLoading extends VerifyOtpState {}

class VerifyOtpSuccess extends VerifyOtpState {
  final bool onboardingDone;
  VerifyOtpSuccess({required this.onboardingDone});
}

class VerifyOtpError extends VerifyOtpState {
  final String message;
  VerifyOtpError(this.message);
}