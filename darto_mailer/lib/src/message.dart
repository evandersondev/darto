/// A file/blob attached to a [Message].
///
/// Construct one of the three flavours:
/// - [Attachment.file] — read from a path on disk.
/// - [Attachment.bytes] — in-memory binary content.
/// - [Attachment.string] — in-memory text content.
class Attachment {
  /// File name shown to the recipient.
  final String filename;

  /// MIME type, e.g. `application/pdf`.  When `null` the transport infers it
  /// from [filename].
  final String? contentType;

  /// Set for [Attachment.file].
  final String? path;

  /// Set for [Attachment.bytes].
  final List<int>? bytes;

  /// Set for [Attachment.string].
  final String? content;

  const Attachment._({
    required this.filename,
    this.contentType,
    this.path,
    this.bytes,
    this.content,
  });

  /// Attaches the file at [path].  [filename] defaults to the base name.
  factory Attachment.file(String path, {String? filename, String? contentType}) {
    final name = filename ?? path.split(RegExp(r'[/\\]')).last;
    return Attachment._(filename: name, contentType: contentType, path: path);
  }

  /// Attaches in-memory [bytes] under [filename].
  factory Attachment.bytes(String filename, List<int> bytes, {String? contentType}) =>
      Attachment._(filename: filename, contentType: contentType, bytes: bytes);

  /// Attaches an in-memory text [content] under [filename].
  factory Attachment.string(String filename, String content, {String? contentType}) =>
      Attachment._(filename: filename, contentType: contentType, content: content);
}

/// An email to send through a [Mailer].
///
/// At least one recipient ([to]) and one of [text] / [html] are required.
/// Provide both [text] and [html] to give text-only clients a fallback.
class Message {
  /// Primary recipients.
  final List<String> to;

  /// Carbon-copy recipients.
  final List<String> cc;

  /// Blind carbon-copy recipients.
  final List<String> bcc;

  /// `Reply-To` address.
  final String? replyTo;

  /// Subject line.
  final String? subject;

  /// Plain-text body.
  final String? text;

  /// HTML body.
  final String? html;

  /// Files attached to the message.
  final List<Attachment> attachments;

  /// Extra raw headers — merged after the computed ones.
  final Map<String, String> headers;

  /// Per-message `From` override.  When `null` the [Mailer]'s default `from`
  /// is used.
  final String? from;

  Message({
    required Object to,
    Object? cc,
    Object? bcc,
    this.replyTo,
    this.subject,
    this.text,
    this.html,
    this.attachments = const [],
    this.headers = const {},
    this.from,
  })  : to = _normalize(to),
        cc = _normalize(cc),
        bcc = _normalize(bcc);

  /// Accepts a `String` (single address) or an `Iterable<String>`.
  static List<String> _normalize(Object? v) {
    if (v == null) return const [];
    if (v is String) return [v];
    if (v is Iterable) return v.map((e) => '$e').toList();
    throw ArgumentError(
        'Recipients must be a String or Iterable<String>, got ${v.runtimeType}');
  }
}
