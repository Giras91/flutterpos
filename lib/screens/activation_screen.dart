import 'package:flutter/material.dart';
import '../services/license_service.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _controller = TextEditingController();
  final _license = LicenseService.instance;
  String _status = '';
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    setState(() => _loading = true);
    try {
      await _license.activate(_controller.text.trim());
      setState(() => _status = '✅ Activation successful!');
    } catch (_) {
      setState(() => _status = '❌ Invalid license key.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Software Activation')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter your activation key to unlock full features.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'License Key'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _activate,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Activate'),
            ),
            const SizedBox(height: 20),
            Text(_status, style: const TextStyle(color: Colors.blue)),
            const SizedBox(height: 12),
            Text(
              'Trial status:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FutureBuilder<void>(
              future: _license.initializeIfNeeded(),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Text('Loading...');
                }
                if (_license.isActivated) {
                  return Text('Activated — Key: ${_license.licenseKey}');
                }
                final daysLeft = _license.daysLeft;
                if (daysLeft > 0) {
                  return Text('Trial active — $daysLeft day(s) left');
                }
                return const Text('Trial expired — please activate');
              },
            ),
          ],
        ),
      ),
    );
  }
}
