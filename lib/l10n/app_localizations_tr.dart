// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'What\'s Your Mood';

  @override
  String get continueBtn => 'Devam';

  @override
  String get start => 'Başla';

  @override
  String get next => 'Sonraki';

  @override
  String get nextRound => 'Sonraki Tur';

  @override
  String get finishGame => 'Oyunu Bitir';

  @override
  String get playAgain => 'Yeniden Oyna';

  @override
  String get homePage => 'Ana Sayfa';

  @override
  String get onboardingTitle1 => 'Eğlence Başlasın!';

  @override
  String get onboardingDesc1 => 'Arkadaşlarınla birlikte en komik ve yaratıcı cevapları bul.';

  @override
  String get onboardingTitle2 => 'Fotoğrafını Seç';

  @override
  String get onboardingDesc2 => 'Her turda bir mood kartı görürsün ve en uygun fotoğrafını seçersin.';

  @override
  String get onboardingTitle3 => 'Anıları Paylaş';

  @override
  String get onboardingDesc3 => 'Komik ve eğlenceli anları paylaş, eğlence hiç bitmesin!';

  @override
  String get round => 'Tur';

  @override
  String roundOf(int total) {
    return '$total';
  }

  @override
  String get moodQ1 => 'Ne zaman mutlu hissediyorum?';

  @override
  String get moodQ2 => 'Nerede en rahat hissediyorum?';

  @override
  String get moodQ3 => 'Kimle birlikte kendimi doğal hissediyorum?';

  @override
  String get moodQ4 => 'Hangi müzik beni mutlu eder?';

  @override
  String get moodQ5 => 'En sevdiğim yemek nedir?';

  @override
  String get moodQ6 => 'En rahatladığım an?';

  @override
  String get moodQ7 => 'En eğlendiğim zaman?';

  @override
  String get moodQ8 => 'En güvende hissettiğim yer?';

  @override
  String get moodQ9 => 'Bana ilham veren şey?';

  @override
  String get moodQ10 => 'En mutlu olduğum anı?';

  @override
  String get gameCompleted => 'Oyun Tamamlandı!';

  @override
  String get gameCompletedDesc => 'Tüm turlar bitti. Tebrikler!';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Ayarlar';

  @override
  String get help => 'Yardım';

  @override
  String get about => 'Hakkında';

  @override
  String get language => 'Dil';

  @override
  String get theme => 'Tema';

  @override
  String get light => 'Açık';

  @override
  String get dark => 'Koyu';

  @override
  String get custom => 'Özel';

  @override
  String get turkish => 'Türkçe';

  @override
  String get english => 'İngilizce';

  @override
  String get spanish => 'İspanyolca';

  @override
  String get profileComingSoon => 'Profil yakında gelecek';

  @override
  String get helpComingSoon => 'Yardım yakında gelecek';

  @override
  String get aboutComingSoon => 'Hakkında yakında gelecek';
}
