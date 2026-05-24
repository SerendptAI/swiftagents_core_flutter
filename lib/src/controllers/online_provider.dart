import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class OnlineProvider with ChangeNotifier {
  final _connectionChecker = InternetConnectionChecker.instance;

  StreamSubscription<InternetConnectionStatus>? _subscription;

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  final _onlineController = StreamController<bool>.broadcast();
  Stream<bool> get onlineStream => _onlineController.stream;


  OnlineProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    // Check current online status
    final currentStatus = await _connectionChecker.hasConnection;
    _updateStatus(currentStatus);

    // Listen for online status changes
    _subscription = _connectionChecker.onStatusChange.listen((status) {
      final bool newStatus = [
        InternetConnectionStatus.connected,
        InternetConnectionStatus.slow,
      ].contains(status);

      _updateStatus(newStatus);
    });
  }

  void _updateStatus(bool newStatus) {
    if (_isOnline != newStatus) {
      _isOnline = newStatus;

      _onlineController.add(_isOnline);

      notifyListeners();
    }
  }


  void dispose() {
    _subscription?.cancel();
    _onlineController.close();
  }
}