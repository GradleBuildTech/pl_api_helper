import '../../delegation/token_delegation.dart';

abstract class BaseTokenInterceptor {
  final TokenDelegation tokenDelegate;
  final String? refreshEndpoint;
  final (String? newAccess, String? newRefresh) Function(dynamic response)?
  refreshResponseParser;
  final Map<String, dynamic> Function(String token)? refreshPayloadBuilder;

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

  Future<String> refreshToken();

  void handleTokenClear({bool emitUnauthenticated = true}) async {
    await tokenDelegate.deleteToken();
    if (emitUnauthenticated) {
      onUnauthenticated?.call();
    }
  }
}
