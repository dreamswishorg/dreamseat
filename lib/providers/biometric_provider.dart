import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/biometric_service.dart';

class BiometricState {
  final bool isSupported;
  final bool isEnabled;
  final String label;
  final bool isInitialized;

  const BiometricState({
    this.isSupported = false,
    this.isEnabled = false,
    this.label = 'Face ID',
    this.isInitialized = false,
  });

  BiometricState copyWith({
    bool? isSupported,
    bool? isEnabled,
    String? label,
    bool? isInitialized,
  }) {
    return BiometricState(
      isSupported: isSupported ?? this.isSupported,
      isEnabled: isEnabled ?? this.isEnabled,
      label: label ?? this.label,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class BiometricNotifier extends Notifier<BiometricState> {
  @override
  BiometricState build() {
    BiometricService.enabledNotifier.addListener(_onServiceEnabledChanged);
    ref.onDispose(() {
      BiometricService.enabledNotifier.removeListener(_onServiceEnabledChanged);
    });
    Future.microtask(() {
      if (ref.mounted) refresh();
    });
    return const BiometricState();
  }

  void _onServiceEnabledChanged() {
    if (!ref.mounted) return;
    if (state.isEnabled != BiometricService.enabledNotifier.value) {
      state = state.copyWith(isEnabled: BiometricService.enabledNotifier.value);
    }
  }

  Future<void> refresh() async {
    final supported = await BiometricService.isBiometricAvailable();
    final enabled = await BiometricService.isBiometricEnabled();
    final label = await BiometricService.getBiometricLabel();
    if (!ref.mounted) return;
    state = state.copyWith(
      isSupported: supported,
      isEnabled: enabled,
      label: label,
      isInitialized: true,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    await BiometricService.setBiometricEnabled(enabled);
    if (!ref.mounted) return;
    state = state.copyWith(isEnabled: enabled);
  }
}

final biometricStateProvider = NotifierProvider<BiometricNotifier, BiometricState>(() {
  return BiometricNotifier();
});
