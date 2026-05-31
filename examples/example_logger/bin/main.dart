import 'package:darto/darto.dart';
import 'package:darto/request_id.dart';
import 'package:darto_logger/darto_logger.dart';

void main() async {
  // Structured logger — pretty output in dev, switch `pretty: false` for JSON.
  final log = Logger(minLevel: LogLevel.debug, pretty: true);

  final app = Darto();

  // requestId() stamps each request with an X-Request-Id; requestLogger()
  // logs method/path/status/duration and correlates them by that id.
  app.use(requestId());
  app.use(requestLogger(log));

  app.get('/', [], (Context c) => c.ok({'message': 'Home'}));

  app.get('/users/:id', [], (Context c) {
    // A child logger carries extra fields on every line it writes.
    final reqLog = log.child({'route': 'users.show'});
    reqLog.debug('looking up user', {'id': c.req.param('id')});
    return c.ok({'id': c.req.param('id')});
  });

  app.post('/users', [], (Context c) async {
    final body = await c.req.json();
    log.info('user created', {'email': body['email']});
    return c.created({'created': body});
  });

  app.get('/boom', [], (Context c) {
    log.error('something went wrong', error: StateError('demo failure'));
    return c.internalError({'error': 'demo'});
  });

  await app.listen(3000, () => log.info('listening', {'port': 3000}));
}
