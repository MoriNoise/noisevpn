import '../../core/l10n/strings.dart';
import 'server_models.dart';

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

/// English names for the codes [_countries] doesn't cover (shown in both
/// languages). From the flag set's countries.json.
const Map<String, String> _moreCountries = {
  'AD': "Andorra",
  'AF': "Afghanistan",
  'AG': "Antigua and Barbuda",
  'AI': "Anguilla",
  'AO': "Angola",
  'AQ': "Antarctica",
  'AS': "American Samoa",
  'AW': "Aruba",
  'AX': "Åland Islands",
  'BA': "Bosnia and Herzegovina",
  'BB': "Barbados",
  'BD': "Bangladesh",
  'BF': "Burkina Faso",
  'BI': "Burundi",
  'BJ': "Benin",
  'BL': "Saint Barthélemy",
  'BM': "Bermuda",
  'BN': "Brunei Darussalam",
  'BO': "Bolivia, Plurinational State of",
  'BQ': "Caribbean Netherlands",
  'BS': "Bahamas",
  'BT': "Bhutan",
  'BV': "Bouvet Island",
  'BW': "Botswana",
  'BY': "Belarus",
  'BZ': "Belize",
  'CC': "Cocos (Keeling) Islands",
  'CD': "Congo, the Democratic Republic of the",
  'CF': "Central African Republic",
  'CG': "Republic of the Congo",
  'CI': "Côte d'Ivoire",
  'CK': "Cook Islands",
  'CL': "Chile",
  'CM': "Cameroon",
  'CO': "Colombia",
  'CR': "Costa Rica",
  'CU': "Cuba",
  'CV': "Cape Verde",
  'CW': "Curaçao",
  'CX': "Christmas Island",
  'DJ': "Djibouti",
  'DM': "Dominica",
  'DO': "Dominican Republic",
  'DZ': "Algeria",
  'EC': "Ecuador",
  'EG': "Egypt",
  'EH': "Western Sahara",
  'ER': "Eritrea",
  'ET': "Ethiopia",
  'EU': "Europe",
  'FJ': "Fiji",
  'FK': "Falkland Islands (Malvinas)",
  'FM': "Micronesia, Federated States of",
  'FO': "Faroe Islands",
  'GA': "Gabon",
  'GD': "Grenada",
  'GF': "French Guiana",
  'GG': "Guernsey",
  'GH': "Ghana",
  'GI': "Gibraltar",
  'GL': "Greenland",
  'GM': "Gambia",
  'GN': "Guinea",
  'GP': "Guadeloupe",
  'GQ': "Equatorial Guinea",
  'GS': "South Georgia and the South Sandwich Islands",
  'GT': "Guatemala",
  'GU': "Guam",
  'GW': "Guinea-Bissau",
  'GY': "Guyana",
  'HM': "Heard Island and McDonald Islands",
  'HN': "Honduras",
  'HR': "Croatia",
  'HT': "Haiti",
  'ID': "Indonesia",
  'IM': "Isle of Man",
  'IO': "British Indian Ocean Territory",
  'JE': "Jersey",
  'JM': "Jamaica",
  'JO': "Jordan",
  'KE': "Kenya",
  'KG': "Kyrgyzstan",
  'KH': "Cambodia",
  'KI': "Kiribati",
  'KM': "Comoros",
  'KN': "Saint Kitts and Nevis",
  'KP': "Korea, Democratic People's Republic of",
  'KY': "Cayman Islands",
  'LA': "Laos (Lao People's Democratic Republic)",
  'LB': "Lebanon",
  'LC': "Saint Lucia",
  'LI': "Liechtenstein",
  'LK': "Sri Lanka",
  'LR': "Liberia",
  'LS': "Lesotho",
  'LY': "Libya",
  'MA': "Morocco",
  'MC': "Monaco",
  'ME': "Montenegro",
  'MF': "Saint Martin",
  'MG': "Madagascar",
  'MH': "Marshall Islands",
  'MK': "North Macedonia",
  'ML': "Mali",
  'MM': "Myanmar",
  'MN': "Mongolia",
  'MO': "Macao",
  'MP': "Northern Mariana Islands",
  'MQ': "Martinique",
  'MR': "Mauritania",
  'MS': "Montserrat",
  'MT': "Malta",
  'MU': "Mauritius",
  'MV': "Maldives",
  'MW': "Malawi",
  'MZ': "Mozambique",
  'NA': "Namibia",
  'NC': "New Caledonia",
  'NE': "Niger",
  'NF': "Norfolk Island",
  'NG': "Nigeria",
  'NI': "Nicaragua",
  'NP': "Nepal",
  'NR': "Nauru",
  'NU': "Niue",
  'NZ': "New Zealand",
  'PA': "Panama",
  'PE': "Peru",
  'PF': "French Polynesia",
  'PG': "Papua New Guinea",
  'PH': "Philippines",
  'PK': "Pakistan",
  'PM': "Saint Pierre and Miquelon",
  'PN': "Pitcairn",
  'PR': "Puerto Rico",
  'PS': "Palestine",
  'PW': "Palau",
  'PY': "Paraguay",
  'RE': "Réunion",
  'RW': "Rwanda",
  'SB': "Solomon Islands",
  'SC': "Seychelles",
  'SD': "Sudan",
  'SH': "Saint Helena, Ascension and Tristan da Cunha",
  'SI': "Slovenia",
  'SJ': "Svalbard and Jan Mayen Islands",
  'SL': "Sierra Leone",
  'SM': "San Marino",
  'SN': "Senegal",
  'SO': "Somalia",
  'SR': "Suriname",
  'SS': "South Sudan",
  'ST': "Sao Tome and Principe",
  'SV': "El Salvador",
  'SX': "Sint Maarten (Dutch part)",
  'SY': "Syrian Arab Republic",
  'SZ': "Kingdom of Eswatini",
  'TC': "Turks and Caicos Islands",
  'TD': "Chad",
  'TF': "French Southern Territories",
  'TG': "Togo",
  'TJ': "Tajikistan",
  'TK': "Tokelau",
  'TL': "Timor-Leste",
  'TM': "Turkmenistan",
  'TN': "Tunisia",
  'TO': "Tonga",
  'TT': "Trinidad and Tobago",
  'TV': "Tuvalu",
  'TZ': "Tanzania, United Republic of",
  'UG': "Uganda",
  'UM': "US Minor Outlying Islands",
  'UY': "Uruguay",
  'UZ': "Uzbekistan",
  'VA': "Holy See (Vatican City State)",
  'VC': "Saint Vincent and the Grenadines",
  'VE': "Venezuela, Bolivarian Republic of",
  'VG': "Virgin Islands, British",
  'VI': "Virgin Islands, U.S.",
  'VU': "Vanuatu",
  'WF': "Wallis and Futuna Islands",
  'WS': "Samoa",
  'XK': "Kosovo",
  'YE': "Yemen",
  'YT': "Mayotte",
  'ZM': "Zambia",
  'ZW': "Zimbabwe",
};

