import 'dart:convert';
import 'dart:io';

import 'package:example/models/tweet_model.dart';
import 'package:example/routes/app_router.dart';
import 'package:example/routes/auth_router.dart';
import 'package:path/path.dart';

import 'package:darto/darto.dart';

void main() async {
  final app = Darto(logger: Logger(debug: true));

  // Router
  app.use('/app', appRouter());
  app.use('/auth', authRouter());

  /// Serve static files from the 'public' directory.
  app.static('public');

  // app.timeout(5000);

  // app.use((Err err, Request req, Response res, Next next) {
  //   if (!res.finished) {
  //     res.status(SERVICE_UNAVAILABLE).json({
  //       'error': 'Request timed out or internal error occurred.',
  //     });
  //   }
  // });

  app.get('/delay', (Request req, Response res) {
    Future.delayed(Duration(milliseconds: 6000), () {
      if (!req.timedOut) {
        res.json({'message': 'Delayed response'});
      }
    });
  });

  app.get('/todos/:id', (req, res) {
    final id = req.params['id'];

    final todo = {
      'id': id,
      'title': 'Sample Todo',
      'completed': false,
      'real': 2.301,
      'createdAt': DateTime.now(),
    };

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
        'title': 'New Task',
        'description': null,
        'id': '19e742c3-ccae-4832-addc-5d418d7da3ca',
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

  // Middleware global
  app.use((Request req, Response res, Next next) {
    app.set('title', 'Tweets');
    next();
  });

  app.get('/user/:id', middleware1, middleware2, (req, res) {
    final title = app.get('title');
    res.json({'message': title});
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
