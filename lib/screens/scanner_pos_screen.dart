import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/pos_product.dart';
import '../providers/auth_provider.dart';
import '../services/pos/pos_repository.dart';
import '../services/pos/printer_service.dart';

class ScannerPosScreen extends StatefulWidget {
  const ScannerPosScreen({super.key});
  @override
  State<ScannerPosScreen> createState() => _ScannerPosScreenState();
}

class _ScannerPosScreenState extends State<ScannerPosScreen> {
  final _repository = PosRepository();
  final _printerService = PosPrinterService();
  final _scanController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  final _focusNode = FocusNode();
  final Map<String, PosCartLine> _cart = {};
  List<PosProduct> _matches = [];
  bool _cameraOpen = false;
  bool _showCartOnCompact = false;
  bool _processing = false;
  String _payment = 'cash';
  String? _lastCameraCode;
  DateTime _lastCameraAt = DateTime.fromMillisecondsSinceEpoch(0);
  double get _subtotal => _cart.values.fold(0, (sum, line) => sum + line.total);
  double get _discount => double.tryParse(_discountController.text) ?? 0;

  @override
  void initState() {
    super.initState();
    _searchProducts();
  }

  @override
  void dispose() {
    _scanController.dispose();
    _discountController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _searchProducts() async {
    final businessId = context.read<AuthProvider>().user!.id;
    final results = await _repository.getProducts(
        businessId: businessId, search: _scanController.text);
    if (mounted) setState(() => _matches = results.take(8).toList());
  }

  Future<void> _scan(String raw) async {
    final barcode = raw.trim();
    if (barcode.isEmpty || _processing) return;
    _processing = true;
    _scanController.clear();
    try {
      final product = await _repository.findByBarcode(barcode,
          businessId: context.read<AuthProvider>().user!.id);
      if (!mounted) return;
      if (product == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No product found for $barcode')));
      } else if (product.stock <= (_cart[product.id]?.quantity ?? 0)) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${product.name} is out of stock.')));
      } else {
        setState(() {
          final line = _cart[product.id];
          if (line == null) {
            _cart[product.id] = PosCartLine(product: product);
          } else {
            line.quantity++;
          }
        });
      }
      await _searchProducts();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Scanner could not reach the product catalog.')));
    } finally {
      _processing = false;
      if (mounted) _focusNode.requestFocus();
    }
  }

  void _cameraScan(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    if (value == null) return;
    final now = DateTime.now();
    if (_lastCameraCode == value &&
        now.difference(_lastCameraAt).inMilliseconds < 1200) return;
    _lastCameraCode = value;
    _lastCameraAt = now;
    _scan(value);
  }

  void _addProduct(PosProduct product) {
    final line = _cart[product.id];
    if (product.stock <= (line?.quantity ?? 0)) return;
    setState(() {
      if (line == null) {
        _cart[product.id] = PosCartLine(product: product);
      } else {
        line.quantity++;
      }
    });
    _focusNode.requestFocus();
  }

