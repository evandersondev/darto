# Darto 🛠️

Darto is a microframework inspired by Express for building web applications in Dart. It offers a simple API with familiar middleware patterns that make it easy to get started with web development!

<br>

### Support 💖

If you find Darto useful, please consider supporting its development 🌟[Buy Me a Coffee](https://buymeacoffee.com/evandersondev).🌟 Your support helps us improve the framework and make it even better!

<br>

## Installation 📦

Run the following command to install Darto:

```bash
dart pub add darto
```

or

Add the package to your `pubspec.yaml` file:

```yaml
dependencies:
  darto: ^0.0.9
```

Then, run the following command:

```bash
flutter pub get
```

<br>

## Basic Usage 🚀

```dart
import 'package:darto/darto.dart';

void main() {
  final app = Darto();

  // Example route
  app.get('/ping', (Request req, Response res) {
    res.send('pong');
  });

  app.listen(3000);
}
```

<br>

### Config static files

To upload files, you can use the class Upload. Here's an example:

```dart
void main() {
  // Serve static files from the "public" folder (using default options)
  // You can access the static files in browser using the following URL:
  // http://localhost:3000/public/index.html
  app.static('public');

  // Or you can send  the file as a response
  app.get('/images', (Request req, Response res) {
    res.sendFile('public/image.png');
  });
}
```

<br>

### Upload Files

To upload files, you can use the class Upload. Here's an example:

```dart
void main() {
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
}
```

<br>

## Middleware Usage 🛠️

Darto supports different types of middleware to handle various tasks throughout the request-response lifecycle.

### Global Middleware

Global middlewares are applied to all incoming requests. You can register a global middleware using the `use` method.

```dart
void main() {
  final app = Darto();

  // Global middleware to log incoming requests
  app.use((Request req, Response res, Next next) {
    print('📝 Request: ${req.method} ${req.originalUrl}');

    next();
  });

  app.listen(3000, () {
    print('🔹 Server is running at http://localhost:3000');
  });
}
```

<br>

### Route-Specific Middleware

Route-specific middlewares are applied to specific routes. You can pass a middleware as an optional parameter when defining a route.

```dart
void main() {
  final app = Darto();

  // Middleware specific to a route
  app.use('/task/:id', (Request req, Response res, Next next) {
    print('Request Type: ${req.method}');

    next();
  });

  app.get('/task/:id', (Request req, Response res) {
    final id = req.params['id'];

    res.send({'task': id});
  });

  // You can use the middleware directly in the route definition
  // Create a middleware function
  logMiddleware(Request req, Response res, Next next) {
    print('Request Type: ${req.method}');

    next();
  };

  // Example route with middleware
  app.get('/user/:id', logMiddleware, (Request req, Response res) {
    final id = req.params['id'];

    res.send({'user': id});
  });

  app.listen(3000, () {
    print('🔹 Server is running at http://localhost:3000');
  });
}
```

<br>

## Example Routes 📡

```dart
// Route to get user information by ID
app.get('/user/:id', (Request req, Response res) {
  final id = req.params['id'];

  res.send({'user': id});
});

// Route to redirect to an external site
app.get('/go', (Request req, Response res) {
  res.redirect('http://example.com');
});

// Route to get a body
app.get('/file', (Request req, Response res) async {
  final body = await req.body;

  res.send(body);
});
```

<br>

## Main Features

- **Middlewares**  
  Easily apply both global and route-specific middlewares to process requests, manage authentication, logging, data manipulation, and more.

- **File Uploads**  
  Supports file uploads natively using the `Upload` class, allowing the seamless handling and storage of files sent by clients.

- **File Downloads**  
  With the `download` method, you can send files as attachments, specify custom file names, and set up error callbacks for a controlled download experience.

- **Static File Serving**  
  Serve static files from designated directories using the `static` method, making folders (e.g., "public") accessible directly via URL.

- **Send Files (sendFile)**  
  Automatically handles the correct Content-Type based on file extensions to ensure files such as HTML, CSS, JavaScript, images, PDFs, etc., are served with the proper headers.

- **Flexible Routing**  
  Define routes with dynamic parameters (e.g., `/user/:id`) similar to Express.js, allowing easy extraction of parameters for RESTful API design.

- **CORS and Custom Headers**  
  Configure CORS and set custom HTTP headers to adhere to security policies and enhance communication.

- **Input Sanitization and Basic Security**  
  Incorporates input sanitization mechanisms along with basic protections to avoid injection attacks and mitigate denial-of-service (DoS) scenarios.

<br>

---

Made with ❤️ for Dart/Flutter developers! 🎯
