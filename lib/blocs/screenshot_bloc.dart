import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../data/database_helper.dart';
import '../services/screenshot_service.dart';

// Events
abstract class ScreenshotEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartScreenshots extends ScreenshotEvent {
  final int sessionId;
  StartScreenshots({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

class StopScreenshots extends ScreenshotEvent {}
class TakeScreenshot extends ScreenshotEvent {}

// States
abstract class ScreenshotState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ScreenshotInitial extends ScreenshotState {}

class ScreenshotActive extends ScreenshotState {
  final int sessionId;
  final int screenshotCount;

  ScreenshotActive({required this.sessionId, required this.screenshotCount});

  @override
  List<Object?> get props => [sessionId, screenshotCount];
}

class ScreenshotInactive extends ScreenshotState {}

class ScreenshotError extends ScreenshotState {
  final String message;

  ScreenshotError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class ScreenshotBloc extends Bloc<ScreenshotEvent, ScreenshotState> {
  Timer? _screenshotTimer;
  int _currentSessionId = 0;
  int _screenshotCount = 0;
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturing = false; // Prevent concurrent captures

  ScreenshotBloc() : super(ScreenshotInitial()) {
    on<StartScreenshots>(_onStartScreenshots);
    on<StopScreenshots>(_onStopScreenshots);
    on<TakeScreenshot>(_onTakeScreenshot);
  }

  void _onStartScreenshots(StartScreenshots event, Emitter<ScreenshotState> emit) {
    _currentSessionId = event.sessionId;
    _screenshotCount = 0;

    // Take screenshot every 15 minutes
    print('🔄 Starting screenshot timer - every 1 minutes');
    _screenshotTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      print('⏰ 1 minutes passed - taking screenshot');
      add(TakeScreenshot());
    });

    // Take first screenshot immediately when tracking starts
    print('📸 Taking initial screenshot immediately');
    add(TakeScreenshot());

    emit(ScreenshotActive(sessionId: _currentSessionId, screenshotCount: _screenshotCount));
  }

  void _onStopScreenshots(StopScreenshots event, Emitter<ScreenshotState> emit) {
    _screenshotTimer?.cancel();
    _screenshotTimer = null;
    emit(ScreenshotInactive());
  }

  Future<void> _onTakeScreenshot(TakeScreenshot event, Emitter<ScreenshotState> emit) async {
    // Prevent concurrent screenshot captures
    if (_isCapturing) {
      print('🚫 Screenshot already in progress, skipping...');
      return;
    }

    _isCapturing = true;

    try {
      print('📸 Attempting to take screenshot...');

      // First, try using the ScreenshotService
      String? filePath = await ScreenshotService.captureScreen();

      if (filePath == null) {
        print('⚠️ ScreenshotService failed, trying alternative approach...');
        filePath = await _captureScreenshotAlternative();
      }

      if (filePath != null) {
        // Verify file exists before saving to database
        final file = File(filePath);
        if (await file.exists()) {
          // Save to database
          await DatabaseHelper.instance.insertScreenshot({
            'session_id': _currentSessionId,
            'file_path': filePath,
            'timestamp': DateTime.now().toIso8601String(),
          });

          _screenshotCount++;
          print('✅ Screenshot saved successfully: $filePath');
          print('📊 File size: ${await file.length()} bytes');

          emit(ScreenshotActive(sessionId: _currentSessionId, screenshotCount: _screenshotCount));
        } else {
          print('❌ Screenshot file does not exist: $filePath');
          emit(ScreenshotError(message: 'Screenshot file was not created'));
        }
      } else {
        print('❌ Failed to capture screenshot - no file path returned');
        emit(ScreenshotError(message: 'Failed to capture screenshot'));
      }
    } catch (e) {
      print('❌ Screenshot error: ${e.toString()}');
      emit(ScreenshotError(message: 'Failed to take screenshot: ${e.toString()}'));
    } finally {
      _isCapturing = false; // Always reset the flag
    }
  }

  Future<String?> _captureScreenshotAlternative() async {
    try {
      Directory? directory;

      if (Platform.isMacOS) {
        // For macOS, save directly to user's Documents folder
        final userHome = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];

        if (userHome != null) {
          // Save directly to user's Documents/TrackerApp_Screenshots
          final documentsPath = path.join(userHome, 'Documents', 'TrackerApp_Screenshots');
          directory = Directory(documentsPath);

          // Create the directory if it doesn't exist
          if (!await directory.exists()) {
            await directory.create(recursive: true);
            print('📁 Created screenshots directory: ${directory.path}');
          }

          print('📂 Using user Documents directory: ${directory.path}');
        } else {
          throw Exception('Could not determine user home directory');
        }
      } else {
        // For other platforms, use Downloads folder instead of app documents
        try {
          final downloadsPath = path.join(Platform.environment['HOME'] ?? '', 'Downloads', 'TrackerApp_Screenshots');
          directory = Directory(downloadsPath);
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
        } catch (e) {
          // Final fallback
          directory = await getApplicationDocumentsDirectory();
        }
      }

      if (directory == null) {
        throw Exception('Could not determine save directory');
      }

      // Create a unique filename with microseconds to prevent conflicts
      final now = DateTime.now();
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final timeStr = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final uniqueId = '${now.millisecond}${now.microsecond}';
      final fileName = 'tracker_screenshot_${dateStr}_${timeStr}_$uniqueId.png';
      final filePath = path.join(directory.path, fileName);

      print('💾 Attempting to save screenshot to: $filePath');

      // Add a small delay to prevent rapid-fire screenshots
      await Future.delayed(Duration(milliseconds: 100));

      // Use the screenshot controller to capture the current widget
      final Uint8List? imageBytes = await _screenshotController.capture();

      if (imageBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(imageBytes);

        // Verify the file was written successfully
        if (await file.exists()) {
          final fileSize = await file.length();
          print('✅ Screenshot saved successfully!');
          print('📂 File location: $filePath');
          print('📊 File size: $fileSize bytes');
          print('📁 Find your screenshots in: ${directory.path}');
          print('🔍 Quick access: Open Finder → Documents → TrackerApp_Screenshots');

          return filePath;
        } else {
          print('❌ File was not created after writing bytes');
          return null;
        }
      } else {
        print('❌ No image bytes captured from screenshot controller');
        return null;
      }
    } catch (e) {
      print('❌ Alternative screenshot capture failed: $e');
      print('📍 Attempted path access failed, this might be a permissions issue');
      return null;
    }
  }

  // Method to get screenshots directory for debugging
  Future<String> getScreenshotsDirectory() async {
    if (Platform.isMacOS) {
      final userHome = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (userHome != null) {
        return path.join(userHome, 'Documents', 'TrackerApp_Screenshots');
      }
    }
    // Fallback for other platforms
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  @override
  Future<void> close() {
    _screenshotTimer?.cancel();
    return super.close();
  }
}