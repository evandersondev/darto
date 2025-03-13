import 'package:darto/darto.dart';

Router createRouter() {
  final router = Router();

  router.get('/', (req, res) async {
    res.send({'message': 'Bem-vindo ao Darto!'});
  });

  router.get('/user/:id', (Request req, Response res) async {
    final id = req.params['id'];
    print('🔹 Handler executado para /user/$id'); // Log de depuração

    // Simulação de busca de usuário no banco de dados
    final user = {'id': id, 'name': 'Sample User', 'email': 'user@example.com'};

    print('🔹 Enviando resposta: $user'); // Log de depuração
    res.send(user);
  });

  router.get('/search', (req, res) async {
    final name = req.query['name'] ?? 'Desconhecido';
    res.send({'message': 'Buscando usuário', 'name': name});
  });

  return router;
}
