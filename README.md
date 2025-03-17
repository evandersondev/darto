# Darto 🛠️

Darto is a microframework inspired by Express and Fastify for building web applications in Dart. It offers a simple API with familiar middleware patterns that make it easy to get started with web development!

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
  app.get('/ping', (req, res) {
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
  app.use('public');

  // You can access the static files in browser using the following URL:
  // http://localhost:3000/public/index.html

  // Or use render method to render a view

  app.get('/users', (req, res) {
    final id = req.params['id'];
    res.render('index.html');
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
  app.use((req, res, next) {
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
  app.use('/task/:id', req, res, next) {
    print('Request Type: ${req.method}');
    next();
  };

  app.get('/task/:id', (req, res) {
    final id = req.params['id'];
    res.send({'task': id});
  });

  // You can use the middleware directly in the route definition
  // Create a middleware function
  logMiddleware(req, res, next) {
    print('Request Type: ${req.method}');
    next();
  };

  // Example route with middleware
  app.get('/user/:id', logMiddleware, (req, res) {
    final id = req.params['id'];
    res.send({'user': id});
  });

  app.listen(3000, () {
    print('🔹 Server is running at http://localhost:3000');
  });
}
```

<br>

## Available Methods ✨

### Response Methods

- **`status(dynamic statusCode)`**: Sets the HTTP status for the response. Accepts an `int` or an `HttpStatus` from Dart's `dart:io`.
- **`send(dynamic data)`**: Sends JSON data in the response and closes it.
- **`end([dynamic data])`**: Writes optional data and ends the response.
- **`download(String filePath, [dynamic filename, dynamic callback])`**: Sends a file as an attachment for download. Optionally accepts a custom file name and an error callback.
- **`cookie(String name, String value, [Map<String, dynamic>? options])`**: Sets a cookie on the response.
- **`clearCookie(String name, [Map<String, dynamic>? options])**: Clears a cookie.
- **`redirect(String url)`**: Redirects to the specified URL.

<br>

### Request Methods

- **`body`**: Returns the parsed request body.
- **`cookies`**: Returns a map of cookies from the request.
- **`baseUrl`**: The base URL on which the router was mounted.
- **`host`**: The host header (e.g., "example.com:3000").
- **`hostname`**: The host name without the port.
- **`method`**: The HTTP method of the request.
- **`originalUrl`**: The original URL of the request.
- **`path`**: The path portion of the request URL.
- **`ip`**: The client's IP address.
- **`ips`**: A list of IP addresses (using the `x-forwarded-for` header if available).
- **`protocol`**: The protocol used (e.g., "http" or "https").

<br>

## Security Features 🔒

Darto includes basic security measures:

- **Input Sanitization:** Use `DartoBase.sanitizeInput` to clean user inputs and prevent code injection.
- **DoS Protection:** Apply `DartoBase.rateLimit` in your middleware chain to limit the rate of requests and avoid denial-of-service attacks.

<br>

## Example Routes 📡

```dart
// Route to get user information by ID
app.get('/user/:id', (req, res) {
  final id = req.params['id'];
  res.send({'user': id});
});

// Route to redirect to an external site
app.get('/go', (req, res) {
  res.redirect('http://example.com');
});
```

<br>

---

Made with ❤️ for Dart/Flutter developers! 🎯
