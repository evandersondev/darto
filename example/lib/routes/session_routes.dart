import 'package:darto/darto.dart';

void sessionRoutes(Darto app) {
  app.use(
    session(
      SessionOptions(
        secret: 'seu-segredo-super-secreto',
        maxAge: 30,
        httpOnly: true,
        secure: false,
      ),
    ),
  );

  app.post('/login', (Request req, Response res) async {
    final body = await req.body;

    if (body['username'] == 'admin' && body['password'] == '123') {
      req.session['user'] = {'id': 1, 'username': 'admin'};
      req.session.save();
      res.json({'message': 'Login bem-sucedido'});
    } else {
      res.status(401).json({'message': 'Credenciais inválidas'});
    }
  });

  app.get('/protected', (Request req, Response res) {
    final user = req.session.get('user');

    if (user != null) {
      res.json({'message': 'Acesso concedido', 'user': user});
    } else {
      res.status(401).json({'message': 'Não autenticado'});
    }
  });

  app.post('/logout', (Request req, Response res) {
    req.session.destroy(() {
      res.json({'message': 'Logout bem-sucedido'});
    });
  });
}