/// Other ways remarks name a country.
const Map<String, String> _aliases = {
  'UK': 'GB',
  'USA': 'US',
  'UAE': 'AE',
  'KSA': 'SA',
  'HOLLAND': 'NL',
  'ENGLAND': 'GB',
  'BRITAIN': 'GB',
  'AMERICA': 'US',
  'TURKEY': 'TR',
  'KOREA': 'KR',
  'CZECH': 'CZ',
  'DEUTSCHLAND': 'DE',
  'انگلیس': 'GB',
  'امریکا': 'US',
  'ترکیه': 'TR',
  'المان': 'DE',
};

/// Short words that are also country codes but usually mean something
/// else in a remark ("AI Ready", "IN", "IT team"…).
const Set<String> _ambiguousCodes = {'AI', 'IN', 'IT', 'IS', 'TO', 'ME', 'NO', 'AT', 'BY', 'AM', 'GO', 'DO', 'ID', 'SO', 'OR', 'TV', 'MY', 'PE'};

/// Finds a country in a remark that has no flag emoji: a known code as its
/// own word (DE, NL, UK…), or an English or Persian country name.
String? detectCountry(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  final words = t.split(RegExp(r'[\s|\-–—•·_,./()\[\]#:@]+')).where((w) => w.isNotEmpty).toList();
  for (final w in words) {
    final upper = w.toUpperCase();
    final alias = _aliases[upper] ?? _aliases[w];
    if (alias != null) return alias;
    // Codes count only in capitals, and not the ambiguous ones.
    if (w.length == 2 && w == upper && !_ambiguousCodes.contains(w) && (_countries.containsKey(w) || _moreCountries.containsKey(w))) {
      return w;
    }
  }
  final lower = t.toLowerCase();
  for (final e in _countries.entries) {
    if (RegExp('\\b${RegExp.escape(e.value.$1.toLowerCase())}\\b').hasMatch(lower)) return e.key;
    if (t.contains(e.value.$2)) return e.key;
  }
  for (final e in _moreCountries.entries) {
    if (e.value.length >= 5 && RegExp('\\b${RegExp.escape(e.value.toLowerCase())}\\b').hasMatch(lower)) return e.key;
  }
  return null;
}

