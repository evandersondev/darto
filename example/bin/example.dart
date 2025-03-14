import 'package:darto/darto.dart';
import 'package:example/models/tweet_model.dart';

void main() async {
  final app = Darto(logger: Logger(debug: true), snackCase: true);

  app.useCors(origin: '*');

  /// Serve static files from the 'public' directory.
  ///
  /// example: GET /images/logo.png
  /// example: GET /css/style.css
  /// example: GET /js/script.js
  /// example: GET /views/index.html
  app.serveStatic('public');

  app.get('/todos/:id', (Request req, Response res) {
    final id = req.params['id'];
    final todo = {'id': id, 'title': 'Sample Todo', 'completed': false};

    res.status(OK).send(todo);
  });

  app.get('/tweets', (Request req, Response res) {
    final tweets = [
      Tweet(id: '1', text: 'Tweet 1'),
      Tweet(id: '2', text: 'Tweet 2'),
      Tweet(id: '3', text: 'Tweet 3'),
    ];

    return res.json(tweets);
  });

  app.get('/hello', (Request req, Response res) {
    return res.json({'message': 'Hello, World!', 'status': 'OK'});
  });

  app.get('/users', (Request req, Response res) {
    return res.json([
      {
        'id': 1,
        'name': 'John Doe',
        'email': 'john@example.com',
        'age': 30,
        'address': {
          'street': '123 Main St',
          'city': 'Anytown',
          'state': 'CA',
          'zip': '12345',
        },
      },
      {
        'id': 2,
        'name': 'Jane Smith',
        'email': 'jane@example.com',
        'age': 25,
        'address': {
          'street': '456 Elm St',
          'city': 'Othertown',
          'state': 'NY',
          'zip': '67890',
        },
      },
    ]);
  });

  app.get('/', (Request req, Response res) {
    return res.render('public/about.html');
  });

  app.listen(3000, () {
    print('🚀 Servidor rodando em http://localhost:3000');
  });
}
