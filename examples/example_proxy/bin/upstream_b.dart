// Upstream B — "products" service on port 4002
import 'package:darto/darto.dart';
import 'package:darto/logger.dart';

void main() async {
  final app = Darto();
  app.use(logger());

  final products = <Map<String, dynamic>>[
    {'id': '1', 'name': 'Keyboard', 'price': 199.90},
    {'id': '2', 'name': 'Mouse', 'price': 89.90},
  ];

  app.get('/api/products', [], (c) => c.ok(products));

  app.get('/api/products/:id', [], (c) {
    final id = c.req.param('id');
    final product = products.firstWhere(
      (p) => p['id'] == id,
      orElse: () => {},
    );
    return product.isEmpty
        ? c.notFound({'error': 'Product not found'})
        : c.ok(product);
  });

  await app.listen(4002, () => print('Upstream B (products) on http://localhost:4002'));
}