String countryName(S s, String? code) {
  if (code == null) return s.otherLocations;
  final names = _countries[code];
  if (names == null) return _moreCountries[code] ?? code;
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


/// Removes flag emoji (and their joiners) from a remark.
String _withoutFlags(String text) {
  final out = StringBuffer();
  final runes = text.runes.toList();
  for (var i = 0; i < runes.length; i++) {
    final r = runes[i];
    if (r == 0xFE0F || r == 0x200D) continue;
    if (r >= 0x1F1E6 && r <= 0x1F1FF) continue;
    out.writeCharCode(r);
  }
  return out.toString().replaceAll(RegExp(r'\s+'), ' ').replaceAll(RegExp(r'^[\s|\-–—•·_:]+|[\s|\-–—•·_:]+$'), '');
}

/// A server's name as its provider wrote it (without the flag, which is
/// shown as an image). Falls back to the country, then the host.
String serverTitle(S s, VpnServer server) {
  final clean = _withoutFlags(server.remark);
  final code = server.countryCode;
  if (clean.isEmpty || (code != null && clean.toUpperCase() == code)) {
    return code != null ? countryName(s, code) : server.host;
  }
  return clean;
}

/// Protocol and transport, e.g. "VLESS · TCP", "WireGuard".
String protocolLabel(VpnServer server) {
  final p = switch (server.protocol.toLowerCase()) {
    'ss' || 'shadowsocks' => 'Shadowsocks',
    'hy2' || 'hysteria2' || 'hysteria' => 'Hysteria2',
    'wireguard' || 'wg' => 'WireGuard',
    'socks' || 'socks5' => 'SOCKS',
    'xray' || '' => '',
    final other => other.toUpperCase(),
  };
  final transport = server.transport.trim().toUpperCase();
  if (p == 'WireGuard' || p == 'Hysteria2' || transport.isEmpty) return p.isEmpty ? transport : p;
  return p.isEmpty ? transport : '$p · $transport';
}

/// Under the title: the country (unless the title already says it) and
/// the protocol.
String serverSubtitle(S s, VpnServer server) {
  final title = serverTitle(s, server).toLowerCase();
  final code = server.countryCode;
  final country = code == null ? null : countryName(s, code);
  return [
    if (country != null && !title.contains(country.toLowerCase())) country,
    protocolLabel(server),
  ].where((x) => x.isNotEmpty).join(' · ');
}
