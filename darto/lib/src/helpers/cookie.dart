import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:darto/src/core/darto_base.dart';

class CookieOptions {
  final String? path;
  final String? domain;
  final bool? httpOnly;
  final bool? secure;
  final int? maxAge;
  final DateTime? expires;
  final String? sameSite; // 'Strict' | 'Lax' | 'None'

  const CookieOptions({
    this.path,
    this.domain,
    this.httpOnly,
    this.secure,
    this.maxAge,
    this.expires,
    this.sameSite,
  });
}

String generateCookie(String name, String value, [CookieOptions? opt]) {
  final parts = <String>[];

  parts.add('$name=$value');

  if (opt != null) {
    if (opt.path != null) parts.add('Path=${opt.path}');
    if (opt.domain != null) parts.add('Domain=${opt.domain}');
    if (opt.httpOnly == true) parts.add('HttpOnly');
    if (opt.secure == true) parts.add('Secure');
    if (opt.maxAge != null) parts.add('Max-Age=${opt.maxAge}');
    if (opt.expires != null)
      parts.add('Expires=${_formatHttpDate(opt.expires!)}');
    if (opt.sameSite != null) parts.add('SameSite=${opt.sameSite}');
  }

  return parts.join('; ');
}

String _formatHttpDate(DateTime date) {
  const wkday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const month = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  final d = date.toUtc();

  final w = wkday[d.weekday - 1];
  final m = month[d.month - 1];

  final dd = d.day.toString().padLeft(2, '0');
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  final ss = d.second.toString().padLeft(2, '0');

  return '$w, $dd $m ${d.year} $hh:$mm:$ss GMT';
}

void setCookie(Context c, String name, String value, [CookieOptions? opt]) {
  final cookie = generateCookie(name, value, opt);
  // Use `add` (not `set`) so multiple cookies produce multiple Set-Cookie
  // headers instead of overwriting each other.
  c.res.raw.headers.add('Set-Cookie', cookie);
}

/// Parses the cookies sent by the client (the request `Cookie` header).
Map<String, String> getCookies(Context c) {
  final header = c.req.header('cookie');
  if (header == null) return {};

  final cookies = <String, String>{};

  for (final part in header.split(';')) {
    final trimmed = part.trim();
    if (trimmed.isEmpty) continue;
    // Split on the FIRST '=' only — cookie values may contain '=' (e.g. the
    // base64url padding used by signed/session cookies).
    final eq = trimmed.indexOf('=');
    if (eq <= 0) continue;
    final name = trimmed.substring(0, eq).trim();
    cookies[name] = trimmed.substring(eq + 1).trim();
  }

  return cookies;
}

String? getCookie(Context c, String key) {
  return getCookies(c)[key];
}

void deleteCookie(Context c, String name) {
  setCookie(
    c,
    name,
    '',
    CookieOptions(
      expires: DateTime.fromMillisecondsSinceEpoch(0),
    ),
  );
}

Future<String> generateSignedCookie(
  String name,
  String value,
  String secret, [
  CookieOptions? opt,
]) async {
  final sig = _sign(value, secret);
  final signedValue = '$value.$sig';

  return generateCookie(name, signedValue, opt);
}

Future<void> setSignedCookie(
  Context c,
  String name,
  String value,
  String secret, [
  CookieOptions? opt,
]) async {
  final cookie = await generateSignedCookie(name, value, secret, opt);
  c.res.raw.headers.add('Set-Cookie', cookie);
}

Future<String?> getSignedCookie(
  Context c,
  String secret,
  String key,
) async {
  final raw = getCookies(c)[key];
  if (raw == null) return null;

  // Signature is the segment after the last '.', so values may contain dots.
  final dot = raw.lastIndexOf('.');
  if (dot <= 0) return null;

  final value = raw.substring(0, dot);
  final sig = raw.substring(dot + 1);

  if (sig != _sign(value, secret)) return null;

  return value;
}

String _sign(String value, String secret) {
  final key = utf8.encode(secret);
  final bytes = utf8.encode(value);

  final hmacSha256 = Hmac(sha256, key);
  final digest = hmacSha256.convert(bytes);

  return base64UrlEncode(digest.bytes);
}
