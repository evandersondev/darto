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
  c.res.setHeader('Set-Cookie', cookie);
}

Map<String, String> getCookies(Context c) {
  final header = c.res.header('cookie');
  if (header == null) return {};

  final cookies = <String, String>{};

  for (final part in header.split(';')) {
    final kv = part.trim().split('=');
    if (kv.length == 2) {
      cookies[kv[0]] = kv[1];
    }
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
  c.res.setHeader('Set-Cookie', cookie);
}

Future<String?> getSignedCookie(
  Context c,
  String secret,
  String key,
) async {
  final cookies = getCookies(c);
  final raw = cookies[key];

  if (raw == null) return null;

  final parts = raw.split('.');
  if (parts.length != 2) return null;

  final value = parts[0];
  final sig = parts[1];

  final expected = _sign(value, secret);

  if (sig != expected) return null;

  return value;
}

String _sign(String value, String secret) {
  final key = utf8.encode(secret);
  final bytes = utf8.encode(value);

  final hmacSha256 = Hmac(sha256, key);
  final digest = hmacSha256.convert(bytes);

  return base64UrlEncode(digest.bytes);
}
