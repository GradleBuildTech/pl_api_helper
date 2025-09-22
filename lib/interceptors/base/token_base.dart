import '../../delegation/token_delegation.dart';

abstract class BaseTokenInterceptor {
  /// Delegate to handle token storage and retrieval
  final TokenDelegation tokenDelegate;

  /// Endpoint to refresh the token
  final String? refreshEndpoint;

  /// Function to parse the refresh response and extract new tokens
  final (String? newAccess, String? newRefresh) Function(dynamic response)?
  refreshResponseParser;

  /// Function to build the payload for the refresh request
  final Map<String, dynamic> Function(String token)? refreshPayloadBuilder;

  /// Callback when user is unauthenticated and token cannot be refreshed
  final Function()? onUnauthenticated;

  BaseTokenInterceptor({
    this.refreshEndpoint,
    this.refreshResponseParser,
    this.refreshPayloadBuilder,
    this.onUnauthenticated,
    required this.tokenDelegate,
  }) : assert(
         (refreshEndpoint == null &&
                 refreshPayloadBuilder == null &&
                 refreshResponseParser == null) ||
             (refreshEndpoint != null &&
                 refreshPayloadBuilder != null &&
                 refreshResponseParser != null),
         'All refresh parameters must be provided together or none at all.',
       );

  /// Method to refresh the token
  Future<String> refreshToken();

  /// Method to clear tokens and handle unauthenticated state
  void handleTokenClear({bool emitUnauthenticated = true}) async {
    await tokenDelegate.deleteToken();
    if (emitUnauthenticated) {
      onUnauthenticated?.call();
    }
  }
}
