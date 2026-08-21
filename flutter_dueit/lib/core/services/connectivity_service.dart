import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents network connectivity state for user-friendly UX hints
enum ConnectivityStatus {
  online,
  offline,
  reconnecting,
}

class ConnectivityState {
  final ConnectivityStatus status;
  final String? message;
  final bool isInitial;

  const ConnectivityState({
    required this.status,
    this.message,
    this.isInitial = false,
  });

  bool get isOnline => status == ConnectivityStatus.online;
  bool get isOffline => status == ConnectivityStatus.offline;
  bool get isReconnecting => status == ConnectivityStatus.reconnecting;

  ConnectivityState copyWith({
    ConnectivityStatus? status,
    String? message,
    bool? isInitial,
  }) {
    return ConnectivityState(
      status: status ?? this.status,
      message: message ?? this.message,
      isInitial: isInitial ?? this.isInitial,
    );
  }
}

abstract class ConnectivityService {
  Stream<ConnectivityState> get connectivityStream;
  ConnectivityState get currentState;
  void dispose();
}

class ConnectivityServiceImpl implements ConnectivityService {
  final Connectivity _connectivity;
  final StreamController<ConnectivityState> _controller =
      StreamController<ConnectivityState>.broadcast();

  late StreamSubscription<List<ConnectivityResult>> _subscription;
  ConnectivityState _currentState = const ConnectivityState(
    status: ConnectivityStatus.online,
    isInitial: true,
  );
  Timer? _reconnectMessageTimer;
  bool _wasOffline = false;

  ConnectivityServiceImpl({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _init();
  }

  void _init() {
    _subscription = _connectivity.onConnectivityChanged.listen(_handleResults);
    // Check initial state
    _connectivity.checkConnectivity().then(_handleResults);
  }

  void _handleResults(List<ConnectivityResult> results) {
    final hasConnection = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);

    if (!hasConnection) {
      _wasOffline = true;
      _reconnectMessageTimer?.cancel();
      _updateState(const ConnectivityState(
        status: ConnectivityStatus.offline,
        message: 'Offline — Changes will sync when you\'re back online',
      ));
    } else {
      if (_wasOffline) {
        _wasOffline = false;
        // Show brief "Back online" message that auto-dismisses
        _updateState(const ConnectivityState(
          status: ConnectivityStatus.online,
          message: 'Back online',
        ));

        _reconnectMessageTimer?.cancel();
        _reconnectMessageTimer = Timer(const Duration(seconds: 3), () {
          _updateState(const ConnectivityState(
            status: ConnectivityStatus.online,
            message: null,
          ));
        });
      } else {
        _updateState(const ConnectivityState(
          status: ConnectivityStatus.online,
          message: null,
        ));
      }
    }
  }

  void _updateState(ConnectivityState state) {
    _currentState = state;
    if (!_controller.isClosed) {
      _controller.add(state);
    }
  }

  @override
  Stream<ConnectivityState> get connectivityStream => _controller.stream;

  @override
  ConnectivityState get currentState => _currentState;

  @override
  void dispose() {
    _reconnectMessageTimer?.cancel();
    _subscription.cancel();
    _controller.close();
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityServiceImpl();
  ref.onDispose(service.dispose);
  return service;
});

final connectivityStateProvider = StreamProvider<ConnectivityState>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.connectivityStream;
});
