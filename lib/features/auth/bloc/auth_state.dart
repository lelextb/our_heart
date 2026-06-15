// lib/features/auth/bloc/auth_state.dart

/// Represents the current state of the PIN authentication flow.
enum AuthStatus {
  /// App just launched, no attempt yet or PIN not set.
  initial,

  /// User has successfully authenticated.
  authenticated,

  /// User needs to enter PIN (either first time or after timeout).
  unauthenticated,

  /// User is in the process of setting a new PIN.
  settingPin,
}

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}