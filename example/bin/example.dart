import 'dart:convert';
import 'dart:io';

import 'package:darto/darto.dart';
import 'package:example/models/tweet_model.dart';
import 'package:example/routes/app_router.dart';
import 'package:example/routes/auth_router.dart';
import 'package:path/path.dart';

void main() async {
  final app = Darto(logger: Logger(debug: true));

  // Router
  app.use('/app', appRouter());
  app.use('/auth', authRouter());

  /// Serve static files from the 'public' directory.
  app.static('public');

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

  app.get('/users', (Request req, Response res) {
    res.set('X-Custom-Header', 'CustomValue');
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

  // app.get('/', (Request req, Response res) {
  //   return res.sendFile('public/test.pdf');
  // });

  app.post('/users', (req, res) async {
    final user = await req.body;
    return res.json(jsonDecode(user));
  });

  // Middleware global
  app.use((Request req, Response res, Next next) {
    // print('Request Authorization: ${req.headers.authorization}');
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

  middleware2(Request req, Response res, Next next) async {
    print(req.path);
    print('Middleware 2');
    next();
  }

  // Rotas
  app.get('/user/:id', middleware1, middleware2, (req, res) {
    res.json({'message': 'USER'});
  });

  // Instance of Upload class
  final upload = Upload(join(Directory.current.path, 'uploads'));

  // Route to handle file upload
  app.post('/upload', upload.single('file'), (Request req, Response res) {
    if (req.file != null) {
      res.json(req.file);
    } else {
      res.status(BAD_REQUEST).json({'error': 'No file uploaded'});
    }
  });

  // Route to test web socket server
  app.get('/websocket-test', (req, res) {
    res.sendFile('public/websocket_test.html');
  });

  // Instance of WebSocket server
  final server = DartoWebsocket();

  // Register a handler for the 'connection' event
  server.on('connection', (DartoSocketChannel socket) {
    // Handle incoming messages from the client
    socket.stream.listen((message) {
      socket.sink.add('Echo: $message');
    });
  });

  app.listen(3000, () {
    // This will start the WebSocket server on port 3001
    // server.listen('0.0.0.0', 3001);
    print('🚀 Server is running http://localhost:3000');
  });
}
