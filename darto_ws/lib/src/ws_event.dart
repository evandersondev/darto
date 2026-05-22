import 'dart:convert';

/// Payload received from the client in an [onMessage] callback.
class WSEvent {
  /// The raw data — either a [String] or [List<int>] (binary frame).
  final dynamic data;

  const WSEvent(this.data);

  /// Decodes [data] as UTF-8 text.
  String get text =>
      data is String ? data as String : String.fromCharCodes(data as List<int>);

  /// Decodes [data] as a JSON object. Throws if the content is not valid JSON.
  Map<String, dynamic> get json =>
      (jsonDecode(text) as Map).cast<String, dynamic>();

  @override
  String toString() => 'WSEvent($data)';
}
