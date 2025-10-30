import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/mode_selection_screen.dart';
import 'widgets/responsive_layout.dart';
import 'services/guide_service.dart';
import 'services/config_service.dart';
import 'screens/setup_screen.dart';
import 'screens/maintenance_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/activation_screen.dart';
import 'services/license_service.dart';
import 'services/secure_storage_service.dart';
import 'services/pin_store.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  await ConfigService.instance.init();
  await LicenseService.instance.init();
  await LicenseService.instance.initializeIfNeeded();
  // Initialize secure storage and Hive for encrypted PIN storage
  await SecureStorageService.instance.init();
  await Hive.initFlutter();
  await PinStore.instance.init();
  // Perform a one-time migration of user PINs from the DB to the encrypted PinStore
  await PinStore.instance.migrateFromDatabase();
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
      // Use ConfigService to decide whether first-run setup is required.
      routes: {
        '/setup': (_) => const SetupScreen(),
        '/maintenance': (_) => const MaintenanceScreen(),
        '/lock': (_) => const LockScreen(),
        '/activation': (_) => const ActivationScreen(),
        '/pos': (_) => Builder(
          builder: (context) => ResponsiveLayout(
            builder: (context, constraints, info) {
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
        ),
      },
      home: Builder(
        builder: (context) {
          // ConfigService is initialized in main(); read the flag directly.
          final showSetup = !ConfigService.instance.isSetupDone;
          if (showSetup) {
            return const SetupScreen();
          }

          // Check license state: if expired and not activated, show activation screen
          if (LicenseService.instance.isExpired) {
            return const ActivationScreen();
          }

          // If setup is complete and license is valid or in trial, require unlocking first.
          return const LockScreen();
        },
      ),
    );
  }
}
