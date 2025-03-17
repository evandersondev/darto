import 'dart:convert';

import 'package:darto/darto.dart';
import 'package:example/models/tweet_model.dart';

void main() async {
  final app = Darto(logger: Logger(debug: true), snakeCase: true);

  app.useCors(origin: '*');

  /// Serve static files from the 'public' directory.
  ///
  /// example: GET /images/logo.png
  /// example: GET /css/style.css
  /// example: GET /js/script.js
  /// example: GET /views/index.html
  app.use('public');

  app.get('/todos/:id', (req, res) {
    final id = req.params['id'];
    final todo = {'id': id, 'title': 'Sample Todo', 'completed': false};

    res.status(OK).send(todo);
  });

  app.get('/tweets', (req, res) {
    final tweets = [
      Tweet(id: '1', text: 'Tweet 1'),
      Tweet(id: '2', text: 'Tweet 2'),
      Tweet(id: '3', text: 'Tweet 3'),
    ];

    return res.json(tweets);
  });

  app.get('/hello', (req, res) {
    res.json({'message': 'Hello, World!', 'status': 'OK'});
  });

  app.get('/users', (req, res) {
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

  app.get('/', (req, res) {
    return res.render('public/about.html');
  });

  app.post('/users', (req, res) async {
    final user = await req.body;
    return res.json(jsonDecode(user));
  });

  // Middleware global
  app.use((req, res, next) {
    print('Time: ${DateTime.now()}');
    next();
  });

  // // Middleware específico de rota
  // app.use('/user/:id', (req, res, next) async {
  //   print('Request Type: ${req.method}');
  //   next();
  // });

  // Middlewares específicos de rota
  middleware1(req, res, next) async {
    print('Middleware 1');
    next();
  }

  middleware2(req, res, next) async {
    print('Middleware 2');
    next();
  }

  // Rotas
  app.get('/user/:id', (req, res) {
    res.json({'message': 'USER'});
  }, [middleware1, middleware2]);

  app.listen(3000, () {
    print('🚀 Servidor rodando em http://localhost:3000');
  });
}
