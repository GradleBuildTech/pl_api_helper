abstract class TokenDelegation {
  Future<String> getAccessToken();
  Future<String> getRefreshToken();
  Future<void> saveAccessToken(String token);
  Future<void> deleteToken();
  Future<void> saveRefreshToken(String refreshToken);
  Future<void> saveTokens(String accessToken, String? refreshToken);
}
