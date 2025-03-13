import 'package:darto/darto.dart';

void main() async {
  final app = Darto();

  app.useCors(origin: '*');
  app.serveStatic('public');

  app.get('/todos/:id', (Request req, Response res) async {
    final id = req.params['id'];
    final todo = {'id': id, 'title': 'Sample Todo', 'completed': false};

    res.status(OK).send(todo);
  });

  app.listen(3000, () {
    print('🚀 Servidor rodando em http://localhost:3000');
  });
}
