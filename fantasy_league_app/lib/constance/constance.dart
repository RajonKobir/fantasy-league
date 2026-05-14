import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConstanceData {
  static String get UserImageUrl => dotenv.env['USER_IMAGE_URL'] ?? '';
  static String get Ligality => dotenv.env['LEGALITY_URL'] ?? '';
  static String get appIcon {
    try {
      return dotenv.env['APP_ICON_URL'] ?? 'assets/playerImage.png';
    } catch (e) {
      return 'assets/playerImage.png';
    }
  }

  static const PASSWORD_MIN_LENGTH = 6;
  static const TermsofService = '';
  static const PrivacyPolicy = '';
  static const HowItWork = '';
  static const PointSystem = '';

  static const NoInternet = 'No internet connection\nPlease!. try again later.';

  static const SIZE_TITLE10 = 10.0;
  static const SIZE_TITLE12 = 12.0;
  static const SIZE_TITLE14 = 14.0;
  static const SIZE_TITLE16 = 16.0;
  static const SIZE_TITLE18 = 18.0;
  static const SIZE_TITLE20 = 20.0;
  static const SIZE_TITLE22 = 22.0;

  static const Usertoken = 'Usertoken';
  static const UserData = 'UserData';
  static const Is_login = 'Is_login';

  static const gameGround = 'assets/gameGround.png';
  static const playerImage = 'assets/playerImage.png';
  static const lineups = 'assets/lineups.png';
  static const tv = 'assets/tv.png';

  // Added missing assets used in the app
  static const notificationCup = 'assets/notification_cup.png';
  static const palyerProfilePic = 'assets/palyer_profile_pic.png';
}
