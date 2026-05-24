import 'package:darto/darto.dart';

void main() {
  final app = Darto();

  app.get('/json',        [], (Context c) => c.json({'type': 'json', 'value': 42}));
  app.get('/text',        [], (Context c) => c.text('Hello, plain text!'));
  app.get('/html',        [], (Context c) => c.html('<h1>Hello, HTML!</h1>'));
  app.get('/ok',          [], (Context c) => c.ok({'status': 'OK'}));
  app.get('/created',     [], (Context c) => c.created({'id': 1, 'created': true}));
  app.get('/no-content',  [], (Context c) => c.noContent());
  app.get('/bad-request', [], (Context c) => c.badRequest({'error': 'Bad input'}));
  app.get('/not-found',   [], (Context c) => c.notFound({'error': 'Resource missing'}));
  app.get('/conflict',    [], (Context c) => c.conflict({'error': 'Already exists'}));
  app.get('/unauthorized',[], (Context c) => c.unauthorized({'error': 'Login required'}));
  app.get('/forbidden',   [], (Context c) => c.forbidden({'error': 'Access denied'}));
  app.get('/internal',    [], (Context c) => c.internalError({'error': 'Unexpected error'}));
  app.get('/status-custom',[], (Context c) => c.status(418).json({'error': "I'm a teapot"}));
  app.get('/redirect',    [], (Context c) => c.redirect('/ok'));

  app.listen(3000, () => print('Response helpers server running on port 3000'));
}
