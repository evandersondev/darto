import 'dart:io';

import 'package:darto/darto.dart';
import 'package:example/middlewares/logger_test_middleware.dart';
import 'package:example/middlewares/route_middleware.dart';
import 'package:example/models/tweet_model.dart';
import 'package:example/routes/app_router.dart';
import 'package:example/routes/auth_router.dart';
import 'package:example/routes/book_router.dart';
import 'package:example/routes/fastify_routes.dart';
import 'package:example/routes/files_router.dart';
import 'package:example/routes/new_router.dart';
import 'package:path/path.dart';

void main() async {
  final app = Darto(logger: true).basePath('/api/v1');

  // Config static files
  app.static('public');

  // Routes
  app.use(bookRouter);
  app.use(fastifyRoutesWithDarto);
  app.use(fileRoutes);

  // Routes with prefix
  app.use('/app', appRouter());
  app.use('/auth', authRouter());
  app.use('/api', fastifyRoutesWithRouter);
  app.use('/new-routes', newRoutes);

  // Middleware global
  app.use(loggerTestMiddleware);

  // Config template engine
  // app.set('views', join(Directory.current.path, 'lib', 'pages'));
  // app.set('view engine', 'mustache');
  app.engine('mustache', join(Directory.current.path, 'lib', 'pages'));

  app.get('/hello2', (Request req, Response res) {
    res.send('hello2');
  });

  // app.timeout(5000);

  app.get('/delay', (Request req, Response res) {
    Future.delayed(Duration(milliseconds: 6000), () {
      if (!req.timedOut) {
        res.json({'message': 'Delayed response'});
      }
    });
  });

  app.get('/todos/:id', (Request req, Response res) {
    final id = req.param['id'];

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

    return res.json(tweets.map((el) => el.toMap()).toList());
  });

  app.get('/hello', (req, res) {
    res.json({'message': 'Hello, World!', 'status': 'OK'});
  });

  app.get('/users', (Request req, Response res) {
    res.headers.append('X-Custom-Header', 'CustomValue');
    return res.json([
      {
        'title': 'New Task',
        'description': null,
        'id': '19e742c3-ccae-4832-addc-5d418d7da3ca',
      },
    ]);
  });

  app.post('/users', (req, res) async {
    final user = await req.body;
    return res.json(user);
  });

  // Middleware for specific route
  app.use('/user/:id', routeMiddleware);

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

  app.get('/user/:id', middleware1, middleware2, (req, res) {
    final title = app.get('title');
    res.json({'message': title});
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

  app.get('/home', (req, res) {
    return {
      'message': 'Hello, World!',
      'status': 'OK',
      'data': {
        'name': 'John Doe',
        'age': 30,
        'address': {
          'street': '123 Main St',
          'city': 'Anytown',
          'state': 'CA',
          'zip': '12345',
        },
      },
    };
  });

  app.head('/head-test', (req, res) {
    return 'HEAD request!';
  });

  app.trace('/trace-test', (req, res) {
    return 'TRACE request!';
  });

  app.options('/options-test', (req, res) {
    return 'OPTIONS request!';
  });

  app.patch('/patch-test', (req, res) {
    return 'PATCH request!';
  });

  // Param method
  app.param('id', (req, res, next, id) {
    print('Custom param middleware for id: $id from app');
    next();
  });

  // app.all
  app.all('/all', (req, res) {
    res.json({'message': 'This route should handle all HTTP methods'});
  });

  // Optional params
  app.get('/author/:name?/post/:id', (Request req, Response res) {
    // final name = req.param['name'] ?? 'World';
    final [name, id] = req.params();
    res.send('Hello, $name -  $id!');
  });

  // Wildcard params
  app.get('/wildcard/*', (Request req, Response res) {
    // Pode-se acessar a parte que foi capturada pelo wildcard,
    // se necessário, utilizando alguma lógica extra.
    res.send('Hello, World!');
  });

  // Body Parse
  app.post('/parsed', (Request req, Response res) async {
    final tweet = await req.bodyParse((body) => Tweet.fromMap(body));

    res.send(tweet.text);
  });

  // Blob
  app.post('/blob', (Request req, Response res) async {
    final blob = await req.blob();
    res.send(blob);
  });

  // ArrayBuffer
  app.post('/array-buffer', (Request req, Response res) async {
    final arrayBuffer = await req.arrayBuffer();
    print(arrayBuffer);
    res.send(arrayBuffer);
  });

  // Form Data
  app.post('/form-data', (Request req, Response res) async {
    final formData = await req.formData();

    res.send(formData);
  });

  app.listen(
    8080,
    //  () {
    //   // This will start the WebSocket server on port 3001
    //   // server.listen('0.0.0.0', 3001);
    //   app.log.error('🚀 Server is running http://localhost:3000');
    // }
  );
}
