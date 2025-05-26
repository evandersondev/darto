import 'package:darto/darto.dart';

void newRoutes(Router router) {
  router
      .route('/new')
      .all((req, res, next) {
        req.log.debug('New route');

        next();
      })
      .get((req, res, next) {
        res.send('New route');
      })
      .post((req, res, next) {
        next(Exception('Not implemented'));
      })
      .put((req, res, next) {
        next(Exception('Not implemented'));
      });
}
