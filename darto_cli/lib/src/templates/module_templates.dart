/// Templates for `darto g module|controller|service <name>`.
library;

import '../utils.dart';

// ─── controller (includes route registration) ─────────────────────────────────

String controllerTemplate(String name) {
  final pascal = toPascalCase(name);
  final snake = toSnakeCase(name);
  final camel = toCamelCase(name);
  return '''
import 'package:darto/darto.dart';

import '${snake}_service.dart';

class ${pascal}Controller {
  final _service = ${pascal}Service();

  Handler get findAll => (Context c) async {
        final items = await _service.findAll();
        return c.ok(items);
      };

  Handler get findOne => (Context c) async {
        final id = c.req.param('id')!;
        final item = await _service.findOne(id);
        if (item == null) return c.notFound({'error': '$pascal not found'});
        return c.ok(item);
      };

  Handler get create => (Context c) async {
        final body = await c.req.json();
        final item = await _service.create(body);
        return c.created(item);
      };

  Handler get update => (Context c) async {
        final id = c.req.param('id')!;
        final body = await c.req.json();
        final item = await _service.update(id, body);
        if (item == null) return c.notFound({'error': '$pascal not found'});
        return c.ok(item);
      };

  Handler get delete => (Context c) async {
        final id = c.req.param('id')!;
        await _service.delete(id);
        return c.noContent();
      };
}

void ${camel}Router(Router router) {
  final ctrl = ${pascal}Controller();

  router.get('/', [], ctrl.findAll);
  router.get('/:id', [], ctrl.findOne);
  router.post('/', [], ctrl.create);
  router.put('/:id', [], ctrl.update);
  router.delete('/:id', [], ctrl.delete);
}
''';
}

// ─── service (business logic — swap _store for a real DB adapter) ─────────────

String serviceTemplate(String name) {
  final pascal = toPascalCase(name);
  return '''
class ${pascal}Service {
  final _store = <Map<String, dynamic>>[];
  int _seq = 1;

  Future<List<Map<String, dynamic>>> findAll() async =>
      List.unmodifiable(_store);

  Future<Map<String, dynamic>?> findOne(String id) async {
    try {
      return _store.firstWhere((e) => e['id'].toString() == id);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final record = {'id': _seq++, ...data};
    _store.add(record);
    return record;
  }

  Future<Map<String, dynamic>?> update(
      String id, Map<String, dynamic> data) async {
    final i = _store.indexWhere((e) => e['id'].toString() == id);
    if (i == -1) return null;
    _store[i] = {..._store[i], ...data};
    return _store[i];
  }

  Future<void> delete(String id) async =>
      _store.removeWhere((e) => e['id'].toString() == id);
}
''';
}
