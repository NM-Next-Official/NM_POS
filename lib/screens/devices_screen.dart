import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';

import '../services/pos/printer_service.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});
  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final _service = PosPrinterService();
  StreamSubscription<List<Printer>>? _subscription;
  List<Printer> _printers = [];
  Printer? _defaultPrinter;
  bool _scanning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subscription = _service.devices.listen((devices) {
      if (mounted)
        setState(() => _printers =
            devices.where((p) => (p.name ?? '').isNotEmpty).toList());
    });
    _service.getDefault().then((p) {
      if (mounted) setState(() => _defaultPrinter = p);
    });
    _scan();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _error = null;
    });
    try {
      await _service.scan();
      await Future<void>.delayed(const Duration(seconds: 3));
    } catch (e) {
      _error =
          'Device scan failed. Check Bluetooth permissions and connection.';
    }
    if (mounted) setState(() => _scanning = false);
  }

  Future<void> _choose(Printer printer) async {
    try {
      await _service.saveDefault(printer);
      if (!mounted) return;
      setState(() => _defaultPrinter = printer);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${printer.name} selected as receipt printer.')));
    } catch (_) {
      _notify('Could not save this printer.');
    }
  }

  Future<void> _testPrint(Printer printer) async {
    try {
      await _service.printTest(printer);
      if (mounted) _notify('Test receipt sent to ${printer.name}.');
    } catch (_) {
      _notify(
          'Could not print. Check the printer, paper, Bluetooth pairing or USB driver.');
    }
  }

  void _notify(String message) {
    if (mounted)
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.all(26),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Devices',
                    style:
                        TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text('Barcode scanners and receipt printers',
                    style: TextStyle(color: Color(0xFF748295)))
              ])),
          OutlinedButton.icon(
              onPressed: _scanning ? null : _scan,
              icon: const Icon(Icons.refresh),
              label: Text(_scanning ? 'Scanning…' : 'Scan printers'))
        ]),
        const SizedBox(height: 16),
        Expanded(
            child: ListView(children: [
          const _InfoCard(
              icon: Icons.qr_code_scanner_rounded,
              title: 'Barcode and QR scanners',
              body:
                  'USB or Bluetooth HID scanners work like a keyboard. Pair or plug in the scanner, set its suffix to Enter/CR, then use Point of sale. Camera scanning is available on supported phones.'),
          const SizedBox(height: 12),
          _InfoCard(
              icon: Icons.print_outlined,
              title: 'Receipt printer',
              body:
                  'ESC/POS thermal printers can connect over USB or Bluetooth Low Energy (BLE). Android, Windows and macOS support USB through this integration; iOS supports BLE only. Pair Bluetooth devices first. Windows USB printers need their manufacturer driver. Classic-only SPP printers may need a different printer integration.'),
          const SizedBox(height: 16),
          if (_defaultPrinter != null)
            Card(
                color: const Color(0xFFEAF5F0),
                child: ListTile(
                    leading: const Icon(Icons.check_circle_outline,
                        color: Color(0xFF1F8B68)),
                    title: Text(_defaultPrinter!.name ?? 'Selected printer',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        'Default receipt printer · ${_defaultPrinter!.connectionTypeString}'),
                    trailing: IconButton(
                        tooltip: 'Clear default printer',
                        onPressed: () async {
                          await _service.forgetDefault();
                          if (mounted) setState(() => _defaultPrinter = null);
                        },
                        icon: const Icon(Icons.close)))),
          if (_error != null)
            Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child:
                    Text(_error!, style: const TextStyle(color: Colors.red))),
          if (_printers.isEmpty && !_scanning)
            const Padding(
                padding: EdgeInsets.all(18),
                child: Center(
                    child: Text(
                        'No printers found yet. Connect a printer and scan again.',
                        style: TextStyle(color: Color(0xFF748295))))),
          for (final printer in _printers)
            Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                    leading: const Icon(Icons.print_outlined),
                    title: Text(printer.name ?? 'Receipt printer',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                        '${printer.connectionTypeString}${printer.address == null ? '' : ' · ${printer.address}'}'),
                    trailing: Wrap(spacing: 6, children: [
                      IconButton(
                          tooltip: 'Print test receipt',
                          onPressed: () => _testPrint(printer),
                          icon: const Icon(Icons.receipt_long_outlined)),
                      OutlinedButton(
                          onPressed: () => _choose(printer),
                          child: Text(
                              _defaultPrinter?.address == printer.address &&
                                      _defaultPrinter?.name == printer.name
                                  ? 'Selected'
                                  : 'Use printer'))
                    ]))),
        ])),
      ]));
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title, body;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8EDF3)),
          borderRadius: BorderRadius.circular(16)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: const Color(0xFF2E67A0)),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(body,
              style: const TextStyle(color: Color(0xFF748295), height: 1.45))
        ]))
      ]));
}
