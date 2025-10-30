import 'package:flutter/material.dart';
import '../services/config_service.dart';
import '../services/database_helper.dart';
import '../services/reset_service.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final _configService = ConfigService.instance;
  final _db = DatabaseHelper.instance;
  bool _loading = false;

  Future<void> _resetPOS() async {
    setState(() => _loading = true);
    try {
      // Clear setup flag and store name
      await _configService.resetSetup();

  // Reset the on-disk database to factory defaults (re-seeds defaults)
  await _db.resetDatabase();

      // Broadcast reset to in-memory services
      ResetService.instance.triggerReset();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('POS reset complete! Restarting setup...'),
        ),
      );

      // Navigate to setup screen (replace stack)
      Navigator.pushReplacementNamed(context, '/setup');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error resetting POS: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Technician Maintenance')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🛠 Technician Access',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'From here, you can reconfigure or reset the POS. '
              'Use this mode only for maintenance or store migration.',
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Re-run Setup Wizard'),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/setup');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Factory Reset POS'),
              subtitle: const Text('Erase all users and setup data'),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Confirm Reset'),
                    content: const Text(
                      'This will erase all setup, store info, and users. Continue?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _resetPOS();
                }
              },
            ),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
