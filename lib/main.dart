import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/mode_selection_screen.dart';
import 'widgets/responsive_layout.dart';
import 'services/guide_service.dart';
import 'services/dual_display_service.dart';
import 'models/business_info_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize SQLite FFI for desktop platforms (Windows/Linux)
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await GuideService.instance.init();
  await DualDisplayService().initialize();
  await BusinessInfo.initialize();
  // If enabled and supported, show welcome on customer display
  await DualDisplayService().showWelcome();
  runApp(const ExtroPOSApp());
}

class ExtroPOSApp extends StatelessWidget {
  const ExtroPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExtroPOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: ResponsiveLayout(
        builder: (context, constraints, info) {
          // Provide a Scaffold that can adapt padding and max widths for phones
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: info.width < 600 ? 8 : 16,
                  vertical: 8,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: info.width < 900 ? info.width : 1200,
                  ),
                  child: const ModeSelectionScreen(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
