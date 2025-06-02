import 'package:darto/darto.dart';

Handler errorMiddleware(Err err, Request req, Response res, Next next) {
  if (!res.finished) {
    res.status(SERVICE_UNAVAILABLE).json({
      'error': 'Request timed out or internal error occurred.',
    });
  }
}
