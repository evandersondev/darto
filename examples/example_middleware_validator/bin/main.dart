import 'package:darto/darto.dart';
import 'package:darto_validator/darto_validator.dart';

// ── Schemas ───────────────────────────────────────────────────────────────────

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

void main() {
  final app = Darto();

  app.onError((err, c) => c.internalError({'error': err.toString()}));

  // POST /users — validates JSON body, retrieve with c.req.valid('json')
  app.post('/users', [zValidator('json', userSchema)], (Context c) {
    final data = c.req.valid<Map<String, dynamic>>('json');
    return c.created({'user': data});
  });

  // GET /search?q=... — validates query params
  app.get('/search', [zValidator('query', searchSchema)], (Context c) {
    final query = c.req.valid<Map<String, dynamic>>('query');
    return c.ok({'results': [], 'query': query['q']});
  });

  // GET /posts/:id — validates route params
  app.get('/posts/:id', [zValidator('param', postParamSchema)], (Context c) {
    final params = c.req.valid<Map<String, dynamic>>('param');
    return c.ok({'post': params['id']});
  });

  // POST /items — custom error via hook (422 instead of 400)
  app.post('/items', [
    zValidator('json', userSchema, (ZardResult result, c) {
      if (!result.success) {
        return c.status(422).json({
          'message': 'Unprocessable entity',
          'issues': result.error?.format(),
        });
      }
      return null;
    }),
  ], (Context c) {
    final data = c.req.valid<Map<String, dynamic>>('json');
    return c.created({'item': data});
  });

  app.listen(3000, () => print('Validation server running on port 3000'));
}
