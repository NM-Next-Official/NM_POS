import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'languages/app_localizations.dart';
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
    Locale('bn'),
    Locale('en'),
    Locale('hi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'NM POS'**
  String get appTitle;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'START'**
  String get start;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your e-mail'**
  String get enterYourEmail;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get enterYourPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Your Business Name'**
  String get businessName;

  /// No description provided for @businessAddress.
  ///
  /// In en, this message translates to:
  /// **'Business Address'**
  String get businessAddress;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @enterYourOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter Your OTP'**
  String get enterYourOtp;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot ?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t Have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @sendOtp.
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// No description provided for @makeBusinessLite.
  ///
  /// In en, this message translates to:
  /// **'Make Your Business Lite'**
  String get makeBusinessLite;

  /// No description provided for @yourBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Your Business Name'**
  String get yourBusinessName;

  /// No description provided for @pleaseEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get pleaseEnterValidEmail;

  /// No description provided for @pleaseEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @pleaseEnterFirstName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your first name'**
  String get pleaseEnterFirstName;

  /// No description provided for @pleaseEnterLastName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your last name'**
  String get pleaseEnterLastName;

  /// No description provided for @pleaseEnterBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your business name'**
  String get pleaseEnterBusinessName;

  /// No description provided for @otpSentMessage.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to your email!'**
  String get otpSentMessage;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @scanner.
  ///
  /// In en, this message translates to:
  /// **'Scanner'**
  String get scanner;

  /// No description provided for @discounts.
  ///
  /// In en, this message translates to:
  /// **'Discounts'**
  String get discounts;

  /// No description provided for @pos.
  ///
  /// In en, this message translates to:
  /// **'POS'**
  String get pos;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @bengali.
  ///
  /// In en, this message translates to:
  /// **'Bangla'**
  String get bengali;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

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

  /// No description provided for @chooseAccountType.
  ///
  /// In en, this message translates to:
  /// **'Choose Account Type'**
  String get chooseAccountType;

  /// No description provided for @businessOwner.
  ///
  /// In en, this message translates to:
  /// **'Business Owner'**
  String get businessOwner;

  /// No description provided for @businessOwnerDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage one or more shops with staff'**
  String get businessOwnerDesc;

  /// No description provided for @personalBusiness.
  ///
  /// In en, this message translates to:
  /// **'Personal Business'**
  String get personalBusiness;

  /// No description provided for @personalBusinessDesc.
  ///
  /// In en, this message translates to:
  /// **'Single-user small business'**
  String get personalBusinessDesc;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @emailTab.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailTab;

  /// No description provided for @phoneTab.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneTab;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhone;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get invalidPhone;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get phoneRequired;

  /// No description provided for @noAccountYet.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccountYet;

  /// No description provided for @alreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyRegistered;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLink;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @creatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating account...'**
  String get creatingAccount;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get loginFailed;

  /// No description provided for @signupFailed.
  ///
  /// In en, this message translates to:
  /// **'Signup failed. Please try again.'**
  String get signupFailed;

  /// No description provided for @businessDetails.
  ///
  /// In en, this message translates to:
  /// **'Business Details'**
  String get businessDetails;

  /// No description provided for @personalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get personalDetails;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetails;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// No description provided for @emailOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Email or Phone'**
  String get emailOrPhone;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how to receive your reset code'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @sendingCode.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sendingCode;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to'**
  String get otpSubtitle;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendIn(int seconds);

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @verifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying...'**
  String get verifying;

  /// No description provided for @otpInvalid.
  ///
  /// In en, this message translates to:
  /// **'Incorrect code. Please try again.'**
  String get otpInvalid;

  /// No description provided for @otpExpired.
  ///
  /// In en, this message translates to:
  /// **'Code expired. Request a new one.'**
  String get otpExpired;

  /// No description provided for @newPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordTitle;

  /// No description provided for @newPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a strong password for your account'**
  String get newPasswordSubtitle;

  /// No description provided for @passwordStrength.
  ///
  /// In en, this message translates to:
  /// **'Password strength'**
  String get passwordStrength;

  /// No description provided for @weak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get weak;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @strong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get strong;

  /// No description provided for @resetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully!'**
  String get resetSuccess;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @accountNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this information'**
  String get accountNotFound;

  /// No description provided for @otpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Code sent'**
  String get otpSentTo;

  /// No description provided for @didNotReceive.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code?'**
  String get didNotReceive;
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
      <String>['bn', 'en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
