import 'package:postgres/postgres.dart';
import 'package:uuid/uuid.dart';

import '../../models/pos_product.dart';
import '../db/postgres_db.dart';

class PosRepository {
  static const _uuid = Uuid();

  Future<void> ensureSchema() async {
    final pool = await PostgresDb.instance.pool;
    await pool.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        business_id UUID NOT NULL REFERENCES users(id),
        barcode VARCHAR(100) NOT NULL,
        name VARCHAR(160) NOT NULL,
        category VARCHAR(100) NOT NULL DEFAULT 'General',
        cost_price NUMERIC(12,2) NOT NULL CHECK (cost_price >= 0),
        selling_price NUMERIC(12,2) NOT NULL CHECK (selling_price >= 0),
        stock_quantity INTEGER NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
        reorder_level INTEGER NOT NULL DEFAULT 5 CHECK (reorder_level >= 0),
        active BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        UNIQUE (business_id, barcode)
      )
    ''');
    await pool.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        business_id UUID NOT NULL REFERENCES users(id),
        cashier_id UUID NOT NULL REFERENCES users(id),
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        subtotal NUMERIC(12,2) NOT NULL CHECK (subtotal >= 0),
        discount NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (discount >= 0),
        total NUMERIC(12,2) NOT NULL CHECK (total >= 0),
        total_cost NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total_cost >= 0),
        net_profit NUMERIC(12,2) NOT NULL DEFAULT 0,
        payment_method VARCHAR(20) NOT NULL DEFAULT 'cash'
      )
    ''');
    await pool.execute('''
      CREATE TABLE IF NOT EXISTS sale_items (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        sale_id UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
        product_id UUID NOT NULL REFERENCES products(id),
        product_name VARCHAR(160) NOT NULL,
        barcode VARCHAR(100) NOT NULL,
        quantity INTEGER NOT NULL CHECK (quantity > 0),
        cost_price NUMERIC(12,2) NOT NULL,
        selling_price NUMERIC(12,2) NOT NULL,
        line_discount NUMERIC(12,2) NOT NULL DEFAULT 0,
        line_total NUMERIC(12,2) NOT NULL
      )
    ''');
    await pool.execute('''
      CREATE TABLE IF NOT EXISTS inventory_movements (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        business_id UUID NOT NULL REFERENCES users(id),
        product_id UUID NOT NULL REFERENCES products(id),
        actor_id UUID NOT NULL REFERENCES users(id),
        sale_id UUID REFERENCES sales(id) ON DELETE SET NULL,
        movement_type VARCHAR(20) NOT NULL CHECK (movement_type IN ('opening', 'purchase_in', 'sale_out')),
        quantity INTEGER NOT NULL CHECK (quantity > 0),
        note TEXT,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    ''');
    await pool.execute(
        'CREATE INDEX IF NOT EXISTS idx_sales_business_created_at ON sales(business_id, created_at DESC)');
    await pool.execute(
        'CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id ON sale_items(sale_id)');
    await pool.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_business_active_name ON products(business_id, active, name)');
  }

  Future<PosProduct?> findByBarcode(String barcode,
      {required String businessId}) async {
    final pool = await PostgresDb.instance.pool;
    final rows = await pool.execute(
      Sql.named(
          'SELECT * FROM products WHERE business_id = @business AND barcode = @barcode AND active = TRUE'),
      parameters: {'business': businessId, 'barcode': barcode.trim()},
    );
    return rows.isEmpty ? null : PosProduct.fromRow(rows.first.toColumnMap());
  }

  Future<List<PosProduct>> getProducts(
      {required String businessId, String search = ''}) async {
    final pool = await PostgresDb.instance.pool;
    final rows = await pool.execute(
      Sql.named('''
        SELECT * FROM products WHERE business_id = @business AND active = TRUE
          AND (@search = '' OR name ILIKE @pattern OR barcode ILIKE @pattern)
        ORDER BY name LIMIT 300
      '''),
      parameters: {
        'business': businessId,
        'search': search.trim(),
        'pattern': '%${search.trim()}%'
      },
    );
    return rows.map((r) => PosProduct.fromRow(r.toColumnMap())).toList();
  }

  Future<void> addProduct({
    required String actorId,
    required String businessId,
    required String barcode,
    required String name,
    required String category,
    required double costPrice,
    required double sellingPrice,
    required int stock,
    required int reorderLevel,
  }) async {
    final pool = await PostgresDb.instance.pool;
    final productId = _uuid.v4();
    await pool.runTx((tx) async {
      await tx.execute(
        Sql.named('''
        INSERT INTO products
          (id, business_id, barcode, name, category, cost_price, selling_price, stock_quantity, reorder_level)
        VALUES (@id, @business, @barcode, @name, @category, @cost, @price, @stock, @reorder)
      '''),
        parameters: {
          'id': productId,
          'business': businessId,
          'barcode': barcode.trim(),
          'name': name.trim(),
          'category': category.trim().isEmpty ? 'General' : category.trim(),
          'cost': costPrice,
          'price': sellingPrice,
          'stock': stock,
          'reorder': reorderLevel,
        },
      );
      if (stock > 0) {
        await tx.execute(
          Sql.named(
              '''INSERT INTO inventory_movements (business_id, product_id, actor_id, movement_type, quantity, note)
            VALUES (@business, @product, @actor, 'opening', @quantity, 'Opening stock')'''),
          parameters: {
            'business': businessId,
            'product': productId,
            'actor': actorId,
            'quantity': stock
          },
        );
      }
    });
  }

  Future<void> receiveStock(
      {required String productId,
      required String actorId,
      required String businessId,
      required int quantity}) async {
    if (quantity <= 0) throw ArgumentError.value(quantity, 'quantity');
    final pool = await PostgresDb.instance.pool;
    await pool.runTx((tx) async {
      final result = await tx.execute(
        Sql.named('''
          UPDATE products SET stock_quantity = stock_quantity + @quantity, updated_at = NOW()
          WHERE id = @id AND business_id = @business AND active = TRUE
        '''),
        parameters: {
          'quantity': quantity,
          'id': productId,
          'business': businessId
        },
      );
      if (result.affectedRows == 0) throw StateError('Product not found.');
      await tx.execute(
        Sql.named(
            '''INSERT INTO inventory_movements (business_id, product_id, actor_id, movement_type, quantity)
          VALUES (@business, @product, @actor, 'purchase_in', @quantity)'''),
        parameters: {
          'business': businessId,
          'product': productId,
          'actor': actorId,
          'quantity': quantity
        },
      );
    });
  }

  Future<PosDashboardSummary> getSummary({required String businessId}) async {
    final pool = await PostgresDb.instance.pool;
    final headline = await pool.execute(Sql.named('''
      SELECT
        COALESCE((SELECT SUM(total) FROM sales WHERE business_id = @business AND created_at >= CURRENT_DATE), 0) AS sales_today,
        (SELECT COUNT(*) FROM sales WHERE business_id = @business AND created_at >= CURRENT_DATE) AS orders_today,
        (SELECT COUNT(*) FROM products WHERE business_id = @business AND active = TRUE AND stock_quantity <= reorder_level) AS low_stock,
        (SELECT COUNT(*) FROM products WHERE business_id = @business AND active = TRUE) AS product_count,
        COALESCE((SELECT SUM(discount) FROM sales WHERE business_id = @business AND created_at >= CURRENT_DATE), 0) AS discount_today,
        COALESCE((SELECT SUM(net_profit) FROM sales WHERE business_id = @business AND created_at >= CURRENT_DATE), 0) AS profit_today
    '''), parameters: {'business': businessId});
    final row = headline.first.toColumnMap();
    final tops = await pool.execute(Sql.named('''
      SELECT product_name, SUM(quantity)::INTEGER AS units
      FROM sale_items i JOIN sales s ON s.id = i.sale_id
      WHERE s.business_id = @business AND s.created_at >= CURRENT_DATE
      GROUP BY product_name ORDER BY units DESC LIMIT 5
    '''), parameters: {'business': businessId});
    final low = await pool.execute(Sql.named('''
      SELECT * FROM products WHERE business_id = @business AND active = TRUE AND stock_quantity <= reorder_level
      ORDER BY stock_quantity ASC, name LIMIT 6
    '''), parameters: {'business': businessId});
    return PosDashboardSummary(
      salesToday: (row['sales_today'] as num).toDouble(),
      ordersToday: (row['orders_today'] as num).toInt(),
      lowStockCount: (row['low_stock'] as num).toInt(),
      productCount: (row['product_count'] as num).toInt(),
      discountToday: (row['discount_today'] as num).toDouble(),
      profitToday: (row['profit_today'] as num).toDouble(),
      topProducts: tops.map((r) => r.toColumnMap()).toList(),
      lowStockProducts:
          low.map((r) => PosProduct.fromRow(r.toColumnMap())).toList(),
    );
  }

  Future<String> completeSale({
    required String cashierId,
    required String businessId,
    required List<PosCartLine> lines,
    required double discount,
    required String paymentMethod,
  }) async {
    if (lines.isEmpty) throw StateError('The cart is empty.');
    final pool = await PostgresDb.instance.pool;
    final saleId = _uuid.v4();
    await pool.runTx((tx) async {
      final quantities = <String, int>{};
      final products = <String, PosProduct>{};
      for (final line in lines) {
        quantities.update(
            line.product.id, (quantity) => quantity + line.quantity,
            ifAbsent: () => line.quantity);
        products[line.product.id] = line.product;
      }
      final snapshots = <String, Map<String, dynamic>>{};
      var subtotal = 0.0;
      var totalCost = 0.0;
      final sortedIds = quantities.keys.toList()..sort();
      for (final productId in sortedIds) {
        final locked = await tx.execute(
          Sql.named(
              'SELECT stock_quantity, cost_price, selling_price FROM products WHERE id = @id AND business_id = @business AND active = TRUE FOR UPDATE'),
          parameters: {'id': productId, 'business': businessId},
        );
        if (locked.isEmpty ||
            (locked.first.toColumnMap()['stock_quantity'] as int) <
                quantities[productId]!) {
          throw StateError(
              'Not enough stock for ${products[productId]!.name}.');
        }
        final details = locked.first.toColumnMap();
        snapshots[productId] = details;
        subtotal += (details['selling_price'] as num).toDouble() *
            quantities[productId]!;
        totalCost +=
            (details['cost_price'] as num).toDouble() * quantities[productId]!;
      }
      if (discount < 0 || discount > subtotal) {
        throw StateError('Discount must be between 0 and the subtotal.');
      }
      final total = subtotal - discount;
      await tx.execute(
        Sql.named('''
          INSERT INTO sales (id, business_id, cashier_id, subtotal, discount, total, total_cost, net_profit, payment_method)
          VALUES (@id, @business, @cashier, @subtotal, @discount, @total, @cost, @profit, @method)
        '''),
        parameters: {
          'id': saleId,
          'business': businessId,
          'cashier': cashierId,
          'subtotal': subtotal,
          'discount': discount,
          'total': total,
          'cost': totalCost,
          'profit': total - totalCost,
          'method': paymentMethod,
        },
      );
      for (final productId in sortedIds) {
        final product = products[productId]!;
        final quantity = quantities[productId]!;
        final cost = (snapshots[productId]!['cost_price'] as num).toDouble();
        final sellingPrice =
            (snapshots[productId]!['selling_price'] as num).toDouble();
        final lineTotal = sellingPrice * quantity;
        final lineDiscount =
            subtotal == 0 ? 0 : discount * lineTotal / subtotal;
        await tx.execute(
          Sql.named(
              'UPDATE products SET stock_quantity = stock_quantity - @qty, updated_at = NOW() WHERE id = @id AND business_id = @business'),
          parameters: {
            'qty': quantity,
            'id': productId,
            'business': businessId
          },
        );
        await tx.execute(
          Sql.named(
              '''INSERT INTO inventory_movements (business_id, product_id, actor_id, sale_id, movement_type, quantity)
            VALUES (@business, @product, @actor, @sale, 'sale_out', @quantity)'''),
          parameters: {
            'business': businessId,
            'product': productId,
            'actor': cashierId,
            'sale': saleId,
            'quantity': quantity
          },
        );
        await tx.execute(
          Sql.named('''
            INSERT INTO sale_items
              (sale_id, product_id, product_name, barcode, quantity, cost_price, selling_price, line_discount, line_total)
            VALUES (@sale, @product, @name, @barcode, @qty, @cost, @price, @discount, @lineTotal)
          '''),
          parameters: {
            'sale': saleId,
            'product': productId,
            'name': product.name,
            'barcode': product.barcode,
            'qty': quantity,
            'cost': cost,
            'price': sellingPrice,
            'discount': lineDiscount,
            'lineTotal': lineTotal - lineDiscount,
          },
        );
      }
    });
    return saleId;
  }
}
