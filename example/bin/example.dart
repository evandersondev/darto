import 'package:darto/darto.dart';

import './routes.dart';

void main() async {
  final app = Darto();

  app.useCors(origin: '*');

  // Middleware global
  app.use((req, res, next) async {
    print('🔹 Nova requisição: ${req.method} ${req.uri}');
    await next();
  });

  // Usa o roteador importado
  app.use(createRouter());

  app.serveStatic('public');

  app.get('/todos/:id', (Request req, Response res) async {
    final id = req.params['id'];
    print('🔹 Handler executado para /todos/$id'); // Log de depuração
    // Simulação de busca de item no banco de dados
    final todo = {'id': id, 'title': 'Sample Todo', 'completed': false};
    print('🔹 Enviando resposta: $todo'); // Log de depuração
    res.send(todo);
  });

  app.listen(3000, () {
    print('🚀 Servidor rodando em http://localhost:3000');
  });
}
