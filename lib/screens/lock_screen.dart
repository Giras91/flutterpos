import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/lock_manager.dart';
import '../services/technician_service.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _pinCtrl.text.trim();
    if (pin.isEmpty) return;

    // Technician override handled first
    final handled = await TechnicianService.handlePinIfTechnician(context, pin);
    if (handled) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ok = await LockManager.instance.attemptUnlock(pin);
      if (!ok) {
        setState(() => _error = 'Invalid PIN');
        return;
      }

      if (!mounted) return;
      // Navigate to POS home (replace stack)
      Navigator.pushReplacementNamed(context, '/pos');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unlock — ExtroPOS')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter your PIN to unlock',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pinCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'PIN',
                      errorText: _error,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Unlock'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      // Offer help: technician PIN hint is not shown. Keep minimal.
                    },
                    child: const Text('Need help? Contact technician'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
