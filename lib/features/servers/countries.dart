import '../../core/l10n/strings.dart';

/// ISO 3166-1 alpha-2 code -> (English, Persian). Unknown codes show as-is.
const Map<String, (String, String)> _countries = {
  'AE': ('United Arab Emirates', 'امارات'),
  'AL': ('Albania', 'آلبانی'),
  'AM': ('Armenia', 'ارمنستان'),
  'AR': ('Argentina', 'آرژانتین'),
  'AT': ('Austria', 'اتریش'),
  'AU': ('Australia', 'استرالیا'),
  'AZ': ('Azerbaijan', 'آذربایجان'),
  'BE': ('Belgium', 'بلژیک'),
  'BG': ('Bulgaria', 'بلغارستان'),
  'BH': ('Bahrain', 'بحرین'),
  'BR': ('Brazil', 'برزیل'),
  'CA': ('Canada', 'کانادا'),
  'CH': ('Switzerland', 'سوئیس'),
  'CN': ('China', 'چین'),
  'CY': ('Cyprus', 'قبرس'),
  'CZ': ('Czechia', 'چک'),
  'DE': ('Germany', 'آلمان'),
  'DK': ('Denmark', 'دانمارک'),
  'EE': ('Estonia', 'استونی'),
  'ES': ('Spain', 'اسپانیا'),
  'FI': ('Finland', 'فنلاند'),
  'FR': ('France', 'فرانسه'),
  'GB': ('United Kingdom', 'انگلستان'),
  'GE': ('Georgia', 'گرجستان'),
  'GR': ('Greece', 'یونان'),
  'HK': ('Hong Kong', 'هنگ‌کنگ'),
  'HU': ('Hungary', 'مجارستان'),
  'IE': ('Ireland', 'ایرلند'),
  'IL': ('Israel', 'اسرائیل'),
  'IN': ('India', 'هند'),
  'IQ': ('Iraq', 'عراق'),
  'IR': ('Iran', 'ایران'),
  'IS': ('Iceland', 'ایسلند'),
  'IT': ('Italy', 'ایتالیا'),
  'JP': ('Japan', 'ژاپن'),
  'KR': ('South Korea', 'کره جنوبی'),
  'KW': ('Kuwait', 'کویت'),
  'KZ': ('Kazakhstan', 'قزاقستان'),
  'LT': ('Lithuania', 'لیتوانی'),
  'LU': ('Luxembourg', 'لوکزامبورگ'),
  'LV': ('Latvia', 'لتونی'),
  'MD': ('Moldova', 'مولداوی'),
  'MX': ('Mexico', 'مکزیک'),
  'MY': ('Malaysia', 'مالزی'),
  'NL': ('Netherlands', 'هلند'),
  'NO': ('Norway', 'نروژ'),
  'OM': ('Oman', 'عمان'),
  'PL': ('Poland', 'لهستان'),
  'PT': ('Portugal', 'پرتغال'),
  'QA': ('Qatar', 'قطر'),
  'RO': ('Romania', 'رومانی'),
  'RS': ('Serbia', 'صربستان'),
  'RU': ('Russia', 'روسیه'),
  'SA': ('Saudi Arabia', 'عربستان'),
  'SE': ('Sweden', 'سوئد'),
  'SG': ('Singapore', 'سنگاپور'),
  'SK': ('Slovakia', 'اسلواکی'),
  'TH': ('Thailand', 'تایلند'),
  'TR': ('Türkiye', 'ترکیه'),
  'TW': ('Taiwan', 'تایوان'),
  'UA': ('Ukraine', 'اوکراین'),
  'US': ('United States', 'آمریکا'),
  'VN': ('Vietnam', 'ویتنام'),
  'ZA': ('South Africa', 'آفریقای جنوبی'),
};

String countryName(S s, String? code) {
  if (code == null) return s.otherLocations;
  final names = _countries[code];
  if (names == null) return code;
  return s.isFa ? rtl(names.$2) : names.$1;
}

/// The flag emoji for a two-letter code (regional indicator pair).
String flagEmoji(String code) {
  if (code.length != 2) return '';
  final upper = code.toUpperCase();
  return String.fromCharCodes([
    0x1F1E6 + upper.codeUnitAt(0) - 0x41,
    0x1F1E6 + upper.codeUnitAt(1) - 0x41,
  ]);
}
