// Utility to safely extract an access token string from various versions of the
// `flutter_facebook_auth` AccessToken representation. New versions of the
// package changed the AccessToken shape which caused previous `.token` usages
// to fail the analyzer. This helper uses dynamic access with fallbacks.

String fbAccessTokenString(dynamic accessToken) {
  if (accessToken == null) return '';
  try {
    if (accessToken is String) return accessToken;
    if (accessToken is Map) {
      return (accessToken['token'] ?? accessToken['accessToken'] ?? '')
              ?.toString() ??
          '';
    }
    // Try common field names used by different versions
    final val = (accessToken.token ??
        accessToken.accessToken ??
        accessToken.tokenString);
    if (val != null) return val.toString();
    // Try toJson fallback
    if ((accessToken as dynamic).toJson is Function) {
      final json = (accessToken as dynamic).toJson();
      if (json is Map) {
        return (json['token'] ?? json['accessToken'] ?? '')?.toString() ?? '';
      }
    }
  } catch (e) {
    // swallow and return empty string
  }
  return '';
}




