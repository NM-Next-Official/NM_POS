import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pos_product.dart';
import '../services/pos/pos_repository.dart';
import '../providers/auth_provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _repository = PosRepository();
  final _search = TextEditingController();
  Future<List<PosProduct>>? _products;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _load() {
    final request = _repository.getProducts(
        businessId: context.read<AuthProvider>().user!.id,
        search: _search.text);
    setState(() {
      _products = request;
    });
  }

  Future<void> _addProduct() async {
    final actorId = context.read<AuthProvider>().user!.id;
    final form = GlobalKey<FormState>();
    final barcode = TextEditingController();
    final name = TextEditingController();
    final category = TextEditingController(text: 'General');
    final cost = TextEditingController(text: '0.00');
    final price = TextEditingController(text: '0.00');
    final stock = TextEditingController(text: '0');
    final reorder = TextEditingController(text: '5');
    final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Add product'),
              content: SizedBox(
                  width: 440,
                  child: SingleChildScrollView(
                      child: Form(
                          key: form,
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            _input(barcode, 'Barcode / SKU'),
                            _input(name, 'Product name'),
                            _input(category, 'Category'),
                            Row(children: [
                              Expanded(
                                  child: _input(cost, 'Cost price',
                                      numeric: true)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: _input(price, 'Selling price',
                                      numeric: true))
                            ]),
                            Row(children: [
                              Expanded(
                                  child: _input(stock, 'Opening stock',
                                      numeric: true, integer: true)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: _input(reorder, 'Low stock at',
                                      numeric: true, integer: true))
                            ]),
                          ])))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () {
                      if (form.currentState!.validate())
                        Navigator.pop(ctx, true);
                    },
                    child: const Text('Save product'))
              ],
            ));
    if (result == true) {
      try {
        await _repository.addProduct(
            actorId: actorId,
            businessId: actorId,
            barcode: barcode.text,
            name: name.text,
            category: category.text,
            costPrice: double.parse(cost.text),
            sellingPrice: double.parse(price.text),
            stock: int.parse(stock.text),
            reorderLevel: int.parse(reorder.text));
        _load();
        _message('Product added.');
      } catch (_) {
        _message(
            'Could not add product. Check for a duplicate barcode or database issue.');
      }
    }
    for (final c in [barcode, name, category, cost, price, stock, reorder]) {
      c.dispose();
    }
  }

  Future<void> _receiveStock(PosProduct product) async {
    final actorId = context.read<AuthProvider>().user!.id;
    final quantity = TextEditingController();
    final form = GlobalKey<FormState>();
    final result = await showDialog<int>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text('Receive ${product.name}'),
              content: Form(
                  key: form,
                  child: TextFormField(
                      controller: quantity,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Quantity received'),
                      validator: (v) =>
                          int.tryParse(v ?? '') == null || int.parse(v!) <= 0
                              ? 'Enter a quantity above zero'
                              : null)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                FilledButton(
                    onPressed: () {
                      if (form.currentState!.validate())
                        Navigator.pop(ctx, int.parse(quantity.text));
                    },
                    child: const Text('Add stock'))
              ],
            ));
    quantity.dispose();
    if (result == null) return;
    try {
      await _repository.receiveStock(
          productId: product.id,
          actorId: actorId,
          businessId: actorId,
          quantity: result);
      _load();
      _message('Stock updated.');
    } catch (_) {
      _message('Could not update stock.');
    }
  }

  Widget _input(TextEditingController controller, String label,
          {bool numeric = false, bool integer = false}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextFormField(
              controller: controller,
              keyboardType: numeric
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              decoration: InputDecoration(
                  labelText: label, border: const OutlineInputBorder()),
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return 'Required';
                if (numeric &&
                    (double.tryParse(v) == null || double.parse(v) < 0))
                  return 'Enter a valid amount';
                if (integer && (int.tryParse(v) == null || int.parse(v) < 0))
                  return 'Enter a whole number';
                return null;
              }));

  void _message(String message) {
    if (!mounted) return;
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
                Text('Inventory',
                    style:
                        TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text('Products, prices and on-hand stock',
                    style: TextStyle(color: Color(0xFF748295)))
              ])),
          FilledButton.icon(
              onPressed: _addProduct,
              icon: const Icon(Icons.add),
              label: const Text('Add product'))
        ]),
        const SizedBox(height: 20),
        TextField(
            controller: _search,
            onChanged: (_) => _load(),
            decoration: InputDecoration(
                hintText: 'Search product or barcode',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none))),
        const SizedBox(height: 14),
        Expanded(
            child: FutureBuilder<List<PosProduct>>(
                future: _products,
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return const Center(
                        child: Text('Could not load inventory.'));
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  final items = snapshot.data!;
                  if (items.isEmpty)
                    return const Center(
                        child:
                            Text('No products yet. Add a product to begin.'));
                  return Card(
                      color: Colors.white,
                      child: ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final p = items[i];
                            return ListTile(
                                leading: Container(
                                    width: 40,
                                    height: 40,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFF0F3F7),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: const Icon(
                                        Icons.inventory_2_outlined,
                                        size: 20)),
                                title: Text(p.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                subtitle:
                                    Text('${p.barcode}  ·  ${p.category}'),
                                trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                                '৳${p.sellingPrice.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            Text('${p.stock} in stock',
                                                style: TextStyle(
                                                    color: p.stock <=
                                                            p.reorderLevel
                                                        ? Colors.deepOrange
                                                        : Colors.blueGrey,
                                                    fontSize: 12))
                                          ]),
                                      IconButton(
                                          tooltip: 'Receive stock',
                                          onPressed: () => _receiveStock(p),
                                          icon: const Icon(
                                              Icons.add_box_outlined))
                                    ]));
                          }));
                }))
      ]));
}
