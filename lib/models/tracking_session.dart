import 'package:equatable/equatable.dart';

class TrackingSession extends Equatable {

  const TrackingSession({
    this.id,
    required this.startTime,
    this.endTime,
    this.durationMinutes = 0,
    this.screenshotsCount = 0,
    required this.createdAt,
  });

  factory TrackingSession.fromMap(Map<String, dynamic> map) {
    return TrackingSession(
      id: map['id'] as int,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time'] as String) : null,
      durationMinutes: map['duration_minutes'] as int,
      screenshotsCount: map['screenshots_count'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
  final int? id;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final int screenshotsCount;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'screenshots_count': screenshotsCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TrackingSession copyWith({
    int? id,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    int? screenshotsCount,
    DateTime? createdAt,
  }) {
    return TrackingSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      screenshotsCount: screenshotsCount ?? this.screenshotsCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, startTime, endTime, durationMinutes, screenshotsCount, createdAt];
}