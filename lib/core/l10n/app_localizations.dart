import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('en'),
    Locale('es'),
  ];

  /// App name.
  ///
  /// In en, this message translates to:
  /// **'Quadrapp'**
  String get common_appName;

  /// Accessible label of a back button.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// No description provided for @gallery_title.
  ///
  /// In en, this message translates to:
  /// **'Design system'**
  String get gallery_title;

  /// Sample card.
  ///
  /// In en, this message translates to:
  /// **'Low elevation'**
  String get gallery_cardLow;

  /// Sample card.
  ///
  /// In en, this message translates to:
  /// **'High elevation'**
  String get gallery_cardHigh;

  /// Sample pressable card.
  ///
  /// In en, this message translates to:
  /// **'Tap me: the card shrinks to 0.98'**
  String get gallery_cardTap;

  /// Sample brand hero card.
  ///
  /// In en, this message translates to:
  /// **'Hero surface'**
  String get gallery_heroTitle;

  /// Under the big number of a hero ring.
  ///
  /// In en, this message translates to:
  /// **'free'**
  String get gallery_heroFree;

  /// Live badge, connected.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get gallery_liveLive;

  /// Live badge, reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get gallery_liveReconnecting;

  /// Live badge, offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get gallery_liveOffline;

  /// Launches the sample bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Open bottom sheet'**
  String get gallery_openSheet;

  /// Title of the sample bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'New item'**
  String get gallery_sheetTitle;

  /// Body of the sample bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'The body scrolls; the primary action stays pinned at the bottom, even with the keyboard open.'**
  String get gallery_sheetBody;

  /// Primary action of the sample sheet.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get gallery_sheetAction;

  /// Accessible label of the sheet close button.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get gallery_sheetClose;

  /// Launches the sample confirm dialog.
  ///
  /// In en, this message translates to:
  /// **'Open confirm dialog'**
  String get gallery_openConfirm;

  /// Title of the sample confirm dialog.
  ///
  /// In en, this message translates to:
  /// **'Remove device?'**
  String get gallery_confirmTitle;

  /// The object named by the sample dialog.
  ///
  /// In en, this message translates to:
  /// **'SENS-A-18 · Space A-18'**
  String get gallery_confirmSubject;

  /// Body of the sample dialog.
  ///
  /// In en, this message translates to:
  /// **'It will stop sending events. This can\'t be undone.'**
  String get gallery_confirmMessage;

  /// Destructive action of the sample dialog.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get gallery_confirmAction;

  /// Launches the sample snackbar.
  ///
  /// In en, this message translates to:
  /// **'Show snackbar with Undo'**
  String get gallery_openSnack;

  /// Message of the sample snackbar.
  ///
  /// In en, this message translates to:
  /// **'Alert saved'**
  String get gallery_snackMessage;

  /// Undo action of the sample snackbar.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get gallery_snackUndo;

  /// No description provided for @gallery_open.
  ///
  /// In en, this message translates to:
  /// **'Open design system gallery'**
  String get gallery_open;

  /// No description provided for @gallery_darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get gallery_darkMode;

  /// No description provided for @gallery_stateLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get gallery_stateLoading;

  /// No description provided for @gallery_stateEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get gallery_stateEmpty;

  /// No description provided for @gallery_stateError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get gallery_stateError;

  /// No description provided for @gallery_statePartial.
  ///
  /// In en, this message translates to:
  /// **'Partial or out of date'**
  String get gallery_statePartial;

  /// No description provided for @gallery_stateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get gallery_stateSuccess;

  /// No description provided for @gallery_stateDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get gallery_stateDisabled;

  /// No description provided for @gallery_stateFilled.
  ///
  /// In en, this message translates to:
  /// **'Filled'**
  String get gallery_stateFilled;

  /// No description provided for @gallery_buttonPrimary.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get gallery_buttonPrimary;

  /// No description provided for @gallery_buttonTonal.
  ///
  /// In en, this message translates to:
  /// **'Save preferences'**
  String get gallery_buttonTonal;

  /// No description provided for @gallery_buttonText.
  ///
  /// In en, this message translates to:
  /// **'Change my arrival time'**
  String get gallery_buttonText;

  /// No description provided for @gallery_buttonDestructive.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get gallery_buttonDestructive;

  /// No description provided for @gallery_fieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Institutional email'**
  String get gallery_fieldLabel;

  /// No description provided for @gallery_fieldHint.
  ///
  /// In en, this message translates to:
  /// **'name@university.edu'**
  String get gallery_fieldHint;

  /// No description provided for @gallery_fieldHelper.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a one-time code.'**
  String get gallery_fieldHelper;

  /// No description provided for @gallery_fieldError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid institutional email.'**
  String get gallery_fieldError;

  /// No description provided for @gallery_otpLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code, 6 digits'**
  String get gallery_otpLabel;

  /// No description provided for @gallery_otpError.
  ///
  /// In en, this message translates to:
  /// **'The code expired or doesn\'t match. Request a new one.'**
  String get gallery_otpError;

  /// No description provided for @gallery_statusFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get gallery_statusFree;

  /// No description provided for @gallery_statusLimited.
  ///
  /// In en, this message translates to:
  /// **'Limited'**
  String get gallery_statusLimited;

  /// No description provided for @gallery_statusOccupied.
  ///
  /// In en, this message translates to:
  /// **'Occupied'**
  String get gallery_statusOccupied;

  /// No description provided for @gallery_statusUnknown.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get gallery_statusUnknown;

  /// No description provided for @gallery_plateHeadline.
  ///
  /// In en, this message translates to:
  /// **'You arrive in {minutes} min'**
  String gallery_plateHeadline(int minutes);

  /// No description provided for @gallery_plateHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get gallery_plateHigh;

  /// No description provided for @gallery_plateLimited.
  ///
  /// In en, this message translates to:
  /// **'Limited'**
  String get gallery_plateLimited;

  /// No description provided for @gallery_plateLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get gallery_plateLow;

  /// No description provided for @gallery_plateDetail.
  ///
  /// In en, this message translates to:
  /// **'{percent}% chance of finding a space'**
  String gallery_plateDetail(int percent);

  /// No description provided for @gallery_plateFootnote.
  ///
  /// In en, this message translates to:
  /// **'{confidence} · {time}'**
  String gallery_plateFootnote(String confidence, String time);

  /// No description provided for @gallery_confidenceHigh.
  ///
  /// In en, this message translates to:
  /// **'High confidence'**
  String get gallery_confidenceHigh;

  /// No description provided for @gallery_confidenceMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium confidence'**
  String get gallery_confidenceMedium;

  /// No description provided for @gallery_confidenceLow.
  ///
  /// In en, this message translates to:
  /// **'Low confidence'**
  String get gallery_confidenceLow;

  /// No description provided for @gallery_confidenceLowNote.
  ///
  /// In en, this message translates to:
  /// **'Estimate based on limited data'**
  String get gallery_confidenceLowNote;

  /// No description provided for @gallery_freshnessFresh.
  ///
  /// In en, this message translates to:
  /// **'Updated {seconds} s ago'**
  String gallery_freshnessFresh(int seconds);

  /// No description provided for @gallery_freshnessStale.
  ///
  /// In en, this message translates to:
  /// **'No new data since {time}'**
  String gallery_freshnessStale(String time);

  /// No description provided for @gallery_horizonLabel.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String gallery_horizonLabel(int minutes);

  /// No description provided for @gallery_horizonValue.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String gallery_horizonValue(int percent);

  /// No description provided for @gallery_horizonSemantic.
  ///
  /// In en, this message translates to:
  /// **'In {minutes} minutes: {percent}% occupied'**
  String gallery_horizonSemantic(int minutes, int percent);

  /// No description provided for @gallery_horizonMissingSemantic.
  ///
  /// In en, this message translates to:
  /// **'In {minutes} minutes: no forecast'**
  String gallery_horizonMissingSemantic(int minutes);

  /// No description provided for @gallery_horizonExpiredSemantic.
  ///
  /// In en, this message translates to:
  /// **'In {minutes} minutes: forecast expired'**
  String gallery_horizonExpiredSemantic(int minutes);

  /// No description provided for @gallery_horizonSaturation.
  ///
  /// In en, this message translates to:
  /// **'Fills up at {time}'**
  String gallery_horizonSaturation(String time);

  /// No description provided for @gallery_mapSummary.
  ///
  /// In en, this message translates to:
  /// **'Parking map: {free} free, {occupied} occupied, {unknown} with no data'**
  String gallery_mapSummary(int free, int occupied, int unknown);

  /// No description provided for @gallery_zoneName.
  ///
  /// In en, this message translates to:
  /// **'Zone {name}'**
  String gallery_zoneName(String name);

  /// No description provided for @gallery_zoneFree.
  ///
  /// In en, this message translates to:
  /// **'{count} free'**
  String gallery_zoneFree(int count);

  /// No description provided for @gallery_zoneOccupied.
  ///
  /// In en, this message translates to:
  /// **'{count} occupied'**
  String gallery_zoneOccupied(int count);

  /// No description provided for @gallery_zoneUnknown.
  ///
  /// In en, this message translates to:
  /// **'{count} no data'**
  String gallery_zoneUnknown(int count);

  /// No description provided for @gallery_zoneSemantic.
  ///
  /// In en, this message translates to:
  /// **'Zone {name}: {free} free, {occupied} occupied, {unknown} with no data'**
  String gallery_zoneSemantic(String name, int free, int occupied, int unknown);

  /// No description provided for @gallery_kpiLabel.
  ///
  /// In en, this message translates to:
  /// **'Free spaces'**
  String get gallery_kpiLabel;

  /// No description provided for @gallery_kpiCaption.
  ///
  /// In en, this message translates to:
  /// **'of {total}'**
  String gallery_kpiCaption(int total);

  /// No description provided for @gallery_kpiEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get gallery_kpiEmpty;

  /// No description provided for @gallery_kpiError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load'**
  String get gallery_kpiError;

  /// No description provided for @gallery_slotDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get gallery_slotDays;

  /// No description provided for @gallery_slotFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get gallery_slotFrom;

  /// No description provided for @gallery_slotTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get gallery_slotTo;

  /// No description provided for @gallery_slotPick.
  ///
  /// In en, this message translates to:
  /// **'Pick a time'**
  String get gallery_slotPick;

  /// No description provided for @gallery_slotError.
  ///
  /// In en, this message translates to:
  /// **'The end time must be after the start.'**
  String get gallery_slotError;

  /// No description provided for @gallery_dialogOpen.
  ///
  /// In en, this message translates to:
  /// **'Show confirmation dialog'**
  String get gallery_dialogOpen;

  /// No description provided for @gallery_dialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get gallery_dialogTitle;

  /// No description provided for @gallery_dialogMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need a new code to sign in again on this device.'**
  String get gallery_dialogMessage;

  /// No description provided for @gallery_dialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get gallery_dialogConfirm;

  /// No description provided for @gallery_dialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get gallery_dialogCancel;

  /// No description provided for @gallery_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No time slots yet'**
  String get gallery_emptyTitle;

  /// No description provided for @gallery_emptyMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'re not following any time slot yet. Pick the time you usually arrive and we\'ll let you know if the lot is expected to fill up.'**
  String get gallery_emptyMessage;

  /// No description provided for @gallery_emptyAction.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to this time slot'**
  String get gallery_emptyAction;

  /// No description provided for @gallery_errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load availability'**
  String get gallery_errorTitle;

  /// No description provided for @gallery_errorMessage.
  ///
  /// In en, this message translates to:
  /// **'There\'s no connection to the server. Check your network and try again.'**
  String get gallery_errorMessage;

  /// No description provided for @gallery_errorRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get gallery_errorRetry;

  /// No description provided for @gallery_bannerOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Showing the latest data we have, from {time}.'**
  String gallery_bannerOffline(String time);

  /// No description provided for @gallery_bannerStale.
  ///
  /// In en, this message translates to:
  /// **'No new data since {time}. What you see may be out of date.'**
  String gallery_bannerStale(String time);

  /// No description provided for @gallery_bannerError.
  ///
  /// In en, this message translates to:
  /// **'The code expired or doesn\'t match. Request a new one.'**
  String get gallery_bannerError;

  /// No description provided for @gallery_bannerInfo.
  ///
  /// In en, this message translates to:
  /// **'The lot layout was updated.'**
  String get gallery_bannerInfo;

  /// No description provided for @gallery_mapSimulate.
  ///
  /// In en, this message translates to:
  /// **'Simulate a space change'**
  String get gallery_mapSimulate;

  /// Accessible label of the skeleton shown while the saved session is read.
  ///
  /// In en, this message translates to:
  /// **'Checking your session…'**
  String get iam_restoring;

  /// Title of the email screen.
  ///
  /// In en, this message translates to:
  /// **'Plan your arrival at campus'**
  String get iam_loginTitle;

  /// One line under the title of the email screen: what happens next.
  ///
  /// In en, this message translates to:
  /// **'Check the estimated availability before you leave. No reservations or payments.'**
  String get iam_loginSubtitle;

  /// Label of the email field.
  ///
  /// In en, this message translates to:
  /// **'Institutional email'**
  String get iam_emailLabel;

  /// Hint of the email field.
  ///
  /// In en, this message translates to:
  /// **'name@university.edu'**
  String get iam_emailHint;

  /// Email field left empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your institutional email.'**
  String get iam_emailErrorEmpty;

  /// Email with an invalid format.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email, like name@university.edu.'**
  String get iam_emailErrorInvalid;

  /// Button that requests the one-time code.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get iam_sendCode;

  /// Accessible label of the button while the code is requested.
  ///
  /// In en, this message translates to:
  /// **'Sending code…'**
  String get iam_sendingCode;

  /// Disabled button while rate limited; time is a countdown like 0:45.
  ///
  /// In en, this message translates to:
  /// **'Continue in {time}'**
  String iam_sendCodeIn(String time);

  /// Shown on 429; the countdown is on the button.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. You can request another code when the countdown ends.'**
  String get iam_rateLimited;

  /// Server answered 403: no code was sent.
  ///
  /// In en, this message translates to:
  /// **'That email doesn\'t belong to an enabled institution.'**
  String get iam_errorForbidden;

  /// Server answered 400.
  ///
  /// In en, this message translates to:
  /// **'The email format isn\'t valid. Check it and try again.'**
  String get iam_errorEmailFormat;

  /// No network.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Check your connection and try again.'**
  String get iam_errorNetwork;

  /// Any other failure.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Try again in a moment.'**
  String get iam_errorGeneric;

  /// Action of a recoverable error.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get iam_retry;

  /// Notice on /login?reason=expired (US03).
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Sign in again to continue.'**
  String get iam_sessionExpired;

  /// Title of the code screen.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get iam_verifyTitle;

  /// Tells which email received the code.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}.'**
  String iam_verifySentTo(String email);

  /// Validity period of the code (US01 esc. 1).
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{The code is valid for 1 minute.} other{The code is valid for {minutes} minutes.}}'**
  String iam_verifyValidity(int minutes);

  /// Accessible label of the code field.
  ///
  /// In en, this message translates to:
  /// **'Verification code, 6 digits'**
  String get iam_otpLabel;

  /// Button that verifies the code.
  ///
  /// In en, this message translates to:
  /// **'Verify and sign in'**
  String get iam_verifyAction;

  /// Accessible label of the button while the code is verified.
  ///
  /// In en, this message translates to:
  /// **'Verifying…'**
  String get iam_verifying;

  /// Server answered 401 (wrong, expired or out of attempts).
  ///
  /// In en, this message translates to:
  /// **'The code expired or doesn\'t match. Request a new one.'**
  String get iam_errorCodeInvalid;

  /// The code is not 6 digits.
  ///
  /// In en, this message translates to:
  /// **'Enter all 6 digits.'**
  String get iam_errorCodeIncomplete;

  /// Asks for a new code.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get iam_resend;

  /// Disabled resend with a countdown like 0:30.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {time}'**
  String iam_resendIn(String time);

  /// While a new code is requested.
  ///
  /// In en, this message translates to:
  /// **'Sending a new code…'**
  String get iam_resending;

  /// After a successful resend.
  ///
  /// In en, this message translates to:
  /// **'We sent you a new code.'**
  String get iam_noticeResent;

  /// Resend failed by network.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send a new code: you\'re offline.'**
  String get iam_noticeResendNetwork;

  /// Resend failed by another cause.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send a new code. Try again in a moment.'**
  String get iam_noticeResendFailed;

  /// Bottom bar: the parking lots list.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// Bottom bar: the alert subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get nav_alerts;

  /// Bottom bar: account and preferences.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get nav_settings;

  /// Bottom bar (operations): the shift console.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get nav_shift;

  /// Bottom bar (operations): the parking lots.
  ///
  /// In en, this message translates to:
  /// **'Lots'**
  String get nav_lots;

  /// Bottom bar (operations): sensors and gateways.
  ///
  /// In en, this message translates to:
  /// **'Devices'**
  String get nav_devices;

  /// Placeholder title of the Shift tab.
  ///
  /// In en, this message translates to:
  /// **'Shift console coming soon'**
  String get ops_shiftSoonTitle;

  /// Placeholder message of the Shift tab.
  ///
  /// In en, this message translates to:
  /// **'Soon you\'ll see capacity, flow and the expected saturation of your lot.'**
  String get ops_shiftSoonMessage;

  /// Placeholder title of the Lots tab.
  ///
  /// In en, this message translates to:
  /// **'Lots overview coming soon'**
  String get ops_lotsSoonTitle;

  /// Placeholder message of the Lots tab.
  ///
  /// In en, this message translates to:
  /// **'Soon you\'ll see every lot with its occupancy and status.'**
  String get ops_lotsSoonMessage;

  /// Placeholder title of the Devices tab.
  ///
  /// In en, this message translates to:
  /// **'Devices coming soon'**
  String get ops_devicesSoonTitle;

  /// Placeholder message of the Devices tab.
  ///
  /// In en, this message translates to:
  /// **'Soon you\'ll see the health of every sensor and gateway.'**
  String get ops_devicesSoonMessage;

  /// Chip text when no campus is chosen yet.
  ///
  /// In en, this message translates to:
  /// **'Choose campus'**
  String get sede_choose;

  /// Accessible label of the campus chip.
  ///
  /// In en, this message translates to:
  /// **'Campus: {name}. Change campus'**
  String sede_chipLabel(String name);

  /// Title of the campus picker sheet.
  ///
  /// In en, this message translates to:
  /// **'Choose your campus'**
  String get sede_sheetTitle;

  /// One line under the lot picker title.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see the availability of the lot you choose.'**
  String get sede_sheetSubtitle;

  /// Accessible label of the picker close button.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get sede_close;

  /// Shown under a campus whose layout is not published.
  ///
  /// In en, this message translates to:
  /// **'No availability published yet'**
  String get sede_noLayout;

  /// Accessible suffix of the chosen campus.
  ///
  /// In en, this message translates to:
  /// **'Current campus'**
  String get sede_current;

  /// Title when no campus is chosen.
  ///
  /// In en, this message translates to:
  /// **'Which campus are you heading to?'**
  String get sede_promptTitle;

  /// Message when no campus is chosen.
  ///
  /// In en, this message translates to:
  /// **'Pick your campus to see its parking availability.'**
  String get sede_promptMessage;

  /// Title of the campus list error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the campuses'**
  String get sede_errorTitle;

  /// Bottom bar: the pavilions and levels of the chosen campus.
  ///
  /// In en, this message translates to:
  /// **'Zones'**
  String get nav_zones;

  /// Bottom bar: the forecast and arrival advice.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get nav_forecast;

  /// Top bar title of Home.
  ///
  /// In en, this message translates to:
  /// **'Your arrival'**
  String get title_arrival;

  /// Top bar title of the Zones tab.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get title_zones;

  /// Top bar title of the Forecast tab.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get title_forecast;

  /// Top bar title of the Alerts tab.
  ///
  /// In en, this message translates to:
  /// **'Alerts and preferences'**
  String get title_alerts;

  /// Top bar title of the account screen.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get title_account;

  /// Accessible label of the profile icon that opens the account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account_open;

  /// Helper under the email field.
  ///
  /// In en, this message translates to:
  /// **'We use your domain to confirm your community\'s access.'**
  String get iam_emailHelper;

  /// Privacy note on the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'When you ask for a forecast you only share your estimated minutes of arrival. Never your location.'**
  String get iam_privacyMinutes;

  /// Legal line of the sign-in screen; terms and privacy are links.
  ///
  /// In en, this message translates to:
  /// **'By continuing you accept the {terms} and the {privacy}.'**
  String iam_legalIntro(String terms, String privacy);

  /// Link text: the terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get iam_legalTerms;

  /// Link text: the privacy policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get iam_legalPrivacy;

  /// Heading of the code screen.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get iam_verifyHeading;

  /// Tip under the verify button.
  ///
  /// In en, this message translates to:
  /// **'If your connection drops, we\'ll keep your code so you can try again.'**
  String get iam_verifyOfflineTip;

  /// Title of the terms and privacy summary.
  ///
  /// In en, this message translates to:
  /// **'Terms and privacy'**
  String get legal_title;

  /// Intro of the terms and privacy summary.
  ///
  /// In en, this message translates to:
  /// **'A short summary of what Quadrapp does with your data. Quadrapp is free: there are no reservations, payments or tickets.'**
  String get legal_intro;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'What we receive'**
  String get legal_receiveTitle;

  /// Section body.
  ///
  /// In en, this message translates to:
  /// **'Your institutional email, to check that your institution allows you in and to send your one-time code. Your alert preferences and time slots. A device token, to send you the alerts you choose.'**
  String get legal_receiveBody;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'What we never receive'**
  String get legal_neverTitle;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'When you sign out'**
  String get legal_signOutTitle;

  /// Section body.
  ///
  /// In en, this message translates to:
  /// **'Quadrapp removes your session, your saved campus and the data it kept on this phone. Only your language stays.'**
  String get legal_signOutBody;

  /// Note at the end of the summary.
  ///
  /// In en, this message translates to:
  /// **'This summary doesn\'t replace the full Terms and Privacy Policy published on Quadrapp\'s website.'**
  String get legal_note;

  /// How a screen reader says the hidden email.
  ///
  /// In en, this message translates to:
  /// **'{first} followed by hidden characters, at {domain}'**
  String iam_maskedSpoken(String first, String domain);

  /// Accessibility hint of the legal line.
  ///
  /// In en, this message translates to:
  /// **'Opens a summary of the terms and privacy'**
  String get iam_legalOpen;

  /// Title of the arrival time sheet.
  ///
  /// In en, this message translates to:
  /// **'When do you arrive?'**
  String get eta_sheetTitle;

  /// Accessible label of the sheet close button.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get eta_close;

  /// Button: calculate the arrival time with the phone's location.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get eta_useLocation;

  /// Explanation shown before asking for the location permission.
  ///
  /// In en, this message translates to:
  /// **'We calculate the time on your phone. Quadrapp only receives the minutes, never your location.'**
  String get eta_locationBody;

  /// Location permission denied for good.
  ///
  /// In en, this message translates to:
  /// **'Location is blocked for Quadrapp. You can allow it in your phone\'s settings, or pick the time yourself.'**
  String get eta_locationBlocked;

  /// The location service is off.
  ///
  /// In en, this message translates to:
  /// **'Your phone\'s location is off. Turn it on, or pick the time yourself.'**
  String get eta_locationOff;

  /// The chosen campus has no coordinates.
  ///
  /// In en, this message translates to:
  /// **'This campus has no map position yet, so the time can\'t be estimated. Pick it yourself.'**
  String get eta_noPosition;

  /// Heading of the manual options.
  ///
  /// In en, this message translates to:
  /// **'Or pick the time yourself'**
  String get eta_manualTitle;

  /// Unit next to the big number of the manual arrival time.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get eta_minutesUnit;

  /// Hint under the manual arrival time stepper.
  ///
  /// In en, this message translates to:
  /// **'Adjusts in steps of 5 minutes.'**
  String get eta_stepHint;

  /// Quick option chip.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String eta_minutesChip(int minutes);

  /// Accessible text of a minutes value.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1{1 minute} other{{minutes} minutes}}'**
  String eta_minutesSpoken(int minutes);

  /// Accessible label of the minus button.
  ///
  /// In en, this message translates to:
  /// **'Less time'**
  String get eta_less;

  /// Accessible label of the plus button.
  ///
  /// In en, this message translates to:
  /// **'More time'**
  String get eta_more;

  /// Closes the arrival time sheet.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get eta_done;

  /// Caption under the arrival time when the driver chose it.
  ///
  /// In en, this message translates to:
  /// **'chosen by you'**
  String get eta_sourceManual;

  /// Accessible hint of the arrival time column.
  ///
  /// In en, this message translates to:
  /// **'Change arrival time'**
  String get eta_change;

  /// Time-of-day greeting at the top of Home. period is morning, afternoon or evening (Lima time).
  ///
  /// In en, this message translates to:
  /// **'{period, select, morning{Good morning} afternoon{Good afternoon} other{Good evening}}'**
  String home_greeting(String period);

  /// The greeting followed by the user's first name.
  ///
  /// In en, this message translates to:
  /// **'{greeting}, {name}'**
  String home_greetingNamed(String greeting, String name);

  /// The question Home answers.
  ///
  /// In en, this message translates to:
  /// **'Will I find a space when I arrive?'**
  String get home_question;

  /// Chip: the real-time connection is alive.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get home_liveOnline;

  /// Chip: the first real-time connection is being established.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get home_liveConnecting;

  /// Chip: the real-time connection dropped and is being retried.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get home_liveReconnecting;

  /// Chip: the data shown comes from the device cache.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get home_liveOffline;

  /// Arrival category HIGH.
  ///
  /// In en, this message translates to:
  /// **'Good availability'**
  String get home_categoryHigh;

  /// Arrival category LIMITED.
  ///
  /// In en, this message translates to:
  /// **'Limited availability'**
  String get home_categoryLimited;

  /// Arrival category LOW.
  ///
  /// In en, this message translates to:
  /// **'Low availability'**
  String get home_categoryLow;

  /// No arrival category could be shown.
  ///
  /// In en, this message translates to:
  /// **'No estimate'**
  String get home_categoryNone;

  /// Hero statement for a high chance.
  ///
  /// In en, this message translates to:
  /// **'Yes, you\'ll probably find a space.'**
  String get home_statementHigh;

  /// Hero statement for a limited chance.
  ///
  /// In en, this message translates to:
  /// **'You might find a space, but it\'s not certain.'**
  String get home_statementLimited;

  /// Hero statement for a low chance.
  ///
  /// In en, this message translates to:
  /// **'You\'re unlikely to find a space.'**
  String get home_statementLow;

  /// Hero statement when there is no arrival time yet.
  ///
  /// In en, this message translates to:
  /// **'Tell us when you arrive to estimate your availability.'**
  String get home_statementNeedsEta;

  /// Hero statement when the advice is unavailable.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t estimate your availability right now.'**
  String get home_statementUnavailable;

  /// Hero button that opens the arrival time sheet.
  ///
  /// In en, this message translates to:
  /// **'Set arrival time'**
  String get home_chooseEta;

  /// Hero column label (shown in capitals).
  ///
  /// In en, this message translates to:
  /// **'Arrive in'**
  String get home_statArrive;

  /// Hero column label (shown in capitals).
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get home_statNow;

  /// Hero column label (shown in capitals).
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get home_statConfidence;

  /// A number of minutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String home_minutes(int minutes);

  /// Free spaces right now.
  ///
  /// In en, this message translates to:
  /// **'{count} free'**
  String home_freeCount(int count);

  /// Under the free count: the capacity.
  ///
  /// In en, this message translates to:
  /// **'of {total} spaces'**
  String home_ofSpaces(int total);

  /// Capacity and the spaces without data.
  ///
  /// In en, this message translates to:
  /// **'of {total} spaces · {unknown} no data'**
  String home_ofSpacesUnknown(int total, int unknown);

  /// Confidence level HIGH.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get home_confidenceHigh;

  /// Confidence level MEDIUM.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get home_confidenceMedium;

  /// Confidence level LOW.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get home_confidenceLow;

  /// Age of the prediction, e.g. 'forecast 2 min ago'.
  ///
  /// In en, this message translates to:
  /// **'forecast {age}'**
  String home_forecastAge(String age);

  /// Warning for a low-confidence advice.
  ///
  /// In en, this message translates to:
  /// **'This estimate is based on limited information.'**
  String get home_lowConfidence;

  /// Next availability when the lot is full.
  ///
  /// In en, this message translates to:
  /// **'A space is expected to free up in {min}–{max} min.'**
  String home_nextFree(int min, int max);

  /// Next availability when there are no exits.
  ///
  /// In en, this message translates to:
  /// **'We can\'t estimate the wait: no exits were recorded recently.'**
  String get home_nextNone;

  /// Title of the horizons card.
  ///
  /// In en, this message translates to:
  /// **'How it may change'**
  String get home_changeTitle;

  /// Accessible label of a horizon tile.
  ///
  /// In en, this message translates to:
  /// **'In {minutes} min: {percent}%, {category}'**
  String home_horizonSpoken(int minutes, int percent, String category);

  /// Accessible label of a horizon tile without advice.
  ///
  /// In en, this message translates to:
  /// **'In {minutes} min: not available'**
  String home_horizonMissing(int minutes);

  /// Accessibility hint of a horizon tile.
  ///
  /// In en, this message translates to:
  /// **'Opens the forecast'**
  String get home_horizonsHint;

  /// Privacy line at the bottom of Home.
  ///
  /// In en, this message translates to:
  /// **'We share arrival minutes, never your location.'**
  String get home_privacyLine;

  /// Button on a campus without data.
  ///
  /// In en, this message translates to:
  /// **'Choose another campus'**
  String get home_pickAnother;

  /// Notice when the advice failed but the rest loaded.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your arrival estimate. Pull down to try again.'**
  String get home_partialAdvice;

  /// Notice when the occupancy failed but the rest loaded.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the current spaces. Pull down to try again.'**
  String get home_partialOccupancy;

  /// Notice when some horizons are missing.
  ///
  /// In en, this message translates to:
  /// **'Some forecasts aren\'t available right now.'**
  String get home_partialForecast;

  /// Accessible label of the skeleton while the lots load.
  ///
  /// In en, this message translates to:
  /// **'Loading parking lots…'**
  String get lots_loading;

  /// Title when the institution has no parking lots (US04).
  ///
  /// In en, this message translates to:
  /// **'No parking lots yet'**
  String get lots_emptyTitle;

  /// Informative message when there are no lots.
  ///
  /// In en, this message translates to:
  /// **'Your institution hasn\'t set up any parking lots yet. Pull down to check again.'**
  String get lots_emptyMessage;

  /// Title of the list error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load parking lots'**
  String get lots_errorTitle;

  /// List error caused by the network.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Check your connection and try again.'**
  String get lots_errorNetwork;

  /// List error with another cause.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our side. Try again in a moment.'**
  String get lots_errorGeneric;

  /// Retries loading the lots.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get lots_retry;

  /// Banner when the shown data comes from the device cache.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Showing the latest data we have.'**
  String get lots_offlineBanner;

  /// Age of the data, e.g. 'Updated 20 s ago'.
  ///
  /// In en, this message translates to:
  /// **'Updated {age}'**
  String lots_updatedAgo(String age);

  /// Relative time in seconds.
  ///
  /// In en, this message translates to:
  /// **'{count} s ago'**
  String time_agoSeconds(int count);

  /// Relative time in minutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String time_agoMinutes(int count);

  /// Relative time in hours.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String time_agoHours(int count);

  /// Warning inside a card whose data is stale (docs/05).
  ///
  /// In en, this message translates to:
  /// **'No new data since {time}. What you see may be out of date.'**
  String lots_staleSince(String time);

  /// A lot without a published layout is shown without availability (US04).
  ///
  /// In en, this message translates to:
  /// **'No current data'**
  String get lots_noCurrentData;

  /// Explains why there is no availability.
  ///
  /// In en, this message translates to:
  /// **'This lot has no published layout yet.'**
  String get lots_noCurrentDataHint;

  /// State of a parking space.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get space_free;

  /// State of a parking space.
  ///
  /// In en, this message translates to:
  /// **'Occupied'**
  String get space_occupied;

  /// State of a parking space whose sensor has no data.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get space_unknown;

  /// Honest note under the account card.
  ///
  /// In en, this message translates to:
  /// **'More settings, like alerts and language, arrive in a later update.'**
  String get settings_moreSoon;

  /// Label of the account role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get settings_role;

  /// Role DRIVER.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get settings_roleDriver;

  /// Role OPERATOR.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get settings_roleOperator;

  /// Role ADMIN.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get settings_roleAdmin;

  /// Screen reader summary of the account card.
  ///
  /// In en, this message translates to:
  /// **'Account: {email}, {institution}, role {role}'**
  String settings_accountSemantics(
    String email,
    String institution,
    String role,
  );

  /// Button that signs out.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut_action;

  /// Accessible label while signing out.
  ///
  /// In en, this message translates to:
  /// **'Signing out…'**
  String get signOut_signingOut;

  /// Confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOut_confirmTitle;

  /// Names the account that will be signed out.
  ///
  /// In en, this message translates to:
  /// **'You\'ll sign out of {email} on this device and will need a code to sign in again.'**
  String signOut_confirmMessage(String email);

  /// Dismisses the dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get signOut_cancel;

  /// Sign out failed unexpectedly.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t sign you out. Try again.'**
  String get signOut_error;

  /// Debug-only entry to the mock controls panel.
  ///
  /// In en, this message translates to:
  /// **'Open mock controls'**
  String get debug_open;

  /// Title of the debug-only panel.
  ///
  /// In en, this message translates to:
  /// **'Mock controls'**
  String get debug_title;

  /// Credentials the mock server accepts.
  ///
  /// In en, this message translates to:
  /// **'Test users: conductor@upc.edu.pe (driver) and administrador@upc.edu.pe (admin) · code 123456'**
  String get debug_credentials;

  /// Switch: every call fails as if offline.
  ///
  /// In en, this message translates to:
  /// **'No network'**
  String get debug_forceNetworkError;

  /// Help of the no-network switch.
  ///
  /// In en, this message translates to:
  /// **'Every call fails as if the phone were offline.'**
  String get debug_forceNetworkErrorHelp;

  /// Switch: the live socket drops.
  ///
  /// In en, this message translates to:
  /// **'Realtime outage'**
  String get debug_realtimeOutage;

  /// Help of the realtime outage switch.
  ///
  /// In en, this message translates to:
  /// **'The live connection drops (the status chip shows Reconnecting); REST calls keep working.'**
  String get debug_realtimeOutageHelp;

  /// Label of the simulated location permission picker.
  ///
  /// In en, this message translates to:
  /// **'Location permission'**
  String get debug_locationPermission;

  /// Location permission: granted.
  ///
  /// In en, this message translates to:
  /// **'Granted'**
  String get debug_locationGranted;

  /// Location permission: can still be asked.
  ///
  /// In en, this message translates to:
  /// **'Not granted yet'**
  String get debug_locationDenied;

  /// Location permission: only changeable in Settings.
  ///
  /// In en, this message translates to:
  /// **'Denied for good'**
  String get debug_locationDeniedForever;

  /// The phone's location service is off.
  ///
  /// In en, this message translates to:
  /// **'Location off'**
  String get debug_locationOff;

  /// Switch: the system dialog denies the location permission.
  ///
  /// In en, this message translates to:
  /// **'Deny the permission dialog'**
  String get debug_denyLocationPrompt;

  /// Help of the deny-prompt switch.
  ///
  /// In en, this message translates to:
  /// **'Asking for the permission fails: the first time it stays denied, the second time for good.'**
  String get debug_denyLocationPromptHelp;

  /// Switch for 401.
  ///
  /// In en, this message translates to:
  /// **'401 on protected calls'**
  String get debug_force401;

  /// Help of the 401 switch.
  ///
  /// In en, this message translates to:
  /// **'Protected calls answer 401 (access token rejected).'**
  String get debug_force401Help;

  /// Switch for 429.
  ///
  /// In en, this message translates to:
  /// **'429 on code requests'**
  String get debug_force429;

  /// Help of the 429 switch.
  ///
  /// In en, this message translates to:
  /// **'Requesting a code answers 429 with a 45 second wait.'**
  String get debug_force429Help;

  /// Switch: the refresh token is rejected.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get debug_sessionExpired;

  /// Help of the expired-session switch.
  ///
  /// In en, this message translates to:
  /// **'The refresh token is rejected (401): the session expires.'**
  String get debug_sessionExpiredHelp;

  /// Switch: console routes answer 403.
  ///
  /// In en, this message translates to:
  /// **'403 on console routes'**
  String get debug_forceConsole403;

  /// Help of the 403 console switch.
  ///
  /// In en, this message translates to:
  /// **'The console overview and the devices answer 403, as for a driver (TS17).'**
  String get debug_forceConsole403Help;

  /// Switch: the overview comes without the saturation.
  ///
  /// In en, this message translates to:
  /// **'Partial console overview'**
  String get debug_forceConsolePartial;

  /// Help of the partial console switch.
  ///
  /// In en, this message translates to:
  /// **'The overview answers 200 without the expected saturation (TS17 scenario 3).'**
  String get debug_forceConsolePartialHelp;

  /// Switch: registering a device fails.
  ///
  /// In en, this message translates to:
  /// **'Device registration fails'**
  String get debug_forceDeviceRegisterFailure;

  /// Help of the device registration switch.
  ///
  /// In en, this message translates to:
  /// **'Registering a device answers a server error (500).'**
  String get debug_forceDeviceRegisterFailureHelp;

  /// Section title.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get debug_actions;

  /// Runs the real refresh with the switches above.
  ///
  /// In en, this message translates to:
  /// **'Expire the session now'**
  String get debug_expireNow;

  /// Lists parking lots to see the effect of the switches.
  ///
  /// In en, this message translates to:
  /// **'Call a protected endpoint'**
  String get debug_probe;

  /// Refresh succeeded.
  ///
  /// In en, this message translates to:
  /// **'The session was renewed.'**
  String get debug_resultRefreshed;

  /// Protected call succeeded.
  ///
  /// In en, this message translates to:
  /// **'Protected call OK: {count} parking lots.'**
  String debug_resultOk(int count);

  /// Failure type name (debug only).
  ///
  /// In en, this message translates to:
  /// **'Failed: {type}'**
  String debug_resultFailure(String type);

  /// Reloads the mock seed: lots, spaces, subscriptions and preferences.
  ///
  /// In en, this message translates to:
  /// **'Reset test data'**
  String get debug_resetData;

  /// Shown after resetting the mock data.
  ///
  /// In en, this message translates to:
  /// **'Test data reset to the seed.'**
  String get debug_resultReset;

  /// Label of the result line.
  ///
  /// In en, this message translates to:
  /// **'Last result'**
  String get debug_resultLabel;

  /// Top bar action of Zones that opens the sort and filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Sort and filter'**
  String get zones_filterAction;

  /// Same action while a sort or filter is on.
  ///
  /// In en, this message translates to:
  /// **'Sort and filter, active'**
  String get zones_filterActionActive;

  /// Title of the sort and filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Sort and filter'**
  String get zones_filterTitle;

  /// Closes the sort and filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get zones_filterClose;

  /// Heading of the order options.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get zones_orderLabel;

  /// Order pavilions as the lot publishes them.
  ///
  /// In en, this message translates to:
  /// **'By pavilion'**
  String get zones_orderByName;

  /// Order pavilions by free spaces.
  ///
  /// In en, this message translates to:
  /// **'Most free spaces first'**
  String get zones_orderMostFree;

  /// Switch that hides pavilions without free spaces.
  ///
  /// In en, this message translates to:
  /// **'Only pavilions with free spaces'**
  String get zones_onlyFree;

  /// Goes back to the default order and shows every pavilion.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get zones_filterReset;

  /// Closes the sort and filter sheet.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get zones_filterDone;

  /// Total spaces of a lot, pavilion or level.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get zones_capacity;

  /// Free spaces of a lot, pavilion or level.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get zones_free;

  /// Spaces whose sensor has no data.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get zones_unknown;

  /// Explains that unknown spaces are never free.
  ///
  /// In en, this message translates to:
  /// **'Spaces with no data aren\'t counted as free until their sensor reports again.'**
  String get zones_unknownBanner;

  /// Free spaces of a pavilion or level.
  ///
  /// In en, this message translates to:
  /// **'{count} free'**
  String zones_freeCount(int count);

  /// Occupied spaces.
  ///
  /// In en, this message translates to:
  /// **'{count} occupied'**
  String zones_occupiedCount(int count);

  /// Spaces with no data.
  ///
  /// In en, this message translates to:
  /// **'{count} no data'**
  String zones_unknownCount(int count);

  /// Availability pill: plenty of room.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get zones_availabilityGood;

  /// Availability pill: close to the lot saturation threshold.
  ///
  /// In en, this message translates to:
  /// **'Limited'**
  String get zones_availabilityLimited;

  /// Availability pill: no free spaces.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get zones_availabilityFull;

  /// Availability pill: nothing to count.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get zones_availabilityNoData;

  /// Screen reader summary of a pavilion card.
  ///
  /// In en, this message translates to:
  /// **'{name}{description}: {free}, {unknown}, availability {availability}'**
  String zones_zoneSemantics(
    String name,
    String description,
    String free,
    String unknown,
    String availability,
  );

  /// Hint of a pavilion card with several levels.
  ///
  /// In en, this message translates to:
  /// **'Opens the levels of the pavilion'**
  String get zones_openLevels;

  /// Hint of a pavilion or level card that opens a level.
  ///
  /// In en, this message translates to:
  /// **'Opens the map of the level'**
  String get zones_openLevelMap;

  /// Accessible label of the Zones skeleton.
  ///
  /// In en, this message translates to:
  /// **'Loading the pavilions…'**
  String get zones_loading;

  /// Empty state: a published layout without zones.
  ///
  /// In en, this message translates to:
  /// **'This lot has no pavilions yet'**
  String get zones_emptyTitle;

  /// Empty state hint.
  ///
  /// In en, this message translates to:
  /// **'Pull down to check again.'**
  String get zones_emptyMessage;

  /// Empty state when the filter hides every pavilion.
  ///
  /// In en, this message translates to:
  /// **'No pavilion has free spaces right now'**
  String get zones_noFreeTitle;

  /// Empty state hint when the filter hides every pavilion.
  ///
  /// In en, this message translates to:
  /// **'Show all of them to see how full each one is.'**
  String get zones_noFreeMessage;

  /// Resets the filter.
  ///
  /// In en, this message translates to:
  /// **'Show all pavilions'**
  String get zones_showAll;

  /// Banner: the layout is missing but the counts arrived.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the pavilions. Showing the totals of the lot.'**
  String get zones_partialLayout;

  /// Banner: the counts are missing but the layout arrived.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load availability. Showing the pavilions without counts.'**
  String get zones_partialOccupancy;

  /// Empty state of a pavilion that does not exist.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find this pavilion'**
  String get zones_notFoundTitle;

  /// Empty state of a level that does not exist.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find this level'**
  String get zones_levelNotFoundTitle;

  /// Hint of a pavilion or level that does not exist.
  ///
  /// In en, this message translates to:
  /// **'The layout may have changed. Go back to the list.'**
  String get zones_notFoundMessage;

  /// Goes back to the Zones list.
  ///
  /// In en, this message translates to:
  /// **'Back to parking'**
  String get zones_backToZones;

  /// Heading of the levels of a pavilion.
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get zones_levelsHeading;

  /// Label of the map or list switch.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get zones_viewLabel;

  /// Shows the level as a map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get zones_viewMap;

  /// Shows the level as a list of spaces.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get zones_viewList;

  /// Screen reader summary of the level map.
  ///
  /// In en, this message translates to:
  /// **'Map: {free}, {occupied}, {unknown}'**
  String zones_mapSummary(String free, String occupied, String unknown);

  /// Note shown when the spaces have no position.
  ///
  /// In en, this message translates to:
  /// **'This level doesn\'t have a map yet. Showing the list.'**
  String get zones_noMap;

  /// List filter: every space.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get zones_filterAll;

  /// List filter: free spaces.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get zones_filterFree;

  /// List filter: spaces with no data.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get zones_filterUnknown;

  /// Empty list after filtering.
  ///
  /// In en, this message translates to:
  /// **'No spaces match this filter.'**
  String get zones_listEmpty;

  /// Screen reader summary of a space row.
  ///
  /// In en, this message translates to:
  /// **'Space {label}: {state}'**
  String zones_spaceSemantics(String label, String state);

  /// Why a space has no data: the sensor stopped reporting.
  ///
  /// In en, this message translates to:
  /// **'No signal from the sensor'**
  String get zones_reasonNoHeartbeat;

  /// Why a space has no data: critical battery.
  ///
  /// In en, this message translates to:
  /// **'Sensor battery is low'**
  String get zones_reasonLowBattery;

  /// Why a space has no data: no sensor.
  ///
  /// In en, this message translates to:
  /// **'No sensor assigned'**
  String get zones_reasonNoSensor;

  /// A space with no data and no known reason.
  ///
  /// In en, this message translates to:
  /// **'Waiting for data'**
  String get zones_reasonWaiting;

  /// Top bar action of Forecast that opens the arrival time sheet.
  ///
  /// In en, this message translates to:
  /// **'Choose your arrival time'**
  String get forecast_etaAction;

  /// Caption of the arrival hero when the ETA is estimated on the device.
  ///
  /// In en, this message translates to:
  /// **'If you leave now'**
  String get forecast_ifLeaveNow;

  /// Caption of the arrival hero when the driver set the ETA.
  ///
  /// In en, this message translates to:
  /// **'Your arrival time'**
  String get forecast_yourArrivalTime;

  /// Headline of the arrival hero.
  ///
  /// In en, this message translates to:
  /// **'You arrive in {minutes} min'**
  String forecast_arriveIn(int minutes);

  /// The driver picked the ETA.
  ///
  /// In en, this message translates to:
  /// **'Set by you'**
  String get forecast_etaManual;

  /// The ETA is being calculated.
  ///
  /// In en, this message translates to:
  /// **'Estimating…'**
  String get forecast_etaEstimating;

  /// Headline of the arrival hero without an ETA.
  ///
  /// In en, this message translates to:
  /// **'Pick when you arrive'**
  String get forecast_etaPrompt;

  /// Caption of the arrival hero without an ETA.
  ///
  /// In en, this message translates to:
  /// **'Your arrival'**
  String get forecast_etaPromptCaption;

  /// Screen reader summary of the arrival hero.
  ///
  /// In en, this message translates to:
  /// **'{caption}. {headline}. {source}'**
  String forecast_heroSemantics(String caption, String headline, String source);

  /// Tag of the forecast row closest to the ETA.
  ///
  /// In en, this message translates to:
  /// **'Your arrival'**
  String get forecast_yourArrivalTag;

  /// Confidence of a forecast row.
  ///
  /// In en, this message translates to:
  /// **'Confidence: {level}'**
  String forecast_confidenceLine(String level);

  /// A horizon without a forecast.
  ///
  /// In en, this message translates to:
  /// **'No forecast for this time'**
  String get forecast_rowMissing;

  /// A forecast that is no longer current.
  ///
  /// In en, this message translates to:
  /// **'Forecast expired'**
  String get forecast_rowExpired;

  /// A horizon with a forecast but without arrival odds.
  ///
  /// In en, this message translates to:
  /// **'Arrival odds not available'**
  String get forecast_rowNoOdds;

  /// Hint of a forecast row.
  ///
  /// In en, this message translates to:
  /// **'Opens the forecast details'**
  String get forecast_rowHint;

  /// Screen reader summary of a forecast row.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min, at {time}: {percent} percent, {category}. {confidence}.{tag}'**
  String forecast_rowSpoken(
    int minutes,
    String time,
    int percent,
    String category,
    String confidence,
    String tag,
  );

  /// Screen reader summary of a forecast row without odds.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min, at {time}: {state}.{tag}'**
  String forecast_rowSpokenOther(
    int minutes,
    String time,
    String state,
    String tag,
  );

  /// How the forecast is made.
  ///
  /// In en, this message translates to:
  /// **'Estimate based on historical occupancy, flow, the academic calendar and events.'**
  String get forecast_note;

  /// When the forecasts were generated.
  ///
  /// In en, this message translates to:
  /// **'Generated at {time} · {age}'**
  String forecast_generatedAt(String time, String age);

  /// Banner: some horizons have no forecast.
  ///
  /// In en, this message translates to:
  /// **'Some forecasts are missing. Showing the ones we have.'**
  String get forecast_partialMissing;

  /// Banner: some forecasts are no longer current.
  ///
  /// In en, this message translates to:
  /// **'Some forecasts have expired, so they aren\'t shown as current.'**
  String get forecast_partialExpired;

  /// Banner: the forecasts failed but the odds arrived.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the forecast details. Showing the arrival odds.'**
  String get forecast_partialDetails;

  /// Banner: a forecast has low confidence or comes from the contingency estimate.
  ///
  /// In en, this message translates to:
  /// **'There is little history for this lot. Treat these numbers as a rough guide.'**
  String get forecast_lowConfidenceBanner;

  /// Empty state: the lot has no forecasts.
  ///
  /// In en, this message translates to:
  /// **'No forecasts yet'**
  String get forecast_emptyTitle;

  /// Empty state hint.
  ///
  /// In en, this message translates to:
  /// **'This lot doesn\'t have enough history yet. Check back later.'**
  String get forecast_emptyMessage;

  /// Accessible label of the Forecast skeleton.
  ///
  /// In en, this message translates to:
  /// **'Loading forecasts…'**
  String get forecast_loading;

  /// Title of the forecast details sheet.
  ///
  /// In en, this message translates to:
  /// **'Forecast in {minutes} min'**
  String forecast_detailTitle(int minutes);

  /// Closes the forecast details sheet.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get forecast_detailClose;

  /// The time a forecast refers to.
  ///
  /// In en, this message translates to:
  /// **'For {time}'**
  String forecast_detailForTime(String time);

  /// Label of the arrival odds.
  ///
  /// In en, this message translates to:
  /// **'Chance of finding a space'**
  String get forecast_detailChance;

  /// Label of the expected occupancy.
  ///
  /// In en, this message translates to:
  /// **'Expected occupancy'**
  String get forecast_detailOccupancy;

  /// Label of the expected saturation.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get forecast_detailSaturation;

  /// The lot is expected to saturate.
  ///
  /// In en, this message translates to:
  /// **'Expected to fill up at {time} ({percent}%)'**
  String forecast_detailFillsAt(String time, String percent);

  /// No saturation is expected.
  ///
  /// In en, this message translates to:
  /// **'Not expected to fill up'**
  String get forecast_detailNoSaturation;

  /// Label of the generation time.
  ///
  /// In en, this message translates to:
  /// **'Generated'**
  String get forecast_detailGenerated;

  /// Label of how long the forecast stays current.
  ///
  /// In en, this message translates to:
  /// **'Valid for'**
  String get forecast_detailValid;

  /// How long the forecast stays current.
  ///
  /// In en, this message translates to:
  /// **'{minutes} more min'**
  String forecast_detailValidMinutes(int minutes);

  /// The forecast is about to expire.
  ///
  /// In en, this message translates to:
  /// **'Less than a minute'**
  String get forecast_detailValidSoon;

  /// The forecast is no longer current.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get forecast_detailExpired;

  /// Label of how the forecast was made.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get forecast_detailSource;

  /// The forecast comes from the main model.
  ///
  /// In en, this message translates to:
  /// **'Main model'**
  String get forecast_sourceModel;

  /// The forecast comes from the contingency estimate.
  ///
  /// In en, this message translates to:
  /// **'Contingency estimate (limited history)'**
  String get forecast_sourceFallback;

  /// Version of the model.
  ///
  /// In en, this message translates to:
  /// **'Model {version}'**
  String forecast_detailModel(String version);

  /// Warning in the details of a low-confidence forecast.
  ///
  /// In en, this message translates to:
  /// **'This forecast relies on limited information. Use it as a reference.'**
  String get forecast_detailLowConfidence;

  /// Note in the details of an expired forecast.
  ///
  /// In en, this message translates to:
  /// **'This forecast has expired and isn\'t shown as current.'**
  String get forecast_detailExpiredNote;

  /// Note in the details of a missing forecast.
  ///
  /// In en, this message translates to:
  /// **'There is no forecast for this time yet.'**
  String get forecast_detailMissingNote;

  /// Accessible label of the Alerts skeleton.
  ///
  /// In en, this message translates to:
  /// **'Loading your alerts…'**
  String get alerts_loading;

  /// Error state title of Alerts.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your alerts'**
  String get alerts_errorTitle;

  /// Banner: the preferences are missing.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your preferences.'**
  String get alerts_partialPreferences;

  /// Banner: the time slots are missing.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your time slots.'**
  String get alerts_partialSlots;

  /// Master switch of the push notifications.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications'**
  String get alerts_pushTitle;

  /// Helper of the master switch when it is on.
  ///
  /// In en, this message translates to:
  /// **'We\'ll alert you on this phone.'**
  String get alerts_pushOn;

  /// Helper of the master switch when it is off.
  ///
  /// In en, this message translates to:
  /// **'Off: you won\'t get alerts, even for the slots you follow.'**
  String get alerts_pushOff;

  /// Heading of the alert preferences.
  ///
  /// In en, this message translates to:
  /// **'Tell me when'**
  String get alerts_sectionWhen;

  /// Hint under the alert preferences when notifications are off.
  ///
  /// In en, this message translates to:
  /// **'Turn notifications on to choose which alerts you get.'**
  String get alerts_whenOffHint;

  /// Preference: saturation alerts.
  ///
  /// In en, this message translates to:
  /// **'A lot is expected to fill up'**
  String get alerts_saturationTitle;

  /// Helper of the saturation alerts.
  ///
  /// In en, this message translates to:
  /// **'In the time slots you follow'**
  String get alerts_saturationHelp;

  /// Preference: low arrival availability.
  ///
  /// In en, this message translates to:
  /// **'Availability is low'**
  String get alerts_lowArrivalTitle;

  /// Helper of the low availability alert.
  ///
  /// In en, this message translates to:
  /// **'For your estimated arrival time'**
  String get alerts_lowArrivalHelp;

  /// Preference: stale data alerts.
  ///
  /// In en, this message translates to:
  /// **'Data is out of date'**
  String get alerts_staleTitle;

  /// Helper of the stale data alert.
  ///
  /// In en, this message translates to:
  /// **'More than 10 minutes without a reading'**
  String get alerts_staleHelp;

  /// Preference: event alerts.
  ///
  /// In en, this message translates to:
  /// **'Events change things'**
  String get alerts_eventsTitle;

  /// Helper of the event alert.
  ///
  /// In en, this message translates to:
  /// **'Only campus calendar events'**
  String get alerts_eventsHelp;

  /// Heading of the subscriptions list.
  ///
  /// In en, this message translates to:
  /// **'Your time slots'**
  String get alerts_slotsTitle;

  /// Empty state of the subscriptions.
  ///
  /// In en, this message translates to:
  /// **'You don\'t follow any slot yet'**
  String get alerts_slotsEmptyTitle;

  /// Empty state hint of the subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Pick the days and time you usually arrive and we\'ll warn you if the lot is expected to fill up.'**
  String get alerts_slotsEmptyMessage;

  /// Opens the new time slot sheet.
  ///
  /// In en, this message translates to:
  /// **'Add a time slot'**
  String get alerts_addSlot;

  /// A time slot that is switched off.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get alerts_slotPaused;

  /// Screen reader label of the switch of a time slot.
  ///
  /// In en, this message translates to:
  /// **'Alerts for {lot}, {days}, {time}'**
  String alerts_slotSwitchLabel(String lot, String days, String time);

  /// Tooltip of the delete button of a time slot.
  ///
  /// In en, this message translates to:
  /// **'Delete the slot for {lot}, {days}, {time}'**
  String alerts_slotDeleteTooltip(String lot, String days, String time);

  /// Title of the delete confirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete this time slot?'**
  String get alerts_deleteTitle;

  /// The time slot named in the delete confirmation.
  ///
  /// In en, this message translates to:
  /// **'{lot} · {days} · {time}'**
  String alerts_deleteSubject(String lot, String days, String time);

  /// Body of the delete confirmation.
  ///
  /// In en, this message translates to:
  /// **'You\'ll stop getting alerts for this slot. Your other slots stay.'**
  String get alerts_deleteMessage;

  /// Confirms deleting a time slot.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get alerts_deleteConfirm;

  /// Cancels deleting a time slot.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get alerts_deleteCancel;

  /// Heading of the offline behaviour card.
  ///
  /// In en, this message translates to:
  /// **'Intermittent connection'**
  String get alerts_connectivityTitle;

  /// The offline behaviour is automatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get alerts_connectivityValue;

  /// What the app does without a connection.
  ///
  /// In en, this message translates to:
  /// **'Keeps the last lookup and syncs when the connection returns.'**
  String get alerts_connectivityHelp;

  /// Privacy note of the alerts screen.
  ///
  /// In en, this message translates to:
  /// **'Your preferences stay in your account. Quadrapp doesn\'t receive your location; only arrival minutes.'**
  String get alerts_privacy;

  /// Snackbar: the permission was denied.
  ///
  /// In en, this message translates to:
  /// **'We can\'t alert you without the notifications permission.'**
  String get alerts_noticePermissionDenied;

  /// Snackbar: the permission can only be changed in settings.
  ///
  /// In en, this message translates to:
  /// **'Notifications are blocked. Turn them on in your phone\'s settings.'**
  String get alerts_noticePermissionBlocked;

  /// Snackbar: the device could not be registered.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t turn on notifications on this phone. Try again later.'**
  String get alerts_noticeActivationFailed;

  /// Snackbar: saving the preferences failed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save your preferences. Try again.'**
  String get alerts_noticeSaveFailed;

  /// Snackbar: switching a slot failed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t update the time slot. Try again.'**
  String get alerts_noticeSlotFailed;

  /// Snackbar: reactivating a slot that duplicates an active one.
  ///
  /// In en, this message translates to:
  /// **'You already follow that time slot, so this one stays paused.'**
  String get alerts_noticeSlotDuplicate;

  /// Snackbar: deleting a slot failed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t delete the time slot. Try again.'**
  String get alerts_noticeDeleteFailed;

  /// Snackbar: a slot was deleted.
  ///
  /// In en, this message translates to:
  /// **'Time slot deleted'**
  String get alerts_noticeDeleted;

  /// Snackbar: a slot was created.
  ///
  /// In en, this message translates to:
  /// **'Time slot added'**
  String get alerts_noticeCreated;

  /// Snackbar: a slot was created but the permission was denied.
  ///
  /// In en, this message translates to:
  /// **'Slot added, but without the notifications permission we can\'t alert you.'**
  String get alerts_noticeCreatedDenied;

  /// Snackbar: a slot was created but the permission is blocked.
  ///
  /// In en, this message translates to:
  /// **'Slot added. Notifications are blocked: turn them on in your phone\'s settings.'**
  String get alerts_noticeCreatedBlocked;

  /// Snackbar: a slot was created but the device could not be registered.
  ///
  /// In en, this message translates to:
  /// **'Slot added, but we couldn\'t turn on notifications on this phone.'**
  String get alerts_noticeCreatedNoDevice;

  /// Title of the new time slot sheet.
  ///
  /// In en, this message translates to:
  /// **'New time slot'**
  String get alerts_sheetTitle;

  /// One line under the new time slot sheet title.
  ///
  /// In en, this message translates to:
  /// **'We\'ll let you know if we expect it to fill up at this time.'**
  String get alerts_sheetSubtitle;

  /// Closes the new time slot sheet.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get alerts_sheetClose;

  /// Label of the lot chooser.
  ///
  /// In en, this message translates to:
  /// **'Parking lot'**
  String get alerts_sheetLot;

  /// Label of the day chooser.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get alerts_sheetDays;

  /// Label of the start time.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get alerts_sheetFrom;

  /// Label of the end time.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get alerts_sheetTo;

  /// Placeholder of a time button.
  ///
  /// In en, this message translates to:
  /// **'Pick a time'**
  String get alerts_sheetPickTime;

  /// Context shown before the permission is requested.
  ///
  /// In en, this message translates to:
  /// **'We\'ll ask for the notifications permission if you haven\'t allowed it yet.'**
  String get alerts_sheetPermissionHint;

  /// Primary action of the new time slot sheet.
  ///
  /// In en, this message translates to:
  /// **'Add time slot'**
  String get alerts_sheetCreate;

  /// Accessible label while the slot is created.
  ///
  /// In en, this message translates to:
  /// **'Adding…'**
  String get alerts_sheetCreating;

  /// Validation: no day chosen.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one day.'**
  String get alerts_errorDays;

  /// Validation: a time is missing.
  ///
  /// In en, this message translates to:
  /// **'Pick a start and an end time.'**
  String get alerts_errorTimes;

  /// Validation: the slot is inverted.
  ///
  /// In en, this message translates to:
  /// **'The end time must be after the start.'**
  String get alerts_errorOrder;

  /// The slot duplicates an active one.
  ///
  /// In en, this message translates to:
  /// **'You already follow this time slot.'**
  String get alerts_errorDuplicate;

  /// Validation: no lot chosen.
  ///
  /// In en, this message translates to:
  /// **'Choose a parking lot.'**
  String get alerts_errorNoLot;

  /// What Quadrapp never receives.
  ///
  /// In en, this message translates to:
  /// **'Your location. Your arrival time is calculated on your phone and only the minutes reach Quadrapp. If you turn on live traffic, your approximate location (about 100 m) goes to Google, only to calculate that time; Quadrapp doesn\'t receive it or store it. We don\'t read license plates and we don\'t handle payments.'**
  String get legal_neverBody;

  /// Where the arrival time comes from: a maps provider with traffic.
  ///
  /// In en, this message translates to:
  /// **'with live traffic'**
  String get eta_sourceTraffic;

  /// Where the arrival time comes from: the phone, without traffic.
  ///
  /// In en, this message translates to:
  /// **'estimated on your phone'**
  String get eta_sourceDevice;

  /// How long ago the arrival time was calculated.
  ///
  /// In en, this message translates to:
  /// **'Your arrival time updated {age}'**
  String eta_updatedAgo(String age);

  /// Switch of the automatic arrival time.
  ///
  /// In en, this message translates to:
  /// **'Calculate my arrival automatically'**
  String get eta_autoTitle;

  /// Helper of the automatic switch when it is on.
  ///
  /// In en, this message translates to:
  /// **'We estimate how long you take from where you are and keep it up to date.'**
  String get eta_autoOn;

  /// Helper of the automatic switch when it is off.
  ///
  /// In en, this message translates to:
  /// **'Off: we won\'t use your location. Only the time you pick below counts.'**
  String get eta_autoOff;

  /// Switch of the traffic-aware arrival time.
  ///
  /// In en, this message translates to:
  /// **'Include live traffic'**
  String get eta_trafficTitle;

  /// Helper of the traffic switch when it is on: what is shared.
  ///
  /// In en, this message translates to:
  /// **'Your approximate location (about 100 m) goes to Google to calculate traffic, only for this estimate. Quadrapp doesn\'t receive it or store it.'**
  String get eta_trafficOn;

  /// Helper of the traffic switch when it is off.
  ///
  /// In en, this message translates to:
  /// **'Off: your location never leaves your phone. The estimate doesn\'t include traffic.'**
  String get eta_trafficOff;

  /// The current arrival time and where it comes from.
  ///
  /// In en, this message translates to:
  /// **'Now: {minutes} min · {source}'**
  String eta_currentSummary(int minutes, String source);

  /// Note on a manual arrival time.
  ///
  /// In en, this message translates to:
  /// **'Chosen by you. It goes down by itself as time passes.'**
  String get eta_manualCountdown;

  /// Drops the manual time and uses the automatic one.
  ///
  /// In en, this message translates to:
  /// **'Go back to automatic'**
  String get eta_backToAuto;

  /// Why there is no arrival time: too far.
  ///
  /// In en, this message translates to:
  /// **'You\'re more than 2 hours from campus. Advice starts once you\'re closer; you can pick a time meanwhile.'**
  String get eta_tooFar;

  /// Hero statement when the arrival time is above the maximum.
  ///
  /// In en, this message translates to:
  /// **'You\'re more than 2 hours from campus. We\'ll show what to expect once you\'re closer. You can pick a time meanwhile.'**
  String get home_statementTooFar;

  /// Arrival time of 0 minutes.
  ///
  /// In en, this message translates to:
  /// **'You\'re here'**
  String get home_arriveNow;

  /// Privacy line of Home when live traffic is on.
  ///
  /// In en, this message translates to:
  /// **'Quadrapp receives only arrival minutes. With live traffic on, your approximate location goes to Google.'**
  String get home_privacyLineTraffic;

  /// The arrival time changed.
  ///
  /// In en, this message translates to:
  /// **'Updated: you arrive in {eta} min (was {previous})'**
  String home_changeEta(int eta, int previous);

  /// The chance of finding a space changed with the arrival time.
  ///
  /// In en, this message translates to:
  /// **'Chance of a space: {percent}% (was {previous}%)'**
  String home_changeChance(int percent, int previous);

  /// The arrival category changed with the arrival time.
  ///
  /// In en, this message translates to:
  /// **'Now {category} (was {previous})'**
  String home_changeCategory(String category, String previous);

  /// The ETA comes from a maps provider with traffic.
  ///
  /// In en, this message translates to:
  /// **'With live traffic'**
  String get forecast_etaTraffic;

  /// The ETA was calculated on the phone, without traffic.
  ///
  /// In en, this message translates to:
  /// **'Estimated on your phone'**
  String get forecast_etaDevice;

  /// Caption of the arrival hero when the driver is too far.
  ///
  /// In en, this message translates to:
  /// **'More than 2 hours away'**
  String get forecast_tooFar;

  /// Switch: the phone drives toward the chosen campus.
  ///
  /// In en, this message translates to:
  /// **'Simulate the drive to campus'**
  String get debug_simulateTrip;

  /// Help of the trip switch.
  ///
  /// In en, this message translates to:
  /// **'The simulated phone drives to the chosen campus at 150 km/h: the arrival time goes down on its own and the advice updates.'**
  String get debug_simulateTripHelp;

  /// Switch: the simulated maps provider reports heavy traffic.
  ///
  /// In en, this message translates to:
  /// **'Heavy traffic'**
  String get debug_heavyTraffic;

  /// Help of the heavy traffic switch.
  ///
  /// In en, this message translates to:
  /// **'The simulated maps provider multiplies the trip by 1.8 instead of 1.3.'**
  String get debug_heavyTrafficHelp;

  /// Switch: the simulated maps provider does not answer.
  ///
  /// In en, this message translates to:
  /// **'Maps provider down'**
  String get debug_routesOutage;

  /// Help of the maps outage switch.
  ///
  /// In en, this message translates to:
  /// **'The app falls back to the estimate on the phone, without showing an error.'**
  String get debug_routesOutageHelp;

  /// The arrival time was calculated a few seconds ago.
  ///
  /// In en, this message translates to:
  /// **'Your arrival time was just updated'**
  String get eta_updatedNow;
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
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
