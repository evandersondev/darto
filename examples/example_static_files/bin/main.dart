import 'package:darto/darto.dart';
import 'package:darto_static/darto_static.dart';

void main() {
  final app = Darto();

  app.mount('/public', (Context c, Next next) async {
    print('HIT: ${c.req.path}');
    await next();
  });
  // Serve files from the public/ directory under /public
  app.mount('/public', serveStatic('public'));

  app.get('/', [], (Context c) => c.html('''
<!DOCTYPE html>
<html>
<head>
  <title>Static Files Example</title>
  <link rel="stylesheet" href="/public/style.css">
</head>
<body>
  <h1>Static Files Demo</h1>
  <p>Files served from the <code>public/</code> folder under <code>/public/*</code>.</p>
  <ul>
    <li><a href="/public/index.html">public/index.html</a></li>
    <li><a href="/public/style.css">public/style.css</a></li>
  </ul>
</body>
</html>
'''));

  app.listen(3000, () => print('Static files server running on port 3000'));
}
