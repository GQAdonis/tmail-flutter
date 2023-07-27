
import 'package:core/presentation/extensions/color_extension.dart';
import 'package:flutter/material.dart';
import 'package:jmap_dart_client/jmap/mail/calendar/properties/attendee/calendar_attendee.dart';
import 'package:tmail_ui_user/features/email/presentation/styles/attendee_widget_styles.dart';

class AttendeeWidget extends StatelessWidget {

  final CalendarAttendee attendee;

  const AttendeeWidget({
    super.key,
    required this.attendee
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: AttendeeWidgetStyles.textSize,
          fontWeight: FontWeight.w500,
          color: Colors.black
        ),
        children: [
          if (attendee.name?.name.isNotEmpty == true)
            TextSpan(text: attendee.name!.name),
          if (attendee.mailto?.mailAddress.value.isNotEmpty == true)
            TextSpan(
              text: ' <${attendee.mailto!.mailAddress.value}> ',
              style: const TextStyle(
                color: AppColor.colorMailto,
                fontSize: AttendeeWidgetStyles.textSize,
                fontWeight: FontWeight.w500
              ),
            ),
          const TextSpan(text: ', '),
        ]
      )
    );
  }
}