import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final authSessionEventsProvider = Provider<AuthSessionEvents>((ref) {
  final events = AuthSessionEvents();
  ref.onDispose(events.dispose);
  return events;
});

class AuthSessionEvents {
  final StreamController<void> _expiredController =
      StreamController<void>.broadcast();

  Stream<void> get expired => _expiredController.stream;

  void notifyExpired() {
    if (!_expiredController.isClosed) _expiredController.add(null);
  }

  void dispose() => _expiredController.close();
}
