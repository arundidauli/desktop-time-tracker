import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/tracker_bloc.dart';
import '../blocs/screenshot_bloc.dart';
import '../blocs/activity_bloc.dart';
import '../widgets/inactivity_dialog.dart';

class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.timer, color: Colors.blue),
            SizedBox(width: 8),
            Text('Desktop Tracker', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTrackerControls(),
              SizedBox(height: 20),
              _buildStatusCards(),
              SizedBox(height: 20),
              _buildWeeklyReport(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackerControls() {
    return BlocConsumer<TrackerBloc, TrackerState>(
      listener: (context, state) {
        if (state is TrackerRunning) {
          context.read<ScreenshotBloc>().add(StartScreenshots(sessionId: state.session.id!));
          context.read<ActivityBloc>().add(StartActivityMonitoring());
        } else if (state is TrackerStopped) {
          context.read<ScreenshotBloc>().add(StopScreenshots());
          context.read<ActivityBloc>().add(StopActivityMonitoring());
        }
      },
      builder: (context, state) {
        final isRunning = state is TrackerRunning;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Time Tracker Controls',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isRunning ? null : () => context.read<TrackerBloc>().add(StartTracking()),
                        icon: Icon(Icons.play_arrow, color: Colors.white),
                        label: Text('Start', style: TextStyle(color: Colors.white, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRunning ? Colors.grey : Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isRunning ? () => context.read<TrackerBloc>().add(StopTracking()) : null,
                        icon: Icon(Icons.stop, color: Colors.white),
                        label: Text('Stop', style: TextStyle(color: Colors.white, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isRunning ? Colors.red : Colors.grey,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 3,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.read<TrackerBloc>().add(LoadWeeklyReport()),
                        icon: Icon(Icons.analytics, color: Colors.blue),
                        label: Text('Report', style: TextStyle(color: Colors.blue, fontSize: 16)),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCards() {
    return Column(
      children: [
        _buildTrackerStatus(),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildScreenshotStatus()),
            SizedBox(width: 16),
            Expanded(child: _buildActivityMonitor()),
          ],
        ),
      ],
    );
  }

  Widget _buildTrackerStatus() {
    return BlocBuilder<TrackerBloc, TrackerState>(
      builder: (context, state) {
        Color statusColor = Colors.grey;
        String statusText = 'Not Started';
        IconData statusIcon = Icons.timer_off;

        if (state is TrackerRunning) {
          statusColor = Colors.green;
          statusText = 'Running';
          statusIcon = Icons.timer;
        } else if (state is TrackerStopped) {
          statusColor = Colors.red;
          statusText = 'Stopped';
          statusIcon = Icons.stop_circle;
        }

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [statusColor.withOpacity(0.1), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Tracking Status',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                _buildStatusRow(Icons.circle, 'Status:', statusText, statusColor),
                if (state is TrackerRunning) ...[
                  SizedBox(height: 8),
                  _buildStatusRow(Icons.access_time, 'Started:',
                      DateFormat('HH:mm:ss').format(state.session.startTime), Colors.grey[600]!),
                  SizedBox(height: 8),
                  _buildStatusRow(Icons.schedule, 'Duration:',
                      _formatDuration(state.currentDuration), Colors.blue),
                ] else if (state is TrackerStopped && state.lastSession != null) ...[
                  SizedBox(height: 8),
                  _buildStatusRow(Icons.history, 'Last Session:',
                      '${state.lastSession!.durationMinutes} minutes', Colors.grey[600]!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScreenshotStatus() {
    return BlocListener<ActivityBloc, ActivityState>(
      listener: (context, state) {
        if (state is InactivityAlert) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => InactivityDialog(inactiveDuration: state.inactiveDuration),
          );
        }
      },
      child: BlocBuilder<ScreenshotBloc, ScreenshotState>(
        builder: (context, state) {
          Color statusColor = Colors.grey;
          String statusText = 'Not Started';
          IconData statusIcon = Icons.camera_alt_outlined;

          if (state is ScreenshotActive) {
            statusColor = Colors.green;
            statusText = 'Active';
            statusIcon = Icons.camera_alt;
          } else if (state is ScreenshotInactive) {
            statusColor = Colors.red;
            statusText = 'Inactive';
            statusIcon = Icons.camera_alt_outlined;
          }

          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              height: 160,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.blue.withOpacity(0.1), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(statusIcon, color: Colors.blue, size: 24),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Screenshots',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (state is ScreenshotActive) ...[
                        SizedBox(height: 8),
                        Text('Every 15 minutes', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        Text('Count: ${state.screenshotCount}', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActivityMonitor() {
    return BlocBuilder<ActivityBloc, ActivityState>(
      builder: (context, state) {
        Color statusColor = Colors.grey;
        String statusText = 'Not Started';
        IconData statusIcon = Icons.sensors_off;

        if (state is ActivityMonitoring) {
          statusColor = Colors.green;
          statusText = 'Monitoring';
          statusIcon = Icons.sensors;
        } else if (state is ActivityStopped) {
          statusColor = Colors.red;
          statusText = 'Stopped';
          statusIcon = Icons.sensors_off;
        }

        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            height: 160,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.orange.withOpacity(0.1), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: Colors.orange, size: 24),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Activity Monitor',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (state is ActivityMonitoring) ...[
                      SizedBox(height: 8),
                      Text('Alert after 30min', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      Text(
                        'Last: ${DateFormat('HH:mm:ss').format(state.lastActivity)}',
                        style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyReport() {
    return BlocBuilder<TrackerBloc, TrackerState>(
      builder: (context, state) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            height: 400,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.blue, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Weekly Report',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                if (state is WeeklyReportLoaded) ...[
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Total Hours This Week: ${state.totalHours}h',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.sessions.length,
                      itemBuilder: (context, index) {
                        final session = state.sessions[index];
                        final isCompleted = session.endTime != null;

                        return Card(
                          margin: EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: isCompleted ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                              child: Icon(
                                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: isCompleted ? Colors.green : Colors.orange,
                              ),
                            ),
                            title: Text(
                              DateFormat('MMM dd, yyyy').format(session.createdAt),
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.play_arrow, size: 16, color: Colors.grey[600]),
                                    SizedBox(width: 4),
                                    Text('${DateFormat('HH:mm').format(session.startTime)}'),
                                    SizedBox(width: 16),
                                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                                    SizedBox(width: 4),
                                    Text('${session.durationMinutes}min'),
                                  ],
                                ),
                                SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.camera_alt, size: 16, color: Colors.grey[600]),
                                    SizedBox(width: 4),
                                    Text('${session.screenshotsCount} screenshots'),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCompleted ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isCompleted ? 'Completed' : 'In Progress',
                                style: TextStyle(
                                  color: isCompleted ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'No Data Available',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Click "Report" button to load weekly data',
                            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusRow(IconData icon, String label, String value, Color valueColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }
}