import 'package:darto/darto.dart';

void main() {
  final app = Darto();

  // POST /upload/single — in-memory, small files
  app.post('/upload/single', [], (Context c) async {
    final body = await c.req.parseBody();
    final file = body['file'] as UploadedFile;
    return c.ok({
      'message': 'File uploaded',
      'file': {
        'name': file.name,
        'size': file.size,
        'mimeType': file.mimeType,
      },
    });
  });

  // POST /upload/multiple — in-memory, multiple files
  app.post('/upload/multiple', [], (Context c) async {
    final body = await c.req.parseBody();
    final raw = body['files'];
    final files = raw is List ? raw.cast<UploadedFile>() : [raw as UploadedFile];
    return c.ok({
      'message': '${files.length} file(s) uploaded',
      'files': files
          .map((f) => {'name': f.name, 'size': f.size, 'mimeType': f.mimeType})
          .toList(),
    });
  });

  // POST /upload/disk — stream directly to disk, large files
  app.post('/upload/disk', [], (Context c) async {
    final body = await c.req.parseBody(saveDir: 'uploads');
    final file = body['file'] as UploadedFile;
    return c.ok({
      'message': 'File saved to disk',
      'file': {
        'name': file.name,
        'path': file.path,
        'size': file.size,
        'mimeType': file.mimeType,
      },
    });
  });

  app.get('/', [], (Context c) => c.ok({
        'endpoints': [
          'POST /upload/single   — multipart/form-data, field: file (in-memory)',
          'POST /upload/multiple — multipart/form-data, field: files (in-memory)',
          'POST /upload/disk     — multipart/form-data, field: file (streamed to disk)',
        ]
      }));

  app.listen(3000, () => print('Upload server running on port 3000'));
}
