import 'package:flutter/material.dart';
import 'package:fantasyleague/constance/constance.dart';
import 'package:fantasyleague/constance/routes.dart';
import 'package:fantasyleague/constance/themes.dart';

class Dialogs {
  static void showDialogWithOneButton(
    BuildContext? context,
    String? title,
    String? content, {
    String? buttonLabel = "Okay",
    required VoidCallback? onButtonPress,
    barrierDismissible = true,
  }) {
    showDialog(
      context: context!,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext buildContext) {
        return AlertDialog(
          title: Text(title!),
          content: Text(content!),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if (onButtonPress != null) {
                  onButtonPress();
                } else {
                  Navigator.of(buildContext).pop();
                }
              },
              child: Text(buttonLabel!),
            ),
          ],
        );
      },
    );
  }

  // Returns true when the first button is pressed, false for the second, null if dismissed.
  static Future<bool?> showDialogWithTwoButtons(
    BuildContext? context,
    String? title,
    String? content, {
    String? button1Label = "Okay",
    String? button2Label = "Cancel",
    barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context!,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext buildContext) {
        return AlertDialog(
          title: Text(title!),
          content: Text(content!),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(buildContext).pop(true);
              },
              child: Text(button1Label!),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(buildContext).pop(false);
              },
              child: Text(button2Label!),
            ),
          ],
        );
      },
    );
  }

  static void showDeadlineDialogWithOneButton(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext buildContext) {
        return AlertDialog(
          title: const Text(
            'The deadline has passed!',
          ),
          content: const Text(
            "Check out the contests you've joined for this match.",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: ConstanceData.SIZE_TITLE16,
            ),
          ),
          actions: <Widget>[
            InkWell(
              child: Text(
                "Ok",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AllCoustomTheme.getThemeData().primaryColor,
                  fontSize: ConstanceData.SIZE_TITLE18,
                ),
              ),
              onTap: () => Navigator.pop(context),
            )
          ],
        );
      },
    ).then((onValue) {
      Navigator.of(context)
          .pushNamedAndRemoveUntil(Routes.TAB, (Route<dynamic> route) => false);
    });
  }
}
