import 'package:darto/darto.dart';

import './routes.dart';

void main() async {
  final app = Darto();

  app.useCors(origin: '*');

  // Middleware global
  // app.use((req, res, next) async {
  //   print('🔹 Nova requisição: ${req.method} ${req.uri}');
  //   await next();
  // });

  // Usa o roteador importado
  app.use(createRouter());
  app.serveStatic('public');

  app.get('/todos/:id', (Request req, Response res) async {
    final id = req.params['id'];
    final todo = {'id': id, 'title': 'Sample Todo', 'completed': false};
    res.status(OK).send(todo);
  });

  app.get('/download', (Request req, Response res) async {
    final filePath = 'test.pdf';
    print(req.baseUrl);
    print(await req.body);
    print(req.cookies);
    print(req.hostname);
    print(req.host);
    print(req.method);

    res.download(filePath);
  });

  app.listen(3000, () {
    print('🚀 Servidor rodando em http://localhost:3000');
  });
}
