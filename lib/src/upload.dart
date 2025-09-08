import 'dart:io';
import 'dart:math';

import 'package:darto/darto.dart';
import 'package:mime/mime.dart';

class Upload {
  final String saveDir;

  Upload(this.saveDir);

  Middleware single(String fieldName) {
    return (Request req, Response res, NextFunction next) async {
      try {
        final contentType = req.headers.get('content-type');
        if (contentType == null ||
            !contentType.startsWith('multipart/form-data')) {
          res
              .status(BAD_REQUEST)
              .send('Content-Type must be multipart/form-data');
          return;
        }

        final boundary = contentType.split('boundary=').last;

        final transformer = MimeMultipartTransformer(boundary);
        final bodyStream = req.cast<List<int>>().transform(transformer);
        await for (final part in bodyStream) {
          if (part.headers.containsKey('content-disposition')) {
            final contentDisposition = part.headers['content-disposition']!;
            final name = RegExp(r'name="(.+?)"')
                .firstMatch(contentDisposition)
                ?.group(1);
            final filename = RegExp(r'filename="(.+?)"')
                .firstMatch(contentDisposition)
                ?.group(1);

            if (name == fieldName && filename != null) {
              final savePath = Directory(saveDir);
              if (!savePath.existsSync()) {
                savePath.createSync(recursive: true);
              }
              final timestamp = DateTime.now().millisecondsSinceEpoch;
              final randomSuffix = Random().nextInt(1E9.toInt());
              final fileNameWithoutExtension = filename.split('.').first;
              final extension = filename.split('.').last;
              final newFilename =
                  '$timestamp-$fileNameWithoutExtension-$randomSuffix.$extension';
              final file = File('${savePath.path}/$newFilename');
              final fileSink = file.openWrite();
              await part.pipe(fileSink);
              await fileSink.close();
              req.file = {
                'fieldname': fieldName,
                'originalname': filename,
                'path': file.path,
                'size': await file.length(),
              };
              break;
            } else {
              res.status(BAD_REQUEST).send('Invalid file upload');
            }
          } else {
            res.status(BAD_REQUEST).send('Invalid file upload');
          }
        }
        next();
      } catch (e) {
        res.status(INTERNAL_SERVER_ERROR).send('Error during file upload: $e');
      }
    };
  }
}
