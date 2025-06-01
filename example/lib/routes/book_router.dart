import 'package:darto/darto.dart';

final bookRouter =
    (Router router) => router
        .route('/books')
        .all((req, res, next) {
          req.log.info('all');

          next();
        })
        .get((req, res, next) {
          return res.json([
            {'id': 1, 'name': 'Book 1'},
            {'id': 2, 'name': 'Book 2'},
          ]);
        })
        .post((req, res, next) {
          return res.json({'id': 3, 'name': 'Book 3'});
        });
