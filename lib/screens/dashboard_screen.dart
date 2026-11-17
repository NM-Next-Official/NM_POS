import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pos_product.dart';
import '../providers/auth_provider.dart';
import '../services/pos/pos_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen(
      {super.key, required this.onSell, required this.onInventory});
  final VoidCallback onSell;
  final VoidCallback onInventory;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _repository = PosRepository();
  late Future<PosDashboardSummary> _summary;

  @override
  void initState() {
    super.initState();
    _summary = _repository.getSummary(
        businessId: context.read<AuthProvider>().user!.id);
  }

  Future<void> _refresh() async {
    final request = _repository.getSummary(
        businessId: context.read<AuthProvider>().user!.id);
    setState(() {
      _summary = request;
    });
    await request;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return FutureBuilder<PosDashboardSummary>(
      future: _summary,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _PagePadding(
              child: _ErrorPanel(
                  message:
                      'Could not load dashboard data. Check your PostgreSQL connection and run the POS schema setup.',
                  onRetry: _refresh));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _ink));
        }
        final data = snapshot.data!;
        return RefreshIndicator(
          color: _ink,
          onRefresh: _refresh,
          child: _PagePadding(
            child: ListView(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(
                              'Good ${_greeting()}, ${user?.firstName ?? 'there'}',
                              style:
                                  const TextStyle(color: _muted, fontSize: 14)),
                          const SizedBox(height: 5),
                          const Text('Business overview',
                              style: TextStyle(
                                  color: _ink,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800)),
                        ])),
                    FilledButton.icon(
                        onPressed: widget.onSell,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('New sale'),
                        style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE4EAF2),
                            foregroundColor: const Color(0xFF06111E),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 16))),
                  ],
                ),
                const SizedBox(height: 24),
                Wrap(spacing: 14, runSpacing: 14, children: [
                  _MetricCard(
                      label: "Today's sales",
                      value: '৳${data.salesToday.toStringAsFixed(2)}',
                      icon: Icons.trending_up_rounded,
                      tone: const Color(0xFF1F8B68),
                      wide: wide),
                  _MetricCard(
                      label: 'Orders today',
                      value: '${data.ordersToday}',
                      icon: Icons.receipt_long_outlined,
                      tone: const Color(0xFF3B6FC4),
                      wide: wide),
                  _MetricCard(
                      label: 'Products',
                      value: '${data.productCount}',
                      icon: Icons.inventory_2_outlined,
                      tone: const Color(0xFF8C63C7),
                      wide: wide),
                  _MetricCard(
                      label: 'Low stock',
                      value: '${data.lowStockCount}',
                      icon: Icons.warning_amber_rounded,
                      tone: const Color(0xFFD68828),
                      wide: wide),
                  _MetricCard(
                      label: 'Net profit today',
                      value: '৳${data.profitToday.toStringAsFixed(2)}',
                      icon: Icons.account_balance_wallet_outlined,
                      tone: const Color(0xFF27877F),
                      wide: wide),
                ]),
                const SizedBox(height: 22),
                if (data.productCount == 0)
                  _EmptyInventory(onAdd: widget.onInventory)
                else
                  LayoutBuilder(builder: (context, constraints) {
                    final twoColumns = constraints.maxWidth > 760;
                    final top = _ContentCard(
                        title: 'Top products today',
                        subtitle: 'Units sold',
                        child: data.topProducts.isEmpty
                            ? const _QuietEmpty(
                                'Sales will appear here once a checkout is completed.')
                            : Column(children: [
                                for (var i = 0;
                                    i < data.topProducts.length;
                                    i++)
                                  _RankRow(
                                      rank: i + 1,
                                      name: data.topProducts[i]['product_name']
                                          .toString(),
                                      value:
                                          '${data.topProducts[i]['units']} sold')
                              ]));
                    final low = _ContentCard(
                        title: 'Needs restocking',
                        subtitle: '${data.lowStockCount} at or below minimum',
                        child: data.lowStockProducts.isEmpty
                            ? const _QuietEmpty('Stock levels are healthy.')
                            : Column(children: [
                                for (final product in data.lowStockProducts)
                                  _StockRow(product: product)
                              ]));
                    return twoColumns
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Expanded(child: top),
                                const SizedBox(width: 16),
                                Expanded(child: low)
                              ])
                        : Column(
                            children: [top, const SizedBox(height: 16), low]);
                  }),
                const SizedBox(height: 20),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                        'Discounts today  ·  ৳${data.discountToday.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: _muted, fontWeight: FontWeight.w600))),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

const _ink = Color(0xFFE4EAF2);
const _muted = Color(0xFF9AABBB);
const _line = Color(0xFF223548);

class _PagePadding extends StatelessWidget {
  const _PagePadding({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
      color: const Color(0xFF030D19),
      child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 12), child: child));
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.tone,
      required this.wide});
  final String label, value;
  final IconData icon;
  final Color tone;
  final bool wide;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: wide
          ? (MediaQuery.sizeOf(context).width - 140) / 4
          : (MediaQuery.sizeOf(context).width - 90) / 2,
      child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: const Color(0xFF0D1A29),
              border: Border.all(color: _line),
              borderRadius: BorderRadius.circular(18)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: tone.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: tone, size: 20)),
            const SizedBox(height: 18),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: _ink, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: _muted, fontSize: 13, fontWeight: FontWeight.w500))
          ])));
}

class _ContentCard extends StatelessWidget {
  const _ContentCard(
      {required this.title, required this.subtitle, required this.child});
  final String title, subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF0D1A29),
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                color: _ink, fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
        const SizedBox(height: 16),
        child
      ]));
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rank, required this.name, required this.value});
  final int rank;
  final String name, value;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: const Color(0xFF192A3C),
                borderRadius: BorderRadius.circular(9)),
            child: Text('$rank',
                style: const TextStyle(
                    color: _muted, fontWeight: FontWeight.w700))),
        const SizedBox(width: 10),
        Expanded(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(color: _ink, fontWeight: FontWeight.w600))),
        Text(value, style: const TextStyle(color: _muted, fontSize: 12))
      ]));
}

class _StockRow extends StatelessWidget {
  const _StockRow({required this.product});
  final PosProduct product;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w600)),
          Text('Minimum ${product.reorderLevel}',
              style: const TextStyle(color: _muted, fontSize: 11))
        ])),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0xFFFFF3E3),
                borderRadius: BorderRadius.circular(20)),
            child: Text('${product.stock} left',
                style: const TextStyle(
                    color: Color(0xFFAD6714),
                    fontWeight: FontWeight.w700,
                    fontSize: 12)))
      ]));
}

class _QuietEmpty extends StatelessWidget {
  const _QuietEmpty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(color: _muted, height: 1.5));
}

class _EmptyInventory extends StatelessWidget {
  const _EmptyInventory({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
          color: const Color(0xFF0D1A29),
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.inventory_2_outlined, color: _ink, size: 32),
        const SizedBox(height: 12),
        const Text('Your product catalog is ready',
            style: TextStyle(
                color: _ink, fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 6),
        const Text(
            'Add products with a barcode, cost, selling price and opening stock to start using the scanner and POS.',
            style: TextStyle(color: _muted, height: 1.45)),
        const SizedBox(height: 16),
        OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add first product'))
      ]));
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
      child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 42, color: _muted),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _ink, height: 1.4)),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry'))
          ])));
}
