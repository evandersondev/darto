import 'package:darto/darto.dart';
import 'package:darto/logger.dart';

void main() {
  final app = Darto();

  // Global logger middleware — logs every request
  app.use(logger());

  app.get('/', [], (Context c) => c.ok({'message': 'Home'}));
  app.get('/users', [], (Context c) => c.ok({'users': ['Alice', 'Bob']}));
  app.get('/users/:id', [], (Context c) => c.ok({'id': c.req.param('id')}));
  app.post('/users', [], (Context c) async {
    final body = await c.req.json();
    return c.created({'created': body});
  });

  app.listen(3000, () => print('Logger server running on port 3000'));
}
