import 'package:example_test/app.dart';

void main() {
  final app = buildApp();
  app.listen(3000, () => print('Test example on http://localhost:3000'));
}