  Future<void> _checkout() async {
    final user = context.read<AuthProvider>().user;
    if (user == null || _cart.isEmpty || _processing) return;
    if (_discount < 0 || _discount > _subtotal) {
      _toast('Discount must not exceed the subtotal.');
      return;
    }
    setState(() => _processing = true);
    try {
      final items = _cart.values.toList();
      final saleId = await _repository.completeSale(
          cashierId: user.id,
          businessId: user.id,
          lines: items,
          discount: _discount,
          paymentMethod: _payment);
      final printer = await _printerService.getDefault();
      var printed = false;
      if (printer != null) {
        try {
          await _printerService.printSale(
              printer: printer,
              saleId: saleId,
              itemLines: items
                  .map((e) =>
                      '${e.product.name} x${e.quantity}  BDT ${e.total.toStringAsFixed(2)}')
                  .toList(),
              subtotal: _subtotal,
              discount: _discount,
              total: _subtotal - _discount);
          printed = true;
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _cart.clear();
        _discountController.text = '0';
      });
      await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: const Text('Sale completed'),
                  content: Text(
                      'Sale ${saleId.substring(0, 8)} saved.${printer == null ? '\nSet up a receipt printer in Devices.' : printed ? '\nReceipt printed.' : '\nSale saved, but receipt printing failed.'}'),
                  actions: [
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Done'))
                  ]));
    } catch (e) {
      _toast(e is StateError
          ? e.message.toString()
          : 'Checkout failed. The sale was not completed.');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _toast(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 850;
    final catalog = _catalog();
    final cart = _cartPanel(compact: !wide);
    return Padding(
        padding: const EdgeInsets.all(22),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Point of sale',
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  Text('Scan a barcode or add an item from the catalog',
                      style: TextStyle(color: Color(0xFF748295)))
                ])),
            if (defaultTargetPlatform != TargetPlatform.windows &&
                defaultTargetPlatform != TargetPlatform.linux)
              IconButton(
                  tooltip: _cameraOpen ? 'Close camera' : 'Use camera scanner',
                  onPressed: () => setState(() => _cameraOpen = !_cameraOpen),
                  icon: Icon(_cameraOpen
                      ? Icons.close
                      : Icons.qr_code_scanner_rounded))
          ]),
          const SizedBox(height: 18),
          if (_cameraOpen)
            Container(
                height: 190,
                margin: const EdgeInsets.only(bottom: 14),
                clipBehavior: Clip.antiAlias,
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(16)),
                child: MobileScanner(onDetect: _cameraScan)),
          Expanded(
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Expanded(flex: 6, child: catalog),
                          const SizedBox(width: 18),
                          Expanded(flex: 5, child: cart)
                        ])
                  : Column(children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: SegmentedButton<bool>(
                          segments: [
                            const ButtonSegment(
                                value: false,
                                label: Text('Scan products'),
                                icon: Icon(Icons.qr_code_scanner)),
                            ButtonSegment(
                                value: true,
                                label: Text('Cart (${_cart.length})'),
                                icon: const Icon(Icons.shopping_cart_outlined)),
                          ],
                          selected: {_showCartOnCompact},
                          onSelectionChanged: (value) =>
                              setState(() => _showCartOnCompact = value.first),
                        ),
                      ),
                      Expanded(child: _showCartOnCompact ? cart : catalog),
                    ])),
        ]));
  }

  Widget _catalog() => Column(children: [
        TextField(
            focusNode: _focusNode,
            controller: _scanController,
            autofocus: true,
            onChanged: (_) => _searchProducts(),
            onSubmitted: _scan,
            keyboardType: TextInputType.none,
            decoration: InputDecoration(
                hintText: 'Scan or enter barcode / product name',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                    onPressed: () {
                      _scanController.clear();
                      _searchProducts();
                      _focusNode.requestFocus();
                    },
                    icon: const Icon(Icons.clear)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none))),
        const SizedBox(height: 10),
        Expanded(
            child: _matches.isEmpty
                ? const Center(
                    child: Text('No matching products',
                        style: TextStyle(color: Color(0xFF748295))))
                : ListView.separated(
                    itemCount: _matches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 7),
                    itemBuilder: (context, i) {
                      final p = _matches[i];
                      return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: ListTile(
                              onTap: () => _addProduct(p),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              title: Text(p.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              subtitle:
                                  Text('${p.barcode} · ${p.stock} in stock'),
                              trailing: Text(
                                  '৳${p.sellingPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800))));
                    })),
      ]);

  Widget _cartPanel({bool compact = false}) => Container(
      padding: EdgeInsets.all(compact ? 10 : 16),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8EDF3)),
          borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text('Current sale',
                  style: TextStyle(
                      fontSize: compact ? 15 : 17,
                      fontWeight: FontWeight.w800))),
          Text('${_cart.length} items',
              style: const TextStyle(color: Color(0xFF748295)))
        ]),
        Divider(height: compact ? 14 : 22),
        Expanded(
            child: _cart.isEmpty
                ? const Center(
                    child: Text('Your cart is empty',
                        style: TextStyle(color: Color(0xFF748295))))
                : ListView(
                    children: _cart.values
                        .map((line) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(line.product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                '৳${line.product.sellingPrice.toStringAsFixed(2)} each'),
                            trailing:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(
                                  onPressed: () => setState(() {
                                        line.quantity--;
                                        if (line.quantity <= 0)
                                          _cart.remove(line.product.id);
                                      }),
                                  icon:
                                      const Icon(Icons.remove_circle_outline)),
                              Text('${line.quantity}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              IconButton(
                                  onPressed: () => _addProduct(line.product),
                                  icon: const Icon(Icons.add_circle_outline)),
                              Text('৳${line.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700))
                            ])))
                        .toList())),
        TextField(
            controller: _discountController,
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Discount (BDT)',
                prefixIcon: Icon(Icons.sell_outlined),
                isDense: true)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
            initialValue: _payment,
            decoration: const InputDecoration(
                labelText: 'Payment method', isDense: true),
            items: const [
              DropdownMenuItem(value: 'cash', child: Text('Cash')),
              DropdownMenuItem(value: 'card', child: Text('Card')),
              DropdownMenuItem(value: 'mobile', child: Text('Mobile payment'))
            ],
            onChanged: (v) => setState(() => _payment = v ?? 'cash')),
        const SizedBox(height: 10),
        Row(children: [
          const Expanded(
              child:
                  Text('Subtotal', style: TextStyle(color: Color(0xFF748295)))),
          Text('৳${_subtotal.toStringAsFixed(2)}')
        ]),
        const SizedBox(height: 6),
        Row(children: [
          const Expanded(
              child: Text('Total due',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
          Text(
              '৳${(_subtotal - _discount).clamp(0, double.infinity).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))
        ]),
        const SizedBox(height: 12),
        SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
                onPressed: _cart.isEmpty || _processing ? null : _checkout,
                icon: _processing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.point_of_sale_rounded),
                label: Text(_processing ? 'Processing…' : 'Complete sale'),
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF182535),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15)))),
      ]));
}
