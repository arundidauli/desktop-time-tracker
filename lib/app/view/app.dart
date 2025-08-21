import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tracker/blocs/activity_bloc.dart';
import 'package:tracker/blocs/screenshot_bloc.dart';
import 'package:tracker/blocs/tracker_bloc.dart';
import 'package:tracker/counter/counter.dart';
import 'package:tracker/l10n/l10n.dart';
import 'package:tracker/screens/tracker_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => TrackerBloc()),
        BlocProvider(create: (context) => ScreenshotBloc()),
        BlocProvider(create: (context) => ActivityBloc()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Desktop Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: TrackerScreen(),
      ),
    );
  }
}