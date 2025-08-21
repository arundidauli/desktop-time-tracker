import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ScreenshotService {
  static Future<String?> captureScreen() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final screenshotsDir = Directory(path.join(directory.path, 'tracker_screenshots'));

      if (!await screenshotsDir.exists()) {
        await screenshotsDir.create(recursive: true);
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'screenshot_$timestamp.png';
      final filePath = path.join(screenshotsDir.path, fileName);

      if (Platform.isWindows) {
        return await _captureWindowsScreen(filePath);
      } else if (Platform.isMacOS) {
        return await _captureMacOSScreen(filePath);
      } else if (Platform.isLinux) {
        return await _captureLinuxScreen(filePath);
      }

      return null;
    } catch (e) {
      print('Error capturing screen: $e');
      return null;
    }
  }

  static Future<String?> _captureWindowsScreen(String filePath) async {
    try {
      // Use PowerShell to take screenshot on Windows
      final result = await Process.run('powershell', [
        '-Command',
        '''
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        \$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        \$bitmap = New-Object System.Drawing.Bitmap \$bounds.Width, \$bounds.Height
        \$graphics = [System.Drawing.Graphics]::FromImage(\$bitmap)
        \$graphics.CopyFromScreen(\$bounds.Location, [System.Drawing.Point]::Empty, \$bounds.Size)
        \$bitmap.Save("$filePath", [System.Drawing.Imaging.ImageFormat]::Png)
        \$graphics.Dispose()
        \$bitmap.Dispose()
        '''
      ]);

      if (result.exitCode == 0) {
        return filePath;
      } else {
        print('PowerShell screenshot failed: ${result.stderr}');
        return null;
      }
    } catch (e) {
      print('Windows screenshot error: $e');
      return null;
    }
  }

  static Future<String?> _captureMacOSScreen(String filePath) async {
    try {
      // Use screencapture command on macOS
      final result = await Process.run('screencapture', ['-x', filePath]);

      if (result.exitCode == 0) {
        return filePath;
      } else {
        print('macOS screencapture failed: ${result.stderr}');
        return null;
      }
    } catch (e) {
      print('macOS screenshot error: $e');
      return null;
    }
  }

  static Future<String?> _captureLinuxScreen(String filePath) async {
    try {
      // Try different screenshot tools on Linux
      List<List<String>> commands = [
        ['gnome-screenshot', '-f', filePath],
        ['scrot', filePath],
        ['import', '-window', 'root', filePath], // ImageMagick
      ];

      for (var command in commands) {
        try {
          final result = await Process.run(command[0], command.sublist(1));
          if (result.exitCode == 0) {
            return filePath;
          }
        } catch (e) {
          continue; // Try next command
        }
      }

      print('No screenshot tool available on Linux');
      return null;
    } catch (e) {
      print('Linux screenshot error: $e');
      return null;
    }
  }
}