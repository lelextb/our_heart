import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/strings.dart';
import 'bloc/auth_cubit.dart';
import 'bloc/auth_state.dart';
import 'widgets/pin_input_widget.dart';

/// Full‑screen PIN entry / setup view.
///
/// Displays different UI based on [AuthStatus]:
/// - [AuthStatus.unauthenticated] → enter existing PIN
/// - [AuthStatus.settingPin] → set a new PIN (two‑step)
class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String? _firstPin; // temporarily holds the first entry during setup

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                final status = state.status;

                if (status == AuthStatus.settingPin) {
                  return _buildSetPin(state);
                }

                // unauthenticated or initial
                return _buildEnterPin(state);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnterPin(AuthState state) {
    return PinInputWidget(
      key: const ValueKey('enter_pin'),
      title: Strings.enterPin,
      errorMessage: state.errorMessage,
      enabled: !state.isLoading,
      onPinComplete: (pin) {
        context.read<AuthCubit>().verifyPin(pin);
      },
    );
  }

  Widget _buildSetPin(AuthState state) {
    if (_firstPin == null) {
      // Step 1: choose PIN
      return PinInputWidget(
        key: const ValueKey('set_pin_step1'),
        title: Strings.setPin,
        errorMessage: state.errorMessage,
        enabled: !state.isLoading,
        onPinComplete: (pin) {
          setState(() {
            _firstPin = pin;
          });
          context.read<AuthCubit>().clearError();
        },
      );
    }

    // Step 2: confirm PIN
    return PinInputWidget(
      key: const ValueKey('set_pin_step2'),
      title: Strings.confirmPin,
      errorMessage: state.errorMessage,
      enabled: !state.isLoading,
      onPinComplete: (confirmPin) {
        context.read<AuthCubit>().setPin(_firstPin!, confirmPin);
        _firstPin = null;
      },
    );
  }
}