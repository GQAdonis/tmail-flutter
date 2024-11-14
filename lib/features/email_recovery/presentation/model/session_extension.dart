
import 'package:duration/duration.dart';
import 'package:email_recovery/email_recovery/capability_deleted_messages_vault.dart';
import 'package:jmap_dart_client/jmap/core/capability/capability_identifier.dart';
import 'package:jmap_dart_client/jmap/core/capability/capability_properties.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';

extension SessionExtension on Session {

  String getRestorationHorizonAsString() {
    return ((props[0] as Map<CapabilityIdentifier, CapabilityProperties>?)
        ?[capabilityDeletedMessagesVault]
        ?.props[0] as Map<String, dynamic>?)
        ?['restorationHorizon']
        ?? "15 days";
  }

  Duration getRestorationHorizonAsDuration() {
    String horizonWithCorrectFormat = getRestorationHorizonAsString()
        .replaceAll(" days", "d")
        .replaceAll(" day", "d")
        .replaceAll(" hours", "h")
        .replaceAll(" hour", "h")
        .replaceAll(" minutes", "m")
        .replaceAll(" minute", "m")
        .replaceAll(" seconds", "s")
        .replaceAll(" second", "s")
        .replaceAll(" milliseconds", "ms")
        .replaceAll(" millisecond", "ms");

    return parseDuration(horizonWithCorrectFormat, separator: ' ');
  }

  DateTime getRestorationHorizonAsDateTime() {
    return DateTime.now().subtract(getRestorationHorizonAsDuration());
  }
}