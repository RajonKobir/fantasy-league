import 'dart:ui';

import 'package:intl/intl.dart';

class Validators {
  bool emailValidator(String email) {
    // basic length check
    if (email.isEmpty || email.length > 254) return false;

    // must contain exactly one "@"
    final parts = email.split('@');
    if (parts.length != 2) return false;

    final local = parts[0];
    final domain = parts[1];

    // local & domain must exist
    if (local.isEmpty || domain.isEmpty) return false;

    // local part rules
    if (local.startsWith('.') || local.endsWith('.')) return false;
    if (local.contains('..')) return false;

    // domain rules
    if (!domain.contains('.')) return false;
    if (domain.startsWith('.') || domain.endsWith('.')) return false;
    if (domain.contains('..')) return false;

    // allowed characters (manual check)
    const allowed = 'abcdefghijklmnopqrstuvwxyz'
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        '0123456789'
        '.-_+';

    for (final ch in local.split('')) {
      if (!allowed.contains(ch)) return false;
    }

    for (final ch in domain.replaceAll('.', '').split('')) {
      if (!allowed.contains(ch)) return false;
    }

    return true;
  }

  /// Validates a login identifier which must be an email address.
  bool loginValidator(String input) {
    if (input.isEmpty) return false;
    return emailValidator(input);
  }

  bool phoneValidator(String phone) => phone.length > 5;

  bool passwordValidator(String password) => password.length > 6;

  String timeForApi(int seconds) {
    var secondOfDate = DateTime.fromMillisecondsSinceEpoch(seconds);
    var formatter = DateFormat('yyyy-MM-dd');
    String formattedString = formatter.format(secondOfDate);
    return formattedString;
  }
}

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}




