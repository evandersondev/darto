# Darto 🚀

Darto is a microframework inspired by Express and Fastify for building web applications in Dart. It offers a simple API with familiar middleware patterns that make it easy to get started with web development!

## Installation 📦

Run the following command to install Darto:

```bash
dart pub add darto
```

or

Add the package to your `pubspec.yaml` file:

```yaml
dependencies:
  darto: ^0.0.3
```

Then, run the following command:

```bash
flutter pub get
```

## Basic Usage 🚀

Create a file (e.g., `example/bin/main.dart`) with the following content:

```dart
import 'package:darto/darto.dart';

void main() async {
  final app = Darto();

  // Global middleware to log incoming requests
  app.use((req, res, next) async {
    print('📝 Request: ${req.method} ${req.originalUrl}');
    await next();
  });

  // Serve static files from the "public" folder (using default options)
  app.serveStatic('public');

  // Example route: Get user details by ID
  app.get('/user/:id', (req, res) async {
    final id = req.params['id'];
    res.send({'user': id});
  });

  // Example route: Redirect to an external URL
  app.get('/go', (req, res) async {
    res.redirect('http://example.com');
  });

  // Example route: File download with a custom file name and error callback
  app.get('/download', (req, res) async {
    res.download('public/report-12345.pdf', 'report.pdf', (err) {
      if (err != null) {
        print('❌ Download error: $err');
      } else {
        print('✅ Download successful!');
      }
    });
  });

  app.listen(3000, () {
    print('🔹 Server is running at http://localhost:3000');
  });
}
```

## Available Methods ✨

### Response Methods

- **`status(dynamic statusCode)`**: Sets the HTTP status for the response. Accepts an `int` or an `HttpStatus` from Dart's `dart:io`.
- **`send(dynamic data)`**: Sends JSON data in the response and closes it.
- **`end([dynamic data])`**: Writes optional data and ends the response.
- **`download(String filePath, [dynamic filename, dynamic callback])`**: Sends a file as an attachment for download. Optionally accepts a custom file name and an error callback.
- **`cookie(String name, String value, [Map<String, dynamic>? options])`**: Sets a cookie on the response.
- **`clearCookie(String name, [Map<String, dynamic>? options])`**: Clears a cookie.
- **`redirect(String url)`**: Redirects to the specified URL.

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

## Security Features 🔒

Darto includes basic security measures:

- **Input Sanitization:** Use `DartoBase.sanitizeInput` to clean user inputs and prevent code injection.
- **DoS Protection:** Apply `DartoBase.rateLimit` in your middleware chain to limit the rate of requests and avoid denial-of-service attacks.

## Example Routes 📡

```dart
// Route to get user information by ID
app.get('/user/:id', (req, res) async {
  final id = req.params['id'];
  res.send({'user': id});
});

// Route to redirect to an external site
app.get('/go', (req, res) async {
  res.redirect('http://example.com');
});
```

---

Made with ❤️ for Flutter developers! 🎯
