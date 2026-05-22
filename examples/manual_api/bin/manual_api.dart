import 'package:manual_api/app.dart';
import 'package:manual_api/config/env.dart';

void main() {
  final app = createApp();

  app.listen(Env.port, () {
    print('Server is running on http://localhost:${Env.port}');
  });
}
