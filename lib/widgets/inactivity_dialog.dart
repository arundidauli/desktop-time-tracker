import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/activity_bloc.dart';

class InactivityDialog extends StatelessWidget {
  final Duration inactiveDuration;

  const InactivityDialog({
    Key? key,
    required this.inactiveDuration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 8),
          Text('Inactivity Detected'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You have been inactive for ${inactiveDuration.inMinutes} minutes.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 10),
          Text(
            'Are you still working?',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.read<ActivityBloc>().add(DismissInactivityAlert());
          },
          child: Text('Yes, I\'m here'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // You could add logic here to pause tracking or take other action
            context.read<ActivityBloc>().add(DismissInactivityAlert());
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: Text('Resume Work', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}