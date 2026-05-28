/// Normalised user profile returned by an [OAuthProvider] after a successful
/// authorization code exchange + userinfo fetch.
///
/// [raw] preserves the full provider response — use it when [email], [name]
/// or [picture] aren't enough and you need provider-specific fields.
class OAuthUser {
  /// Stable per-provider identifier — Google's `sub`, GitHub's `id`, etc.
  final String id;

  final String? email;
  final String? name;
  final String? picture;

  /// Untouched provider response (or decoded `id_token` claims for OIDC).
  final Map<String, dynamic> raw;

  const OAuthUser({
    required this.id,
    this.email,
    this.name,
    this.picture,
    required this.raw,
  });

  @override
  String toString() => 'OAuthUser(id=$id, email=$email, name=$name)';
}
