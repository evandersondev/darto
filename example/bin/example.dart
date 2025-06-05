import 'dart:io';

import 'package:darto/darto.dart';
import 'package:example/middlewares/logger_test_middleware.dart';
import 'package:example/models/tweet_model.dart';
import 'package:example/routes/app_router.dart';
import 'package:example/routes/auth_router.dart';
import 'package:example/routes/book_router.dart';
import 'package:example/routes/fastify_routes.dart';
import 'package:example/routes/new_router.dart';
import 'package:path/path.dart';

void main() async {
  final app = Darto(
    logger: true,
    gzip: true,
    snakeCase: true,
  ).basePath('/api/v1');

  // Routes
  app.use('/app', appRouter());
  app.use('/auth', authRouter());
  app.use(fastifyRoutesWithDarto);
  app.use('/api', fastifyRoutesWithRouter);
  app.use('/new-routes', newRoutes);
  app.use(bookRouter);

  app.static('public');

  app.get('/about', (Request req, Response res) {
    res.sendFile('public/about.html');
  });

  // Middleware global
  app.use(loggerTestMiddleware);

  // Config template engine
  // app.set('views', join(Directory.current.path, 'lib', 'pages'));
  // app.set('view engine', 'mustache');

  app.engine('mustache', join(Directory.current.path, 'lib', 'pages'));

  app.use((Request req, Response res, Next next) {
    res.setRender((content) {
      return res.html('''
        <html>
          <head>
            <title>My layout</title>
          </head>
          <body>
            <h1>My Template Layout</h1>
            $content
            <footer>
            <p>This is the footer</p>
            </footer>
          </body>
        </html>
        ''');
    });

    next();
  });

  app.get('/', (Request req, Response res) {
    res.render('index', {
      'title': 'Welcome',
      'header': 'Hello',
      'message': 'This is a sample mustache template rendered with Darto.',
    });
  });

  // Get instance of DartoMailer
  final mailer = DartoMailer();

  // Create a transporter instance
  final transporter = mailer.createTransport(
    host: 'sandbox.smtp.mailtrap.io',
    port: 2525,
    ssl: false,
    auth: {'username': 'seu-username', 'password': 'sua-password'},
  );

  // Send an email using the transporter
  app.post('/send-email', (Request req, Response res) async {
    final success = await transporter.sendMail(
      from: 'seu-email@gmail.com',
      to: 'destinatario@exemplo.com',
      subject: 'Teste de Email via Gmail',
      html: '''
      <h1>Bem-vindo ao Darto Mailer!</h1>
      <p>Este é um email de teste usando Darto Mailer.</p>
    ''',
    );

    if (!res.finished) {
      if (success) {
        return res.json({'message': 'Email enviado com sucesso!'});
      } else {
        return res.status(500).json({'error': 'Falha ao enviar email'});
      }
    }
  });

  app.get('/hello2', (Request req, Response res) {
    res.send('hello2');
  });

  /// Serve static files from the 'public' directory.

  app.timeout(5000);

  app.use((Exception err, Request req, Response res, Next next) {
    // Se o erro for de timeout, pode customizar a resposta,
    // mas se não for, repassa para o próximo middleware.
    if (req.timedOut && !res.finished) {
      res.status(SERVICE_UNAVAILABLE).json({
        'error': 'Request timed out or internal error occurred.',
      });
    } else {
      next(err);
    }
  });

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

    res.status(OK).json(todo);
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

  // app.get('/', (Request req, Response res) {
  //   return res.sendFile('public/test.pdf');
  // });

  app.post('/users', (req, res) async {
    final user = await req.body;
    return res.json(user);
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

  // define not found route handler
  // app.addHook.onNotFound((Request req, Response res) {
  //   res.redirect('/404');
  // });

  // app.get('/404', (Request req, Response res) {
  //   res.status(NOT_FOUND).json({'404': 'Route not found (Auto Redirect)'});
  // });

  // Define onRequest hook
  // app.addHook.onRequest((req) {
  //   print("onRequest: ${req.method} ${req.path}");
  // });

  // // Define preHandler hook
  // app.addHook.preHandler((req, res) async {
  //   print("preHandler: processing request before handler");
  // });

  // // Define onResponse hook
  // app.addHook.onResponse((req, res) {
  //   print("onResponse: response sent for ${req.method} ${req.path}");
  // });

  // // Define onError hook
  // app.addHook.onError((error, req, res) {
  //   print("onError: error occurred ${error.toString()} on ${req.path}");
  // });

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

  app.get('/stream', (req, res) async {
    return res.stream((stream) {
      // Write all data through the stream controller to avoid conflicts
      stream.write('Starting stream...\n');
      stream.write('Data 1\n');
      stream.write('Data 2\n');
      stream.onAbort(() => print('Client disconnected'));
    });
  });

  app.get('/text', (req, res) async {
    return res.streamText((stream) {
      stream.writeln('Line 1');
      stream.writeln('Line 2');
      stream.onAbort(() => print('Text stream aborted'));
    });
  });

  app.get('/sse', (req, res) async {
    return res.streamSSE((stream) async {
      stream.event('Event 1', id: '1');
      await Future.delayed(Duration(seconds: 1));
      stream.event('Event 2', id: '2');
      stream.onAbort(() => print('SSE connection closed'));
    });
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
