// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get common_appName => 'Quadrapp';

  @override
  String get common_back => 'Back';

  @override
  String get gallery_title => 'Design system';

  @override
  String get gallery_cardLow => 'Low elevation';

  @override
  String get gallery_cardHigh => 'High elevation';

  @override
  String get gallery_cardTap => 'Tap me: the card shrinks to 0.98';

  @override
  String get gallery_heroTitle => 'Hero surface';

  @override
  String get gallery_heroFree => 'free';

  @override
  String get gallery_liveLive => 'Live';

  @override
  String get gallery_liveReconnecting => 'Reconnecting…';

  @override
  String get gallery_liveOffline => 'Offline';

  @override
  String get gallery_openSheet => 'Open bottom sheet';

  @override
  String get gallery_sheetTitle => 'New item';

  @override
  String get gallery_sheetBody =>
      'The body scrolls; the primary action stays pinned at the bottom, even with the keyboard open.';

  @override
  String get gallery_sheetAction => 'Save';

  @override
  String get gallery_sheetClose => 'Close';

  @override
  String get gallery_openConfirm => 'Open confirm dialog';

  @override
  String get gallery_confirmTitle => 'Remove device?';

  @override
  String get gallery_confirmSubject => 'SENS-A-18 · Space A-18';

  @override
  String get gallery_confirmMessage =>
      'It will stop sending events. This can\'t be undone.';

  @override
  String get gallery_confirmAction => 'Remove';

  @override
  String get gallery_openSnack => 'Show snackbar with Undo';

  @override
  String get gallery_snackMessage => 'Alert saved';

  @override
  String get gallery_snackUndo => 'Undo';

  @override
  String get gallery_open => 'Open design system gallery';

  @override
  String get gallery_darkMode => 'Dark mode';

  @override
  String get gallery_stateLoading => 'Loading';

  @override
  String get gallery_stateEmpty => 'Empty';

  @override
  String get gallery_stateError => 'Error';

  @override
  String get gallery_statePartial => 'Partial or out of date';

  @override
  String get gallery_stateSuccess => 'Success';

  @override
  String get gallery_stateDisabled => 'Disabled';

  @override
  String get gallery_stateFilled => 'Filled';

  @override
  String get gallery_buttonPrimary => 'Send code';

  @override
  String get gallery_buttonTonal => 'Save preferences';

  @override
  String get gallery_buttonText => 'Change my arrival time';

  @override
  String get gallery_buttonDestructive => 'Sign out';

  @override
  String get gallery_fieldLabel => 'Institutional email';

  @override
  String get gallery_fieldHint => 'name@university.edu';

  @override
  String get gallery_fieldHelper => 'We\'ll send you a one-time code.';

  @override
  String get gallery_fieldError => 'Enter a valid institutional email.';

  @override
  String get gallery_otpLabel => 'Verification code, 6 digits';

  @override
  String get gallery_otpError =>
      'The code expired or doesn\'t match. Request a new one.';

  @override
  String get gallery_statusFree => 'Free';

  @override
  String get gallery_statusLimited => 'Limited';

  @override
  String get gallery_statusOccupied => 'Occupied';

  @override
  String get gallery_statusUnknown => 'No data';

  @override
  String gallery_plateHeadline(int minutes) {
    return 'You arrive in $minutes min';
  }

  @override
  String get gallery_plateHigh => 'High';

  @override
  String get gallery_plateLimited => 'Limited';

  @override
  String get gallery_plateLow => 'Low';

  @override
  String gallery_plateDetail(int percent) {
    return '$percent% chance of finding a space';
  }

  @override
  String gallery_plateFootnote(String confidence, String time) {
    return '$confidence · $time';
  }

  @override
  String get gallery_confidenceHigh => 'High confidence';

  @override
  String get gallery_confidenceMedium => 'Medium confidence';

  @override
  String get gallery_confidenceLow => 'Low confidence';

  @override
  String get gallery_confidenceLowNote => 'Estimate based on limited data';

  @override
  String gallery_freshnessFresh(int seconds) {
    return 'Updated $seconds s ago';
  }

  @override
  String gallery_freshnessStale(String time) {
    return 'No new data since $time';
  }

  @override
  String gallery_horizonLabel(int minutes) {
    return '$minutes min';
  }

  @override
  String gallery_horizonValue(int percent) {
    return '$percent%';
  }

  @override
  String gallery_horizonSemantic(int minutes, int percent) {
    return 'In $minutes minutes: $percent% occupied';
  }

  @override
  String gallery_horizonMissingSemantic(int minutes) {
    return 'In $minutes minutes: no forecast';
  }

  @override
  String gallery_horizonExpiredSemantic(int minutes) {
    return 'In $minutes minutes: forecast expired';
  }

  @override
  String gallery_horizonSaturation(String time) {
    return 'Fills up at $time';
  }

  @override
  String gallery_mapSummary(int free, int occupied, int unknown) {
    return 'Parking map: $free free, $occupied occupied, $unknown with no data';
  }

  @override
  String gallery_zoneName(String name) {
    return 'Zone $name';
  }

  @override
  String gallery_zoneFree(int count) {
    return '$count free';
  }

  @override
  String gallery_zoneOccupied(int count) {
    return '$count occupied';
  }

  @override
  String gallery_zoneUnknown(int count) {
    return '$count no data';
  }

  @override
  String gallery_zoneSemantic(
    String name,
    int free,
    int occupied,
    int unknown,
  ) {
    return 'Zone $name: $free free, $occupied occupied, $unknown with no data';
  }

  @override
  String get gallery_kpiLabel => 'Free spaces';

  @override
  String gallery_kpiCaption(int total) {
    return 'of $total';
  }

  @override
  String get gallery_kpiEmpty => 'No data yet';

  @override
  String get gallery_kpiError => 'Couldn\'t load';

  @override
  String get gallery_slotDays => 'Days';

  @override
  String get gallery_slotFrom => 'From';

  @override
  String get gallery_slotTo => 'To';

  @override
  String get gallery_slotPick => 'Pick a time';

  @override
  String get gallery_slotError => 'The end time must be after the start.';

  @override
  String get gallery_dialogOpen => 'Show confirmation dialog';

  @override
  String get gallery_dialogTitle => 'Sign out';

  @override
  String get gallery_dialogMessage =>
      'You\'ll need a new code to sign in again on this device.';

  @override
  String get gallery_dialogConfirm => 'Sign out';

  @override
  String get gallery_dialogCancel => 'Cancel';

  @override
  String get gallery_emptyTitle => 'No time slots yet';

  @override
  String get gallery_emptyMessage =>
      'You\'re not following any time slot yet. Pick the time you usually arrive and we\'ll let you know if the lot is expected to fill up.';

  @override
  String get gallery_emptyAction => 'Subscribe to this time slot';

  @override
  String get gallery_errorTitle => 'Couldn\'t load availability';

  @override
  String get gallery_errorMessage =>
      'There\'s no connection to the server. Check your network and try again.';

  @override
  String get gallery_errorRetry => 'Retry';

  @override
  String gallery_bannerOffline(String time) {
    return 'You\'re offline. Showing the latest data we have, from $time.';
  }

  @override
  String gallery_bannerStale(String time) {
    return 'No new data since $time. What you see may be out of date.';
  }

  @override
  String get gallery_bannerError =>
      'The code expired or doesn\'t match. Request a new one.';

  @override
  String get gallery_bannerInfo => 'The lot layout was updated.';

  @override
  String get gallery_mapSimulate => 'Simulate a space change';

  @override
  String get iam_restoring => 'Checking your session…';

  @override
  String get iam_loginTitle => 'Plan your arrival at campus';

  @override
  String get iam_loginSubtitle =>
      'Check the estimated availability before you leave. No reservations or payments.';

  @override
  String get iam_emailLabel => 'Institutional email';

  @override
  String get iam_emailHint => 'name@university.edu';

  @override
  String get iam_emailErrorEmpty => 'Enter your institutional email.';

  @override
  String get iam_emailErrorInvalid =>
      'Enter a valid email, like name@university.edu.';

  @override
  String get iam_sendCode => 'Continue';

  @override
  String get iam_sendingCode => 'Sending code…';

  @override
  String iam_sendCodeIn(String time) {
    return 'Continue in $time';
  }

  @override
  String get iam_rateLimited =>
      'Too many attempts. You can request another code when the countdown ends.';

  @override
  String get iam_errorForbidden =>
      'That email doesn\'t belong to an enabled institution.';

  @override
  String get iam_errorEmailFormat =>
      'The email format isn\'t valid. Check it and try again.';

  @override
  String get iam_errorNetwork =>
      'You\'re offline. Check your connection and try again.';

  @override
  String get iam_errorGeneric =>
      'Something went wrong on our side. Try again in a moment.';

  @override
  String get iam_retry => 'Try again';

  @override
  String get iam_sessionExpired =>
      'Your session expired. Sign in again to continue.';

  @override
  String get iam_verifyTitle => 'Verify your email';

  @override
  String iam_verifySentTo(String email) {
    return 'We sent a 6-digit code to $email.';
  }

  @override
  String iam_verifyValidity(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'The code is valid for $minutes minutes.',
      one: 'The code is valid for 1 minute.',
    );
    return '$_temp0';
  }

  @override
  String get iam_otpLabel => 'Verification code, 6 digits';

  @override
  String get iam_verifyAction => 'Verify and sign in';

  @override
  String get iam_verifying => 'Verifying…';

  @override
  String get iam_errorCodeInvalid =>
      'The code expired or doesn\'t match. Request a new one.';

  @override
  String get iam_errorCodeIncomplete => 'Enter all 6 digits.';

  @override
  String get iam_resend => 'Resend code';

  @override
  String iam_resendIn(String time) {
    return 'Resend code in $time';
  }

  @override
  String get iam_resending => 'Sending a new code…';

  @override
  String get iam_noticeResent => 'We sent you a new code.';

  @override
  String get iam_noticeResendNetwork =>
      'Couldn\'t send a new code: you\'re offline.';

  @override
  String get iam_noticeResendFailed =>
      'Couldn\'t send a new code. Try again in a moment.';

  @override
  String get nav_home => 'Home';

  @override
  String get nav_alerts => 'Alerts';

  @override
  String get nav_settings => 'Settings';

  @override
  String get nav_shift => 'Shift';

  @override
  String get nav_lots => 'Lots';

  @override
  String get nav_devices => 'Devices';

  @override
  String get ops_shiftSoonTitle => 'Shift console coming soon';

  @override
  String get ops_shiftSoonMessage =>
      'Soon you\'ll see capacity, flow and the expected saturation of your lot.';

  @override
  String get ops_lotsSoonTitle => 'Lots overview coming soon';

  @override
  String get ops_lotsSoonMessage =>
      'Soon you\'ll see every lot with its occupancy and status.';

  @override
  String get ops_devicesSoonTitle => 'Devices coming soon';

  @override
  String get ops_devicesSoonMessage =>
      'Soon you\'ll see the health of every sensor and gateway.';

  @override
  String get sede_choose => 'Choose campus';

  @override
  String sede_chipLabel(String name) {
    return 'Campus: $name. Change campus';
  }

  @override
  String get sede_sheetTitle => 'Choose your campus';

  @override
  String get sede_sheetSubtitle =>
      'You\'ll see the availability of the lot you choose.';

  @override
  String get sede_close => 'Close';

  @override
  String get sede_noLayout => 'No availability published yet';

  @override
  String get sede_current => 'Current campus';

  @override
  String get sede_promptTitle => 'Which campus are you heading to?';

  @override
  String get sede_promptMessage =>
      'Pick your campus to see its parking availability.';

  @override
  String get sede_errorTitle => 'Couldn\'t load the campuses';

  @override
  String get nav_zones => 'Zones';

  @override
  String get nav_forecast => 'Forecast';

  @override
  String get title_arrival => 'Your arrival';

  @override
  String get title_zones => 'Parking';

  @override
  String get title_forecast => 'Forecast';

  @override
  String get title_alerts => 'Alerts and preferences';

  @override
  String get title_account => 'Account';

  @override
  String get account_open => 'Account';

  @override
  String get iam_emailHelper =>
      'We use your domain to confirm your community\'s access.';

  @override
  String get iam_privacyMinutes =>
      'When you ask for a forecast you only share your estimated minutes of arrival. Never your location.';

  @override
  String iam_legalIntro(String terms, String privacy) {
    return 'By continuing you accept the $terms and the $privacy.';
  }

  @override
  String get iam_legalTerms => 'Terms';

  @override
  String get iam_legalPrivacy => 'Privacy Policy';

  @override
  String get iam_verifyHeading => 'Verification code';

  @override
  String get iam_verifyOfflineTip =>
      'If your connection drops, we\'ll keep your code so you can try again.';

  @override
  String get legal_title => 'Terms and privacy';

  @override
  String get legal_intro =>
      'A short summary of what Quadrapp does with your data. Quadrapp is free: there are no reservations, payments or tickets.';

  @override
  String get legal_receiveTitle => 'What we receive';

  @override
  String get legal_receiveBody =>
      'Your institutional email, to check that your institution allows you in and to send your one-time code. Your alert preferences and time slots. A device token, to send you the alerts you choose.';

  @override
  String get legal_neverTitle => 'What we never receive';

  @override
  String get legal_signOutTitle => 'When you sign out';

  @override
  String get legal_signOutBody =>
      'Quadrapp removes your session, your saved campus and the data it kept on this phone. Only your language stays.';

  @override
  String get legal_note =>
      'This summary doesn\'t replace the full Terms and Privacy Policy published on Quadrapp\'s website.';

  @override
  String iam_maskedSpoken(String first, String domain) {
    return '$first followed by hidden characters, at $domain';
  }

  @override
  String get iam_legalOpen => 'Opens a summary of the terms and privacy';

  @override
  String get eta_sheetTitle => 'When do you arrive?';

  @override
  String get eta_close => 'Close';

  @override
  String get eta_useLocation => 'Use my location';

  @override
  String get eta_locationBody =>
      'We calculate the time on your phone. Quadrapp only receives the minutes, never your location.';

  @override
  String get eta_locationBlocked =>
      'Location is blocked for Quadrapp. You can allow it in your phone\'s settings, or pick the time yourself.';

  @override
  String get eta_locationOff =>
      'Your phone\'s location is off. Turn it on, or pick the time yourself.';

  @override
  String get eta_noPosition =>
      'This campus has no map position yet, so the time can\'t be estimated. Pick it yourself.';

  @override
  String get eta_manualTitle => 'Or pick the time yourself';

  @override
  String get eta_minutesUnit => 'min';

  @override
  String get eta_stepHint => 'Adjusts in steps of 5 minutes.';

  @override
  String eta_minutesChip(int minutes) {
    return '$minutes min';
  }

  @override
  String eta_minutesSpoken(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get eta_less => 'Less time';

  @override
  String get eta_more => 'More time';

  @override
  String get eta_done => 'Done';

  @override
  String get eta_sourceManual => 'chosen by you';

  @override
  String get eta_change => 'Change arrival time';

  @override
  String home_greeting(String period) {
    String _temp0 = intl.Intl.selectLogic(
      period,
      {
        'morning': 'Good morning',
        'afternoon': 'Good afternoon',
        'other': 'Good evening',
      },
    );
    return '$_temp0';
  }

  @override
  String home_greetingNamed(String greeting, String name) {
    return '$greeting, $name';
  }

  @override
  String get home_question => 'Will I find a space when I arrive?';

  @override
  String get home_liveOnline => 'Online';

  @override
  String get home_liveConnecting => 'Connecting…';

  @override
  String get home_liveReconnecting => 'Reconnecting…';

  @override
  String get home_liveOffline => 'Offline';

  @override
  String get home_categoryHigh => 'Good availability';

  @override
  String get home_categoryLimited => 'Limited availability';

  @override
  String get home_categoryLow => 'Low availability';

  @override
  String get home_categoryNone => 'No estimate';

  @override
  String get home_statementHigh => 'Yes, you\'ll probably find a space.';

  @override
  String get home_statementLimited =>
      'You might find a space, but it\'s not certain.';

  @override
  String get home_statementLow => 'You\'re unlikely to find a space.';

  @override
  String get home_statementNeedsEta =>
      'Tell us when you arrive to estimate your availability.';

  @override
  String get home_statementUnavailable =>
      'We couldn\'t estimate your availability right now.';

  @override
  String get home_chooseEta => 'Set arrival time';

  @override
  String get home_statArrive => 'Arrive in';

  @override
  String get home_statNow => 'Now';

  @override
  String get home_statConfidence => 'Confidence';

  @override
  String home_minutes(int minutes) {
    return '$minutes min';
  }

  @override
  String home_freeCount(int count) {
    return '$count free';
  }

  @override
  String home_ofSpaces(int total) {
    return 'of $total spaces';
  }

  @override
  String home_ofSpacesUnknown(int total, int unknown) {
    return 'of $total spaces · $unknown no data';
  }

  @override
  String get home_confidenceHigh => 'High';

  @override
  String get home_confidenceMedium => 'Medium';

  @override
  String get home_confidenceLow => 'Low';

  @override
  String home_forecastAge(String age) {
    return 'forecast $age';
  }

  @override
  String get home_lowConfidence =>
      'This estimate is based on limited information.';

  @override
  String home_nextFree(int min, int max) {
    return 'A space is expected to free up in $min–$max min.';
  }

  @override
  String get home_nextNone =>
      'We can\'t estimate the wait: no exits were recorded recently.';

  @override
  String get home_changeTitle => 'How it may change';

  @override
  String home_horizonSpoken(int minutes, int percent, String category) {
    return 'In $minutes min: $percent%, $category';
  }

  @override
  String home_horizonMissing(int minutes) {
    return 'In $minutes min: not available';
  }

  @override
  String get home_horizonsHint => 'Opens the forecast';

  @override
  String get home_privacyLine =>
      'We share arrival minutes, never your location.';

  @override
  String get home_pickAnother => 'Choose another campus';

  @override
  String get home_partialAdvice =>
      'We couldn\'t load your arrival estimate. Pull down to try again.';

  @override
  String get home_partialOccupancy =>
      'We couldn\'t load the current spaces. Pull down to try again.';

  @override
  String get home_partialForecast =>
      'Some forecasts aren\'t available right now.';

  @override
  String get lots_loading => 'Loading parking lots…';

  @override
  String get lots_emptyTitle => 'No parking lots yet';

  @override
  String get lots_emptyMessage =>
      'Your institution hasn\'t set up any parking lots yet. Pull down to check again.';

  @override
  String get lots_errorTitle => 'Couldn\'t load parking lots';

  @override
  String get lots_errorNetwork =>
      'You\'re offline. Check your connection and try again.';

  @override
  String get lots_errorGeneric =>
      'Something went wrong on our side. Try again in a moment.';

  @override
  String get lots_retry => 'Try again';

  @override
  String get lots_offlineBanner =>
      'You\'re offline. Showing the latest data we have.';

  @override
  String lots_updatedAgo(String age) {
    return 'Updated $age';
  }

  @override
  String time_agoSeconds(int count) {
    return '$count s ago';
  }

  @override
  String time_agoMinutes(int count) {
    return '$count min ago';
  }

  @override
  String time_agoHours(int count) {
    return '$count h ago';
  }

  @override
  String lots_staleSince(String time) {
    return 'No new data since $time. What you see may be out of date.';
  }

  @override
  String get lots_noCurrentData => 'No current data';

  @override
  String get lots_noCurrentDataHint => 'This lot has no published layout yet.';

  @override
  String get space_free => 'Free';

  @override
  String get space_occupied => 'Occupied';

  @override
  String get space_unknown => 'No data';

  @override
  String get settings_moreSoon =>
      'More settings, like alerts and language, arrive in a later update.';

  @override
  String get settings_role => 'Role';

  @override
  String get settings_roleDriver => 'Driver';

  @override
  String get settings_roleOperator => 'Operator';

  @override
  String get settings_roleAdmin => 'Administrator';

  @override
  String settings_accountSemantics(
    String email,
    String institution,
    String role,
  ) {
    return 'Account: $email, $institution, role $role';
  }

  @override
  String get signOut_action => 'Sign out';

  @override
  String get signOut_signingOut => 'Signing out…';

  @override
  String get signOut_confirmTitle => 'Sign out?';

  @override
  String signOut_confirmMessage(String email) {
    return 'You\'ll sign out of $email on this device and will need a code to sign in again.';
  }

  @override
  String get signOut_cancel => 'Cancel';

  @override
  String get signOut_error => 'We couldn\'t sign you out. Try again.';

  @override
  String get debug_open => 'Open mock controls';

  @override
  String get debug_title => 'Mock controls';

  @override
  String get debug_credentials =>
      'Test users: conductor@upc.edu.pe (driver) and administrador@upc.edu.pe (admin) · code 123456';

  @override
  String get debug_forceNetworkError => 'No network';

  @override
  String get debug_forceNetworkErrorHelp =>
      'Every call fails as if the phone were offline.';

  @override
  String get debug_realtimeOutage => 'Realtime outage';

  @override
  String get debug_realtimeOutageHelp =>
      'The live connection drops (the status chip shows Reconnecting); REST calls keep working.';

  @override
  String get debug_locationPermission => 'Location permission';

  @override
  String get debug_locationGranted => 'Granted';

  @override
  String get debug_locationDenied => 'Not granted yet';

  @override
  String get debug_locationDeniedForever => 'Denied for good';

  @override
  String get debug_locationOff => 'Location off';

  @override
  String get debug_denyLocationPrompt => 'Deny the permission dialog';

  @override
  String get debug_denyLocationPromptHelp =>
      'Asking for the permission fails: the first time it stays denied, the second time for good.';

  @override
  String get debug_force401 => '401 on protected calls';

  @override
  String get debug_force401Help =>
      'Protected calls answer 401 (access token rejected).';

  @override
  String get debug_force429 => '429 on code requests';

  @override
  String get debug_force429Help =>
      'Requesting a code answers 429 with a 45 second wait.';

  @override
  String get debug_sessionExpired => 'Session expired';

  @override
  String get debug_sessionExpiredHelp =>
      'The refresh token is rejected (401): the session expires.';

  @override
  String get debug_forceConsole403 => '403 on console routes';

  @override
  String get debug_forceConsole403Help =>
      'The console overview and the devices answer 403, as for a driver (TS17).';

  @override
  String get debug_forceConsolePartial => 'Partial console overview';

  @override
  String get debug_forceConsolePartialHelp =>
      'The overview answers 200 without the expected saturation (TS17 scenario 3).';

  @override
  String get debug_forceDeviceRegisterFailure => 'Device registration fails';

  @override
  String get debug_forceDeviceRegisterFailureHelp =>
      'Registering a device answers a server error (500).';

  @override
  String get debug_actions => 'Actions';

  @override
  String get debug_expireNow => 'Expire the session now';

  @override
  String get debug_probe => 'Call a protected endpoint';

  @override
  String get debug_resultRefreshed => 'The session was renewed.';

  @override
  String debug_resultOk(int count) {
    return 'Protected call OK: $count parking lots.';
  }

  @override
  String debug_resultFailure(String type) {
    return 'Failed: $type';
  }

  @override
  String get debug_resetData => 'Reset test data';

  @override
  String get debug_resultReset => 'Test data reset to the seed.';

  @override
  String get debug_resultLabel => 'Last result';

  @override
  String get zones_filterAction => 'Sort and filter';

  @override
  String get zones_filterActionActive => 'Sort and filter, active';

  @override
  String get zones_filterTitle => 'Sort and filter';

  @override
  String get zones_filterClose => 'Close';

  @override
  String get zones_orderLabel => 'Order';

  @override
  String get zones_orderByName => 'By pavilion';

  @override
  String get zones_orderMostFree => 'Most free spaces first';

  @override
  String get zones_onlyFree => 'Only pavilions with free spaces';

  @override
  String get zones_filterReset => 'Reset';

  @override
  String get zones_filterDone => 'Done';

  @override
  String get zones_capacity => 'Capacity';

  @override
  String get zones_free => 'Free';

  @override
  String get zones_unknown => 'No data';

  @override
  String get zones_unknownBanner =>
      'Spaces with no data aren\'t counted as free until their sensor reports again.';

  @override
  String zones_freeCount(int count) {
    return '$count free';
  }

  @override
  String zones_occupiedCount(int count) {
    return '$count occupied';
  }

  @override
  String zones_unknownCount(int count) {
    return '$count no data';
  }

  @override
  String get zones_availabilityGood => 'Good';

  @override
  String get zones_availabilityLimited => 'Limited';

  @override
  String get zones_availabilityFull => 'Full';

  @override
  String get zones_availabilityNoData => 'No data';

  @override
  String zones_zoneSemantics(
    String name,
    String description,
    String free,
    String unknown,
    String availability,
  ) {
    return '$name$description: $free, $unknown, availability $availability';
  }

  @override
  String get zones_openLevels => 'Opens the levels of the pavilion';

  @override
  String get zones_openLevelMap => 'Opens the map of the level';

  @override
  String get zones_loading => 'Loading the pavilions…';

  @override
  String get zones_emptyTitle => 'This lot has no pavilions yet';

  @override
  String get zones_emptyMessage => 'Pull down to check again.';

  @override
  String get zones_noFreeTitle => 'No pavilion has free spaces right now';

  @override
  String get zones_noFreeMessage =>
      'Show all of them to see how full each one is.';

  @override
  String get zones_showAll => 'Show all pavilions';

  @override
  String get zones_partialLayout =>
      'We couldn\'t load the pavilions. Showing the totals of the lot.';

  @override
  String get zones_partialOccupancy =>
      'We couldn\'t load availability. Showing the pavilions without counts.';

  @override
  String get zones_notFoundTitle => 'We couldn\'t find this pavilion';

  @override
  String get zones_levelNotFoundTitle => 'We couldn\'t find this level';

  @override
  String get zones_notFoundMessage =>
      'The layout may have changed. Go back to the list.';

  @override
  String get zones_backToZones => 'Back to parking';

  @override
  String get zones_levelsHeading => 'Levels';

  @override
  String get zones_viewLabel => 'View';

  @override
  String get zones_viewMap => 'Map';

  @override
  String get zones_viewList => 'List';

  @override
  String zones_mapSummary(String free, String occupied, String unknown) {
    return 'Map: $free, $occupied, $unknown';
  }

  @override
  String get zones_noMap =>
      'This level doesn\'t have a map yet. Showing the list.';

  @override
  String get zones_filterAll => 'All';

  @override
  String get zones_filterFree => 'Free';

  @override
  String get zones_filterUnknown => 'No data';

  @override
  String get zones_listEmpty => 'No spaces match this filter.';

  @override
  String zones_spaceSemantics(String label, String state) {
    return 'Space $label: $state';
  }

  @override
  String get zones_reasonNoHeartbeat => 'No signal from the sensor';

  @override
  String get zones_reasonLowBattery => 'Sensor battery is low';

  @override
  String get zones_reasonNoSensor => 'No sensor assigned';

  @override
  String get zones_reasonWaiting => 'Waiting for data';

  @override
  String get forecast_etaAction => 'Choose your arrival time';

  @override
  String get forecast_ifLeaveNow => 'If you leave now';

  @override
  String get forecast_yourArrivalTime => 'Your arrival time';

  @override
  String forecast_arriveIn(int minutes) {
    return 'You arrive in $minutes min';
  }

  @override
  String get forecast_etaManual => 'Set by you';

  @override
  String get forecast_etaEstimating => 'Estimating…';

  @override
  String get forecast_etaPrompt => 'Pick when you arrive';

  @override
  String get forecast_etaPromptCaption => 'Your arrival';

  @override
  String forecast_heroSemantics(
    String caption,
    String headline,
    String source,
  ) {
    return '$caption. $headline. $source';
  }

  @override
  String get forecast_yourArrivalTag => 'Your arrival';

  @override
  String forecast_confidenceLine(String level) {
    return 'Confidence: $level';
  }

  @override
  String get forecast_rowMissing => 'No forecast for this time';

  @override
  String get forecast_rowExpired => 'Forecast expired';

  @override
  String get forecast_rowNoOdds => 'Arrival odds not available';

  @override
  String get forecast_rowHint => 'Opens the forecast details';

  @override
  String forecast_rowSpoken(
    int minutes,
    String time,
    int percent,
    String category,
    String confidence,
    String tag,
  ) {
    return '$minutes min, at $time: $percent percent, $category. $confidence.$tag';
  }

  @override
  String forecast_rowSpokenOther(
    int minutes,
    String time,
    String state,
    String tag,
  ) {
    return '$minutes min, at $time: $state.$tag';
  }

  @override
  String get forecast_note =>
      'Estimate based on historical occupancy, flow, the academic calendar and events.';

  @override
  String forecast_generatedAt(String time, String age) {
    return 'Generated at $time · $age';
  }

  @override
  String get forecast_partialMissing =>
      'Some forecasts are missing. Showing the ones we have.';

  @override
  String get forecast_partialExpired =>
      'Some forecasts have expired, so they aren\'t shown as current.';

  @override
  String get forecast_partialDetails =>
      'We couldn\'t load the forecast details. Showing the arrival odds.';

  @override
  String get forecast_lowConfidenceBanner =>
      'There is little history for this lot. Treat these numbers as a rough guide.';

  @override
  String get forecast_emptyTitle => 'No forecasts yet';

  @override
  String get forecast_emptyMessage =>
      'This lot doesn\'t have enough history yet. Check back later.';

  @override
  String get forecast_loading => 'Loading forecasts…';

  @override
  String forecast_detailTitle(int minutes) {
    return 'Forecast in $minutes min';
  }

  @override
  String get forecast_detailClose => 'Close';

  @override
  String forecast_detailForTime(String time) {
    return 'For $time';
  }

  @override
  String get forecast_detailChance => 'Chance of finding a space';

  @override
  String get forecast_detailOccupancy => 'Expected occupancy';

  @override
  String get forecast_detailSaturation => 'Saturation';

  @override
  String forecast_detailFillsAt(String time, String percent) {
    return 'Expected to fill up at $time ($percent%)';
  }

  @override
  String get forecast_detailNoSaturation => 'Not expected to fill up';

  @override
  String get forecast_detailGenerated => 'Generated';

  @override
  String get forecast_detailValid => 'Valid for';

  @override
  String forecast_detailValidMinutes(int minutes) {
    return '$minutes more min';
  }

  @override
  String get forecast_detailValidSoon => 'Less than a minute';

  @override
  String get forecast_detailExpired => 'Expired';

  @override
  String get forecast_detailSource => 'Source';

  @override
  String get forecast_sourceModel => 'Main model';

  @override
  String get forecast_sourceFallback =>
      'Contingency estimate (limited history)';

  @override
  String forecast_detailModel(String version) {
    return 'Model $version';
  }

  @override
  String get forecast_detailLowConfidence =>
      'This forecast relies on limited information. Use it as a reference.';

  @override
  String get forecast_detailExpiredNote =>
      'This forecast has expired and isn\'t shown as current.';

  @override
  String get forecast_detailMissingNote =>
      'There is no forecast for this time yet.';

  @override
  String get alerts_loading => 'Loading your alerts…';

  @override
  String get alerts_errorTitle => 'Couldn\'t load your alerts';

  @override
  String get alerts_partialPreferences => 'We couldn\'t load your preferences.';

  @override
  String get alerts_partialSlots => 'We couldn\'t load your time slots.';

  @override
  String get alerts_pushTitle => 'Receive notifications';

  @override
  String get alerts_pushOn => 'We\'ll alert you on this phone.';

  @override
  String get alerts_pushOff =>
      'Off: you won\'t get alerts, even for the slots you follow.';

  @override
  String get alerts_sectionWhen => 'Tell me when';

  @override
  String get alerts_whenOffHint =>
      'Turn notifications on to choose which alerts you get.';

  @override
  String get alerts_saturationTitle => 'A lot is expected to fill up';

  @override
  String get alerts_saturationHelp => 'In the time slots you follow';

  @override
  String get alerts_lowArrivalTitle => 'Availability is low';

  @override
  String get alerts_lowArrivalHelp => 'For your estimated arrival time';

  @override
  String get alerts_staleTitle => 'Data is out of date';

  @override
  String get alerts_staleHelp => 'More than 10 minutes without a reading';

  @override
  String get alerts_eventsTitle => 'Events change things';

  @override
  String get alerts_eventsHelp => 'Only campus calendar events';

  @override
  String get alerts_slotsTitle => 'Your time slots';

  @override
  String get alerts_slotsEmptyTitle => 'You don\'t follow any slot yet';

  @override
  String get alerts_slotsEmptyMessage =>
      'Pick the days and time you usually arrive and we\'ll warn you if the lot is expected to fill up.';

  @override
  String get alerts_addSlot => 'Add a time slot';

  @override
  String get alerts_slotPaused => 'Paused';

  @override
  String alerts_slotSwitchLabel(String lot, String days, String time) {
    return 'Alerts for $lot, $days, $time';
  }

  @override
  String alerts_slotDeleteTooltip(String lot, String days, String time) {
    return 'Delete the slot for $lot, $days, $time';
  }

  @override
  String get alerts_deleteTitle => 'Delete this time slot?';

  @override
  String alerts_deleteSubject(String lot, String days, String time) {
    return '$lot · $days · $time';
  }

  @override
  String get alerts_deleteMessage =>
      'You\'ll stop getting alerts for this slot. Your other slots stay.';

  @override
  String get alerts_deleteConfirm => 'Delete';

  @override
  String get alerts_deleteCancel => 'Cancel';

  @override
  String get alerts_connectivityTitle => 'Intermittent connection';

  @override
  String get alerts_connectivityValue => 'Automatic';

  @override
  String get alerts_connectivityHelp =>
      'Keeps the last lookup and syncs when the connection returns.';

  @override
  String get alerts_privacy =>
      'Your preferences stay in your account. Quadrapp doesn\'t receive your location; only arrival minutes.';

  @override
  String get alerts_noticePermissionDenied =>
      'We can\'t alert you without the notifications permission.';

  @override
  String get alerts_noticePermissionBlocked =>
      'Notifications are blocked. Turn them on in your phone\'s settings.';

  @override
  String get alerts_noticeActivationFailed =>
      'We couldn\'t turn on notifications on this phone. Try again later.';

  @override
  String get alerts_noticeSaveFailed =>
      'We couldn\'t save your preferences. Try again.';

  @override
  String get alerts_noticeSlotFailed =>
      'We couldn\'t update the time slot. Try again.';

  @override
  String get alerts_noticeSlotDuplicate =>
      'You already follow that time slot, so this one stays paused.';

  @override
  String get alerts_noticeDeleteFailed =>
      'We couldn\'t delete the time slot. Try again.';

  @override
  String get alerts_noticeDeleted => 'Time slot deleted';

  @override
  String get alerts_noticeCreated => 'Time slot added';

  @override
  String get alerts_noticeCreatedDenied =>
      'Slot added, but without the notifications permission we can\'t alert you.';

  @override
  String get alerts_noticeCreatedBlocked =>
      'Slot added. Notifications are blocked: turn them on in your phone\'s settings.';

  @override
  String get alerts_noticeCreatedNoDevice =>
      'Slot added, but we couldn\'t turn on notifications on this phone.';

  @override
  String get alerts_sheetTitle => 'New time slot';

  @override
  String get alerts_sheetSubtitle =>
      'We\'ll let you know if we expect it to fill up at this time.';

  @override
  String get alerts_sheetClose => 'Close';

  @override
  String get alerts_sheetLot => 'Parking lot';

  @override
  String get alerts_sheetDays => 'Days';

  @override
  String get alerts_sheetFrom => 'From';

  @override
  String get alerts_sheetTo => 'To';

  @override
  String get alerts_sheetPickTime => 'Pick a time';

  @override
  String get alerts_sheetPermissionHint =>
      'We\'ll ask for the notifications permission if you haven\'t allowed it yet.';

  @override
  String get alerts_sheetCreate => 'Add time slot';

  @override
  String get alerts_sheetCreating => 'Adding…';

  @override
  String get alerts_errorDays => 'Pick at least one day.';

  @override
  String get alerts_errorTimes => 'Pick a start and an end time.';

  @override
  String get alerts_errorOrder => 'The end time must be after the start.';

  @override
  String get alerts_errorDuplicate => 'You already follow this time slot.';

  @override
  String get alerts_errorNoLot => 'Choose a parking lot.';

  @override
  String get legal_neverBody =>
      'Your location. Your arrival time is calculated on your phone and only the minutes reach Quadrapp. If you turn on live traffic, your approximate location (about 100 m) goes to Google, only to calculate that time; Quadrapp doesn\'t receive it or store it. We don\'t read license plates and we don\'t handle payments.';

  @override
  String get eta_sourceTraffic => 'with live traffic';

  @override
  String get eta_sourceDevice => 'estimated on your phone';

  @override
  String eta_updatedAgo(String age) {
    return 'Your arrival time updated $age';
  }

  @override
  String get eta_autoTitle => 'Calculate my arrival automatically';

  @override
  String get eta_autoOn =>
      'We estimate how long you take from where you are and keep it up to date.';

  @override
  String get eta_autoOff =>
      'Off: we won\'t use your location. Only the time you pick below counts.';

  @override
  String get eta_trafficTitle => 'Include live traffic';

  @override
  String get eta_trafficOn =>
      'Your approximate location (about 100 m) goes to Google to calculate traffic, only for this estimate. Quadrapp doesn\'t receive it or store it.';

  @override
  String get eta_trafficOff =>
      'Off: your location never leaves your phone. The estimate doesn\'t include traffic.';

  @override
  String eta_currentSummary(int minutes, String source) {
    return 'Now: $minutes min · $source';
  }

  @override
  String get eta_manualCountdown =>
      'Chosen by you. It goes down by itself as time passes.';

  @override
  String get eta_backToAuto => 'Go back to automatic';

  @override
  String get eta_tooFar =>
      'You\'re more than 2 hours from campus. Advice starts once you\'re closer; you can pick a time meanwhile.';

  @override
  String get home_statementTooFar =>
      'You\'re more than 2 hours from campus. We\'ll show what to expect once you\'re closer. You can pick a time meanwhile.';

  @override
  String get home_arriveNow => 'You\'re here';

  @override
  String get home_privacyLineTraffic =>
      'Quadrapp receives only arrival minutes. With live traffic on, your approximate location goes to Google.';

  @override
  String home_changeEta(int eta, int previous) {
    return 'Updated: you arrive in $eta min (was $previous)';
  }

  @override
  String home_changeChance(int percent, int previous) {
    return 'Chance of a space: $percent% (was $previous%)';
  }

  @override
  String home_changeCategory(String category, String previous) {
    return 'Now $category (was $previous)';
  }

  @override
  String get forecast_etaTraffic => 'With live traffic';

  @override
  String get forecast_etaDevice => 'Estimated on your phone';

  @override
  String get forecast_tooFar => 'More than 2 hours away';

  @override
  String get debug_simulateTrip => 'Simulate the drive to campus';

  @override
  String get debug_simulateTripHelp =>
      'The simulated phone drives to the chosen campus at 150 km/h: the arrival time goes down on its own and the advice updates.';

  @override
  String get debug_heavyTraffic => 'Heavy traffic';

  @override
  String get debug_heavyTrafficHelp =>
      'The simulated maps provider multiplies the trip by 1.8 instead of 1.3.';

  @override
  String get debug_routesOutage => 'Maps provider down';

  @override
  String get debug_routesOutageHelp =>
      'The app falls back to the estimate on the phone, without showing an error.';

  @override
  String get eta_updatedNow => 'Your arrival time was just updated';
}
