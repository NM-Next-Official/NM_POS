class PosProduct {
  const PosProduct({
    required this.id,
    required this.barcode,
    required this.name,
    required this.category,
    required this.costPrice,
    required this.sellingPrice,
    required this.stock,
    required this.reorderLevel,
  });

  final String id;
  final String barcode;
  final String name;
  final String category;
  final double costPrice;
  final double sellingPrice;
  final int stock;
  final int reorderLevel;

  factory PosProduct.fromRow(Map<String, dynamic> row) => PosProduct(
        id: row['id'].toString(),
        barcode: row['barcode'] as String,
        name: row['name'] as String,
        category: (row['category'] as String?) ?? 'General',
        costPrice: (row['cost_price'] as num).toDouble(),
        sellingPrice: (row['selling_price'] as num).toDouble(),
        stock: row['stock_quantity'] as int,
        reorderLevel: row['reorder_level'] as int,
      );
}

class PosCartLine {
  PosCartLine({required this.product, this.quantity = 1});

  final PosProduct product;
  int quantity;
  double get total => product.sellingPrice * quantity;
}

class PosDashboardSummary {
  const PosDashboardSummary({
    required this.salesToday,
    required this.ordersToday,
    required this.lowStockCount,
    required this.productCount,
    required this.discountToday,
    required this.profitToday,
    required this.topProducts,
    required this.lowStockProducts,
  });

  final double salesToday;
  final int ordersToday;
  final int lowStockCount;
  final int productCount;
  final double discountToday;
  final double profitToday;
  final List<Map<String, dynamic>> topProducts;
  final List<PosProduct> lowStockProducts;
}
