import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/secure_storage_service.dart';
import '../services/pin_store.dart';

// NOTE: this file uses `context` after awaiting dialogs in a few places where
// the surrounding code checks `mounted` immediately afterwards. The linter
// flag `use_build_context_synchronously` is informational here and we guard
// with `if (!mounted) return;` before using `context` for UI. Suppress the
// lint to keep the code compact.
// ignore_for_file: use_build_context_synchronously

/// A small settings screen to export/import the AES encryption key used by
/// Hive to encrypt the `PinStore` box. WARNING: losing this key makes stored
/// PINs unrecoverable. Importing a wrong key will make existing PINs unusable.
class KeyBackupScreen extends StatefulWidget {
  const KeyBackupScreen({super.key});

  @override
  State<KeyBackupScreen> createState() => _KeyBackupScreenState();
}

class _KeyBackupScreenState extends State<KeyBackupScreen> {
  String? _exportedKey;
  bool _showKey = false;
  final _importController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final k = await SecureStorageService.instance.exportKey();
    setState(() {
      _exportedKey = k;
    });
  }

  Future<void> _copyKey() async {
    if (_exportedKey == null) return;
    await Clipboard.setData(ClipboardData(text: _exportedKey!));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Key copied to clipboard')));
  }

  Future<void> _importKeyFlow() async {
    final input = _importController.text.trim();
    if (input.isEmpty) return;

    // Ask for admin PIN to confirm import
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final pinController = TextEditingController();
        return AlertDialog(
          title: const Text('Confirm Import'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter admin PIN to allow importing a new encryption key. Importing a wrong key will make existing encrypted PINs unusable. Make sure you have a secure backup of the current key before importing.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Admin PIN'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                pinController.text.trim() == '' ? false : true,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Get entered PIN again (dialog above returned only boolean); ask once more
    final adminPin = await showDialog<String?>(
      context: context,
      builder: (context) {
        final pinController = TextEditingController();
        return AlertDialog(
          title: const Text('Admin PIN'),
          content: TextField(
            controller: pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Admin PIN'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, pinController.text.trim()),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (adminPin == null || adminPin.isEmpty) return;

    final currentAdmin = PinStore.instance.getAdminPin();
    // Allow official technician override with code '888888'
    final isTechOverride = adminPin == '888888';
    final authorized =
        isTechOverride || (currentAdmin != null && currentAdmin == adminPin);

    if (!authorized) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid admin PIN — import aborted'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Offer backup before import
    final existing = await SecureStorageService.instance.exportKey();
    if (existing != null && existing.isNotEmpty) {
      final backupChoice = await showDialog<String?>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Backup Current Key?'),
          content: const Text(
            'A current encryption key was found. It is strongly recommended to backup the current key before importing a new one. You can export it to a temporary file. Do you want to export now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'no'),
              child: const Text('Skip'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'no'),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'export'),
              child: const Text('Export'),
            ),
          ],
        ),
      );

      if (backupChoice == 'export') {
        try {
          final tmpDir = Directory.systemTemp.createTempSync(
            'extropos_key_backup_',
          );
          final file = File('${tmpDir.path}/extropos_key_backup.txt');
          await file.writeAsString(existing);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Current key exported to ${file.path}')),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Backup export failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
          // abort import if backup fails to avoid accidental key loss
          return;
        }
      } else if (backupChoice == null) {
        // dialog dismissed
        return;
      }
    }

    setState(() => _loading = true);
    try {
      await SecureStorageService.instance.importKey(input);
      await _loadKey();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Encryption key imported successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final masked = _exportedKey == null
        ? 'No key found'
        : (_showKey
              ? _exportedKey!
              : '${_exportedKey!.substring(0, 8)}...${_exportedKey!.substring(_exportedKey!.length - 8)}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Encryption Key Backup'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export current AES key',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    masked,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _showKey ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: _exportedKey == null
                      ? null
                      : () => setState(() => _showKey = !_showKey),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: _exportedKey == null ? null : _copyKey,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Warning: keep this key private. Losing it will make stored PINs unrecoverable. Importing a wrong key will also render stored PINs unusable.',
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Import AES key',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _importController,
              decoration: const InputDecoration(
                labelText: 'Paste base64 key here',
                hintText: 'Base64-encoded 32-byte key',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _loading ? null : _importKeyFlow,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import Key'),
                ),
                const SizedBox(width: 12),
                if (kDebugMode)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    onPressed: () async {
                      // Developer helper: show raw decoded length
                      try {
                        final input = _importController.text.trim();
                        final bytes = base64Decode(input);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Decoded length=${bytes.length} bytes',
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Decode failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text('Dev: Validate'),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              'Technician override PIN: 888888',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
