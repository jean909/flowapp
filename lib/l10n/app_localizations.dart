import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ro.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('ro'),
  ];

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// No description provided for @activeChallenges.
  ///
  /// In en, this message translates to:
  /// **'Active Challenges'**
  String get activeChallenges;

  /// No description provided for @hallOfFame.
  ///
  /// In en, this message translates to:
  /// **'Hall of Fame'**
  String get hallOfFame;

  /// No description provided for @keepItFlowing.
  ///
  /// In en, this message translates to:
  /// **'Keep it flowin\'!'**
  String get keepItFlowing;

  /// No description provided for @todaysMeals.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Meals'**
  String get todaysMeals;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @popularNow.
  ///
  /// In en, this message translates to:
  /// **'Popular Now'**
  String get popularNow;

  /// No description provided for @allChallenges.
  ///
  /// In en, this message translates to:
  /// **'All Challenges'**
  String get allChallenges;

  /// No description provided for @flowChallenges.
  ///
  /// In en, this message translates to:
  /// **'Flow Challenges'**
  String get flowChallenges;

  /// No description provided for @searchChallenges.
  ///
  /// In en, this message translates to:
  /// **'Search challenges...'**
  String get searchChallenges;

  /// No description provided for @membersEnrolled.
  ///
  /// In en, this message translates to:
  /// **'members enrolled'**
  String get membersEnrolled;

  /// No description provided for @beginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get beginner;

  /// No description provided for @intermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get intermediate;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @challengeBenefits.
  ///
  /// In en, this message translates to:
  /// **'Challenge Benefits'**
  String get challengeBenefits;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @joinNow.
  ///
  /// In en, this message translates to:
  /// **'JOIN NOW'**
  String get joinNow;

  /// No description provided for @stayingStrong.
  ///
  /// In en, this message translates to:
  /// **'STAYING STRONG'**
  String get stayingStrong;

  /// No description provided for @joinedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Joined challenge successfully! 🚀'**
  String get joinedSuccessfully;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @challenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get challenges;

  /// No description provided for @social.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get social;

  /// No description provided for @ai.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get ai;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @aboutFlow.
  ///
  /// In en, this message translates to:
  /// **'About Flow'**
  String get aboutFlow;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @dailyStreaks.
  ///
  /// In en, this message translates to:
  /// **'Daily Streaks'**
  String get dailyStreaks;

  /// No description provided for @coins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get coins;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get alreadyHaveAccount;

  /// No description provided for @needAccount.
  ///
  /// In en, this message translates to:
  /// **'Need an account? Sign Up'**
  String get needAccount;

  /// No description provided for @pleaseFillFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get pleaseFillFields;

  /// No description provided for @onboardingCompleteRequired.
  ///
  /// In en, this message translates to:
  /// **'Please complete this step to continue.'**
  String get onboardingCompleteRequired;

  /// No description provided for @onboardingBodyMetricsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter height (cm) and current weight (kg).'**
  String get onboardingBodyMetricsHint;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get invalidEmail;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get passwordMinLength;

  /// No description provided for @welcomeFamily.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the Flow family! One last step...'**
  String get welcomeFamily;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'GET STARTED'**
  String get getStarted;

  /// No description provided for @nicknameTitle.
  ///
  /// In en, this message translates to:
  /// **'How should we call you?'**
  String get nicknameTitle;

  /// No description provided for @nicknameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your journey deserves a name.'**
  String get nicknameSubtitle;

  /// No description provided for @nicknameHint.
  ///
  /// In en, this message translates to:
  /// **'Your Nickname'**
  String get nicknameHint;

  /// No description provided for @missionTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your mission?'**
  String get missionTitle;

  /// No description provided for @missionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We will tailor your experience based on your objective.'**
  String get missionSubtitle;

  /// No description provided for @loseWeight.
  ///
  /// In en, this message translates to:
  /// **'Lose Weight'**
  String get loseWeight;

  /// No description provided for @loseWeightDesc.
  ///
  /// In en, this message translates to:
  /// **'Burn fat and get leaner'**
  String get loseWeightDesc;

  /// No description provided for @maintainHealth.
  ///
  /// In en, this message translates to:
  /// **'Maintain Health'**
  String get maintainHealth;

  /// No description provided for @maintainHealthDesc.
  ///
  /// In en, this message translates to:
  /// **'Balance and vitality'**
  String get maintainHealthDesc;

  /// No description provided for @gainMuscle.
  ///
  /// In en, this message translates to:
  /// **'Gain Muscle'**
  String get gainMuscle;

  /// No description provided for @gainMuscleDesc.
  ///
  /// In en, this message translates to:
  /// **'Build strength and mass'**
  String get gainMuscleDesc;

  /// No description provided for @additionalFocus.
  ///
  /// In en, this message translates to:
  /// **'Additional Focus'**
  String get additionalFocus;

  /// No description provided for @focusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select up to 3 areas you want to improve.'**
  String get focusSubtitle;

  /// No description provided for @genderTitle.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderTitle;

  /// No description provided for @genderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Biological factors help us calculate your needs.'**
  String get genderSubtitle;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @ageTitle.
  ///
  /// In en, this message translates to:
  /// **'How old are you?'**
  String get ageTitle;

  /// No description provided for @ageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Metabolism changes with age.'**
  String get ageSubtitle;

  /// No description provided for @bodyMetricsTitle.
  ///
  /// In en, this message translates to:
  /// **'Body Metrics'**
  String get bodyMetricsTitle;

  /// No description provided for @bodyMetricsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Precision is the key to progress.'**
  String get bodyMetricsSubtitle;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @currentWeight.
  ///
  /// In en, this message translates to:
  /// **'Current Weight'**
  String get currentWeight;

  /// No description provided for @targetWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Target Weight'**
  String get targetWeightTitle;

  /// No description provided for @targetWeightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where do you want to be?'**
  String get targetWeightSubtitle;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Activity'**
  String get activityTitle;

  /// No description provided for @activitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How active are you on a regular basis?'**
  String get activitySubtitle;

  /// No description provided for @sedentary.
  ///
  /// In en, this message translates to:
  /// **'Sedentary'**
  String get sedentary;

  /// No description provided for @sedentaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Little or no exercise'**
  String get sedentaryDesc;

  /// No description provided for @lightlyActive.
  ///
  /// In en, this message translates to:
  /// **'Lightly Active'**
  String get lightlyActive;

  /// No description provided for @lightlyActiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Exercise 1-3 times/week'**
  String get lightlyActiveDesc;

  /// No description provided for @moderatelyActive.
  ///
  /// In en, this message translates to:
  /// **'Moderately Active'**
  String get moderatelyActive;

  /// No description provided for @moderatelyActiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Exercise 4-5 times/week'**
  String get moderatelyActiveDesc;

  /// No description provided for @veryActive.
  ///
  /// In en, this message translates to:
  /// **'Very Active'**
  String get veryActive;

  /// No description provided for @veryActiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Daily exercise or intense sports'**
  String get veryActiveDesc;

  /// No description provided for @smokingTitle.
  ///
  /// In en, this message translates to:
  /// **'Smoking Habit'**
  String get smokingTitle;

  /// No description provided for @smokingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This helps us understand your nutrient requirements.'**
  String get smokingSubtitle;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @verifyAccount.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Account'**
  String get verifyAccount;

  /// No description provided for @sentLink.
  ///
  /// In en, this message translates to:
  /// **'We sent a confirmation link to your email. Please click it to activate your flow.'**
  String get sentLink;

  /// No description provided for @iveConfirmed.
  ///
  /// In en, this message translates to:
  /// **'I\'ve Confirmed'**
  String get iveConfirmed;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @accountPaused.
  ///
  /// In en, this message translates to:
  /// **'Account paused'**
  String get accountPaused;

  /// No description provided for @accountPausedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your email was not confirmed in time. Confirm your email to reactivate your account and continue using Flow.'**
  String get accountPausedMessage;

  /// No description provided for @resendConfirmationEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend confirmation email'**
  String get resendConfirmationEmail;

  /// No description provided for @confirmationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Confirmation email sent. Check your inbox.'**
  String get confirmationEmailSent;

  /// No description provided for @verificationPending.
  ///
  /// In en, this message translates to:
  /// **'Verification pending. Please check your email and click the link.'**
  String get verificationPending;

  /// No description provided for @journalHistory.
  ///
  /// In en, this message translates to:
  /// **'Journal History'**
  String get journalHistory;

  /// No description provided for @usernameAndDisplayNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username and display name are required'**
  String get usernameAndDisplayNameRequired;

  /// No description provided for @pleaseChooseAvailableUsername.
  ///
  /// In en, this message translates to:
  /// **'Please choose an available username'**
  String get pleaseChooseAvailableUsername;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'username'**
  String get usernameHint;

  /// No description provided for @yourNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourNameHint;

  /// No description provided for @tellUsAboutYourselfHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself...'**
  String get tellUsAboutYourselfHint;

  /// No description provided for @welcomeToSocial.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Social! 👋'**
  String get welcomeToSocial;

  /// No description provided for @createUniqueProfile.
  ///
  /// In en, this message translates to:
  /// **'Create your unique profile to start\nsharing your fitness journey'**
  String get createUniqueProfile;

  /// No description provided for @completeSetup.
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get completeSetup;

  /// No description provided for @usernameRules.
  ///
  /// In en, this message translates to:
  /// **'Lowercase letters, numbers, and underscores only'**
  String get usernameRules;

  /// No description provided for @errorCheckingUsername.
  ///
  /// In en, this message translates to:
  /// **'Error checking username'**
  String get errorCheckingUsername;

  /// No description provided for @usernameAlreadyTaken.
  ///
  /// In en, this message translates to:
  /// **'Username already taken'**
  String get usernameAlreadyTaken;

  /// No description provided for @usernameFormatError.
  ///
  /// In en, this message translates to:
  /// **'Only lowercase letters, numbers, and underscores (3-30 chars)'**
  String get usernameFormatError;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayNameLabel;

  /// No description provided for @bioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bioLabel;

  /// No description provided for @water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get water;

  /// No description provided for @activeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Active'**
  String activeCount(int count);

  /// No description provided for @addWorkout.
  ///
  /// In en, this message translates to:
  /// **'Add Workout'**
  String get addWorkout;

  /// No description provided for @speechRecognitionNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition not available'**
  String get speechRecognitionNotAvailable;

  /// No description provided for @errorStartingRecording.
  ///
  /// In en, this message translates to:
  /// **'Error starting recording: {error}'**
  String errorStartingRecording(String error);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @switchToFreePlan.
  ///
  /// In en, this message translates to:
  /// **'Switch to Free plan?'**
  String get switchToFreePlan;

  /// No description provided for @switchToPlanForCoins.
  ///
  /// In en, this message translates to:
  /// **'Switch to {plan} plan for {cost} coins per month?'**
  String switchToPlanForCoins(String plan, int cost);

  /// No description provided for @planSetToFree.
  ///
  /// In en, this message translates to:
  /// **'Plan set to Free.'**
  String get planSetToFree;

  /// No description provided for @planUpgradedTo.
  ///
  /// In en, this message translates to:
  /// **'Plan upgraded to {plan}!'**
  String planUpgradedTo(String plan);

  /// No description provided for @exportCsvSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported {count} entries to CSV successfully!'**
  String exportCsvSuccess(int count);

  /// No description provided for @exportJsonSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported {count} entries to JSON successfully!'**
  String exportJsonSuccess(int count);

  /// No description provided for @exportError.
  ///
  /// In en, this message translates to:
  /// **'Error exporting: {error}'**
  String exportError(String error);

  /// No description provided for @pdfReportSuccess.
  ///
  /// In en, this message translates to:
  /// **'PDF report generated successfully! ({count} entries)'**
  String pdfReportSuccess(int count);

  /// No description provided for @pdfReportError.
  ///
  /// In en, this message translates to:
  /// **'Error generating PDF: {error}'**
  String pdfReportError(String error);

  /// No description provided for @waterLogged.
  ///
  /// In en, this message translates to:
  /// **'{action} logged!'**
  String waterLogged(String action);

  /// No description provided for @snacks.
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get snacks;

  /// No description provided for @logSleep.
  ///
  /// In en, this message translates to:
  /// **'Log Sleep'**
  String get logSleep;

  /// No description provided for @bedtime.
  ///
  /// In en, this message translates to:
  /// **'Bedtime'**
  String get bedtime;

  /// No description provided for @wakeTime.
  ///
  /// In en, this message translates to:
  /// **'Wake Time'**
  String get wakeTime;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @enterDurationManually.
  ///
  /// In en, this message translates to:
  /// **'Or enter duration manually:'**
  String get enterDurationManually;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// No description provided for @hoursHint.
  ///
  /// In en, this message translates to:
  /// **'Hours (e.g., 7.5)'**
  String get hoursHint;

  /// No description provided for @sleepQuality.
  ///
  /// In en, this message translates to:
  /// **'Sleep Quality:'**
  String get sleepQuality;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesOptional;

  /// No description provided for @sleepLoggedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Sleep logged successfully! 😴'**
  String get sleepLoggedSuccess;

  /// No description provided for @logMood.
  ///
  /// In en, this message translates to:
  /// **'Log Mood'**
  String get logMood;

  /// No description provided for @howAreYouFeeling.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling?'**
  String get howAreYouFeeling;

  /// No description provided for @moodScore.
  ///
  /// In en, this message translates to:
  /// **'Mood Score (1-10):'**
  String get moodScore;

  /// No description provided for @energyLevel.
  ///
  /// In en, this message translates to:
  /// **'Energy Level:'**
  String get energyLevel;

  /// No description provided for @stressLevel.
  ///
  /// In en, this message translates to:
  /// **'Stress Level:'**
  String get stressLevel;

  /// No description provided for @activities.
  ///
  /// In en, this message translates to:
  /// **'Activities:'**
  String get activities;

  /// No description provided for @moodLoggedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Mood logged successfully! 😊'**
  String get moodLoggedSuccess;

  /// No description provided for @pleaseSelectDatePlannedWorkout.
  ///
  /// In en, this message translates to:
  /// **'Please select a date for planned workout'**
  String get pleaseSelectDatePlannedWorkout;

  /// No description provided for @pleaseEnterRoutineName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a routine name'**
  String get pleaseEnterRoutineName;

  /// No description provided for @workoutPlannedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Workout planned successfully!'**
  String get workoutPlannedSuccess;

  /// No description provided for @workoutLoggedKcal.
  ///
  /// In en, this message translates to:
  /// **'Workout logged! {kcal} kcal burned'**
  String workoutLoggedKcal(String kcal);

  /// No description provided for @logWorkout.
  ///
  /// In en, this message translates to:
  /// **'Log Workout'**
  String get logWorkout;

  /// No description provided for @planForLater.
  ///
  /// In en, this message translates to:
  /// **'Plan for later'**
  String get planForLater;

  /// No description provided for @scheduleWorkoutFuture.
  ///
  /// In en, this message translates to:
  /// **'Schedule this workout for a future date'**
  String get scheduleWorkoutFuture;

  /// No description provided for @saveAsRoutine.
  ///
  /// In en, this message translates to:
  /// **'Save as Routine'**
  String get saveAsRoutine;

  /// No description provided for @saveWorkoutReusable.
  ///
  /// In en, this message translates to:
  /// **'Save this workout as a reusable routine'**
  String get saveWorkoutReusable;

  /// No description provided for @exerciseUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exercise updated successfully!'**
  String get exerciseUpdatedSuccess;

  /// No description provided for @errorUpdatingExercise.
  ///
  /// In en, this message translates to:
  /// **'Error updating exercise: {error}'**
  String errorUpdatingExercise(String error);

  /// No description provided for @editCustomExercise.
  ///
  /// In en, this message translates to:
  /// **'Edit Custom Exercise'**
  String get editCustomExercise;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @errorStoppingRecording.
  ///
  /// In en, this message translates to:
  /// **'Error stopping recording: {error}'**
  String errorStoppingRecording(String error);

  /// No description provided for @errorProcessing.
  ///
  /// In en, this message translates to:
  /// **'Error processing: {error}'**
  String errorProcessing(String error);

  /// No description provided for @analyticsReportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Analytics report generated successfully! 📊'**
  String get analyticsReportSuccess;

  /// No description provided for @errorGeneratingReport.
  ///
  /// In en, this message translates to:
  /// **'Error generating report: {error}'**
  String errorGeneratingReport(String error);

  /// No description provided for @reportTypeReport.
  ///
  /// In en, this message translates to:
  /// **'{type} Report'**
  String reportTypeReport(String type);

  /// No description provided for @errorLoadingExercises.
  ///
  /// In en, this message translates to:
  /// **'Error loading exercises: {error}'**
  String errorLoadingExercises(String error);

  /// No description provided for @errorSearchingExercises.
  ///
  /// In en, this message translates to:
  /// **'Error searching: {error}'**
  String errorSearchingExercises(String error);

  /// No description provided for @errorLoadingJournalHistory.
  ///
  /// In en, this message translates to:
  /// **'Error loading journal history: {error}'**
  String errorLoadingJournalHistory(String error);

  /// No description provided for @noAudioFileAvailable.
  ///
  /// In en, this message translates to:
  /// **'No audio file available'**
  String get noAudioFileAvailable;

  /// No description provided for @errorPlayingAudio.
  ///
  /// In en, this message translates to:
  /// **'Error playing audio: {error}'**
  String errorPlayingAudio(String error);

  /// No description provided for @deleteJournalEntryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this journal entry?'**
  String get deleteJournalEntryConfirm;

  /// No description provided for @journalEntryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Journal entry deleted'**
  String get journalEntryDeleted;

  /// No description provided for @errorDeletingEntry.
  ///
  /// In en, this message translates to:
  /// **'Error deleting entry: {error}'**
  String errorDeletingEntry(String error);

  /// No description provided for @journalHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Journal History'**
  String get journalHistoryTitle;

  /// No description provided for @errorLoadingArchivedPosts.
  ///
  /// In en, this message translates to:
  /// **'Error loading archived posts: {error}'**
  String errorLoadingArchivedPosts(String error);

  /// No description provided for @errorLoadingSavedPosts.
  ///
  /// In en, this message translates to:
  /// **'Error loading saved posts: {error}'**
  String errorLoadingSavedPosts(String error);

  /// No description provided for @errorLoadingSettings.
  ///
  /// In en, this message translates to:
  /// **'Error loading settings: {error}'**
  String errorLoadingSettings(String error);

  /// No description provided for @errorUpdatingSettings.
  ///
  /// In en, this message translates to:
  /// **'Error updating settings: {error}'**
  String errorUpdatingSettings(String error);

  /// No description provided for @publicProfile.
  ///
  /// In en, this message translates to:
  /// **'Public Profile'**
  String get publicProfile;

  /// No description provided for @aboutSocial.
  ///
  /// In en, this message translates to:
  /// **'About Social'**
  String get aboutSocial;

  /// No description provided for @manageSocialProfileSettings.
  ///
  /// In en, this message translates to:
  /// **'Manage your social profile settings'**
  String get manageSocialProfileSettings;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// No description provided for @voice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voice;

  /// No description provided for @missingRequiredDataOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Missing required data: {fields}. Please complete onboarding.'**
  String missingRequiredDataOnboarding(String fields);

  /// No description provided for @marketplaceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplaceTooltip;

  /// No description provided for @challengesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get challengesTooltip;

  /// No description provided for @notificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTooltip;

  /// No description provided for @editFoodDetailsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit food details'**
  String get editFoodDetailsTooltip;

  /// No description provided for @shareFoodDetailsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share food details'**
  String get shareFoodDetailsTooltip;

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get addedToFavorites;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get removedFromFavorites;

  /// No description provided for @addToFavoritesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavoritesTooltip;

  /// No description provided for @removeFromFavoritesTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavoritesTooltip;

  /// No description provided for @previousDay.
  ///
  /// In en, this message translates to:
  /// **'Previous day'**
  String get previousDay;

  /// No description provided for @nextDay.
  ///
  /// In en, this message translates to:
  /// **'Next day'**
  String get nextDay;

  /// No description provided for @actionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get actionCannotBeUndone;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @addCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get addCommentHint;

  /// No description provided for @profileNowPublic.
  ///
  /// In en, this message translates to:
  /// **'Your profile is now public'**
  String get profileNowPublic;

  /// No description provided for @profileNowPrivate.
  ///
  /// In en, this message translates to:
  /// **'Your profile is now private'**
  String get profileNowPrivate;

  /// No description provided for @myProfileTooltip.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfileTooltip;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @myAddons.
  ///
  /// In en, this message translates to:
  /// **'My Add-ons'**
  String get myAddons;

  /// No description provided for @marketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplace;

  /// No description provided for @allAddons.
  ///
  /// In en, this message translates to:
  /// **'All Add-ons'**
  String get allAddons;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'ALL'**
  String get categoryAll;

  /// No description provided for @categoryTracker.
  ///
  /// In en, this message translates to:
  /// **'TRACKER'**
  String get categoryTracker;

  /// No description provided for @categoryAnalytics.
  ///
  /// In en, this message translates to:
  /// **'ANALYTICS'**
  String get categoryAnalytics;

  /// No description provided for @categoryAI.
  ///
  /// In en, this message translates to:
  /// **'AI'**
  String get categoryAI;

  /// No description provided for @notEnoughCoins.
  ///
  /// In en, this message translates to:
  /// **'Not enough Flow Coins! 🪙'**
  String get notEnoughCoins;

  /// No description provided for @genderOptimization.
  ///
  /// In en, this message translates to:
  /// **'Gender Optimization'**
  String get genderOptimization;

  /// No description provided for @confirmActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate Add-on?'**
  String get confirmActivate;

  /// No description provided for @costConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will cost coins. Confirm?'**
  String get costConfirm;

  /// No description provided for @buyActivate.
  ///
  /// In en, this message translates to:
  /// **'Buy & Activate'**
  String get buyActivate;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @addTo.
  ///
  /// In en, this message translates to:
  /// **'Add to'**
  String get addTo;

  /// No description provided for @searchFoodHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a food...'**
  String get searchFoodHint;

  /// No description provided for @searchYourMeal.
  ///
  /// In en, this message translates to:
  /// **'Search for your meal'**
  String get searchYourMeal;

  /// No description provided for @recentFoods.
  ///
  /// In en, this message translates to:
  /// **'Recent Foods'**
  String get recentFoods;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @mealLogged.
  ///
  /// In en, this message translates to:
  /// **'Meal logged successfully!'**
  String get mealLogged;

  /// No description provided for @foodDetails.
  ///
  /// In en, this message translates to:
  /// **'Food Details: {foodName}'**
  String foodDetails(String foodName);

  /// No description provided for @variousBrands.
  ///
  /// In en, this message translates to:
  /// **'Various Brands'**
  String get variousBrands;

  /// No description provided for @quantityGrams.
  ///
  /// In en, this message translates to:
  /// **'Quantity (grams)'**
  String get quantityGrams;

  /// No description provided for @nutritionSummary.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Summary'**
  String get nutritionSummary;

  /// No description provided for @logTo.
  ///
  /// In en, this message translates to:
  /// **'Log to'**
  String get logTo;

  /// No description provided for @fastingHistory.
  ///
  /// In en, this message translates to:
  /// **'Fasting History'**
  String get fastingHistory;

  /// No description provided for @totalFasts.
  ///
  /// In en, this message translates to:
  /// **'Total Fasts'**
  String get totalFasts;

  /// No description provided for @avgDuration.
  ///
  /// In en, this message translates to:
  /// **'Avg Duration'**
  String get avgDuration;

  /// No description provided for @longestFast.
  ///
  /// In en, this message translates to:
  /// **'Longest'**
  String get longestFast;

  /// No description provided for @fast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get fast;

  /// No description provided for @topUpCoins.
  ///
  /// In en, this message translates to:
  /// **'Top-up Flow Coins'**
  String get topUpCoins;

  /// No description provided for @currentBalance.
  ///
  /// In en, this message translates to:
  /// **'Your current balance'**
  String get currentBalance;

  /// No description provided for @mostPopular.
  ///
  /// In en, this message translates to:
  /// **'Most Popular'**
  String get mostPopular;

  /// No description provided for @noPackages.
  ///
  /// In en, this message translates to:
  /// **'No coin packages available.'**
  String get noPackages;

  /// No description provided for @proLabel.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get proLabel;

  /// No description provided for @freePlan.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get freePlan;

  /// No description provided for @premiumPlan.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumPlan;

  /// No description provided for @creatorPlan.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get creatorPlan;

  /// No description provided for @subscriptionPlans.
  ///
  /// In en, this message translates to:
  /// **'Subscription Plans'**
  String get subscriptionPlans;

  /// No description provided for @essentialFeatures.
  ///
  /// In en, this message translates to:
  /// **'Essential features'**
  String get essentialFeatures;

  /// No description provided for @changePlan.
  ///
  /// In en, this message translates to:
  /// **'Change Plan? 🚀'**
  String get changePlan;

  /// No description provided for @confirmPurchase.
  ///
  /// In en, this message translates to:
  /// **'Confirm Purchase'**
  String get confirmPurchase;

  /// No description provided for @activateAnyway.
  ///
  /// In en, this message translates to:
  /// **'Activate Anyway'**
  String get activateAnyway;

  /// No description provided for @creatorStudioSoon.
  ///
  /// In en, this message translates to:
  /// **'Creator Studio coming soon!'**
  String get creatorStudioSoon;

  /// No description provided for @publishToolSoon.
  ///
  /// In en, this message translates to:
  /// **'Publish tool coming soon!'**
  String get publishToolSoon;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated! ✅'**
  String get profileUpdated;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @heightCm.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get heightCm;

  /// No description provided for @weightKg.
  ///
  /// In en, this message translates to:
  /// **'Current Weight (kg)'**
  String get weightKg;

  /// No description provided for @targetWeightKg.
  ///
  /// In en, this message translates to:
  /// **'Target Weight (kg)'**
  String get targetWeightKg;

  /// No description provided for @yourGoal.
  ///
  /// In en, this message translates to:
  /// **'Your Goal'**
  String get yourGoal;

  /// No description provided for @activityLevel.
  ///
  /// In en, this message translates to:
  /// **'Activity Level'**
  String get activityLevel;

  /// No description provided for @waterSettings.
  ///
  /// In en, this message translates to:
  /// **'Water Settings'**
  String get waterSettings;

  /// No description provided for @dailyWaterTarget.
  ///
  /// In en, this message translates to:
  /// **'Daily Water Target (ml)'**
  String get dailyWaterTarget;

  /// No description provided for @waterReminders.
  ///
  /// In en, this message translates to:
  /// **'Water Reminders'**
  String get waterReminders;

  /// No description provided for @waterRemindersDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified to stay hydrated'**
  String get waterRemindersDesc;

  /// No description provided for @currentBmi.
  ///
  /// In en, this message translates to:
  /// **'Current BMI'**
  String get currentBmi;

  /// No description provided for @idealWeightRange.
  ///
  /// In en, this message translates to:
  /// **'Ideal Weight for your height:'**
  String get idealWeightRange;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get community;

  /// No description provided for @userName.
  ///
  /// In en, this message translates to:
  /// **'User Name'**
  String get userName;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @cycleTracker.
  ///
  /// In en, this message translates to:
  /// **'Cycle Tracker'**
  String get cycleTracker;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day {number}'**
  String day(int number);

  /// No description provided for @nextIn.
  ///
  /// In en, this message translates to:
  /// **'Next in'**
  String get nextIn;

  /// No description provided for @nextInDays.
  ///
  /// In en, this message translates to:
  /// **'Next in {days} days'**
  String nextInDays(Object days);

  /// No description provided for @phase.
  ///
  /// In en, this message translates to:
  /// **'Phase'**
  String get phase;

  /// No description provided for @currentCycle.
  ///
  /// In en, this message translates to:
  /// **'Current Cycle'**
  String get currentCycle;

  /// No description provided for @dayOfCycle.
  ///
  /// In en, this message translates to:
  /// **'Day of Cycle'**
  String get dayOfCycle;

  /// No description provided for @cyclePhases.
  ///
  /// In en, this message translates to:
  /// **'Cycle Phases'**
  String get cyclePhases;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @todaysSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Symptoms'**
  String get todaysSymptoms;

  /// No description provided for @smartSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Smart Suggestions'**
  String get smartSuggestions;

  /// No description provided for @customSymptoms.
  ///
  /// In en, this message translates to:
  /// **'Custom Symptoms'**
  String get customSymptoms;

  /// No description provided for @addCustomSymptom.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Symptom'**
  String get addCustomSymptom;

  /// No description provided for @enterSymptomName.
  ///
  /// In en, this message translates to:
  /// **'Enter symptom name'**
  String get enterSymptomName;

  /// No description provided for @logPeriod.
  ///
  /// In en, this message translates to:
  /// **'Log Period'**
  String get logPeriod;

  /// No description provided for @markPeriodStart.
  ///
  /// In en, this message translates to:
  /// **'Mark the start of your period?'**
  String get markPeriodStart;

  /// No description provided for @periodLogged.
  ///
  /// In en, this message translates to:
  /// **'Period logged successfully!'**
  String get periodLogged;

  /// No description provided for @cycleRoadmap.
  ///
  /// In en, this message translates to:
  /// **'Cycle Roadmap'**
  String get cycleRoadmap;

  /// No description provided for @hydrationTip.
  ///
  /// In en, this message translates to:
  /// **'Hydration Tip'**
  String get hydrationTip;

  /// No description provided for @menstrual.
  ///
  /// In en, this message translates to:
  /// **'Menstrual'**
  String get menstrual;

  /// No description provided for @ovulation.
  ///
  /// In en, this message translates to:
  /// **'Ovulation'**
  String get ovulation;

  /// No description provided for @luteal.
  ///
  /// In en, this message translates to:
  /// **'Luteal'**
  String get luteal;

  /// No description provided for @follicular.
  ///
  /// In en, this message translates to:
  /// **'Follicular'**
  String get follicular;

  /// No description provided for @cramps.
  ///
  /// In en, this message translates to:
  /// **'Cramps'**
  String get cramps;

  /// No description provided for @headache.
  ///
  /// In en, this message translates to:
  /// **'Headache'**
  String get headache;

  /// No description provided for @moodSwings.
  ///
  /// In en, this message translates to:
  /// **'Mood Swings'**
  String get moodSwings;

  /// No description provided for @fatigue.
  ///
  /// In en, this message translates to:
  /// **'Fatigue'**
  String get fatigue;

  /// No description provided for @bloating.
  ///
  /// In en, this message translates to:
  /// **'Bloating'**
  String get bloating;

  /// No description provided for @acne.
  ///
  /// In en, this message translates to:
  /// **'Acne'**
  String get acne;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @log.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get log;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @fastingActiveDialog.
  ///
  /// In en, this message translates to:
  /// **'Fasting Active 🛑'**
  String get fastingActiveDialog;

  /// No description provided for @fastingEndLog.
  ///
  /// In en, this message translates to:
  /// **'You are currently in a fasting window. Do you want to end your fast to log this meal?'**
  String get fastingEndLog;

  /// No description provided for @endFastLog.
  ///
  /// In en, this message translates to:
  /// **'End Fast & Log'**
  String get endFastLog;

  /// No description provided for @addWater.
  ///
  /// In en, this message translates to:
  /// **'Add Water'**
  String get addWater;

  /// No description provided for @glass.
  ///
  /// In en, this message translates to:
  /// **'Glass'**
  String get glass;

  /// No description provided for @bottle.
  ///
  /// In en, this message translates to:
  /// **'Bottle'**
  String get bottle;

  /// No description provided for @large.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get large;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Or enter amount:'**
  String get enterAmount;

  /// No description provided for @ml.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get ml;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @warnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get warnings;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @logWeight.
  ///
  /// In en, this message translates to:
  /// **'Log Weight'**
  String get logWeight;

  /// No description provided for @logMorningWeight.
  ///
  /// In en, this message translates to:
  /// **'Log Morning Weight'**
  String get logMorningWeight;

  /// No description provided for @editDailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Edit Daily Goal'**
  String get editDailyGoal;

  /// No description provided for @setManualTarget.
  ///
  /// In en, this message translates to:
  /// **'Set your manual calorie target:'**
  String get setManualTarget;

  /// No description provided for @caloriesKcal.
  ///
  /// In en, this message translates to:
  /// **'Calories (kcal)'**
  String get caloriesKcal;

  /// No description provided for @morningWeight.
  ///
  /// In en, this message translates to:
  /// **'Morning Weight'**
  String get morningWeight;

  /// No description provided for @lastLogged.
  ///
  /// In en, this message translates to:
  /// **'Last Logged: {weight} kg'**
  String lastLogged(Object weight);

  /// No description provided for @keepTrackProgress.
  ///
  /// In en, this message translates to:
  /// **'Keep track of your daily progress'**
  String get keepTrackProgress;

  /// No description provided for @tomorrowsEst.
  ///
  /// In en, this message translates to:
  /// **'Tomorrows Est: {weight} kg'**
  String tomorrowsEst(Object weight);

  /// No description provided for @bmi.
  ///
  /// In en, this message translates to:
  /// **'BMI'**
  String get bmi;

  /// No description provided for @hydrationWave.
  ///
  /// In en, this message translates to:
  /// **'Hydration Wave'**
  String get hydrationWave;

  /// No description provided for @eatingWindow.
  ///
  /// In en, this message translates to:
  /// **'Eating Window'**
  String get eatingWindow;

  /// No description provided for @readyToFast.
  ///
  /// In en, this message translates to:
  /// **'Ready to fast?'**
  String get readyToFast;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get viewHistory;

  /// No description provided for @endFast.
  ///
  /// In en, this message translates to:
  /// **'End Fast'**
  String get endFast;

  /// No description provided for @startFasting.
  ///
  /// In en, this message translates to:
  /// **'Start Fasting'**
  String get startFasting;

  /// No description provided for @bloodSugarRising.
  ///
  /// In en, this message translates to:
  /// **'Blood Sugar Rising 🩸'**
  String get bloodSugarRising;

  /// No description provided for @bloodSugarFalling.
  ///
  /// In en, this message translates to:
  /// **'Blood Sugar Falling 📉'**
  String get bloodSugarFalling;

  /// No description provided for @ketosis.
  ///
  /// In en, this message translates to:
  /// **'Fat Burning (Ketosis) 🔥'**
  String get ketosis;

  /// No description provided for @autophagy.
  ///
  /// In en, this message translates to:
  /// **'Autophagy (Repair) 🧬'**
  String get autophagy;

  /// No description provided for @elapsed.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m elapsed'**
  String elapsed(Object hours, Object minutes);

  /// No description provided for @highProtein.
  ///
  /// In en, this message translates to:
  /// **'High Protein 💪'**
  String get highProtein;

  /// No description provided for @lowCarb.
  ///
  /// In en, this message translates to:
  /// **'Low Carb 🥬'**
  String get lowCarb;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light 🪶'**
  String get light;

  /// No description provided for @balanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced ⚖️'**
  String get balanced;

  /// No description provided for @myTrackers.
  ///
  /// In en, this message translates to:
  /// **'My Trackers'**
  String get myTrackers;

  /// No description provided for @noCustomTrackers.
  ///
  /// In en, this message translates to:
  /// **'No custom trackers yet.'**
  String get noCustomTrackers;

  /// No description provided for @selectTrackers.
  ///
  /// In en, this message translates to:
  /// **'Select Trackers'**
  String get selectTrackers;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @flowUser.
  ///
  /// In en, this message translates to:
  /// **'Flow User'**
  String get flowUser;

  /// No description provided for @pandaDoingGreat.
  ///
  /// In en, this message translates to:
  /// **'You\'re doing great! Keep it up!'**
  String get pandaDoingGreat;

  /// No description provided for @flowSays.
  ///
  /// In en, this message translates to:
  /// **'Flow says'**
  String get flowSays;

  /// No description provided for @flowThinking.
  ///
  /// In en, this message translates to:
  /// **'Flow is thinking...'**
  String get flowThinking;

  /// No description provided for @pandaCarefulCal.
  ///
  /// In en, this message translates to:
  /// **'Careful with those calories! Maybe a light walk?'**
  String get pandaCarefulCal;

  /// No description provided for @pandaProtein.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget your protein for muscle recovery!'**
  String get pandaProtein;

  /// No description provided for @pandaWater.
  ///
  /// In en, this message translates to:
  /// **'Time for some water, stay hydrated!'**
  String get pandaWater;

  /// No description provided for @pandaStreak.
  ///
  /// In en, this message translates to:
  /// **'Wow, a {days} day streak! You\'re unstoppable!'**
  String pandaStreak(Object days);

  /// No description provided for @streakReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t break your streak!'**
  String get streakReminderTitle;

  /// No description provided for @streakReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Log a meal or workout to keep your {days} day streak.'**
  String streakReminderBody(String days);

  /// No description provided for @calorieGoalHit.
  ///
  /// In en, this message translates to:
  /// **'Daily calorie goal hit! 🎯'**
  String get calorieGoalHit;

  /// No description provided for @streakMilestone.
  ///
  /// In en, this message translates to:
  /// **'{days} day streak! You\'re on fire! 🔥'**
  String streakMilestone(int days);

  /// No description provided for @shareProgress.
  ///
  /// In en, this message translates to:
  /// **'Share progress'**
  String get shareProgress;

  /// No description provided for @shareProgressStreak.
  ///
  /// In en, this message translates to:
  /// **'I\'m on a {days} day streak on Flow! 🔥'**
  String shareProgressStreak(int days);

  /// No description provided for @shareProgressDefault.
  ///
  /// In en, this message translates to:
  /// **'I\'m tracking my health with Flow! 🎯'**
  String get shareProgressDefault;

  /// No description provided for @workoutLoggedCelebration.
  ///
  /// In en, this message translates to:
  /// **'Workout logged! 💪'**
  String get workoutLoggedCelebration;

  /// No description provided for @healthAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Health Analysis'**
  String get healthAnalysis;

  /// No description provided for @excellentStatus.
  ///
  /// In en, this message translates to:
  /// **'Excellent ✨'**
  String get excellentStatus;

  /// No description provided for @goodStatus.
  ///
  /// In en, this message translates to:
  /// **'Good 👍'**
  String get goodStatus;

  /// No description provided for @needsWorkStatus.
  ///
  /// In en, this message translates to:
  /// **'Needs Work 📈'**
  String get needsWorkStatus;

  /// No description provided for @perfectlyBalanced.
  ///
  /// In en, this message translates to:
  /// **'Perfectly Balanced ✨'**
  String get perfectlyBalanced;

  /// No description provided for @calorieSurplus.
  ///
  /// In en, this message translates to:
  /// **'Calorie Surplus 📈'**
  String get calorieSurplus;

  /// No description provided for @calorieDeficit.
  ///
  /// In en, this message translates to:
  /// **'Calorie Deficit 📉'**
  String get calorieDeficit;

  /// No description provided for @totalProgress.
  ///
  /// In en, this message translates to:
  /// **'Total Progress'**
  String get totalProgress;

  /// No description provided for @activitiesWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Activities & Workouts 🏋️'**
  String get activitiesWorkouts;

  /// No description provided for @noActivitiesLogged.
  ///
  /// In en, this message translates to:
  /// **'No activities logged yet. Get moving! 🏃‍♂️'**
  String get noActivitiesLogged;

  /// No description provided for @muscleGroup.
  ///
  /// In en, this message translates to:
  /// **'Muscle Group'**
  String get muscleGroup;

  /// No description provided for @difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get difficulty;

  /// No description provided for @activityLogged.
  ///
  /// In en, this message translates to:
  /// **'Activity logged! Calories burned recorded. 🔥'**
  String get activityLogged;

  /// No description provided for @kcalLeft.
  ///
  /// In en, this message translates to:
  /// **'kcal left'**
  String get kcalLeft;

  /// No description provided for @perfectStatus.
  ///
  /// In en, this message translates to:
  /// **'Perfect'**
  String get perfectStatus;

  /// No description provided for @searchExerciseHint.
  ///
  /// In en, this message translates to:
  /// **'Search exercises (e.g. Push-ups)...'**
  String get searchExerciseHint;

  /// No description provided for @selectExercise.
  ///
  /// In en, this message translates to:
  /// **'Select Exercise'**
  String get selectExercise;

  /// No description provided for @quickAdd.
  ///
  /// In en, this message translates to:
  /// **'Quick Add'**
  String get quickAdd;

  /// No description provided for @sets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get sets;

  /// No description provided for @reps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get reps;

  /// No description provided for @hydrationScore.
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get hydrationScore;

  /// No description provided for @calorieBalance.
  ///
  /// In en, this message translates to:
  /// **'Calorie Balance'**
  String get calorieBalance;

  /// No description provided for @proteinTarget.
  ///
  /// In en, this message translates to:
  /// **'Protein Target'**
  String get proteinTarget;

  /// No description provided for @flowBasic.
  ///
  /// In en, this message translates to:
  /// **'FLOW BASIC'**
  String get flowBasic;

  /// No description provided for @flowPremier.
  ///
  /// In en, this message translates to:
  /// **'FLOW PREMIER'**
  String get flowPremier;

  /// No description provided for @flowCreator.
  ///
  /// In en, this message translates to:
  /// **'FLOW CREATOR'**
  String get flowCreator;

  /// No description provided for @vitalityBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Vitality Breakdown'**
  String get vitalityBreakdown;

  /// No description provided for @vitalityShield.
  ///
  /// In en, this message translates to:
  /// **'VITALITY SHIELD'**
  String get vitalityShield;

  /// No description provided for @dailyNutrientCoverage.
  ///
  /// In en, this message translates to:
  /// **'Daily nutrient coverage vs. RDA'**
  String get dailyNutrientCoverage;

  /// No description provided for @aiCoach.
  ///
  /// In en, this message translates to:
  /// **'AI Coach'**
  String get aiCoach;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Hello! I am your FLOW AI Coach. How can I help you today?'**
  String get welcomeMessage;

  /// No description provided for @coachDefaultReply.
  ///
  /// In en, this message translates to:
  /// **'That sounds like a great plan! To achieve your goal of weight loss, focusing on high-protein meals can really help with satiety.'**
  String get coachDefaultReply;

  /// No description provided for @askMeAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything...'**
  String get askMeAnything;

  /// No description provided for @insightsProgress.
  ///
  /// In en, this message translates to:
  /// **'Insights & Progress'**
  String get insightsProgress;

  /// No description provided for @tbd.
  ///
  /// In en, this message translates to:
  /// **'TBD'**
  String get tbd;

  /// No description provided for @reached.
  ///
  /// In en, this message translates to:
  /// **'Reached!'**
  String get reached;

  /// No description provided for @needsDeficit.
  ///
  /// In en, this message translates to:
  /// **'Needs Deficit'**
  String get needsDeficit;

  /// No description provided for @needsSurplus.
  ///
  /// In en, this message translates to:
  /// **'Needs Surplus'**
  String get needsSurplus;

  /// No description provided for @moreThan3Years.
  ///
  /// In en, this message translates to:
  /// **'> 3 years'**
  String get moreThan3Years;

  /// No description provided for @bodyMassIndex.
  ///
  /// In en, this message translates to:
  /// **'Body Mass Index (BMI)'**
  String get bodyMassIndex;

  /// No description provided for @normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get normal;

  /// No description provided for @smartProjection.
  ///
  /// In en, this message translates to:
  /// **'SMART PROJECTION'**
  String get smartProjection;

  /// No description provided for @estGoal.
  ///
  /// In en, this message translates to:
  /// **'Est. Goal: {date}'**
  String estGoal(Object date);

  /// No description provided for @predictedTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Predicted weight for tomorrow'**
  String get predictedTomorrow;

  /// No description provided for @metabolismSpeed.
  ///
  /// In en, this message translates to:
  /// **'Metabolism Speed'**
  String get metabolismSpeed;

  /// No description provided for @metabolismNormalMsg.
  ///
  /// In en, this message translates to:
  /// **'Your metabolism is working as expected.'**
  String get metabolismNormalMsg;

  /// No description provided for @metabolismFast.
  ///
  /// In en, this message translates to:
  /// **'Fast 🔥'**
  String get metabolismFast;

  /// No description provided for @metabolismFastMsg.
  ///
  /// In en, this message translates to:
  /// **'You are burning fat faster than calculated!'**
  String get metabolismFastMsg;

  /// No description provided for @metabolismSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow 🐢'**
  String get metabolismSlow;

  /// No description provided for @metabolismSlowMsg.
  ///
  /// In en, this message translates to:
  /// **'Weight loss is slower than expected. Check tracking accuracy.'**
  String get metabolismSlowMsg;

  /// No description provided for @metabolismOnFire.
  ///
  /// In en, this message translates to:
  /// **'On Fire 🔥'**
  String get metabolismOnFire;

  /// No description provided for @metabolismOnFireMsg.
  ///
  /// In en, this message translates to:
  /// **'Losing weight even in surplus/maintenance!'**
  String get metabolismOnFireMsg;

  /// No description provided for @weightEvolution.
  ///
  /// In en, this message translates to:
  /// **'Weight Evolution'**
  String get weightEvolution;

  /// No description provided for @theoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Actual vs Theoretical (Theory based on last 7 days calories)'**
  String get theoryDescription;

  /// No description provided for @noWeightLogs.
  ///
  /// In en, this message translates to:
  /// **'No weight logs yet'**
  String get noWeightLogs;

  /// No description provided for @weeklyCalories.
  ///
  /// In en, this message translates to:
  /// **'Weekly Calories'**
  String get weeklyCalories;

  /// No description provided for @avgWeeklyMacros.
  ///
  /// In en, this message translates to:
  /// **'Avg Weekly Macros'**
  String get avgWeeklyMacros;

  /// No description provided for @nutrient_protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get nutrient_protein;

  /// No description provided for @nutrient_protein_desc.
  ///
  /// In en, this message translates to:
  /// **'The building blocks of muscle and tissue.'**
  String get nutrient_protein_desc;

  /// No description provided for @kcalUnit.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get kcalUnit;

  /// No description provided for @preparingPost.
  ///
  /// In en, this message translates to:
  /// **'Preparing post...'**
  String get preparingPost;

  /// No description provided for @uploadingImage.
  ///
  /// In en, this message translates to:
  /// **'Uploading image...'**
  String get uploadingImage;

  /// No description provided for @finalizingPost.
  ///
  /// In en, this message translates to:
  /// **'Finalizing post...'**
  String get finalizingPost;

  /// No description provided for @deleteWorkoutConfirmWithName.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String deleteWorkoutConfirmWithName(Object name);

  /// No description provided for @nutrient_carbs.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrates'**
  String get nutrient_carbs;

  /// No description provided for @nutrient_carbs_desc.
  ///
  /// In en, this message translates to:
  /// **'Your body\'s primary energy source.'**
  String get nutrient_carbs_desc;

  /// No description provided for @nutrient_fat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get nutrient_fat;

  /// No description provided for @nutrient_fat_desc.
  ///
  /// In en, this message translates to:
  /// **'Essential for hormone production and brain health.'**
  String get nutrient_fat_desc;

  /// No description provided for @nutrient_fiber.
  ///
  /// In en, this message translates to:
  /// **'Fiber'**
  String get nutrient_fiber;

  /// No description provided for @nutrient_fiber_desc.
  ///
  /// In en, this message translates to:
  /// **'Crucial for digestion and heart health.'**
  String get nutrient_fiber_desc;

  /// No description provided for @nutrient_sugar.
  ///
  /// In en, this message translates to:
  /// **'Sugar'**
  String get nutrient_sugar;

  /// No description provided for @nutrient_sugar_desc.
  ///
  /// In en, this message translates to:
  /// **'Simple carbohydrates that provide quick energy.'**
  String get nutrient_sugar_desc;

  /// No description provided for @nutrient_omega3.
  ///
  /// In en, this message translates to:
  /// **'Omega-3'**
  String get nutrient_omega3;

  /// No description provided for @nutrient_omega3_desc.
  ///
  /// In en, this message translates to:
  /// **'Heart and brain health hero. Reduces inflammation.'**
  String get nutrient_omega3_desc;

  /// No description provided for @nutrient_saturated_fat.
  ///
  /// In en, this message translates to:
  /// **'Saturated Fat'**
  String get nutrient_saturated_fat;

  /// No description provided for @nutrient_saturated_fat_desc.
  ///
  /// In en, this message translates to:
  /// **'Found in animal products. Maintain in moderation.'**
  String get nutrient_saturated_fat_desc;

  /// No description provided for @nutrient_vitamin_c.
  ///
  /// In en, this message translates to:
  /// **'Vitamin C'**
  String get nutrient_vitamin_c;

  /// No description provided for @nutrient_vitamin_c_desc.
  ///
  /// In en, this message translates to:
  /// **'Immune support and skin health.'**
  String get nutrient_vitamin_c_desc;

  /// No description provided for @nutrient_vitamin_d.
  ///
  /// In en, this message translates to:
  /// **'Vitamin D'**
  String get nutrient_vitamin_d;

  /// No description provided for @nutrient_vitamin_d_desc.
  ///
  /// In en, this message translates to:
  /// **'The \'sunshine vitamin\' for bone health and mood.'**
  String get nutrient_vitamin_d_desc;

  /// No description provided for @nutrient_vitamin_b12.
  ///
  /// In en, this message translates to:
  /// **'Vitamin B12'**
  String get nutrient_vitamin_b12;

  /// No description provided for @nutrient_vitamin_b12_desc.
  ///
  /// In en, this message translates to:
  /// **'Vital for nerve function and blood cells.'**
  String get nutrient_vitamin_b12_desc;

  /// No description provided for @nutrient_calcium.
  ///
  /// In en, this message translates to:
  /// **'Calcium'**
  String get nutrient_calcium;

  /// No description provided for @nutrient_calcium_desc.
  ///
  /// In en, this message translates to:
  /// **'Strong bones and teeth.'**
  String get nutrient_calcium_desc;

  /// No description provided for @nutrient_iron.
  ///
  /// In en, this message translates to:
  /// **'Iron'**
  String get nutrient_iron;

  /// No description provided for @nutrient_iron_desc.
  ///
  /// In en, this message translates to:
  /// **'Carries oxygen through your blood.'**
  String get nutrient_iron_desc;

  /// No description provided for @nutrient_magnesium.
  ///
  /// In en, this message translates to:
  /// **'Magnesium'**
  String get nutrient_magnesium;

  /// No description provided for @nutrient_magnesium_desc.
  ///
  /// In en, this message translates to:
  /// **'Over 300 biochemical reactions in the body.'**
  String get nutrient_magnesium_desc;

  /// No description provided for @nutrient_potassium.
  ///
  /// In en, this message translates to:
  /// **'Potassium'**
  String get nutrient_potassium;

  /// No description provided for @nutrient_potassium_desc.
  ///
  /// In en, this message translates to:
  /// **'Proper heart and muscle function.'**
  String get nutrient_potassium_desc;

  /// No description provided for @nutrient_zinc.
  ///
  /// In en, this message translates to:
  /// **'Zinc'**
  String get nutrient_zinc;

  /// No description provided for @nutrient_zinc_desc.
  ///
  /// In en, this message translates to:
  /// **'Immunity and cell growth.'**
  String get nutrient_zinc_desc;

  /// No description provided for @nutrient_caffeine.
  ///
  /// In en, this message translates to:
  /// **'Caffeine'**
  String get nutrient_caffeine;

  /// No description provided for @nutrient_caffeine_desc.
  ///
  /// In en, this message translates to:
  /// **'Stimulant found in coffee and tea.'**
  String get nutrient_caffeine_desc;

  /// No description provided for @cat_macro.
  ///
  /// In en, this message translates to:
  /// **'Macronutrients'**
  String get cat_macro;

  /// No description provided for @cat_essential_fats.
  ///
  /// In en, this message translates to:
  /// **'Essential Fats'**
  String get cat_essential_fats;

  /// No description provided for @cat_vitamins.
  ///
  /// In en, this message translates to:
  /// **'Vitamins'**
  String get cat_vitamins;

  /// No description provided for @cat_minerals.
  ///
  /// In en, this message translates to:
  /// **'Minerals'**
  String get cat_minerals;

  /// No description provided for @cat_others.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get cat_others;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid login credentials. Please check your email and password.'**
  String get invalidCredentials;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Your Password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a link to get back into your account.'**
  String get resetPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Success! Check your email for the reset link.'**
  String get resetLinkSent;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'No user found with this email.'**
  String get userNotFound;

  /// No description provided for @macronutrientDistribution.
  ///
  /// In en, this message translates to:
  /// **'Macronutrient Distribution'**
  String get macronutrientDistribution;

  /// No description provided for @dailyProgress.
  ///
  /// In en, this message translates to:
  /// **'Daily Progress'**
  String get dailyProgress;

  /// No description provided for @allergyWarning.
  ///
  /// In en, this message translates to:
  /// **'Allergy Warning'**
  String get allergyWarning;

  /// No description provided for @thisFoodMayContain.
  ///
  /// In en, this message translates to:
  /// **'This food may contain'**
  String get thisFoodMayContain;

  /// No description provided for @healthScore.
  ///
  /// In en, this message translates to:
  /// **'Health Score'**
  String get healthScore;

  /// No description provided for @micronutrientCoverage.
  ///
  /// In en, this message translates to:
  /// **'Micronutrient Coverage'**
  String get micronutrientCoverage;

  /// No description provided for @rdaComparison.
  ///
  /// In en, this message translates to:
  /// **'RDA Comparison'**
  String get rdaComparison;

  /// No description provided for @bodyImpact.
  ///
  /// In en, this message translates to:
  /// **'Body Impact'**
  String get bodyImpact;

  /// No description provided for @mealTiming.
  ///
  /// In en, this message translates to:
  /// **'Meal Timing'**
  String get mealTiming;

  /// No description provided for @bestTimeToEat.
  ///
  /// In en, this message translates to:
  /// **'Best Time to Eat'**
  String get bestTimeToEat;

  /// No description provided for @nutritionalDensity.
  ///
  /// In en, this message translates to:
  /// **'Nutritional Density'**
  String get nutritionalDensity;

  /// No description provided for @calorieDensity.
  ///
  /// In en, this message translates to:
  /// **'Calorie Density'**
  String get calorieDensity;

  /// No description provided for @proteinQuality.
  ///
  /// In en, this message translates to:
  /// **'Protein Quality'**
  String get proteinQuality;

  /// No description provided for @fiberContent.
  ///
  /// In en, this message translates to:
  /// **'Fiber Content'**
  String get fiberContent;

  /// No description provided for @sugarContent.
  ///
  /// In en, this message translates to:
  /// **'Sugar Content'**
  String get sugarContent;

  /// No description provided for @saturatedFatContent.
  ///
  /// In en, this message translates to:
  /// **'Saturated Fat Content'**
  String get saturatedFatContent;

  /// No description provided for @excellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent! 🌟'**
  String get excellent;

  /// No description provided for @good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get good;

  /// No description provided for @moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get moderate;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @veryHigh.
  ///
  /// In en, this message translates to:
  /// **'Very High'**
  String get veryHigh;

  /// No description provided for @supportsMuscleGrowth.
  ///
  /// In en, this message translates to:
  /// **'Supports muscle growth and recovery'**
  String get supportsMuscleGrowth;

  /// No description provided for @providesEnergy.
  ///
  /// In en, this message translates to:
  /// **'Provides sustained energy'**
  String get providesEnergy;

  /// No description provided for @aidsDigestion.
  ///
  /// In en, this message translates to:
  /// **'Aids digestion and gut health'**
  String get aidsDigestion;

  /// No description provided for @boostsImmunity.
  ///
  /// In en, this message translates to:
  /// **'Boosts immune system'**
  String get boostsImmunity;

  /// No description provided for @supportsBoneHealth.
  ///
  /// In en, this message translates to:
  /// **'Supports bone health'**
  String get supportsBoneHealth;

  /// No description provided for @improvesHeartHealth.
  ///
  /// In en, this message translates to:
  /// **'Improves heart health'**
  String get improvesHeartHealth;

  /// No description provided for @enhancesBrainFunction.
  ///
  /// In en, this message translates to:
  /// **'Enhances brain function'**
  String get enhancesBrainFunction;

  /// No description provided for @regulatesBloodSugar.
  ///
  /// In en, this message translates to:
  /// **'Helps regulate blood sugar'**
  String get regulatesBloodSugar;

  /// No description provided for @promotesWeightLoss.
  ///
  /// In en, this message translates to:
  /// **'Promotes weight loss'**
  String get promotesWeightLoss;

  /// No description provided for @supportsWeightGain.
  ///
  /// In en, this message translates to:
  /// **'Supports healthy weight gain'**
  String get supportsWeightGain;

  /// No description provided for @percentOfRDA.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of RDA'**
  String percentOfRDA(Object percent);

  /// No description provided for @percentOfRDA_other.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of RDA'**
  String percentOfRDA_other(Object percent);

  /// No description provided for @meetsDailyNeeds.
  ///
  /// In en, this message translates to:
  /// **'Meets daily needs'**
  String get meetsDailyNeeds;

  /// No description provided for @exceedsDailyNeeds.
  ///
  /// In en, this message translates to:
  /// **'Exceeds daily needs'**
  String get exceedsDailyNeeds;

  /// No description provided for @belowDailyNeeds.
  ///
  /// In en, this message translates to:
  /// **'Below daily needs'**
  String get belowDailyNeeds;

  /// No description provided for @nutritionalBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Nutritional Breakdown'**
  String get nutritionalBreakdown;

  /// No description provided for @impactOnGoals.
  ///
  /// In en, this message translates to:
  /// **'Impact on Your Goals'**
  String get impactOnGoals;

  /// No description provided for @recommendedFor.
  ///
  /// In en, this message translates to:
  /// **'Recommended For'**
  String get recommendedFor;

  /// No description provided for @notRecommendedFor.
  ///
  /// In en, this message translates to:
  /// **'Not Recommended For'**
  String get notRecommendedFor;

  /// No description provided for @recognizedFoods.
  ///
  /// In en, this message translates to:
  /// **'Recognized Foods'**
  String get recognizedFoods;

  /// No description provided for @retakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake Photo'**
  String get retakePhoto;

  /// No description provided for @addEdit.
  ///
  /// In en, this message translates to:
  /// **'Add & Edit'**
  String get addEdit;

  /// No description provided for @fastAdd.
  ///
  /// In en, this message translates to:
  /// **'Fast Add'**
  String get fastAdd;

  /// No description provided for @pleaseSelectMealType.
  ///
  /// In en, this message translates to:
  /// **'Please select a meal type'**
  String get pleaseSelectMealType;

  /// No description provided for @noFoodsRecognized.
  ///
  /// In en, this message translates to:
  /// **'No foods recognized'**
  String get noFoodsRecognized;

  /// No description provided for @selectMealType.
  ///
  /// In en, this message translates to:
  /// **'Select Meal Type:'**
  String get selectMealType;

  /// No description provided for @foodAddedTo.
  ///
  /// In en, this message translates to:
  /// **'{foodName} added to {mealType}'**
  String foodAddedTo(String foodName, String mealType);

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera permission required'**
  String get cameraPermissionRequired;

  /// No description provided for @microphonePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission required'**
  String get microphonePermissionRequired;

  /// No description provided for @speechRecognitionError.
  ///
  /// In en, this message translates to:
  /// **'Speech recognition error: {error}'**
  String speechRecognitionError(String error);

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found in Open Food Facts database'**
  String get productNotFound;

  /// No description provided for @noFoodItemsDetected.
  ///
  /// In en, this message translates to:
  /// **'No food items detected in your voice input'**
  String get noFoodItemsDetected;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcode;

  /// No description provided for @positionBarcode.
  ///
  /// In en, this message translates to:
  /// **'Position the barcode within the frame'**
  String get positionBarcode;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listening;

  /// No description provided for @speakFoodItems.
  ///
  /// In en, this message translates to:
  /// **'Speak the food items you want to add'**
  String get speakFoodItems;

  /// No description provided for @stopListening.
  ///
  /// In en, this message translates to:
  /// **'Stop Listening'**
  String get stopListening;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @viewFoodDetails.
  ///
  /// In en, this message translates to:
  /// **'View Food Details'**
  String get viewFoodDetails;

  /// No description provided for @viewAlternativeFood.
  ///
  /// In en, this message translates to:
  /// **'View Alternative Food'**
  String get viewAlternativeFood;

  /// No description provided for @viewFood.
  ///
  /// In en, this message translates to:
  /// **'View Food'**
  String get viewFood;

  /// No description provided for @wouldLikeToViewDetails.
  ///
  /// In en, this message translates to:
  /// **'Would you like to view details for {foodName}?'**
  String wouldLikeToViewDetails(String foodName);

  /// No description provided for @editFoodDetails.
  ///
  /// In en, this message translates to:
  /// **'Edit Food Details'**
  String get editFoodDetails;

  /// No description provided for @foodUpdated.
  ///
  /// In en, this message translates to:
  /// **'Food updated successfully'**
  String get foodUpdated;

  /// No description provided for @errorUpdatingFavorites.
  ///
  /// In en, this message translates to:
  /// **'Error updating favorites'**
  String get errorUpdatingFavorites;

  /// No description provided for @errorSharingFoodDetails.
  ///
  /// In en, this message translates to:
  /// **'Error sharing food details'**
  String get errorSharingFoodDetails;

  /// No description provided for @breakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get breakfast;

  /// No description provided for @lunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get lunch;

  /// No description provided for @dinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get dinner;

  /// No description provided for @snack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get snack;

  /// No description provided for @trackerSettings.
  ///
  /// In en, this message translates to:
  /// **'Tracker Settings'**
  String get trackerSettings;

  /// No description provided for @configurationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Configuration not available right now due to maintenance.'**
  String get configurationNotAvailable;

  /// No description provided for @doYouWantToLeave.
  ///
  /// In en, this message translates to:
  /// **'Do you want to leave this page and view \"{foodName}\"?'**
  String doYouWantToLeave(String foodName);

  /// No description provided for @symptomHistory.
  ///
  /// In en, this message translates to:
  /// **'Symptom History'**
  String get symptomHistory;

  /// No description provided for @setManualCalorieTarget.
  ///
  /// In en, this message translates to:
  /// **'Set your manual calorie target:'**
  String get setManualCalorieTarget;

  /// No description provided for @workoutLogComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Workout Log Coming Soon!'**
  String get workoutLogComingSoon;

  /// No description provided for @fastingError.
  ///
  /// In en, this message translates to:
  /// **'Fasting Error: {error}'**
  String fastingError(String error);

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found'**
  String get profileNotFound;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile: {error}'**
  String errorLoadingProfile(String error);

  /// No description provided for @settingsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Settings coming soon!'**
  String get settingsComingSoon;

  /// No description provided for @savedPosts.
  ///
  /// In en, this message translates to:
  /// **'Saved Posts'**
  String get savedPosts;

  /// No description provided for @savedPostsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Saved posts coming soon!'**
  String get savedPostsComingSoon;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @archiveComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Archive coming soon!'**
  String get archiveComingSoon;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @areYouSureLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get areYouSureLogout;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @deletePost.
  ///
  /// In en, this message translates to:
  /// **'Delete Post'**
  String get deletePost;

  /// No description provided for @deletePostQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete Post?'**
  String get deletePostQuestion;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @noPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No Posts Yet'**
  String get noPostsYet;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @taggedPostsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Tagged posts coming soon'**
  String get taggedPostsComingSoon;

  /// No description provided for @yourStory.
  ///
  /// In en, this message translates to:
  /// **'Your Story'**
  String get yourStory;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @trending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get trending;

  /// No description provided for @successCoinsAdded.
  ///
  /// In en, this message translates to:
  /// **'Success! You added {amount} coins. 🪙'**
  String successCoinsAdded(int amount);

  /// No description provided for @workoutCompleted.
  ///
  /// In en, this message translates to:
  /// **'Workout Completed'**
  String get workoutCompleted;

  /// No description provided for @greatJob.
  ///
  /// In en, this message translates to:
  /// **'Great Job!'**
  String get greatJob;

  /// No description provided for @planWorkout.
  ///
  /// In en, this message translates to:
  /// **'Plan Workout'**
  String get planWorkout;

  /// No description provided for @routineName.
  ///
  /// In en, this message translates to:
  /// **'Routine Name'**
  String get routineName;

  /// No description provided for @enterRoutineName.
  ///
  /// In en, this message translates to:
  /// **'Enter routine name...'**
  String get enterRoutineName;

  /// No description provided for @routineSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Routine saved successfully!'**
  String get routineSavedSuccessfully;

  /// No description provided for @pleaseSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Please select a date'**
  String get pleaseSelectDate;

  /// No description provided for @workoutPlannedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Workout planned successfully!'**
  String get workoutPlannedSuccessfully;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select Time'**
  String get selectTime;

  /// No description provided for @planning.
  ///
  /// In en, this message translates to:
  /// **'Planning...'**
  String get planning;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @optionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Optional notes...'**
  String get optionalNotes;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get calories;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @tapToLogWorkout.
  ///
  /// In en, this message translates to:
  /// **'Tap to log your workout! 💪'**
  String get tapToLogWorkout;

  /// No description provided for @exerciseWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight Used (kg)'**
  String get exerciseWeight;

  /// No description provided for @plannedWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Planned Workouts'**
  String get plannedWorkouts;

  /// No description provided for @manageWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Manage Workouts'**
  String get manageWorkouts;

  /// No description provided for @noPlannedWorkouts.
  ///
  /// In en, this message translates to:
  /// **'No planned workouts'**
  String get noPlannedWorkouts;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'more'**
  String get more;

  /// No description provided for @exercises.
  ///
  /// In en, this message translates to:
  /// **'exercises'**
  String get exercises;

  /// No description provided for @deleteWorkout.
  ///
  /// In en, this message translates to:
  /// **'Delete Workout'**
  String get deleteWorkout;

  /// No description provided for @deleteWorkoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this workout?'**
  String get deleteWorkoutConfirm;

  /// No description provided for @workoutDeleted.
  ///
  /// In en, this message translates to:
  /// **'Workout deleted successfully'**
  String get workoutDeleted;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @exitApp.
  ///
  /// In en, this message translates to:
  /// **'Exit App'**
  String get exitApp;

  /// No description provided for @exitAppConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to exit the app?'**
  String get exitAppConfirm;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @recipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get recipes;

  /// No description provided for @browseRecipes.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browseRecipes;

  /// No description provided for @myRecipes.
  ///
  /// In en, this message translates to:
  /// **'My Recipes'**
  String get myRecipes;

  /// No description provided for @createRecipe.
  ///
  /// In en, this message translates to:
  /// **'Create Recipe'**
  String get createRecipe;

  /// No description provided for @featuredRecipes.
  ///
  /// In en, this message translates to:
  /// **'Featured Recipes'**
  String get featuredRecipes;

  /// No description provided for @noRecipesYet.
  ///
  /// In en, this message translates to:
  /// **'No recipes yet'**
  String get noRecipesYet;

  /// No description provided for @createYourFirstRecipe.
  ///
  /// In en, this message translates to:
  /// **'Create your first recipe to get started'**
  String get createYourFirstRecipe;

  /// No description provided for @recipeCreationComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Recipe creation feature coming soon!'**
  String get recipeCreationComingSoon;

  /// No description provided for @advancedHealthInsights.
  ///
  /// In en, this message translates to:
  /// **'Advanced Health Insights'**
  String get advancedHealthInsights;

  /// No description provided for @micronutrientRadar.
  ///
  /// In en, this message translates to:
  /// **'Micronutrient Radar'**
  String get micronutrientRadar;

  /// No description provided for @micronutrientRadarDesc.
  ///
  /// In en, this message translates to:
  /// **'Your coverage of essential vitamins & minerals today.'**
  String get micronutrientRadarDesc;

  /// No description provided for @nastiesWatchdog.
  ///
  /// In en, this message translates to:
  /// **'Nasties Watchdog'**
  String get nastiesWatchdog;

  /// No description provided for @nastiesWatchdogDesc.
  ///
  /// In en, this message translates to:
  /// **'Monitoring potentially harmful intakes.'**
  String get nastiesWatchdogDesc;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @hydrationTracking.
  ///
  /// In en, this message translates to:
  /// **'Hydration Tracking'**
  String get hydrationTracking;

  /// No description provided for @todaysHydration.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Hydration'**
  String get todaysHydration;

  /// No description provided for @ofDailyGoal.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of daily goal'**
  String ofDailyGoal(String percent);

  /// No description provided for @yourPersonalizedWaterNeeds.
  ///
  /// In en, this message translates to:
  /// **'Your Personalized Water Needs'**
  String get yourPersonalizedWaterNeeds;

  /// No description provided for @baseWeight.
  ///
  /// In en, this message translates to:
  /// **'Base (Weight)'**
  String get baseWeight;

  /// No description provided for @genderAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Gender Adjustment'**
  String get genderAdjustment;

  /// No description provided for @yourDailyTarget.
  ///
  /// In en, this message translates to:
  /// **'Your Daily Target'**
  String get yourDailyTarget;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @waterBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Water Breakdown'**
  String get waterBreakdown;

  /// No description provided for @manualInput.
  ///
  /// In en, this message translates to:
  /// **'Manual Input'**
  String get manualInput;

  /// No description provided for @fromFood.
  ///
  /// In en, this message translates to:
  /// **'From Food'**
  String get fromFood;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @weeklyTrend.
  ///
  /// In en, this message translates to:
  /// **'Weekly Trend'**
  String get weeklyTrend;

  /// No description provided for @whyWaterMatters.
  ///
  /// In en, this message translates to:
  /// **'Why Water Matters'**
  String get whyWaterMatters;

  /// No description provided for @heartHealth.
  ///
  /// In en, this message translates to:
  /// **'Heart Health'**
  String get heartHealth;

  /// No description provided for @heartHealthDesc.
  ///
  /// In en, this message translates to:
  /// **'Water helps maintain blood volume and supports cardiovascular function.'**
  String get heartHealthDesc;

  /// No description provided for @brainFunction.
  ///
  /// In en, this message translates to:
  /// **'Brain Function'**
  String get brainFunction;

  /// No description provided for @brainFunctionDesc.
  ///
  /// In en, this message translates to:
  /// **'Proper hydration improves cognitive performance, focus, and mental clarity.'**
  String get brainFunctionDesc;

  /// No description provided for @energyLevels.
  ///
  /// In en, this message translates to:
  /// **'Energy Levels'**
  String get energyLevels;

  /// No description provided for @energyLevelsDesc.
  ///
  /// In en, this message translates to:
  /// **'Dehydration can cause fatigue. Staying hydrated keeps your energy up.'**
  String get energyLevelsDesc;

  /// No description provided for @skinHealth.
  ///
  /// In en, this message translates to:
  /// **'Skin Health'**
  String get skinHealth;

  /// No description provided for @skinHealthDesc.
  ///
  /// In en, this message translates to:
  /// **'Water helps maintain skin elasticity and promotes a healthy complexion.'**
  String get skinHealthDesc;

  /// No description provided for @muscleFunction.
  ///
  /// In en, this message translates to:
  /// **'Muscle Function'**
  String get muscleFunction;

  /// No description provided for @muscleFunctionDesc.
  ///
  /// In en, this message translates to:
  /// **'Water is essential for muscle contraction and prevents cramps.'**
  String get muscleFunctionDesc;

  /// No description provided for @digestion.
  ///
  /// In en, this message translates to:
  /// **'Digestion'**
  String get digestion;

  /// No description provided for @digestionDesc.
  ///
  /// In en, this message translates to:
  /// **'Water aids in digestion, nutrient absorption, and prevents constipation.'**
  String get digestionDesc;

  /// No description provided for @yourHydrationImpact.
  ///
  /// In en, this message translates to:
  /// **'Your Hydration Impact'**
  String get yourHydrationImpact;

  /// No description provided for @excellentHydration.
  ///
  /// In en, this message translates to:
  /// **'Excellent Hydration! 💧'**
  String get excellentHydration;

  /// No description provided for @excellentHydrationMsg.
  ///
  /// In en, this message translates to:
  /// **'You\'ve met your daily water goal. Keep it up!'**
  String get excellentHydrationMsg;

  /// No description provided for @goodHydration.
  ///
  /// In en, this message translates to:
  /// **'Good Hydration 👍'**
  String get goodHydration;

  /// No description provided for @goodHydrationMsg.
  ///
  /// In en, this message translates to:
  /// **'You\'re doing well! Just a bit more to reach your goal.'**
  String get goodHydrationMsg;

  /// No description provided for @moderateHydration.
  ///
  /// In en, this message translates to:
  /// **'Moderate Hydration ⚠️'**
  String get moderateHydration;

  /// No description provided for @moderateHydrationMsg.
  ///
  /// In en, this message translates to:
  /// **'You\'re halfway there. Increase your water intake.'**
  String get moderateHydrationMsg;

  /// No description provided for @lowHydration.
  ///
  /// In en, this message translates to:
  /// **'Low Hydration 🚨'**
  String get lowHydration;

  /// No description provided for @lowHydrationMsg.
  ///
  /// In en, this message translates to:
  /// **'Your water intake is below recommended levels.'**
  String get lowHydrationMsg;

  /// No description provided for @optimalBrainFunction.
  ///
  /// In en, this message translates to:
  /// **'✅ Optimal brain function'**
  String get optimalBrainFunction;

  /// No description provided for @peakPhysicalPerformance.
  ///
  /// In en, this message translates to:
  /// **'✅ Peak physical performance'**
  String get peakPhysicalPerformance;

  /// No description provided for @healthySkinDigestion.
  ///
  /// In en, this message translates to:
  /// **'✅ Healthy skin and digestion'**
  String get healthySkinDigestion;

  /// No description provided for @goodEnergyLevels.
  ///
  /// In en, this message translates to:
  /// **'✅ Good energy levels'**
  String get goodEnergyLevels;

  /// No description provided for @normalCognitiveFunction.
  ///
  /// In en, this message translates to:
  /// **'✅ Normal cognitive function'**
  String get normalCognitiveFunction;

  /// No description provided for @drinkMoreOptimal.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Drink more for optimal performance'**
  String get drinkMoreOptimal;

  /// No description provided for @mildDehydrationPossible.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Mild dehydration possible'**
  String get mildDehydrationPossible;

  /// No description provided for @reducedEnergyLevels.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Reduced energy levels'**
  String get reducedEnergyLevels;

  /// No description provided for @drinkMoreWater.
  ///
  /// In en, this message translates to:
  /// **'💡 Drink more water throughout the day'**
  String get drinkMoreWater;

  /// No description provided for @dehydrationRisk.
  ///
  /// In en, this message translates to:
  /// **'🚨 Dehydration risk'**
  String get dehydrationRisk;

  /// No description provided for @fatigueHeadachesPossible.
  ///
  /// In en, this message translates to:
  /// **'🚨 Fatigue and headaches possible'**
  String get fatigueHeadachesPossible;

  /// No description provided for @startDrinkingWater.
  ///
  /// In en, this message translates to:
  /// **'💡 Start drinking water immediately'**
  String get startDrinkingWater;

  /// No description provided for @hydrationTips.
  ///
  /// In en, this message translates to:
  /// **'Hydration Tips'**
  String get hydrationTips;

  /// No description provided for @startYourDayRight.
  ///
  /// In en, this message translates to:
  /// **'Start Your Day Right'**
  String get startYourDayRight;

  /// No description provided for @startYourDayRightDesc.
  ///
  /// In en, this message translates to:
  /// **'Drink a glass of water first thing in the morning to kickstart your metabolism and rehydrate after sleep.'**
  String get startYourDayRightDesc;

  /// No description provided for @setReminders.
  ///
  /// In en, this message translates to:
  /// **'Set Reminders'**
  String get setReminders;

  /// No description provided for @setRemindersDesc.
  ///
  /// In en, this message translates to:
  /// **'Use your phone or app reminders to drink water regularly throughout the day, especially if you tend to forget.'**
  String get setRemindersDesc;

  /// No description provided for @drinkBeforeMeals.
  ///
  /// In en, this message translates to:
  /// **'Drink Before Meals'**
  String get drinkBeforeMeals;

  /// No description provided for @drinkBeforeMealsDesc.
  ///
  /// In en, this message translates to:
  /// **'Drinking water 30 minutes before meals can help with digestion and prevent overeating.'**
  String get drinkBeforeMealsDesc;

  /// No description provided for @carryWaterBottle.
  ///
  /// In en, this message translates to:
  /// **'Carry a Water Bottle'**
  String get carryWaterBottle;

  /// No description provided for @carryWaterBottleDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep a reusable water bottle with you at all times to make it easier to stay hydrated on the go.'**
  String get carryWaterBottleDesc;

  /// No description provided for @eatWaterRichFoods.
  ///
  /// In en, this message translates to:
  /// **'Eat Water-Rich Foods'**
  String get eatWaterRichFoods;

  /// No description provided for @eatWaterRichFoodsDesc.
  ///
  /// In en, this message translates to:
  /// **'Include fruits and vegetables like watermelon, cucumber, and oranges in your diet for extra hydration.'**
  String get eatWaterRichFoodsDesc;

  /// No description provided for @monitorYourUrine.
  ///
  /// In en, this message translates to:
  /// **'Monitor Your Urine'**
  String get monitorYourUrine;

  /// No description provided for @monitorYourUrineDesc.
  ///
  /// In en, this message translates to:
  /// **'Light yellow or clear urine is a good sign of proper hydration. Dark yellow indicates you need more water.'**
  String get monitorYourUrineDesc;

  /// No description provided for @didYouKnow.
  ///
  /// In en, this message translates to:
  /// **'Did You Know?'**
  String get didYouKnow;

  /// No description provided for @bodyIsWater.
  ///
  /// In en, this message translates to:
  /// **'60% of your body is water'**
  String get bodyIsWater;

  /// No description provided for @bodyIsWaterDesc.
  ///
  /// In en, this message translates to:
  /// **'The human body is composed of approximately 60% water, making hydration essential for all bodily functions.'**
  String get bodyIsWaterDesc;

  /// No description provided for @surviveWeeksWithoutFood.
  ///
  /// In en, this message translates to:
  /// **'You can survive weeks without food'**
  String get surviveWeeksWithoutFood;

  /// No description provided for @surviveWeeksWithoutFoodDesc.
  ///
  /// In en, this message translates to:
  /// **'But only 3-4 days without water. This shows how critical water is for survival.'**
  String get surviveWeeksWithoutFoodDesc;

  /// No description provided for @brainIsWater.
  ///
  /// In en, this message translates to:
  /// **'Your brain is 75% water'**
  String get brainIsWater;

  /// No description provided for @brainIsWaterDesc.
  ///
  /// In en, this message translates to:
  /// **'Even mild dehydration can affect cognitive function, memory, and mood.'**
  String get brainIsWaterDesc;

  /// No description provided for @waterRegulatesTemperature.
  ///
  /// In en, this message translates to:
  /// **'Water regulates body temperature'**
  String get waterRegulatesTemperature;

  /// No description provided for @waterRegulatesTemperatureDesc.
  ///
  /// In en, this message translates to:
  /// **'Through sweating and respiration, water helps maintain your body\'s optimal temperature.'**
  String get waterRegulatesTemperatureDesc;

  /// No description provided for @waterCarriesNutrients.
  ///
  /// In en, this message translates to:
  /// **'Water carries nutrients'**
  String get waterCarriesNutrients;

  /// No description provided for @waterCarriesNutrientsDesc.
  ///
  /// In en, this message translates to:
  /// **'Water transports essential nutrients, oxygen, and hormones throughout your body via the bloodstream.'**
  String get waterCarriesNutrientsDesc;

  /// No description provided for @waterFlushesToxins.
  ///
  /// In en, this message translates to:
  /// **'Water flushes toxins'**
  String get waterFlushesToxins;

  /// No description provided for @waterFlushesToxinsDesc.
  ///
  /// In en, this message translates to:
  /// **'Your kidneys use water to filter waste and toxins from your blood, which are then eliminated through urine.'**
  String get waterFlushesToxinsDesc;

  /// No description provided for @errorLoadingFeed.
  ///
  /// In en, this message translates to:
  /// **'Error loading feed: {error}'**
  String errorLoadingFeed(String error);

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorGeneric(String error);

  /// No description provided for @newPostFrom.
  ///
  /// In en, this message translates to:
  /// **'New post from {username}'**
  String newPostFrom(String username);

  /// No description provided for @trophyRoom.
  ///
  /// In en, this message translates to:
  /// **'Trophy Room'**
  String get trophyRoom;

  /// No description provided for @noTrophiesYet.
  ///
  /// In en, this message translates to:
  /// **'No trophies yet!'**
  String get noTrophiesYet;

  /// No description provided for @completeChallengesToEarn.
  ///
  /// In en, this message translates to:
  /// **'Complete challenges to earn them.'**
  String get completeChallengesToEarn;

  /// No description provided for @avatarUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Avatar updated successfully!'**
  String get avatarUpdatedSuccessfully;

  /// No description provided for @errorUploadingAvatar.
  ///
  /// In en, this message translates to:
  /// **'Error uploading avatar: {error}'**
  String errorUploadingAvatar(String error);

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone. All your data will be permanently deleted.'**
  String get deleteAccountConfirm;

  /// No description provided for @contactSupportToDelete.
  ///
  /// In en, this message translates to:
  /// **'To delete your account, please contact support@flow.com with your request.'**
  String get contactSupportToDelete;

  /// No description provided for @errorContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}. Please contact support@flow.com'**
  String errorContactSupport(String error);

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @deleteAccountDescription.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and all associated data. This action cannot be undone.'**
  String get deleteAccountDescription;

  /// No description provided for @deleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete My Account'**
  String get deleteMyAccount;

  /// No description provided for @ourMission.
  ///
  /// In en, this message translates to:
  /// **'Our Mission'**
  String get ourMission;

  /// No description provided for @ourMissionDesc1.
  ///
  /// In en, this message translates to:
  /// **'Empowering you to achieve optimal health through intelligent nutrition tracking, personalized insights, and data-driven wellness decisions.'**
  String get ourMissionDesc1;

  /// No description provided for @ourMissionDesc2.
  ///
  /// In en, this message translates to:
  /// **'We believe that understanding your body\'s nutritional needs is the foundation of a healthy lifestyle. Flow combines cutting-edge technology with comprehensive nutrient tracking to help you make informed choices about your health.'**
  String get ourMissionDesc2;

  /// No description provided for @keyFeatures.
  ///
  /// In en, this message translates to:
  /// **'Key Features'**
  String get keyFeatures;

  /// No description provided for @comprehensiveNutritionTracking.
  ///
  /// In en, this message translates to:
  /// **'Comprehensive Nutrition Tracking'**
  String get comprehensiveNutritionTracking;

  /// No description provided for @comprehensiveNutritionTrackingDesc.
  ///
  /// In en, this message translates to:
  /// **'Track 50+ nutrients including macros, vitamins, minerals, and amino acids'**
  String get comprehensiveNutritionTrackingDesc;

  /// No description provided for @workoutExerciseLogging.
  ///
  /// In en, this message translates to:
  /// **'Workout & Exercise Logging'**
  String get workoutExerciseLogging;

  /// No description provided for @workoutExerciseLoggingDesc.
  ///
  /// In en, this message translates to:
  /// **'Log workouts, track progress, and plan your fitness routine'**
  String get workoutExerciseLoggingDesc;

  /// No description provided for @aiGeneratedRecipes.
  ///
  /// In en, this message translates to:
  /// **'AI-Generated Recipes'**
  String get aiGeneratedRecipes;

  /// No description provided for @aiGeneratedRecipesDesc.
  ///
  /// In en, this message translates to:
  /// **'Discover delicious, nutritious recipes tailored to your dietary preferences'**
  String get aiGeneratedRecipesDesc;

  /// No description provided for @vitalityBreakdownDesc.
  ///
  /// In en, this message translates to:
  /// **'Monitor your daily nutrient intake and identify deficiencies'**
  String get vitalityBreakdownDesc;

  /// No description provided for @challengesGamification.
  ///
  /// In en, this message translates to:
  /// **'Challenges & Gamification'**
  String get challengesGamification;

  /// No description provided for @challengesGamificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Stay motivated with challenges and earn rewards'**
  String get challengesGamificationDesc;

  /// No description provided for @socialCommunity.
  ///
  /// In en, this message translates to:
  /// **'Social Community'**
  String get socialCommunity;

  /// No description provided for @socialCommunityDesc.
  ///
  /// In en, this message translates to:
  /// **'Connect with others on their wellness journey'**
  String get socialCommunityDesc;

  /// No description provided for @theFlowTeam.
  ///
  /// In en, this message translates to:
  /// **'The Flow Team'**
  String get theFlowTeam;

  /// No description provided for @theFlowTeamDesc1.
  ///
  /// In en, this message translates to:
  /// **'Flow is built by a passionate team dedicated to revolutionizing health and wellness tracking. We combine expertise in nutrition, fitness, and technology to create an app that truly understands your needs.'**
  String get theFlowTeamDesc1;

  /// No description provided for @theFlowTeamDesc2.
  ///
  /// In en, this message translates to:
  /// **'Our vision is to become the most comprehensive health tracking platform, helping millions of users achieve their wellness goals through data-driven insights and personalized recommendations.'**
  String get theFlowTeamDesc2;

  /// No description provided for @legalPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Legal & Privacy'**
  String get legalPrivacy;

  /// No description provided for @legalPrivacyDesc.
  ///
  /// In en, this message translates to:
  /// **'Your privacy and data security are our top priorities. We are committed to protecting your personal information and providing a safe, transparent experience.'**
  String get legalPrivacyDesc;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @versionInformation.
  ///
  /// In en, this message translates to:
  /// **'Version Information'**
  String get versionInformation;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @buildNumber.
  ///
  /// In en, this message translates to:
  /// **'Build Number'**
  String get buildNumber;

  /// No description provided for @packageName.
  ///
  /// In en, this message translates to:
  /// **'Package Name'**
  String get packageName;

  /// No description provided for @copyright.
  ///
  /// In en, this message translates to:
  /// **'© {year} Flow. All rights reserved.'**
  String copyright(int year);

  /// No description provided for @yourCompleteHealthWellnessCompanion.
  ///
  /// In en, this message translates to:
  /// **'Your Complete Health & Wellness Companion'**
  String get yourCompleteHealthWellnessCompanion;

  /// No description provided for @gettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get gettingStarted;

  /// No description provided for @nutritionTracking.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Tracking'**
  String get nutritionTracking;

  /// No description provided for @workoutsActivities.
  ///
  /// In en, this message translates to:
  /// **'Workouts & Activities'**
  String get workoutsActivities;

  /// No description provided for @recipesMealPlanning.
  ///
  /// In en, this message translates to:
  /// **'Recipes & Meal Planning'**
  String get recipesMealPlanning;

  /// No description provided for @challengesProgress.
  ///
  /// In en, this message translates to:
  /// **'Challenges & Progress'**
  String get challengesProgress;

  /// No description provided for @aiFeatures.
  ///
  /// In en, this message translates to:
  /// **'AI Features'**
  String get aiFeatures;

  /// No description provided for @accountData.
  ///
  /// In en, this message translates to:
  /// **'Account & Data'**
  String get accountData;

  /// No description provided for @searchForHelp.
  ///
  /// In en, this message translates to:
  /// **'Search for help...'**
  String get searchForHelp;

  /// No description provided for @stillNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Still need help?'**
  String get stillNeedHelp;

  /// No description provided for @supportTeamHere.
  ///
  /// In en, this message translates to:
  /// **'Our support team is here to help you'**
  String get supportTeamHere;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @exportToCSV.
  ///
  /// In en, this message translates to:
  /// **'Export to CSV'**
  String get exportToCSV;

  /// No description provided for @exportToCSVDesc.
  ///
  /// In en, this message translates to:
  /// **'Export your nutrition data as a CSV file for Excel or Google Sheets'**
  String get exportToCSVDesc;

  /// No description provided for @exportToJSON.
  ///
  /// In en, this message translates to:
  /// **'Export to JSON'**
  String get exportToJSON;

  /// No description provided for @exportToJSONDesc.
  ///
  /// In en, this message translates to:
  /// **'Export your data in JSON format for developers or data analysis'**
  String get exportToJSONDesc;

  /// No description provided for @generatePDFReport.
  ///
  /// In en, this message translates to:
  /// **'Generate PDF Report'**
  String get generatePDFReport;

  /// No description provided for @generatePDFReportDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a beautiful PDF report with your nutrition summary and daily breakdown'**
  String get generatePDFReportDesc;

  /// No description provided for @noDataFoundForRange.
  ///
  /// In en, this message translates to:
  /// **'No data found for the selected date range.'**
  String get noDataFoundForRange;

  /// No description provided for @flow.
  ///
  /// In en, this message translates to:
  /// **'FLOW'**
  String get flow;

  /// No description provided for @howDoIGetStarted.
  ///
  /// In en, this message translates to:
  /// **'How do I get started with Flow?'**
  String get howDoIGetStarted;

  /// No description provided for @howDoIGetStartedAnswer.
  ///
  /// In en, this message translates to:
  /// **'After creating your account, you\'ll go through a quick onboarding process where you\'ll set your goals, preferences, and basic information. Once complete, you can start logging meals, workouts, and track your progress on the dashboard.'**
  String get howDoIGetStartedAnswer;

  /// No description provided for @howDoISetTargets.
  ///
  /// In en, this message translates to:
  /// **'How do I set my daily calorie and nutrient targets?'**
  String get howDoISetTargets;

  /// No description provided for @howDoISetTargetsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your targets are automatically calculated based on your profile information (age, weight, height, activity level, and goals). You can adjust these in your Profile settings at any time.'**
  String get howDoISetTargetsAnswer;

  /// No description provided for @whatAreCoins.
  ///
  /// In en, this message translates to:
  /// **'What are coins and how do I earn them?'**
  String get whatAreCoins;

  /// No description provided for @whatAreCoinsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Coins are Flow\'s reward currency. You earn coins by completing daily activities like logging meals, completing workouts, and participating in challenges. Use coins to unlock premium features and rewards.'**
  String get whatAreCoinsAnswer;

  /// No description provided for @howDoILogMeal.
  ///
  /// In en, this message translates to:
  /// **'How do I log a meal?'**
  String get howDoILogMeal;

  /// No description provided for @howDoILogMealAnswer.
  ///
  /// In en, this message translates to:
  /// **'Tap the \"+\" button on your dashboard, select a meal type (Breakfast, Lunch, Dinner, or Snack), then search for foods, scan a barcode, take a photo, or use voice input. You can also add custom foods with your own nutritional information.'**
  String get howDoILogMealAnswer;

  /// No description provided for @canILogMealsPhotos.
  ///
  /// In en, this message translates to:
  /// **'Can I log meals using photos?'**
  String get canILogMealsPhotos;

  /// No description provided for @canILogMealsPhotosAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes! Flow uses advanced image recognition to identify foods from photos. Simply take a photo of your meal, and Flow will recognize the foods and their estimated portions. You can then adjust quantities and add them to your log.'**
  String get canILogMealsPhotosAnswer;

  /// No description provided for @howDoesVoiceInputWork.
  ///
  /// In en, this message translates to:
  /// **'How does voice input work?'**
  String get howDoesVoiceInputWork;

  /// No description provided for @howDoesVoiceInputWorkAnswer.
  ///
  /// In en, this message translates to:
  /// **'Tap the microphone icon when adding a meal, speak what you\'re eating (e.g., \"chicken breast with rice\"), and Flow will recognize the foods and help you log them quickly.'**
  String get howDoesVoiceInputWorkAnswer;

  /// No description provided for @whatIfFoodNotInDatabase.
  ///
  /// In en, this message translates to:
  /// **'What if a food isn\'t in the database?'**
  String get whatIfFoodNotInDatabase;

  /// No description provided for @whatIfFoodNotInDatabaseAnswer.
  ///
  /// In en, this message translates to:
  /// **'You can create custom foods by entering the nutritional information manually. These custom foods will be saved to your account and appear in your recent foods list for easy access.'**
  String get whatIfFoodNotInDatabaseAnswer;

  /// No description provided for @howAccurateNutritionTracking.
  ///
  /// In en, this message translates to:
  /// **'How accurate is the nutrition tracking?'**
  String get howAccurateNutritionTracking;

  /// No description provided for @howAccurateNutritionTrackingAnswer.
  ///
  /// In en, this message translates to:
  /// **'Flow uses comprehensive nutrition databases and AI recognition to provide accurate nutritional information. However, portion sizes from photos are estimates - you can always adjust quantities to match your actual serving size.'**
  String get howAccurateNutritionTrackingAnswer;

  /// No description provided for @howDoILogWorkout.
  ///
  /// In en, this message translates to:
  /// **'How do I log a workout?'**
  String get howDoILogWorkout;

  /// No description provided for @howDoILogWorkoutAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to the Workouts section, tap \"Log Workout\", select an exercise from the database or create a custom one, enter sets, reps, and weight, then save. The calories burned will be automatically calculated and added to your daily totals.'**
  String get howDoILogWorkoutAnswer;

  /// No description provided for @canICreateWorkoutPlans.
  ///
  /// In en, this message translates to:
  /// **'Can I create my own workout plans?'**
  String get canICreateWorkoutPlans;

  /// No description provided for @canICreateWorkoutPlansAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes! You can create custom workout plans in the Programs section. Add exercises, set schedules, and track your progress over time.'**
  String get canICreateWorkoutPlansAnswer;

  /// No description provided for @howAreCaloriesBurnedCalculated.
  ///
  /// In en, this message translates to:
  /// **'How are calories burned calculated?'**
  String get howAreCaloriesBurnedCalculated;

  /// No description provided for @howAreCaloriesBurnedCalculatedAnswer.
  ///
  /// In en, this message translates to:
  /// **'Calories burned are calculated based on the exercise type, duration, intensity, and your personal profile information (weight, age, etc.).'**
  String get howAreCaloriesBurnedCalculatedAnswer;

  /// No description provided for @howDoIFindRecipes.
  ///
  /// In en, this message translates to:
  /// **'How do I find recipes?'**
  String get howDoIFindRecipes;

  /// No description provided for @howDoIFindRecipesAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to the Recipes section to browse our collection of healthy recipes. You can filter by meal type, cuisine, dietary preferences, and search by ingredients or tags.'**
  String get howDoIFindRecipesAnswer;

  /// No description provided for @canICreateRecipes.
  ///
  /// In en, this message translates to:
  /// **'Can I create my own recipes?'**
  String get canICreateRecipes;

  /// No description provided for @canICreateRecipesAnswer.
  ///
  /// In en, this message translates to:
  /// **'Absolutely! Tap \"Create Recipe\" to add your own custom recipes. Enter ingredients, instructions, nutritional information per serving, and upload a photo. Your recipes will be saved to your account.'**
  String get canICreateRecipesAnswer;

  /// No description provided for @howDoIAddRecipeToMealLog.
  ///
  /// In en, this message translates to:
  /// **'How do I add a recipe to my meal log?'**
  String get howDoIAddRecipeToMealLog;

  /// No description provided for @howDoIAddRecipeToMealLogAnswer.
  ///
  /// In en, this message translates to:
  /// **'When viewing a recipe, select your meal type and tap \"Add as Meal\". Flow will calculate the nutritional values based on the number of servings you consumed.'**
  String get howDoIAddRecipeToMealLogAnswer;

  /// No description provided for @whatAreFlowChallenges.
  ///
  /// In en, this message translates to:
  /// **'What are Flow Challenges?'**
  String get whatAreFlowChallenges;

  /// No description provided for @whatAreFlowChallengesAnswer.
  ///
  /// In en, this message translates to:
  /// **'Flow Challenges are community-driven goals that help you stay motivated. Join challenges like \"Drink 2L Water Daily\" or \"Complete 10 Workouts This Month\" to earn rewards and compete with others.'**
  String get whatAreFlowChallengesAnswer;

  /// No description provided for @howDoIJoinChallenge.
  ///
  /// In en, this message translates to:
  /// **'How do I join a challenge?'**
  String get howDoIJoinChallenge;

  /// No description provided for @howDoIJoinChallengeAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to the Challenges section, browse available challenges, and tap \"Join Now\" on any challenge that interests you. Your progress will be automatically tracked based on your logged activities.'**
  String get howDoIJoinChallengeAnswer;

  /// No description provided for @howIsChallengeProgressCalculated.
  ///
  /// In en, this message translates to:
  /// **'How is my challenge progress calculated?'**
  String get howIsChallengeProgressCalculated;

  /// No description provided for @howIsChallengeProgressCalculatedAnswer.
  ///
  /// In en, this message translates to:
  /// **'Progress is automatically calculated from your logged meals, workouts, and activities. For example, if you join a protein challenge, your daily protein intake is tracked from your meal logs.'**
  String get howIsChallengeProgressCalculatedAnswer;

  /// No description provided for @whatIsVitalityBreakdown.
  ///
  /// In en, this message translates to:
  /// **'What is Vitality Breakdown?'**
  String get whatIsVitalityBreakdown;

  /// No description provided for @whatIsVitalityBreakdownAnswer.
  ///
  /// In en, this message translates to:
  /// **'Vitality Breakdown is your comprehensive nutrient monitoring hub. It shows all vitamins, minerals, amino acids, and specialized nutrients you\'ve consumed, compared to recommended daily allowances (RDA).'**
  String get whatIsVitalityBreakdownAnswer;

  /// No description provided for @whatIsVitalityShield.
  ///
  /// In en, this message translates to:
  /// **'What is Vitality Shield?'**
  String get whatIsVitalityShield;

  /// No description provided for @whatIsVitalityShieldAnswer.
  ///
  /// In en, this message translates to:
  /// **'Vitality Shield provides critical alerts for nutrient deficiencies (e.g., low calcium for multiple days) and warnings for excessive intake (high sodium, sugar, caffeine). It helps you maintain optimal nutrition balance.'**
  String get whatIsVitalityShieldAnswer;

  /// No description provided for @howDoIViewNutrientTrends.
  ///
  /// In en, this message translates to:
  /// **'How do I view my nutrient trends?'**
  String get howDoIViewNutrientTrends;

  /// No description provided for @howDoIViewNutrientTrendsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Tap on any nutrient in Vitality Breakdown to see a weekly trend graph showing your intake over the last 7 days. You can share these charts with others.'**
  String get howDoIViewNutrientTrendsAnswer;

  /// No description provided for @canIViewPastDaysNutrition.
  ///
  /// In en, this message translates to:
  /// **'Can I view past days\' nutrition data?'**
  String get canIViewPastDaysNutrition;

  /// No description provided for @canIViewPastDaysNutritionAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes! Use the date picker in Vitality Breakdown to view any previous day\'s nutritional data and see how your intake has changed over time.'**
  String get canIViewPastDaysNutritionAnswer;

  /// No description provided for @whatIsAICoach.
  ///
  /// In en, this message translates to:
  /// **'What is the AI Coach?'**
  String get whatIsAICoach;

  /// No description provided for @whatIsAICoachAnswer.
  ///
  /// In en, this message translates to:
  /// **'The AI Coach provides personalized nutrition and fitness advice based on your goals, logged data, and progress. Ask questions, get meal suggestions, and receive guidance tailored to your journey.'**
  String get whatIsAICoachAnswer;

  /// No description provided for @howDoesFoodRecognitionWork.
  ///
  /// In en, this message translates to:
  /// **'How does food recognition work?'**
  String get howDoesFoodRecognitionWork;

  /// No description provided for @howDoesFoodRecognitionWorkAnswer.
  ///
  /// In en, this message translates to:
  /// **'Flow uses advanced image recognition technology to identify foods from photos. The system recognizes multiple foods in a single image and estimates portion sizes to help you log meals quickly.'**
  String get howDoesFoodRecognitionWorkAnswer;

  /// No description provided for @isMyDataUsedToTrainAI.
  ///
  /// In en, this message translates to:
  /// **'Is my data used to train AI models?'**
  String get isMyDataUsedToTrainAI;

  /// No description provided for @isMyDataUsedToTrainAIAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your personal data is private and secure. We use aggregated, anonymized data to improve our services, but your individual information is never shared or used without your consent.'**
  String get isMyDataUsedToTrainAIAnswer;

  /// No description provided for @howDoIExportData.
  ///
  /// In en, this message translates to:
  /// **'How do I export my data?'**
  String get howDoIExportData;

  /// No description provided for @howDoIExportDataAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to Export Data in the menu. You can export your nutrition data as CSV or JSON files, or generate a PDF report. Select your date range and choose your preferred format.'**
  String get howDoIExportDataAnswer;

  /// No description provided for @canIDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Can I delete my account?'**
  String get canIDeleteAccount;

  /// No description provided for @canIDeleteAccountAnswer.
  ///
  /// In en, this message translates to:
  /// **'Yes, you can delete your account from your Profile settings. This will permanently remove all your data. Please contact support if you need assistance.'**
  String get canIDeleteAccountAnswer;

  /// No description provided for @howDoIChangePassword.
  ///
  /// In en, this message translates to:
  /// **'How do I change my password?'**
  String get howDoIChangePassword;

  /// No description provided for @howDoIChangePasswordAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to your Profile, then Settings, and select \"Change Password\". You\'ll receive an email with instructions to reset your password.'**
  String get howDoIChangePasswordAnswer;

  /// No description provided for @isMyDataSecure.
  ///
  /// In en, this message translates to:
  /// **'Is my data secure?'**
  String get isMyDataSecure;

  /// No description provided for @isMyDataSecureAnswer.
  ///
  /// In en, this message translates to:
  /// **'Absolutely. We use industry-standard encryption and security measures to protect your data. Your information is stored securely and never shared with third parties without your explicit consent.'**
  String get isMyDataSecureAnswer;

  /// No description provided for @enterWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter weight'**
  String get enterWeight;

  /// No description provided for @fastingActive.
  ///
  /// In en, this message translates to:
  /// **'Fasting Active'**
  String get fastingActive;

  /// No description provided for @startFast.
  ///
  /// In en, this message translates to:
  /// **'Start Fast'**
  String get startFast;

  /// No description provided for @bodyIsDigesting.
  ///
  /// In en, this message translates to:
  /// **'Body is digesting'**
  String get bodyIsDigesting;

  /// No description provided for @fatBurningKetosis.
  ///
  /// In en, this message translates to:
  /// **'Fat Burning (Ketosis) 🔥'**
  String get fatBurningKetosis;

  /// No description provided for @autophagyRepair.
  ///
  /// In en, this message translates to:
  /// **'Autophagy (Repair) 🧬'**
  String get autophagyRepair;

  /// No description provided for @pandaCoach.
  ///
  /// In en, this message translates to:
  /// **'Panda Coach'**
  String get pandaCoach;

  /// No description provided for @hydration.
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get hydration;

  /// No description provided for @goodProgress.
  ///
  /// In en, this message translates to:
  /// **'Good Progress 👍'**
  String get goodProgress;

  /// No description provided for @needsFocus.
  ///
  /// In en, this message translates to:
  /// **'Needs Focus 📉'**
  String get needsFocus;

  /// No description provided for @macronutrientsPer100g.
  ///
  /// In en, this message translates to:
  /// **'Macronutrients (per 100g):'**
  String get macronutrientsPer100g;

  /// No description provided for @otherNutrientsPer100g.
  ///
  /// In en, this message translates to:
  /// **'Other Nutrients (per 100g):'**
  String get otherNutrientsPer100g;

  /// No description provided for @allCuisines.
  ///
  /// In en, this message translates to:
  /// **'All Cuisines'**
  String get allCuisines;

  /// No description provided for @allMeals.
  ///
  /// In en, this message translates to:
  /// **'All Meals'**
  String get allMeals;

  /// No description provided for @searchRecipes.
  ///
  /// In en, this message translates to:
  /// **'Search Recipes'**
  String get searchRecipes;

  /// No description provided for @searchByName.
  ///
  /// In en, this message translates to:
  /// **'Search by name...'**
  String get searchByName;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @noTagsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No tags available'**
  String get noTagsAvailable;

  /// No description provided for @allTags.
  ///
  /// In en, this message translates to:
  /// **'All Tags'**
  String get allTags;

  /// No description provided for @viralRecipes.
  ///
  /// In en, this message translates to:
  /// **'Viral Recipes'**
  String get viralRecipes;

  /// No description provided for @untitledRecipe.
  ///
  /// In en, this message translates to:
  /// **'Untitled Recipe'**
  String get untitledRecipe;

  /// No description provided for @recipeAddedAsMeal.
  ///
  /// In en, this message translates to:
  /// **'Recipe added as {mealType}!'**
  String recipeAddedAsMeal(String mealType);

  /// No description provided for @pleaseUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Please upload an image for the recipe'**
  String get pleaseUploadImage;

  /// No description provided for @pleaseAddIngredient.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one ingredient'**
  String get pleaseAddIngredient;

  /// No description provided for @pleaseAddInstruction.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one instruction'**
  String get pleaseAddInstruction;

  /// No description provided for @recipeCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Recipe created successfully!'**
  String get recipeCreatedSuccessfully;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @titleEnglish.
  ///
  /// In en, this message translates to:
  /// **'Title (English)'**
  String get titleEnglish;

  /// No description provided for @prepTimeMin.
  ///
  /// In en, this message translates to:
  /// **'Prep Time (min)'**
  String get prepTimeMin;

  /// No description provided for @cookTimeMin.
  ///
  /// In en, this message translates to:
  /// **'Cook Time (min)'**
  String get cookTimeMin;

  /// No description provided for @mealType.
  ///
  /// In en, this message translates to:
  /// **'Meal Type'**
  String get mealType;

  /// No description provided for @dietType.
  ///
  /// In en, this message translates to:
  /// **'Diet Type'**
  String get dietType;

  /// No description provided for @addIngredient.
  ///
  /// In en, this message translates to:
  /// **'Add Ingredient'**
  String get addIngredient;

  /// No description provided for @addInstruction.
  ///
  /// In en, this message translates to:
  /// **'Add Instruction'**
  String get addInstruction;

  /// No description provided for @nutritionalInformationPerServing.
  ///
  /// In en, this message translates to:
  /// **'Nutritional Information (per serving)'**
  String get nutritionalInformationPerServing;

  /// No description provided for @vitamins.
  ///
  /// In en, this message translates to:
  /// **'Vitamins'**
  String get vitamins;

  /// No description provided for @minerals.
  ///
  /// In en, this message translates to:
  /// **'Minerals'**
  String get minerals;

  /// No description provided for @ingredient.
  ///
  /// In en, this message translates to:
  /// **'Ingredient {number}'**
  String ingredient(int number);

  /// No description provided for @instructionStep.
  ///
  /// In en, this message translates to:
  /// **'Instruction step {number}'**
  String instructionStep(int number);

  /// No description provided for @completeNutritionalInformation.
  ///
  /// In en, this message translates to:
  /// **'Complete Nutritional Information'**
  String get completeNutritionalInformation;

  /// No description provided for @essentialFats.
  ///
  /// In en, this message translates to:
  /// **'Essential Fats'**
  String get essentialFats;

  /// No description provided for @otherNutrients.
  ///
  /// In en, this message translates to:
  /// **'Other Nutrients'**
  String get otherNutrients;

  /// No description provided for @specializedNutrients.
  ///
  /// In en, this message translates to:
  /// **'Specialized Nutrients'**
  String get specializedNutrients;

  /// No description provided for @aminoAcids.
  ///
  /// In en, this message translates to:
  /// **'Amino Acids'**
  String get aminoAcids;

  /// No description provided for @criticalAlerts.
  ///
  /// In en, this message translates to:
  /// **'Critical Alerts'**
  String get criticalAlerts;

  /// No description provided for @highIntakeWarnings.
  ///
  /// In en, this message translates to:
  /// **'High Intake Warnings'**
  String get highIntakeWarnings;

  /// No description provided for @overallCoverage.
  ///
  /// In en, this message translates to:
  /// **'Overall Coverage'**
  String get overallCoverage;

  /// No description provided for @dailyMacrosSummary.
  ///
  /// In en, this message translates to:
  /// **'Daily Macros Summary'**
  String get dailyMacrosSummary;

  /// No description provided for @shareChart.
  ///
  /// In en, this message translates to:
  /// **'Share Chart'**
  String get shareChart;

  /// No description provided for @errorSharing.
  ///
  /// In en, this message translates to:
  /// **'Error sharing: {error}'**
  String errorSharing(String error);

  /// No description provided for @unknownFood.
  ///
  /// In en, this message translates to:
  /// **'Unknown Food'**
  String get unknownFood;

  /// No description provided for @nearTarget.
  ///
  /// In en, this message translates to:
  /// **'Near Target'**
  String get nearTarget;

  /// No description provided for @onTrack.
  ///
  /// In en, this message translates to:
  /// **'On Track'**
  String get onTrack;

  /// No description provided for @veryFilling.
  ///
  /// In en, this message translates to:
  /// **'Very Filling'**
  String get veryFilling;

  /// No description provided for @moderatelyFilling.
  ///
  /// In en, this message translates to:
  /// **'Moderately Filling'**
  String get moderatelyFilling;

  /// No description provided for @somewhatFilling.
  ///
  /// In en, this message translates to:
  /// **'Somewhat Filling'**
  String get somewhatFilling;

  /// No description provided for @notVeryFilling.
  ///
  /// In en, this message translates to:
  /// **'Not Very Filling'**
  String get notVeryFilling;

  /// No description provided for @satietyScore.
  ///
  /// In en, this message translates to:
  /// **'Satiety Score'**
  String get satietyScore;

  /// No description provided for @lowEnergyDensity.
  ///
  /// In en, this message translates to:
  /// **'Low Energy Density'**
  String get lowEnergyDensity;

  /// No description provided for @moderateEnergyDensity.
  ///
  /// In en, this message translates to:
  /// **'Moderate Energy Density'**
  String get moderateEnergyDensity;

  /// No description provided for @highEnergyDensity.
  ///
  /// In en, this message translates to:
  /// **'High Energy Density'**
  String get highEnergyDensity;

  /// No description provided for @veryHighEnergyDensity.
  ///
  /// In en, this message translates to:
  /// **'Very High Energy Density'**
  String get veryHighEnergyDensity;

  /// No description provided for @quickFacts.
  ///
  /// In en, this message translates to:
  /// **'Quick Facts'**
  String get quickFacts;

  /// No description provided for @energyDensity.
  ///
  /// In en, this message translates to:
  /// **'Energy Density'**
  String get energyDensity;

  /// No description provided for @netCarbs.
  ///
  /// In en, this message translates to:
  /// **'Net Carbs'**
  String get netCarbs;

  /// No description provided for @completeYourMeal.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Meal'**
  String get completeYourMeal;

  /// No description provided for @preparationTips.
  ///
  /// In en, this message translates to:
  /// **'Preparation Tips'**
  String get preparationTips;

  /// No description provided for @quickComparison.
  ///
  /// In en, this message translates to:
  /// **'Quick Comparison'**
  String get quickComparison;

  /// No description provided for @thisFood.
  ///
  /// In en, this message translates to:
  /// **'This Food'**
  String get thisFood;

  /// No description provided for @whyThisWorks.
  ///
  /// In en, this message translates to:
  /// **'Why This Works'**
  String get whyThisWorks;

  /// No description provided for @additionalInformation.
  ///
  /// In en, this message translates to:
  /// **'Additional Information'**
  String get additionalInformation;

  /// No description provided for @waterContent.
  ///
  /// In en, this message translates to:
  /// **'Water Content'**
  String get waterContent;

  /// No description provided for @sodium.
  ///
  /// In en, this message translates to:
  /// **'Sodium'**
  String get sodium;

  /// No description provided for @transFat.
  ///
  /// In en, this message translates to:
  /// **'Trans Fat'**
  String get transFat;

  /// No description provided for @monounsaturatedFat.
  ///
  /// In en, this message translates to:
  /// **'Monounsaturated Fat'**
  String get monounsaturatedFat;

  /// No description provided for @polyunsaturatedFat.
  ///
  /// In en, this message translates to:
  /// **'Polyunsaturated Fat'**
  String get polyunsaturatedFat;

  /// No description provided for @extraDetails.
  ///
  /// In en, this message translates to:
  /// **'Extra Details'**
  String get extraDetails;

  /// No description provided for @consumptionHistory.
  ///
  /// In en, this message translates to:
  /// **'Consumption History'**
  String get consumptionHistory;

  /// No description provided for @totalTimes.
  ///
  /// In en, this message translates to:
  /// **'Total times: {count}'**
  String totalTimes(int count);

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month: {count}'**
  String thisMonth(int count);

  /// No description provided for @healthierAlternatives.
  ///
  /// In en, this message translates to:
  /// **'Healthier Alternatives'**
  String get healthierAlternatives;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @avoidAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Avoid Afternoon'**
  String get avoidAfternoon;

  /// No description provided for @snackTime.
  ///
  /// In en, this message translates to:
  /// **'Snack Time'**
  String get snackTime;

  /// No description provided for @pandaAIAdvice.
  ///
  /// In en, this message translates to:
  /// **'Panda AI Advice'**
  String get pandaAIAdvice;

  /// No description provided for @flowSmartChef.
  ///
  /// In en, this message translates to:
  /// **'Flow Smart Chef'**
  String get flowSmartChef;

  /// No description provided for @noPerfectMatches.
  ///
  /// In en, this message translates to:
  /// **'No perfect matches found using strict health filters.'**
  String get noPerfectMatches;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get gotIt;

  /// No description provided for @thisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get thisActionCannotBeUndone;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get noCommentsYet;

  /// No description provided for @beFirstToComment.
  ///
  /// In en, this message translates to:
  /// **'Be the first to comment!'**
  String get beFirstToComment;

  /// No description provided for @addAComment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get addAComment;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @photoPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Photo permission required'**
  String get photoPermissionRequired;

  /// No description provided for @pleaseAddCaptionOrImage.
  ///
  /// In en, this message translates to:
  /// **'Please add a caption or image'**
  String get pleaseAddCaptionOrImage;

  /// No description provided for @postCreated.
  ///
  /// In en, this message translates to:
  /// **'Post created! 🎉'**
  String get postCreated;

  /// No description provided for @createPost.
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPost;

  /// No description provided for @whatsOnYourMind.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get whatsOnYourMind;

  /// No description provided for @backgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background Color:'**
  String get backgroundColor;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @mealPost.
  ///
  /// In en, this message translates to:
  /// **'Meal Post'**
  String get mealPost;

  /// No description provided for @workoutPost.
  ///
  /// In en, this message translates to:
  /// **'Workout Post'**
  String get workoutPost;

  /// No description provided for @photoPost.
  ///
  /// In en, this message translates to:
  /// **'Photo Post'**
  String get photoPost;

  /// No description provided for @textPost.
  ///
  /// In en, this message translates to:
  /// **'Text Post'**
  String get textPost;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'username'**
  String get username;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @tellUsAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself...'**
  String get tellUsAboutYourself;

  /// No description provided for @displayNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Display name is required'**
  String get displayNameRequired;

  /// No description provided for @searchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search users...'**
  String get searchUsers;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No description provided for @errorLoadingChats.
  ///
  /// In en, this message translates to:
  /// **'Error loading chats: {error}'**
  String errorLoadingChats(String error);

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get messageHint;

  /// No description provided for @searchForUsersToMessage.
  ///
  /// In en, this message translates to:
  /// **'Search for users to message'**
  String get searchForUsersToMessage;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @searchFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Search: {query}'**
  String searchFilterLabel(Object query);

  /// No description provided for @tagFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Tag: {tag}'**
  String tagFilterLabel(Object tag);

  /// No description provided for @errorLoadingComments.
  ///
  /// In en, this message translates to:
  /// **'Error loading comments: {error}'**
  String errorLoadingComments(Object error);

  /// No description provided for @beTheFirstToComment.
  ///
  /// In en, this message translates to:
  /// **'Be the first to comment!'**
  String get beTheFirstToComment;

  /// No description provided for @coinsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Coins'**
  String coinsCount(Object count);

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get message;

  /// No description provided for @errorDeletingPost.
  ///
  /// In en, this message translates to:
  /// **'Error deleting post: {error}'**
  String errorDeletingPost(String error);

  /// No description provided for @workoutScheduled.
  ///
  /// In en, this message translates to:
  /// **'Workout Scheduled'**
  String get workoutScheduled;

  /// No description provided for @workoutScheduledForDate.
  ///
  /// In en, this message translates to:
  /// **'You have a workout scheduled for {date}.'**
  String workoutScheduledForDate(String date);

  /// No description provided for @workoutScheduledForDateAtTime.
  ///
  /// In en, this message translates to:
  /// **'You have a workout scheduled for {date} at {time}.'**
  String workoutScheduledForDateAtTime(String date, String time);

  /// No description provided for @welcomeToFlow.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Flow!'**
  String get welcomeToFlow;

  /// No description provided for @startTrackingGoals.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your nutrition and workouts to achieve your goals.'**
  String get startTrackingGoals;

  /// No description provided for @mentalHealth.
  ///
  /// In en, this message translates to:
  /// **'Mental Health'**
  String get mentalHealth;

  /// No description provided for @moreEnergy.
  ///
  /// In en, this message translates to:
  /// **'More Energy'**
  String get moreEnergy;

  /// No description provided for @betterSleep.
  ///
  /// In en, this message translates to:
  /// **'Better Sleep'**
  String get betterSleep;

  /// No description provided for @reduceStress.
  ///
  /// In en, this message translates to:
  /// **'Reduce Stress'**
  String get reduceStress;

  /// No description provided for @boostImmunity.
  ///
  /// In en, this message translates to:
  /// **'Boost Immunity'**
  String get boostImmunity;

  /// No description provided for @improveDigestion.
  ///
  /// In en, this message translates to:
  /// **'Improve Digestion'**
  String get improveDigestion;

  /// No description provided for @yourProgress.
  ///
  /// In en, this message translates to:
  /// **'Your Progress'**
  String get yourProgress;

  /// No description provided for @coinRewards.
  ///
  /// In en, this message translates to:
  /// **'Coin Rewards'**
  String get coinRewards;

  /// No description provided for @earnFlowCoins.
  ///
  /// In en, this message translates to:
  /// **'Earn Flow Coins and unlock new features in the marketplace.'**
  String get earnFlowCoins;

  /// No description provided for @manageDesigns.
  ///
  /// In en, this message translates to:
  /// **'Manage Designs'**
  String get manageDesigns;

  /// No description provided for @newPlan.
  ///
  /// In en, this message translates to:
  /// **'New Plan +'**
  String get newPlan;

  /// No description provided for @notEnoughFlowCoins.
  ///
  /// In en, this message translates to:
  /// **'Not enough Flow Coins! 🪙'**
  String get notEnoughFlowCoins;

  /// No description provided for @daysAvg.
  ///
  /// In en, this message translates to:
  /// **'28 days avg'**
  String get daysAvg;

  /// No description provided for @dailyExercise.
  ///
  /// In en, this message translates to:
  /// **'Daily Exercise'**
  String get dailyExercise;

  /// No description provided for @daysUntilNext.
  ///
  /// In en, this message translates to:
  /// **'{days} days until next'**
  String daysUntilNext(int days);

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @fertile.
  ///
  /// In en, this message translates to:
  /// **'Fertile'**
  String get fertile;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @nutritionRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Recommendations'**
  String get nutritionRecommendations;

  /// No description provided for @foodsToFocusOn.
  ///
  /// In en, this message translates to:
  /// **'Foods to focus on during {phase} phase:'**
  String foodsToFocusOn(String phase);

  /// No description provided for @micronutrientInsight.
  ///
  /// In en, this message translates to:
  /// **'Micronutrient Insight'**
  String get micronutrientInsight;

  /// No description provided for @yourBodyNeeds.
  ///
  /// In en, this message translates to:
  /// **'Your body needs specific nutrients during {phase} phase:'**
  String yourBodyNeeds(String phase);

  /// No description provided for @cycleTrends.
  ///
  /// In en, this message translates to:
  /// **'Cycle Trends'**
  String get cycleTrends;

  /// No description provided for @avgLength.
  ///
  /// In en, this message translates to:
  /// **'Avg Length'**
  String get avgLength;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String days(int count);

  /// No description provided for @regularity.
  ///
  /// In en, this message translates to:
  /// **'Regularity'**
  String get regularity;

  /// No description provided for @basedOnLast12Months.
  ///
  /// In en, this message translates to:
  /// **'Based on last 12 months.'**
  String get basedOnLast12Months;

  /// No description provided for @dailyWellnessScore.
  ///
  /// In en, this message translates to:
  /// **'Daily Wellness Score'**
  String get dailyWellnessScore;

  /// No description provided for @basedOnPhase.
  ///
  /// In en, this message translates to:
  /// **'Based on phase.'**
  String get basedOnPhase;

  /// No description provided for @hormoneBalance.
  ///
  /// In en, this message translates to:
  /// **'Hormone Balance'**
  String get hormoneBalance;

  /// No description provided for @estrogen.
  ///
  /// In en, this message translates to:
  /// **'Estrogen'**
  String get estrogen;

  /// No description provided for @progesterone.
  ///
  /// In en, this message translates to:
  /// **'Progesterone'**
  String get progesterone;

  /// No description provided for @dayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day {n}'**
  String dayLabel(Object n);

  /// No description provided for @timelineStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get timelineStart;

  /// No description provided for @timelineFertile.
  ///
  /// In en, this message translates to:
  /// **'Fertile'**
  String get timelineFertile;

  /// No description provided for @timelineOvulation.
  ///
  /// In en, this message translates to:
  /// **'Ovulation'**
  String get timelineOvulation;

  /// No description provided for @timelineEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get timelineEnd;

  /// No description provided for @phasePhase.
  ///
  /// In en, this message translates to:
  /// **'{phase} Phase'**
  String phasePhase(Object phase);

  /// No description provided for @foodsToFocusOnPhase.
  ///
  /// In en, this message translates to:
  /// **'Foods to focus on during {phase} phase:'**
  String foodsToFocusOnPhase(Object phase);

  /// No description provided for @yourBodyNeedsPhase.
  ///
  /// In en, this message translates to:
  /// **'Your body needs specific nutrients during {phase} phase:'**
  String yourBodyNeedsPhase(Object phase);

  /// No description provided for @day1.
  ///
  /// In en, this message translates to:
  /// **'Day 1'**
  String get day1;

  /// No description provided for @day14.
  ///
  /// In en, this message translates to:
  /// **'Day 14'**
  String get day14;

  /// No description provided for @day28.
  ///
  /// In en, this message translates to:
  /// **'Day 28'**
  String get day28;

  /// No description provided for @menstruationTrackerSetup.
  ///
  /// In en, this message translates to:
  /// **'Menstruation Tracker Setup'**
  String get menstruationTrackerSetup;

  /// No description provided for @menstruationTrackerActivated.
  ///
  /// In en, this message translates to:
  /// **'Menstruation Tracker activated! 🩸'**
  String get menstruationTrackerActivated;

  /// No description provided for @errorSavingData.
  ///
  /// In en, this message translates to:
  /// **'Error saving data: {error}'**
  String errorSavingData(String error);

  /// No description provided for @noDataLoggedToday.
  ///
  /// In en, this message translates to:
  /// **'No data logged today yet.'**
  String get noDataLoggedToday;

  /// No description provided for @createWithAI.
  ///
  /// In en, this message translates to:
  /// **'Create with AI'**
  String get createWithAI;

  /// No description provided for @creatingFoodWithAI.
  ///
  /// In en, this message translates to:
  /// **'Creating food with AI...'**
  String get creatingFoodWithAI;

  /// No description provided for @myFoods.
  ///
  /// In en, this message translates to:
  /// **'My Foods'**
  String get myFoods;

  /// No description provided for @generalFoods.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get generalFoods;

  /// No description provided for @allFoods.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allFoods;

  /// No description provided for @foodCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Food created successfully!'**
  String get foodCreatedSuccessfully;

  /// No description provided for @myFood.
  ///
  /// In en, this message translates to:
  /// **'My Food'**
  String get myFood;

  /// No description provided for @dailyJournal.
  ///
  /// In en, this message translates to:
  /// **'Daily Journal'**
  String get dailyJournal;

  /// No description provided for @startRecording.
  ///
  /// In en, this message translates to:
  /// **'Start Recording'**
  String get startRecording;

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop Recording'**
  String get stopRecording;

  /// No description provided for @transcribe.
  ///
  /// In en, this message translates to:
  /// **'Transcribe'**
  String get transcribe;

  /// No description provided for @journalEntry.
  ///
  /// In en, this message translates to:
  /// **'Journal Entry'**
  String get journalEntry;

  /// No description provided for @journalEntryHint.
  ///
  /// In en, this message translates to:
  /// **'Tell me about your day... What did you eat? What workouts did you do? How much water did you drink?'**
  String get journalEntryHint;

  /// No description provided for @processAndSave.
  ///
  /// In en, this message translates to:
  /// **'Process & Save'**
  String get processAndSave;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How It Works'**
  String get howItWorks;

  /// No description provided for @journalHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'Record your voice or type your daily activities. AI will automatically extract workouts, meals, and water intake, then save everything to your log.'**
  String get journalHowItWorks;

  /// No description provided for @noAudioFile.
  ///
  /// In en, this message translates to:
  /// **'No audio file found'**
  String get noAudioFile;

  /// No description provided for @pleaseEnterText.
  ///
  /// In en, this message translates to:
  /// **'Please enter some text'**
  String get pleaseEnterText;

  /// No description provided for @journalSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Journal saved successfully! All activities have been logged.'**
  String get journalSavedSuccessfully;

  /// No description provided for @processingJournal.
  ///
  /// In en, this message translates to:
  /// **'Processing your journal entry... This may take a few minutes. You\'ll be notified when it\'s complete.'**
  String get processingJournal;

  /// No description provided for @areasToImprove.
  ///
  /// In en, this message translates to:
  /// **'Areas to Improve'**
  String get areasToImprove;

  /// No description provided for @areasToImproveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What areas would you like to focus on? (Select multiple)'**
  String get areasToImproveSubtitle;

  /// No description provided for @dietTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Do you follow any specific diet? (Optional)'**
  String get dietTypeSubtitle;

  /// No description provided for @allergens.
  ///
  /// In en, this message translates to:
  /// **'Allergens'**
  String get allergens;

  /// No description provided for @allergensSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select any food allergies you have (Optional)'**
  String get allergensSubtitle;

  /// No description provided for @foodPreferences.
  ///
  /// In en, this message translates to:
  /// **'Food Preferences'**
  String get foodPreferences;

  /// No description provided for @foodPreferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What describes your eating habits? (Optional)'**
  String get foodPreferencesSubtitle;

  /// No description provided for @cookingFrequency.
  ///
  /// In en, this message translates to:
  /// **'Cooking Frequency'**
  String get cookingFrequency;

  /// No description provided for @cookingFrequencySubtitle.
  ///
  /// In en, this message translates to:
  /// **'How often do you cook? (Optional)'**
  String get cookingFrequencySubtitle;

  /// No description provided for @waterIntake.
  ///
  /// In en, this message translates to:
  /// **'Water Intake'**
  String get waterIntake;

  /// No description provided for @waterIntakeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How much water do you drink daily? (Optional)'**
  String get waterIntakeSubtitle;

  /// No description provided for @sleepSchedule.
  ///
  /// In en, this message translates to:
  /// **'Sleep Schedule'**
  String get sleepSchedule;

  /// No description provided for @sleepScheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your typical sleep schedule? (Optional)'**
  String get sleepScheduleSubtitle;

  /// No description provided for @workoutTimePreference.
  ///
  /// In en, this message translates to:
  /// **'Workout Time Preference'**
  String get workoutTimePreference;

  /// No description provided for @workoutTimePreferenceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When do you prefer to exercise? (Optional)'**
  String get workoutTimePreferenceSubtitle;

  /// No description provided for @healthConditions.
  ///
  /// In en, this message translates to:
  /// **'Health Conditions'**
  String get healthConditions;

  /// No description provided for @healthConditionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Any health conditions we should know about? (Optional)'**
  String get healthConditionsSubtitle;

  /// No description provided for @analyzingInfo.
  ///
  /// In en, this message translates to:
  /// **'Panda is analyzing your info'**
  String get analyzingInfo;

  /// No description provided for @dietsAndPrograms.
  ///
  /// In en, this message translates to:
  /// **'Diets and Programs'**
  String get dietsAndPrograms;

  /// No description provided for @diets.
  ///
  /// In en, this message translates to:
  /// **'Diets'**
  String get diets;

  /// No description provided for @programs.
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get programs;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @activateDietOrProgram.
  ///
  /// In en, this message translates to:
  /// **'Activate a diet or program to get started'**
  String get activateDietOrProgram;

  /// No description provided for @dietActivated.
  ///
  /// In en, this message translates to:
  /// **'Diet activated successfully!'**
  String get dietActivated;

  /// No description provided for @programActivated.
  ///
  /// In en, this message translates to:
  /// **'Program activated successfully!'**
  String get programActivated;

  /// No description provided for @dietDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Diet deactivated'**
  String get dietDeactivated;

  /// No description provided for @programDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Program deactivated'**
  String get programDeactivated;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @deactivateDietConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to deactivate this diet? Your macro targets will be reset.'**
  String get deactivateDietConfirm;

  /// No description provided for @deactivateProgramConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to deactivate this program?'**
  String get deactivateProgramConfirm;

  /// No description provided for @compliance.
  ///
  /// In en, this message translates to:
  /// **'Compliance'**
  String get compliance;

  /// No description provided for @week.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get week;

  /// No description provided for @complete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// No description provided for @weeks.
  ///
  /// In en, this message translates to:
  /// **'weeks'**
  String get weeks;

  /// No description provided for @daysPerWeek.
  ///
  /// In en, this message translates to:
  /// **'days/week'**
  String get daysPerWeek;

  /// No description provided for @keyNutrients.
  ///
  /// In en, this message translates to:
  /// **'Key Nutrients'**
  String get keyNutrients;

  /// No description provided for @specialConsiderations.
  ///
  /// In en, this message translates to:
  /// **'Special Considerations'**
  String get specialConsiderations;

  /// No description provided for @recommendedSupplements.
  ///
  /// In en, this message translates to:
  /// **'Recommended Supplements'**
  String get recommendedSupplements;

  /// No description provided for @sleepTracker.
  ///
  /// In en, this message translates to:
  /// **'Sleep Tracker'**
  String get sleepTracker;

  /// No description provided for @moodTracker.
  ///
  /// In en, this message translates to:
  /// **'Mood Tracker'**
  String get moodTracker;

  /// No description provided for @trackYourSleep.
  ///
  /// In en, this message translates to:
  /// **'Track your sleep patterns'**
  String get trackYourSleep;

  /// No description provided for @trackYourMood.
  ///
  /// In en, this message translates to:
  /// **'Track your daily mood'**
  String get trackYourMood;

  /// No description provided for @noSleepData.
  ///
  /// In en, this message translates to:
  /// **'No sleep data yet'**
  String get noSleepData;

  /// No description provided for @startLoggingSleep.
  ///
  /// In en, this message translates to:
  /// **'Start logging your sleep to see insights'**
  String get startLoggingSleep;

  /// No description provided for @sleepTrends.
  ///
  /// In en, this message translates to:
  /// **'Sleep Trends'**
  String get sleepTrends;

  /// No description provided for @moodTrends.
  ///
  /// In en, this message translates to:
  /// **'Mood Trends'**
  String get moodTrends;

  /// No description provided for @logYourMoodToday.
  ///
  /// In en, this message translates to:
  /// **'Log your mood today to track patterns'**
  String get logYourMoodToday;

  /// No description provided for @recentLogs.
  ///
  /// In en, this message translates to:
  /// **'Recent Logs'**
  String get recentLogs;

  /// No description provided for @advancedAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Advanced Analytics'**
  String get advancedAnalytics;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get generateReport;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// No description provided for @noAnalyticsData.
  ///
  /// In en, this message translates to:
  /// **'No Analytics Data'**
  String get noAnalyticsData;

  /// No description provided for @generateAnalyticsReport.
  ///
  /// In en, this message translates to:
  /// **'Generate your first analytics report to get AI-powered insights'**
  String get generateAnalyticsReport;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @trends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get trends;

  /// No description provided for @recommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendations;

  /// No description provided for @previousReports.
  ///
  /// In en, this message translates to:
  /// **'Previous Reports'**
  String get previousReports;

  /// No description provided for @aiPoweredInsights.
  ///
  /// In en, this message translates to:
  /// **'AI-powered insights & recommendations'**
  String get aiPoweredInsights;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'ro'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'ro':
      return AppLocalizationsRo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
