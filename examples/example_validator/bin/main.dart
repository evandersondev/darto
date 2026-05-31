// validator() is a core Darto middleware — bring your own validation library.
// Here we use zard (via darto_validator) as the schema engine.
//
// The key difference from zValidator():
//   zValidator() → automatic 400 + optional hook
//   validator()  → you return any Response with any status code
import 'package:darto/darto.dart';
import 'package:darto/validator.dart';
import 'package:zard/zard.dart';

// ── Schemas (zard) ────────────────────────────────────────────────────────────

final userSchema = z.map({
  'name': z.string().min(1),
  'email': z.string().email(),
  'age': z.int().min(0).max(150),
});

final searchSchema = z.map({
  'q': z.string().min(1),
});

final postParamSchema = z.map({
  'id': z.string().min(1),
});

final loginSchema = z.map({
  'email': z.string().email(),
  'password': z.string().min(6),
});

// ── App ───────────────────────────────────────────────────────────────────────

void main() {
  final app = Darto();

  app.onError((err, c) => c.internalError({'error': err.toString()}));

  // POST /users — 400 on failure (you choose the format)
  app.post('/users', [
    validator('json', (value, c) {
      final result = userSchema.safeParse(value);
      if (!result.success)
        return c.badRequest({'errors': result.error?.format()});
      return result.data; // stored → retrieve with c.req.valid('json')
    }),
  ], (Context c) {
    final data = c.req.valid<Map<String, dynamic>>('json');
    return c.created({'user': data});
  });

  // GET /search?q=... — query param validation
  app.get('/search', [
    validator('query', (value, c) {
      final result = searchSchema.safeParse(value);
      if (!result.success)
        return c.badRequest({'errors': result.error?.format()});
      return result.data;
    }),
  ], (Context c) {
    final query = c.req.valid<Map<String, dynamic>>('query');
    return c.ok({'results': [], 'query': query['q']});
  });

  // GET /posts/:id — route param validation
  app.get('/posts/:id', [
    validator('param', (value, c) {
      final result = postParamSchema.safeParse(value);
      if (!result.success)
        return c.badRequest({'errors': result.error?.format()});
      return result.data;
    }),
  ], (Context c) {
    final params = c.req.valid<Map<String, dynamic>>('param');
    return c.ok({'post': params['id']});
  });

  // POST /login — 401 on failure (any status code, your call)
  app.post('/login', [
    validator('json', (value, c) {
      final result = loginSchema.safeParse(value);
      if (!result.success)
        return c.status(401).json({'errors': result.error?.format()});
      return result.data;
    }),
  ], (Context c) {
    final credentials = c.req.valid<Map<String, dynamic>>('json');
    return c.ok({'message': 'Welcome, ${credentials['email']}!'});
  });

  app.listen(
      3000, () => print('Validator example running on http://localhost:3000'));
}
