// Minimal i18n layer. The full app stays in Roman-Urdu mixed with English
// since that matches how customers actually search ("mujhe plumber chahiye").
// When the user picks Urdu, key UI labels switch to native Urdu script.
//
// Usage:  Strings.of(context).home   →  'Home' or 'گھر'
//
// Pick the language via `AppState.setLanguage('urdu')`.
//
// Adding new strings: add the key to `_en`, `_ur`, and `_ru` maps.

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class Strings {
  final String lang;
  const Strings._(this.lang);

  static Strings of(BuildContext context) {
    final lang = context.select<AppState, String>((s) => s.language);
    return Strings._(lang);
  }

  String _t(String enWord, String urWord, String roWord) {
    switch (lang) {
      case 'urdu': return urWord;
      case 'roman_urdu': return roWord;
      default: return enWord;
    }
  }

  // Nav + general
  String get home          => _t('Home', 'گھر', 'Home');
  String get history       => _t('History', 'تاریخ', 'History');
  String get track         => _t('Track', 'ٹریک', 'Track');
  String get messages      => _t('Messages', 'پیغامات', 'Messages');
  String get profile       => _t('Profile', 'پروفائل', 'Profile');
  String get search        => _t('Search for services...', 'خدمات تلاش کریں...', 'Service dhoondein...');
  String get bookNow       => _t('Book Now', 'ابھی بک کریں', 'Abhi Book Karein');
  String get welcomeBack   => _t('Welcome Back', 'خوش آمدید', 'Wapas khush amdeed');
  String get createAccount => _t('Create Account', 'اکاؤنٹ بنائیں', 'Account banayein');
  String get signIn        => _t('Sign In', 'سائن ان', 'Sign In');
  String get signOut       => _t('Sign Out', 'سائن آؤٹ', 'Sign Out');

  // Worker hub
  String get earningsToday => _t("Today's Earnings", 'آج کی کمائی', 'Aaj ki Kamai');
  String get thisWeek      => _t('This Week', 'اس ہفتے', 'Iss Hafte');
  String get jobsToday     => _t('Jobs Today', 'آج کے کام', 'Aaj ke Kam');
  String get rating        => _t('Rating', 'ریٹنگ', 'Rating');
  String get activeRequests=> _t('Active Requests', 'فعال درخواستیں', 'Active Requests');
  String get youAreOnline  => _t('You are Online', 'آپ آن لائن ہیں', 'Aap Online Hain');
  String get youAreOffline => _t('You are Offline', 'آپ آف لائن ہیں', 'Aap Offline Hain');
  String get noJobsYet     => _t('No job requests yet', 'ابھی تک کوئی درخواست نہیں', 'Abhi tak koi request nahi');

  // Booking
  String get pickSlot      => _t('Pick a time slot', 'وقت منتخب کریں', 'Waqt chunein');
  String get scheduledTime => _t('Scheduled Time', 'مقررہ وقت', 'Tay shuda waqt');
  String get estimatedCost => _t('Estimated Cost', 'تخمینہ لاگت', 'Andazan Laagat');
  String get bookingConfirmed => _t('Booking Confirmed!', 'بکنگ تصدیق شدہ!', 'Booking Confirm Ho Gayi!');
  String get viewInvoice   => _t('View Invoice', 'انوائس دیکھیں', 'Invoice Dekhein');
  String get trackProvider => _t('Track Provider', 'کاریگر ٹریک کریں', 'Karigar Track Karein');

  // Categories
  String get electrician   => _t('Electrician', 'بجلی کا کام', 'Electrician');
  String get plumber       => _t('Plumber', 'پلمبر', 'Plumber');
  String get acRepair      => _t('AC Repair', 'اے سی مرمت', 'AC Marammat');
  String get cleaning      => _t('Cleaning', 'صفائی', 'Safai');
  String get carpenter     => _t('Carpenter', 'بڑھئی', 'Carpenter');

  // Whether to use right-to-left text direction
  bool get isRTL => lang == 'urdu';
}
