import 'package:flutterquiz/features/wallet/models/payout_method.dart';
import 'package:flutterquiz/utils/constants/string_labels.dart';

export 'api_body_parameter_labels.dart';
export 'api_endpoints_constants.dart';
export 'assets_constants.dart';
export 'error_message_keys.dart';
export 'fonts.dart';
export 'hive_constants.dart';
export 'sound_constants.dart';
export 'string_labels.dart';

const appName = 'Sorugami';
const packageName = 'com.sorugami.app';

/// Add your database url
// NOTE: make sure to not add '/' at the end of url
// NOTE: make sure to check if admin panel is http or https
const databaseUrl = 'https://admin.sorugami.com';

// Enter 2 Letter ISO Country Code
const defaultCountryCodeForPhoneLogin = 'IN';

/// Default App Theme : lightThemeKey or darkThemeKey
const defaultThemeKey = lightThemeKey;

//Database related constants
const baseUrl = '$databaseUrl/Api/';

//lifelines
const fiftyFifty = 'fiftyFifty';
const audiencePoll = 'audiencePoll';
const skip = 'skip';
const resetTime = 'resetTime';

//firestore collection names
const battleRoomCollection = 'battleRoom';
const multiUserBattleRoomCollection = 'multiUserBattleRoom';
const messagesCollection = 'messages';
const informationsCollection = 'informations';

// Phone Number
const maxPhoneNumberLength = 16;

const inBetweenQuestionTimeInSeconds = 1;

//predefined messages for battle
const predefinedMessages = [
  'Merhaba..!!',
  'Nasılsın..?',
  'İyiyim..!!',
  'İyi günler..',
  'Güzel oynadın',
  'Ne performans..!!',
  'Teşekkürler..',
  'Rica ederim..',
  'Mutlu Noeller',
  'Mutlu Yıllar',
  'Mutlu Diwali',
  'İyi geceler',
  'Acele et',
  'Dostummmm',
];

//constants for badges and rewards
const minimumQuestionsForBadges = 5;

///
///Add your exam rules here
///
const examRules = [
  'Bu sınavı dürüstçe tamamlayacağım ve kopya çekmeyeceğim',
  'Telefonunuzu kilitlemeniz durumunda sınav otomatik olarak tamamlanacaktır',
  'Uygulamayı küçültürseniz veya başka bir uygulama açıp 5 saniye içinde uygulamaya geri dönmezseniz sınav otomatik olarak tamamlanacaktır',
  'Ekran kaydı yasaktır',
  'Android’de ekran görüntüsü almak yasaktır',
  'iOS\'ta ekran görüntüsü alırsanız kuralları ihlal etmiş olursunuz ve bu durum sınav görevlisine bildirilecektir',
];

//
//Add notes for wallet request
//

List<String> payoutRequestNotes(
  String payoutRequestCurrency,
  String amount,
  String coins,
) {
  return [
    'Minimum çekilebilir tutar $payoutRequestCurrency $amount ($coins Coin).',
    'Ödeme yapılması 3 - 5 iş günü sürecektir',
  ];
}

//To add more payout methods here
final payoutMethods = [
  //Paypal
  PayoutMethod(
    image: 'assets/images/iban.jpeg',
    type: 'BANKA',
    inputs: [
      (
        name: 'Lütfen IBAN numaranızı giriniz', // Name for the field
        isNumber: false, // If input is number or not
        maxLength: 0, // Leave 0 for no limit for input.
      ),
    ],
  ),

  //Paytm
  PayoutMethod(
    image: 'assets/images/tether.jpeg',
    type: 'TETHER',
    inputs: [
      (
        name: 'Tether (USDT) adresinizi giriniz',
        isNumber: true,
        maxLength: 10,
      ),
    ],
  ),

  /// Example: Bank Transfer
  // PayoutMethod(
  //   inputs: [
  //     (
  //       name: 'Enter Bank Name',
  //       isNumber: false,
  //       maxLength: 0,
  //     ),
  //     (
  //       name: 'Enter Account Number',
  //       isNumber: false,
  //       maxLength: 0,
  //     ),
  //     (
  //       name: 'Enter IFSC Code',
  //       isNumber: false,
  //       maxLength: 0,
  //     ),
  //   ],
  //   image: 'assets/images/paytm.svg',
  //   type: 'Bank Transfer',
  // ),
];

// Max Group Battle Players, do not change.
const maxUsersInGroupBattle = 4;
