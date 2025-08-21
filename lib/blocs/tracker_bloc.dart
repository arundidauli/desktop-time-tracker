import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/database_helper.dart';
import '../models/tracking_session.dart';

// Events
abstract class TrackerEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartTracking extends TrackerEvent {}
class StopTracking extends TrackerEvent {}
class UpdateDuration extends TrackerEvent {}
class LoadWeeklyReport extends TrackerEvent {}

// States
abstract class TrackerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TrackerInitial extends TrackerState {}

class TrackerRunning extends TrackerState {
  final TrackingSession session;
  final Duration currentDuration;

  TrackerRunning({required this.session, required this.currentDuration});

  @override
  List<Object?> get props => [session, currentDuration];
}

class TrackerStopped extends TrackerState {
  final TrackingSession? lastSession;

  TrackerStopped({this.lastSession});

  @override
  List<Object?> get props => [lastSession];
}

class WeeklyReportLoaded extends TrackerState {
  final List<TrackingSession> sessions;
  final int totalHours;

  WeeklyReportLoaded({required this.sessions, required this.totalHours});

  @override
  List<Object?> get props => [sessions, totalHours];
}

class TrackerError extends TrackerState {
  final String message;

  TrackerError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class TrackerBloc extends Bloc<TrackerEvent, TrackerState> {
  TrackingSession? _currentSession;
  Timer? _durationTimer;

  TrackerBloc() : super(TrackerInitial()) {
    on<StartTracking>(_onStartTracking);
    on<StopTracking>(_onStopTracking);
    on<UpdateDuration>(_onUpdateDuration);
    on<LoadWeeklyReport>(_onLoadWeeklyReport);
  }

  Future<void> _onStartTracking(StartTracking event, Emitter<TrackerState> emit) async {
    try {
      final now = DateTime.now();
      _currentSession = TrackingSession(
        startTime: now,
        createdAt: now,
      );

      // Save to database
      final id = await DatabaseHelper.instance.insertTrackingSession(_currentSession!.toMap());
      _currentSession = _currentSession!.copyWith(id: id);

      // Start duration timer
      _durationTimer = Timer.periodic(Duration(minutes: 1), (timer) {
        add(UpdateDuration());
      });

      emit(TrackerRunning(session: _currentSession!, currentDuration: Duration.zero));
    } catch (e) {
      emit(TrackerError(message: 'Failed to start tracking: ${e.toString()}'));
    }
  }

  Future<void> _onStopTracking(StopTracking event, Emitter<TrackerState> emit) async {
    try {
      if (_currentSession != null) {
        _durationTimer?.cancel();

        final endTime = DateTime.now();
        final duration = endTime.difference(_currentSession!.startTime);

        final updatedSession = _currentSession!.copyWith(
          endTime: endTime,
          durationMinutes: duration.inMinutes,
        );

        // Update database
        await DatabaseHelper.instance.updateTrackingSession(
          updatedSession.id!,
          updatedSession.toMap(),
        );

        emit(TrackerStopped(lastSession: updatedSession));
        _currentSession = null;
      }
    } catch (e) {
      emit(TrackerError(message: 'Failed to stop tracking: ${e.toString()}'));
    }
  }

  void _onUpdateDuration(UpdateDuration event, Emitter<TrackerState> emit) {
    if (_currentSession != null) {
      final currentDuration = DateTime.now().difference(_currentSession!.startTime);
      emit(TrackerRunning(session: _currentSession!, currentDuration: currentDuration));
    }
  }

  Future<void> _onLoadWeeklyReport(LoadWeeklyReport event, Emitter<TrackerState> emit) async {
    try {
      final sessionsData = await DatabaseHelper.instance.getWeeklyReport();
      final sessions = sessionsData.map((data) => TrackingSession.fromMap(data)).toList();

      final totalMinutes = sessions.fold<int>(0, (sum, session) => sum + session.durationMinutes);
      final totalHours = (totalMinutes / 60).round();

      emit(WeeklyReportLoaded(sessions: sessions, totalHours: totalHours));
    } catch (e) {
      emit(TrackerError(message: 'Failed to load weekly report: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _durationTimer?.cancel();
    return super.close();
  }
}