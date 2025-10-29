import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../services/printer_service.dart';

class PrinterDebugConsole extends StatefulWidget {
  const PrinterDebugConsole({super.key});

  @override
  State<PrinterDebugConsole> createState() => _PrinterDebugConsoleState();
}

class _PrinterDebugConsoleState extends State<PrinterDebugConsole> {
  final PrinterService _printerService = PrinterService();
  final List<String> _lines = [];
  late final Stream<String> _stream;
  late final StreamSubscription<String> _sub;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    // Ensure service is initialized and persisted preferences are loaded
    await _printerService.initialize();
    // subscribe to the log stream after init so we respect persisted pause state
    _stream = _printerService.printerLogStream;
    _sub = _stream.listen((msg) {
      setState(() {
        _lines.insert(0, '[${DateTime.now().toIso8601String()}] $msg');
        if (_lines.length > 200) _lines.removeLast();
      });
    });
    // Don't force-enable logs on open; respect persisted value loaded by initialize()
    setState(() {});
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  void _clear() => setState(() => _lines.clear());

  Future<void> _exportLogs() async {
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No logs to export')));
      return;
    }

    final defaultName = 'printer-logs-${DateTime.now().toIso8601String().replaceAll(':', '-')}.txt';
    try {
      final dir = await FilePicker.platform.getDirectoryPath();
      if (dir == null) return; // user cancelled

  final path = p.join(dir, defaultName);
  final file = File(path);
  final content = _lines.reversed.join('\n');
  await file.writeAsString(content, flush: true);

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logs exported to: $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export logs: $e')));
    }
  }

  Future<void> _shareLogs() async {
    if (_lines.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No logs to share')));
      return;
    }

    final content = _lines.reversed.join('\n');
    try {
  await SharePlus.instance.share(ShareParams(text: content, subject: 'Printer logs'));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share logs: $e')));
    }
  }

  void _togglePaused() {
    setState(() {
      final wasPaused = !_printerService.isPrinterLogEnabled;
      _printerService.setPrinterLogEnabled(wasPaused);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Debug Console'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color: _printerService.isPrinterLogEnabled ? Colors.greenAccent : Colors.grey,
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: _printerService.isPrinterLogEnabled ? 'Native logs: enabled' : 'Native logs: paused',
                  child: Text(
                    _printerService.isPrinterLogEnabled ? 'Logs ON' : 'Logs OFF',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          IconButton(onPressed: _clear, icon: const Icon(Icons.clear)),
          IconButton(
            tooltip: 'Export logs',
            onPressed: _exportLogs,
            icon: const Icon(Icons.download),
          ),
          IconButton(
            tooltip: 'Share logs',
            onPressed: _shareLogs,
            icon: const Icon(Icons.share),
          ),
          IconButton(
            tooltip: 'Pause/Resume logs',
            onPressed: _togglePaused,
            icon: Icon(_printerService.isPrinterLogEnabled ? Icons.pause : Icons.play_arrow),
          ),
        ],
      ),
      body: _lines.isEmpty
          ? const Center(child: Text('No native logs received yet.'))
          : ListView.builder(
              reverse: false,
              padding: const EdgeInsets.all(12),
              itemCount: _lines.length,
              itemBuilder: (context, index) {
                final line = _lines[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(line, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                );
              },
            ),
    );
  }
}
