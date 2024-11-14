
import 'package:email_recovery/email_recovery/capability_deleted_messages_vault.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jmap_dart_client/jmap/core/capability/default_capability.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/core/state.dart';
import 'package:jmap_dart_client/jmap/core/user_name.dart';
import 'package:tmail_ui_user/features/email_recovery/presentation/model/session_extension.dart';

void main() {

  group('session extension test:', () {
    test(
        'getRestorationHorizonAsDuration() should return the horizon as a duration',
            () {
          // arrange
          const duration = Duration(days: 15);

          final session = Session(
              {capabilityDeletedMessagesVault: DefaultCapability({"restorationHorizon": "15 days"})},
              {}, {}, UserName(''), Uri(), Uri(), Uri(), Uri(), State(''));

          // act
          final horizon = session.getRestorationHorizonAsDuration();

          // assert
          expect(horizon, duration);
        });

    test(
        'getRestorationHorizonAsString should return the horizon as a String',
            () {
          // arrange
          final session = Session(
              {capabilityDeletedMessagesVault: DefaultCapability({"restorationHorizon": "15 days"})},
              {}, {}, UserName(''), Uri(), Uri(), Uri(), Uri(), State(''));

          // act
          final horizon = session.getRestorationHorizonAsString();

          // assert
          expect(horizon, "15 days");
        });
  });
}