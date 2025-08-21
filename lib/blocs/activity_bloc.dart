import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tracker/services/activity_monitor.dart';

// Events
abstract class ActivityEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartActivityMonitoring extends ActivityEvent {}
class StopActivityMonitoring extends ActivityEvent {}
class ActivityDetected extends ActivityEvent {}
class ShowInactivityAlert extends ActivityEvent {}
class DismissInactivityAlert extends ActivityEvent {}

// States
abstract class ActivityState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ActivityInitial extends ActivityState {}

class ActivityMonitoring extends ActivityState {
  final DateTime lastActivity;
  final bool isActive;
  final int totalActivities;
  final Duration inactiveDuration;

  ActivityMonitoring({
    required this.lastActivity,
    required this.isActive,
    this.totalActivities = 0,
    required this.inactiveDuration,
  });

  @override
  List<Object?> get props => [lastActivity, isActive, totalActivities, inactiveDuration];
}

class InactivityAlert extends ActivityState {
  final Duration inactiveDuration;

  InactivityAlert({required this.inactiveDuration});

  @override
  List<Object?> get props => [inactiveDuration];
}

class ActivityStopped extends ActivityState {}

// BLoC
class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  Timer? _inactivityCheckTimer;
  DateTime _lastActivity = DateTime.now();
  int _totalActivities = 0;

  ActivityBloc() : super(ActivityInitial()) {
    on<StartActivityMonitoring>(_onStartActivityMonitoring);
    on<StopActivityMonitoring>(_onStopActivityMonitoring);
    on<ActivityDetected>(_onActivityDetected);
    on<ShowInactivityAlert>(_onShowInactivityAlert);
    on<DismissInactivityAlert>(_onDismissInactivityAlert);
  }

  void _onStartActivityMonitoring(StartActivityMonitoring event, Emitter<ActivityState> emit) {
    _lastActivity = DateTime.now();
    _totalActivities = 0;

    print('🔍 Starting activity monitoring');

    // Start the native activity monitor
    ActivityMonitor.startMonitoring(
      onActivityChange: (isActive) {
        if (isActive) {
          print('🎯 Activity detected by native monitor');
          add(ActivityDetected());
        }
      },
    );

    // Check for inactivity every minute
    _inactivityCheckTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      final inactiveDuration = now.difference(_lastActivity);

      print('⏱️ Checking inactivity: ${inactiveDuration.inMinutes} minutes');

      if (inactiveDuration.inMinutes >= 30) {
        print('⚠️ 30+ minutes of inactivity detected!');
        add(ShowInactivityAlert());
      } else {
        // Update the monitoring state with current info
        emit(ActivityMonitoring(
          lastActivity: _lastActivity,
          isActive: inactiveDuration.inMinutes < 5, // Active if less than 5min ago
          totalActivities: _totalActivities,
          inactiveDuration: inactiveDuration,
        ));
      }
    });

    emit(ActivityMonitoring(
      lastActivity: _lastActivity,
      isActive: true,
      totalActivities: _totalActivities,
      inactiveDuration: Duration.zero,
    ));
  }

  void _onStopActivityMonitoring(StopActivityMonitoring event, Emitter<ActivityState> emit) {
    print('🛑 Stopping activity monitoring');
    _inactivityCheckTimer?.cancel();
    ActivityMonitor.stopMonitoring();
    emit(ActivityStopped());
  }

  void _onActivityDetected(ActivityDetected event, Emitter<ActivityState> emit) {
    _lastActivity = DateTime.now();
    _totalActivities++;

    print('✅ Activity registered: Total activities: $_totalActivities');

    emit(ActivityMonitoring(
      lastActivity: _lastActivity,
      isActive: true,
      totalActivities: _totalActivities,
      inactiveDuration: Duration.zero,
    ));
  }

  void _onShowInactivityAlert(ShowInactivityAlert event, Emitter<ActivityState> emit) {
    final inactiveDuration = DateTime.now().difference(_lastActivity);
    print('🚨 Showing inactivity alert: ${inactiveDuration.inMinutes} minutes');
    emit(InactivityAlert(inactiveDuration: inactiveDuration));
  }

  void _onDismissInactivityAlert(DismissInactivityAlert event, Emitter<ActivityState> emit) {
    _lastActivity = DateTime.now();
    _totalActivities++;

    print('✅ Inactivity alert dismissed - user is back');

    emit(ActivityMonitoring(
      lastActivity: _lastActivity,
      isActive: true,
      totalActivities: _totalActivities,
      inactiveDuration: Duration.zero,
    ));
  }

  @override
  Future<void> close() {
    _inactivityCheckTimer?.cancel();
    ActivityMonitor.stopMonitoring();
    return super.close();
  }
}