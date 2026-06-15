import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/pin_utils.dart';
import '../../../data/local_storage/secure_storage_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required this.secureStorage}) : super(const AuthState());

  final SecureStorageService secureStorage;

  /// Checks whether a PIN is already stored and sets the initial status.
  Future<void> initialize() async {
    try {
      final hash = await secureStorage.pinHash;
      if (hash == null || hash.isEmpty) {
        emit(const AuthState(status: AuthStatus.settingPin));
      } else {
        emit(const AuthState(status: AuthStatus.unauthenticated));
      }
    } catch (e, st) {
      dev.log('AuthCubit initialization failed', error: e, stackTrace: st);
      emit(const AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Failed to read stored PIN.',
      ));
    }
  }

  /// Verifies [pin] against the stored hash.
  Future<void> verifyPin(String pin) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final hash = await secureStorage.pinHash;
      final salt = await secureStorage.pinSalt;

      if (hash == null || salt == null) {
        emit(const AuthState(
          status: AuthStatus.settingPin,
          errorMessage: 'No PIN configured.',
        ));
        return;
      }

      if (PinUtils.verifyPin(pin, salt, hash)) {
        emit(const AuthState(status: AuthStatus.authenticated));
      } else {
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Incorrect PIN.',
          isLoading: false,
        ));
      }
    } catch (e, st) {
      dev.log('PIN verification error', error: e, stackTrace: st);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Verification failed. Please try again.',
      ));
    }
  }

  /// Sets a new PIN after checking that [pin] and [confirmPin] match.
  Future<void> setPin(String pin, String confirmPin) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    if (pin.length != 4) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'PIN must be exactly 4 digits.',
      ));
      return;
    }

    if (pin != confirmPin) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'PINs do not match.',
      ));
      return;
    }

    try {
      final salt = PinUtils.generateSalt();
      final hash = PinUtils.hashPin(pin, salt);
      await secureStorage.savePinCredentials(hash: hash, salt: salt);
      emit(const AuthState(status: AuthStatus.authenticated));
    } catch (e, st) {
      dev.log('Failed to save PIN', error: e, stackTrace: st);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Could not save PIN. Please try again.',
      ));
    }
  }

  /// Changes the existing PIN after verifying the old one.
  Future<void> changePin({
    required String oldPin,
    required String newPin,
    required String confirmNewPin,
  }) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final hash = await secureStorage.pinHash;
      final salt = await secureStorage.pinSalt;

      if (hash == null || salt == null) {
        emit(const AuthState(
          status: AuthStatus.settingPin,
          errorMessage: 'No existing PIN.',
        ));
        return;
      }

      if (!PinUtils.verifyPin(oldPin, salt, hash)) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Current PIN is incorrect.',
        ));
        return;
      }

      if (newPin.length != 4 || newPin != confirmNewPin) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: newPin.length != 4
              ? 'PIN must be exactly 4 digits.'
              : 'PINs do not match.',
        ));
        return;
      }

      final newSalt = PinUtils.generateSalt();
      final newHash = PinUtils.hashPin(newPin, newSalt);
      await secureStorage.savePinCredentials(hash: newHash, salt: newSalt);
      emit(const AuthState(status: AuthStatus.authenticated));
    } catch (e, st) {
      dev.log('Failed to change PIN', error: e, stackTrace: st);
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Could not change PIN.',
      ));
    }
  }

  /// Resets the auth state back to unauthenticated (e.g. after timeout).
  void lock() {
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  /// Clears the current error message (used during PIN setup steps).
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }
}