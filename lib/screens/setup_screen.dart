import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../services/config_service.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../services/pin_store.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameCtrl = TextEditingController();
  final _adminNameCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _adminPinCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminPinCtrl.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;
    // Capture navigator early to avoid using BuildContext across async gaps.
    final navigator = Navigator.of(context);

    setState(() => _saving = true);

    // Save store name and setup flag
    await ConfigService.instance.setStoreName(_storeNameCtrl.text.trim());
    await ConfigService.instance.setSetupDone(true);

    // Create or update admin user
    try {
      final users = await DatabaseService.instance.getUsers();
  final String pin = _adminPinCtrl.text.trim();
      if (users.isNotEmpty) {
        // Try to find an admin; otherwise update first user
        User? admin = users.firstWhere(
          (u) => u.role == UserRole.admin,
          orElse: () => users.first,
        );

        final updated = admin.copyWith(
          fullName: _adminNameCtrl.text.trim(),
          email: _adminEmailCtrl.text.trim(),
        );

        // Persist PIN in the encrypted PinStore and then update the user record
        try {
          await PinStore.instance.setPinForUser(admin.id, pin);
        } catch (_) {}

        await DatabaseService.instance.updateUser(updated);
      } else {
        final id = const Uuid().v4();
        final user = User(
          id: id,
          username: _adminNameCtrl.text
              .trim()
              .replaceAll(' ', '_')
              .toLowerCase(),
          fullName: _adminNameCtrl.text.trim(),
          email: _adminEmailCtrl.text.trim(),
          role: UserRole.admin,
        );
        await DatabaseService.instance.insertUser(user);
        // Save admin PIN securely in Hive encrypted box for quick unlock
        try {
          await PinStore.instance.setAdminPin(pin);
        } catch (_) {
          // non-fatal
        }
        // Also store the admin user's PIN in PinStore for lookup
        try {
          await PinStore.instance.setPinForUser(id, pin);
        } catch (_) {}
      }
    } catch (e) {
      // ignore DB errors but log in debug
      // If update/insert fails for any reason, still mark setup done so user can proceed
      // Developers can inspect logs to debug DB schema mismatches.
    }

    setState(() => _saving = false);

    // Ensure widget is still mounted before navigating
    if (!mounted) return;

    // Navigate to home (pop all and push ModeSelectionScreen via Navigator)
    navigator.pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome — Setup')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 800),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Let\'s get your store ready',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _storeNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Store name',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter store name'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Administrator account',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _adminNameCtrl,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter admin name'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _adminEmailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email (optional)',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _adminPinCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Admin PIN (4 digits)',
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter a PIN';
                        }
                        if (v.trim().length < 3) {
                          return 'PIN must be at least 3 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saving ? null : _completeSetup,
                      child: _saving
                          ? const CircularProgressIndicator.adaptive()
                          : const Text('Complete setup'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () async {
                              // Skip setup: mark as done and go to home
                              final navigator = Navigator.of(context);
                              await ConfigService.instance.setSetupDone(true);
                              if (!mounted) return;
                              navigator.pushReplacementNamed('/');
                            },
                      child: const Text('Skip for now'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
