import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:core/utils/app_logger.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:tmail_ui_user/features/push_notification/domain/state/web_socket_push_state.dart';
import 'package:tmail_ui_user/features/push_notification/domain/usecases/connect_web_socket_interactor.dart';
import 'package:tmail_ui_user/features/push_notification/presentation/controller/push_base_controller.dart';
import 'package:tmail_ui_user/features/push_notification/presentation/extensions/state_change_extension.dart';
import 'package:tmail_ui_user/features/push_notification/presentation/listener/email_change_listener.dart';
import 'package:tmail_ui_user/features/push_notification/presentation/listener/mailbox_change_listener.dart';
import 'package:tmail_ui_user/main/routes/route_navigation.dart';

class WebSocketController extends PushBaseController {
  WebSocketController._internal();

  static final WebSocketController _instance = WebSocketController._internal();

  static WebSocketController get instance => _instance;

  ConnectWebSocketInteractor? _connectWebSocketInteractor;

  @override
  void handleFailureViewState(Failure failure) {
    logError('WebSocketController::handleFailureViewState():Failure $failure');
  }

  @override
  void handleSuccessViewState(Success success) {
    log('WebSocketController::handleSuccessViewState():Success $success');
    if (success is WebSocketPushStateReceived) {
      _handleWebSocketPushStateReceived(success);
    }
  }

  @override
  void initialize({AccountId? accountId, Session? session}) {
    super.initialize(accountId: accountId, session: session);

    _connectWebSocket(accountId, session);
  }

  void _connectWebSocket(AccountId? accountId, Session? session) {
    _connectWebSocketInteractor = getBinding<ConnectWebSocketInteractor>();
    if (_connectWebSocketInteractor == null || accountId == null || session == null) {
      return;
    }

    consumeState(_connectWebSocketInteractor!.execute(session, accountId));
  }
  
  void _handleWebSocketPushStateReceived(WebSocketPushStateReceived success) {
    log('WebSocketController::_handleWebSocketPushStateReceived(): $success');
    if (accountId == null || session == null) return;
    final stateChange = success.stateChange;
    final mapTypeState = stateChange.getMapTypeState(accountId!);
    mappingTypeStateToAction(
      mapTypeState,
      accountId!,
      emailChangeListener: EmailChangeListener.instance,
      mailboxChangeListener: MailboxChangeListener.instance,
      session!.username,
      session: session);
  }
}