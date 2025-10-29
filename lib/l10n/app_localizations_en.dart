// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'What\'s Your Mood';

  @override
  String get continueBtn => 'Continue';

  @override
  String get start => 'Start';

  @override
  String get next => 'Next';

  @override
  String get nextRound => 'Next Round';

  @override
  String get finishGame => 'Finish Game';

  @override
  String get playAgain => 'Play Again';

  @override
  String get homePage => 'Home Page';

  @override
  String get onboardingTitle1 => 'Let\'s Start the Fun!';

  @override
  String get onboardingDesc1 => 'Find the funniest and most creative answers with your friends.';

  @override
  String get onboardingTitle2 => 'Select Your Photo';

  @override
  String get onboardingDesc2 => 'In each round, you\'ll see a mood card and choose your most fitting photo.';

  @override
  String get onboardingTitle3 => 'Share Moments';

  @override
  String get onboardingDesc3 => 'Share funny and entertaining moments, let the fun never end!';

  @override
  String get round => 'Round';

  @override
  String roundOf(int total) {
    return '$total';
  }

  @override
  String get moodQ1 => 'When do I feel happy?';

  @override
  String get moodQ2 => 'Where do I feel most comfortable?';

  @override
  String get moodQ3 => 'With whom do I feel most natural?';

  @override
  String get moodQ4 => 'What music makes me happy?';

  @override
  String get moodQ5 => 'What\'s my favorite food?';

  @override
  String get moodQ6 => 'When do I feel most relaxed?';

  @override
  String get moodQ7 => 'When do I have the most fun?';

  @override
  String get moodQ8 => 'Where do I feel safest?';

  @override
  String get moodQ9 => 'What inspires me?';

  @override
  String get moodQ10 => 'My happiest memory?';

  @override
  String get gameCompleted => 'Game Completed!';

  @override
  String get gameCompletedDesc => 'All rounds completed. Congratulations!';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get help => 'Help';

  @override
  String get about => 'About';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get custom => 'Custom';

  @override
  String get turkish => 'Turkish';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Spanish';

  @override
  String get profileComingSoon => 'Profile coming soon';

  @override
  String get helpComingSoon => 'Help coming soon';

  @override
  String get aboutComingSoon => 'About coming soon';
}
