import 'package:darto/darto.dart';

void sessionRoutes(Darto app) {
  app.use(
    session(
      SessionOptions(
        secret: 'seu-segredo-super-secreto',
        maxAge: 30, // 1 hora para evitar expiração durante testes
        httpOnly: true,
        secure: false,
      ),
    ),
  );

  // Rota de login
  app.post('/login', (Request req, Response res) async {
    final body = await req.body;
    print('Login body: $body'); // Log de depuração
    if (body['username'] == 'admin' && body['password'] == '123') {
      req.session['user'] = {'id': 1, 'username': 'admin'};
      print('Session after login: ${req.session}'); // Log de depuração
      res.json({'message': 'Login bem-sucedido'});
    } else {
      res.status(401).json({'message': 'Credenciais inválidas'});
    }
  });

  // Rota protegida
  app.get('/protected', (Request req, Response res) {
    print('Protected route session: ${req.session}'); // Log de depuração
    if (req.session['user'] != null) {
      res.json({'message': 'Acesso concedido', 'user': req.session['user']});
    } else {
      res.status(401).json({'message': 'Não autenticado'});
    }
  });

  // Rota de logout
  app.post('/logout', (Request req, Response res) {
    print('Logout session before destroy: ${req.session}'); // Log de depuração
    res.json({'message': 'Logout bem-sucedido'});
  });
}
