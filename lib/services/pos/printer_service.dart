import 'dart:convert';

import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PosPrinterService {
  static const _savedPrinterKey = 'pos_default_printer_v1';
  final _plugin = FlutterThermalPrinter.instance;

  Future<void> scan() => _plugin.getPrinters(
        connectionTypes: [ConnectionType.USB, ConnectionType.BLE],
        androidUsesFineLocation: true,
      );

  Stream<List<Printer>> get devices => _plugin.devicesStream;

  Future<void> saveDefault(Printer printer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedPrinterKey, jsonEncode(printer.toJson()));
  }

  Future<Printer?> getDefault() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedPrinterKey);
    if (raw == null) return null;
    try {
      return Printer.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> forgetDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedPrinterKey);
  }

  Future<void> connect(Printer printer) async {
    if (printer.connectionType == ConnectionType.USB) return;
    final connected = await _plugin.connect(printer);
    if (!connected)
      throw StateError('Could not connect to ${printer.name ?? 'printer'}.');
  }

  Future<void> printTest(Printer printer) async {
    await connect(printer);
    await _plugin.printData(
        printer, await _receiptBytes('NM POS', 'Printer ready'),
        longData: true);
  }

  Future<void> printSale({
    required Printer printer,
    required String saleId,
    required List<String> itemLines,
    required double subtotal,
    required double discount,
    required double total,
  }) async {
    await connect(printer);
    final details = [
      ...itemLines,
      '------------------------------',
      'Subtotal  BDT ${subtotal.toStringAsFixed(2)}',
      'Discount  BDT ${discount.toStringAsFixed(2)}',
      'TOTAL     BDT ${total.toStringAsFixed(2)}',
      'Receipt: ${saleId.substring(0, 8)}',
    ].join('\n');
    await _plugin.printData(printer, await _receiptBytes('NM POS', details),
        longData: true);
  }

  Future<List<int>> _receiptBytes(String heading, String details) async {
    final generator = Generator(PaperSize.mm80, await CapabilityProfile.load());
    return <int>[
      ...generator.text(heading,
          styles: const PosStyles(
              align: PosAlign.center,
              bold: true,
              height: PosTextSize.size2,
              width: PosTextSize.size2)),
      ...generator.feed(1),
      ...generator.text(details),
      ...generator.feed(2),
      ...generator.cut(),
    ];
  }
}
