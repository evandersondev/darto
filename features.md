# v 0.0.25

## Inspired by [Hono](https://github.com/honojs/hono)

### Routing

[x] `app.all` Any HTTP method

```dart
app.all('/hello', (Request req, Response res) {
    res.send('Hello, World!');
}
```

[x] `app.on` Multiple HTTP methods or multiple paths

```dart
app.on(['GET', 'POST'], '/hello', (Request req, Response res) {
    res.send('Hello, World!');
});

app.on('GET', ['/hello', '/world'], (Request req, Response res) {
    res.send('Hello, World!');
});
```

### Params

[x] `req.param()` Get a parameter from the URL and return make it a list of strings.

```dart
app.get('/hello/:name/product/:id', (Request req, Response res) {
  // params is retuned in order of the URL
  // Cause this you can destructure it like this
  // List<String?> params = req.param()
  final [name, id] = req.param()

  res.send('Hello, $name! Your product id is $id');
});
```

[x] Optional parameters

```dart
app.get('/hello/:name?', (Request req, Response res) {
  final name = req.params['name'] ?? 'World';

  res.send('Hello, $name!');
});
```

[x] Wildcard parameters

```dart
app.get('/hello/*', (Request req, Response res) {
  // return this route for all routes that start with /hello/
  res..send('Hello, World!');
}
```

### Base path

[x] `Darto().basePath('/api')`

```dart
void main() {
  final app = Darto().basePath('/api');

  // Or use like this `app.basePath()`
}
```

### Response

[x] `res.text()` Content-Type:text/plain - String
[x] `res.html()` Content-Type:text/html - String
[x] `res.notFound()` Send a 404 response
[x] `res.json()` Content-Type:application/json - Map<String, dynamic>

[x] `res.body()`

```dart
app.get('/hello', (Request req, Response res) {
  return res.body(dynamic data, int status, Map<String, dynamic> headers);
}
```

[x] `res.headers.append('X-Debug', 'Debug message')`

[x] `res.setRender()`
You can set a specific path `app.use('/pages/*', middleware)`
You can send a params `res.setRender((dynamic content, Map<String, dynamic> head) {})`

```dart
void main() {
  app.use((Request req, Response res, Next next) {
    res.setRender((content) {
      return res.html(
        '''
        <html>
          <head>
            <title>${head['title']}</title>
          </head>
          <body>
            <div>$content</div>
          </body>
        </html>
        '''
      );
    });

    next();
  });

  app.get('/hello', (Request req, Response res) {
    return res.render('Hello, World!', {
      'title': 'Hello, World!',
    });
  });
}
```

[x] `req.blob()`
[x] `req.formData()`
[x] `req.arrayBuffer()`

[] `req.body.text()` transform the body to string
[] `req.body.json()` transform the body to json
[] `T req.body.parse(T Function(dynamic body))` transform the body to a custom type

---

### Folders Darto Sugestion

- bin
  main.dart
- lib
  - core
  - database (database connection)
  - controllers
  - routes
  - services (external services)
  - models
  - utils
  - middlewares
  - repositories (access to the database)
  - config
  - use-cases
