import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  @override
  set state(int value) => super.state = value;
}

/// Currently active tab index in the Admin Dashboard.
final adminTabProvider = NotifierProvider<AdminTabNotifier, int>(() {
  return AdminTabNotifier();
});

class AdminLedgerSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
}

/// Pre-populated search query for the System Ledger (e.g. when inspecting a merchant from Map).
final adminLedgerSearchProvider = NotifierProvider<AdminLedgerSearchNotifier, String>(() {
  return AdminLedgerSearchNotifier();
});
