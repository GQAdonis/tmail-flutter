import 'package:model/oidc/oidc_configuration.dart';
import 'package:model/oidc/token_oidc.dart';
import 'package:tmail_ui_user/features/login/data/network/authentication_client/authentication_client_base.dart';
import 'package:tmail_ui_user/features/starting_page/data/datasource/saas_authentication_datasource.dart';
import 'package:tmail_ui_user/main/exceptions/exception_thrower.dart';

class SaasAuthenticationDataSourceImpl extends SaasAuthenticationDataSource {

  final AuthenticationClientBase _authenticationClient;
  final ExceptionThrower _exceptionThrower;

  SaasAuthenticationDataSourceImpl(
    this._authenticationClient,
    this._exceptionThrower,
  );

  @override
  Future<TokenOIDC> signInTwakeWorkplace(OIDCConfiguration oidcConfiguration) {
    return Future.sync(() async {
      return await _authenticationClient.signInTwakeWorkplace(oidcConfiguration);
    }).catchError(_exceptionThrower.throwException);
  }

  @override
  Future<TokenOIDC> signUpTwakeWorkplace(OIDCConfiguration oidcConfiguration) {
    return Future.sync(() async {
      return await _authenticationClient.signUpTwakeWorkplace(oidcConfiguration);
    }).catchError(_exceptionThrower.throwException);
  }
}