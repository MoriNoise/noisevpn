import 'package:flutter/widgets.dart';

import '../format.dart';

/// The layout stays left-to-right in both languages. Persian strings are
/// wrapped in a right-to-left embedding so word order and punctuation are
/// still right inside each piece of text.
String rtl(String text) => '\u202B$text\u202C';

/// All user-facing text. A missing translation is a compile error,
/// because both languages implement the same abstract members.
abstract class S {
  const S();

  static S of(BuildContext context) => forCode(Localizations.localeOf(context).languageCode);

  /// For text needed outside the widget tree (the native notification).
  static S forCode(String languageCode) => languageCode == 'fa' ? const _Fa() : const _En();

  bool get isFa;

  /// Localises the digits in an already formatted number.
  String n(String value) => isFa ? Fmt.faDigits(value) : value;

  String ms(int value) => n('$value ms');


  // Text fields
  String get showPassword;
  String get hidePassword;

  // Navigation & pages
  String get navHome;
  String get navServers;
  String get navSettings;
  String get homeSubtitle;
  String get serversSubtitle;
  String get settingsSubtitle;

  // Home
  String get connect;
  String get disconnect;
  String get statusConnected;
  String get statusConnecting;
  String get statusDisconnecting;
  String get statusDisconnected;
  String get hintTapConnect;
  String get hintTapDisconnect;
  String get hintTapCancel;
  String get location;
  String get fastestLocation;
  String get fastestLocationHint;
  String get change;
  String get downloadSpeed;
  String get uploadSpeed;
  String get sessionData;
  String get ping;
  String get planTitle;
  String planUsed(String used, String total);
  String planUnlimited(String used);
  String planExpiresIn(int days);
  String get planExpiresToday;
  String get planExpired;
  String get planNoExpiry;
  String unsupportedPlatform(String platform);
  String notAvailableOn(String platform);
  String get errPermission;
  String get errConnect;
  String get errTimeout;
  String get errNeedsAdmin;
  String get errNoServers;

  // Servers
  String get refresh;
  String get testPing;
  String locationsCount(int count);
  String serversCount(int count);
  String updatedAt(String time);
  String get staleList;
  String get subFailedTitle;
  String get subFailedBody;
  String get tryAgain;
  String get emptyServers;
  String get pingTimeout;
  String get otherLocations;
  String get addServers;
  String get add;
  String get cancel;
  String get remove;
  String get tabSubscription;
  String get tabConfig;
  String get subName;
  String get subUrl;
  String get configText;
  String get configHint;
  String get paste;
  String get errInvalidUrl;
  String get errDuplicateSub;
  String get errNoConfigs;
  String configsAdded(int count);
  String get localConfigs;
  String get noServersTitle;
  String get noServersBody;
  String get refreshFailed;
  String get loadFailed;
  String get loadingServers;
  String removeTitle(String name);
  String get removeSourceBody;
  String get removeConfig;

  // Settings
  String get appearance;
  String get appearanceSubtitle;
  String get themeLight;
  String get themeDark;
  String get themeSystem;
  String get accentColor;
  String accentSwatch(int n);
  String get glassMode;
  String get glassModeHint;
  String get language;
  String get languageSubtitle;
  String get changeTheme;
  String version(String v);

  // Settings sections
  String get tabConnection;
  String get tabGeneral;
  String get connectionMode;
  String get connectionModeHint;
  String get modeTun;
  String get modeTunHint;
  String get modeProxy;
  String modeProxyHint(int port);
  String modeProxyHintWindows(int port);
  String get modeTunHintWindows;
  String get socksPort;
  String get errPort;
  String get perApp;
  String get perAppHint;
  String get perAppOff;
  String get perAppBypass;
  String get perAppOnly;
  String chooseApps(int count);
  String get perAppOnlyNote;
  String get perAppProxyNote;
  String get searchApps;
  String get appsFailed;
  String get noAppsFound;
  String get bypassLan;
  String get bypassLanHint;
  String get dnsTunnel;
  String get dnsTunnelHint;
  String get applyOnReconnect;
  String get reconnectNow;
  String get done;
  String get about;
  String get engine;

  // Errors from flutter_vless 1.1.7
  String get errConfigRejected;
  String get errRouting;
  String get errAlwaysOnRequired;
  String get errAlwaysOnManaged;
  String get errKeychain;

  // Advanced settings
  String get tabAdvanced;
  String get optAuto;
  String get optOn;
  String get optOff;
  String get dnsServer;
  String get dnsServerHint;
  String get dnsCustom;
  String get dnsCustomHint;
  String get errDns;
  String get routing;
  String get routingHint;
  String get bypassIran;
  String get bypassIranHint;
  String get bypassIranAppleNote;
  String get blockAds;
  String get blockAdsHint;
  String get fragment;
  String get fragmentHint;
  String get reconnect;
  String get reconnectHint;
  String get autoReconnect;
  String get autoReconnectHint;
  String get reconnectAttempts;
  String get unlimited;
  String get reconnectMaxDelay;
  String seconds(int value);
  String get onDemand;
  String get onDemandHint;
  String get protection;
  String get protectionHint;
  String get killSwitchNote;
  String alwaysOnStatus(bool enabled, bool lockdown);
  String get requireAlwaysOn;
  String get requireAlwaysOnHint;
  String get openVpnSettings;
  String get systemControls;
  String get systemControlsHint;
  String get notificationButton;
  String get notifDisconnect;
  String get notifOpenApp;
  String get notifNone;
  String get quickAccess;
  String quickAccessHint(String platform);
  String get quickAccessUnlock;
  String get quickAccessUnlockHint;
  String get quickAccessAction;
  String get quickToggle;
  String get quickOpenApp;
  String get addTile;
  String get tileAdded;
  String get tileAlreadyAdded;
  String get tileDeclined;
  String get clearQuickProfile;
  String get quickProfileCleared;
  String get quickUnavailable;
  String optionsRefused(String detail);
  String get diagnostics;
  String get diagnosticsHint;
  String get collectLogs;
  String get viewLog;
  String get copy;
  String get copied;
  String get logEmpty;
  String get testConnection;
  String get testConnectionHint;
  String connectionOk(String ms);
  String get connectionFailed;
  String get xrayCore;
  String get checking;
  // Subscription edit / auto-update
  String get editSubscription;
  String get save;
  String get autoUpdate;
  String get autoUpdateHint;
  String get updateOff;
  String get updateProvider;
  String updateProviderHint(String fallback);
  String providerSays(String every);
  String updateEvery(String every);
  String get updateCustom;
  String get updateHoursLabel;
  String get errHours;
  String hoursShort(double hours);
  String autoShort(String every);
  // Windows fast TUN
  String get tunEngine;
  String get tunEngineFast;
  String get tunEngineStrict;
  String get tunEngineFastHint;
  String get tunEngineStrictHint;
  String get killSwitchFastNote;
  // Desktop Home server panel
  String get searchLocations;
  String get noMatches;
  String get manageServers;
}

class _En extends S {
  const _En();
  @override bool get isFa => false;


  @override String get showPassword => 'Show password';
  @override String get hidePassword => 'Hide password';

  @override String get navHome => 'Home';
  @override String get navServers => 'Servers';
  @override String get navSettings => 'Settings';
  @override String get homeSubtitle => 'Connection status and usage';
  @override String get serversSubtitle => 'Pick the country you want to connect through';
  @override String get settingsSubtitle => 'Appearance, connection and language';

  @override String get connect => 'Connect';
  @override String get disconnect => 'Disconnect';
  @override String get statusConnected => 'Connected';
  @override String get statusConnecting => 'Connecting…';
  @override String get statusDisconnecting => 'Disconnecting…';
  @override String get statusDisconnected => 'Not connected';
  @override String get hintTapConnect => 'Tap to connect';
  @override String get hintTapDisconnect => 'Tap to disconnect';
  @override String get hintTapCancel => 'Tap to cancel';
  @override String get location => 'Location';
  @override String get fastestLocation => 'Fastest location';
  @override String get fastestLocationHint => 'Chosen by lowest ping';
  @override String get change => 'Change';
  @override String get downloadSpeed => 'Download';
  @override String get uploadSpeed => 'Upload';
  @override String get sessionData => 'This session';
  @override String get ping => 'Ping';
  @override String get planTitle => 'Your plan';
  @override String planUsed(String used, String total) => '$used of $total used';
  @override String planUnlimited(String used) => '$used used, no data cap';
  @override String planExpiresIn(int days) => days == 1 ? 'Expires tomorrow' : 'Expires in $days days';
  @override String get planExpiresToday => 'Expires today';
  @override String get planExpired => 'Expired';
  @override String get planNoExpiry => 'No expiry date';
  @override String unsupportedPlatform(String platform) => "flutter_vless has no VPN engine for $platform, so connecting is off here. The server list is live, and ping works if the xray binary is next to the app or on PATH.";
  @override String notAvailableOn(String platform) => 'Not available on $platform';
  @override String get errPermission => 'VPN permission was not granted. Allow it to connect.';
  @override String get errConnect => "Couldn't start the connection. Try another location.";
  @override String get errTimeout => "The server didn't answer in time. Try another location or check your internet.";
  @override String get errNeedsAdmin => 'VPN mode on Windows needs administrator rights. Reopen the app with "Run as administrator", or turn on Proxy only in Settings.';
  @override String get errNoServers => 'No servers yet. Add a subscription or configs in Servers.';

  @override String get refresh => 'Refresh';
  @override String get testPing => 'Test ping';
  @override String locationsCount(int count) => count == 1 ? '1 location' : '$count locations';
  @override String serversCount(int count) => count == 1 ? '1 server' : '$count servers';
  @override String updatedAt(String time) => 'Updated $time';
  @override String get staleList => "Showing the saved list. The subscription couldn't be refreshed.";
  @override String get subFailedTitle => "Couldn't load servers";
  @override String get subFailedBody => 'Check your internet and try again.';
  @override String get tryAgain => 'Try again';
  @override String get emptyServers => 'This subscription has no servers the app can use.';
  @override String get pingTimeout => 'Timeout';
  @override String get otherLocations => 'Other';
  @override String get addServers => 'Add servers';
  @override String get add => 'Add';
  @override String get cancel => 'Cancel';
  @override String get remove => 'Remove';
  @override String get tabSubscription => 'Subscription';
  @override String get tabConfig => 'Configs';
  @override String get subName => 'Name (optional)';
  @override String get subUrl => 'Subscription link';
  @override String get configText => 'Configs';
  @override String get configHint => 'vless://, vmess://, trojan://, ss://, hy2://, wireguard://, a WireGuard .conf, Xray / sing-box JSON or Clash YAML';
  @override String get paste => 'Paste';
  @override String get errInvalidUrl => 'Enter a link that starts with http:// or https://.';
  @override String get errDuplicateSub => 'This subscription is already added.';
  @override String get errNoConfigs => 'No new supported configs found in that text.';
  @override String configsAdded(int count) => count == 1 ? '1 config added' : '$count configs added';
  @override String get localConfigs => 'Local configs';
  @override String get noServersTitle => 'No servers yet';
  @override String get noServersBody => 'Add a subscription link or paste configs to get started.';
  @override String get refreshFailed => "Couldn't refresh, showing the saved list";
  @override String get loadFailed => "Couldn't load this subscription";
  @override String get loadingServers => 'Loading servers…';
  @override String removeTitle(String name) => 'Remove $name?';
  @override String get removeSourceBody => 'Its servers will disappear from the list.';
  @override String get removeConfig => 'Remove config';

  @override String get appearance => 'Appearance';
  @override String get appearanceSubtitle => 'Theme, accent color and glass';
  @override String get themeLight => 'Light';
  @override String get themeDark => 'Dark';
  @override String get themeSystem => 'System';
  @override String get accentColor => 'Accent color';
  @override String accentSwatch(int n) => 'Accent color $n';
  @override String get glassMode => 'Glass effect';
  @override String get glassModeHint => 'Translucent, tinted surfaces over the colour backdrop.';
  @override String get language => 'Language';
  @override String get languageSubtitle => 'The layout stays the same in both';
  @override String get changeTheme => 'Change theme';
  @override String version(String v) => 'Version $v';

  @override String get tabConnection => 'Connection';
  @override String get tabGeneral => 'General';
  @override String get connectionMode => 'Connection mode';
  @override String get connectionModeHint => 'How the app sends traffic through the server';
  @override String get modeTun => 'VPN (TUN)';
  @override String get modeTunHint => 'Every app goes through the tunnel.';
  @override String get modeProxy => 'Proxy only';
  @override String modeProxyHint(int port) => 'No VPN. A SOCKS5 proxy runs on 127.0.0.1:$port for the apps you set it in.';
  @override String modeProxyHintWindows(int port) => 'No VPN. 127.0.0.1:$port is set as the Windows system proxy; apps that ignore system proxy settings connect directly.';
  @override String get modeTunHintWindows => 'Every app goes through the tunnel. Needs the app to run as administrator.';
  @override String get socksPort => 'Local SOCKS5 port';
  @override String get errPort => 'Use a port between 1024 and 65535.';
  @override String get perApp => 'Per-app proxy';
  @override String get perAppHint => 'Choose which apps use the tunnel';
  @override String get perAppOff => 'All apps';
  @override String get perAppBypass => 'Skip selected';
  @override String get perAppOnly => 'Only selected';
  @override String chooseApps(int count) => count == 0 ? 'Choose apps' : 'Choose apps ($count selected)';
  @override String get perAppOnlyNote => 'System services without a launcher icon still use the tunnel.';
  @override String get perAppProxyNote => 'Per-app proxy works in VPN mode.';
  @override String get searchApps => 'Search apps';
  @override String get appsFailed => "Couldn't read the installed apps.";
  @override String get noAppsFound => 'No apps match.';
  @override String get bypassLan => 'Bypass LAN';
  @override String get bypassLanHint => 'Local network addresses (router, printers) stay outside the tunnel.';
  @override String get dnsTunnel => 'DNS through the tunnel';
  @override String get dnsTunnelHint => 'Stops DNS queries leaking to your local network.';
  @override String get applyOnReconnect => 'Changes apply the next time you connect.';
  @override String get reconnectNow => 'Reconnect now';
  @override String get done => 'Done';
  @override String get about => 'About';
  @override String get engine => 'Engine';

  @override String get errConfigRejected => "Xray couldn't use this server's config. Try another location, or update the subscription.";
  @override String get errRouting => "This server's routing can't run on this device. Try another location.";
  @override String get errAlwaysOnRequired => 'Settings require Always-on VPN. Turn it on in the system VPN settings, or turn the option off in Settings → Advanced.';
  @override String get errAlwaysOnManaged => "Android's Always-on VPN keeps this connection up. Turn Always-on off in the system VPN settings to disconnect.";
  @override String get errKeychain => "The VPN profile couldn't be read. Unlock the device and try again; if it keeps happening, reinstall the app.";

  @override String get tabAdvanced => 'Advanced';
  @override String get optAuto => 'Auto';
  @override String get optOn => 'On';
  @override String get optOff => 'Off';
  @override String get dnsServer => 'DNS server';
  @override String get dnsServerHint => "Auto keeps the server's own DNS (sent through the proxy).";
  @override String get dnsCustom => 'Custom';
  @override String get dnsCustomHint => 'IP, or a URL like https://dns.example/dns-query';
  @override String get errDns => 'Enter an IP address or a DNS URL.';
  @override String get routing => 'Routing';
  @override String get routingHint => 'What goes through the server and what connects directly';
  @override String get bypassIran => 'Bypass Iranian sites';
  @override String get bypassIranHint => '.ir sites and Iranian IPs connect directly, without the server.';
  @override String get bypassIranAppleNote => 'On iPhone and Mac this covers .ir domains only (no GeoIP data there).';
  @override String get blockAds => 'Block ads and trackers';
  @override String get blockAdsHint => 'Drops known ad and tracking domains.';
  @override String get fragment => 'TLS fragment';
  @override String get fragmentHint => 'Splits the TLS handshake into pieces to get past SNI filtering. Only for TLS servers; may slow the first connection a little.';
  @override String get reconnect => 'Reconnect';
  @override String get reconnectHint => 'What happens when the connection drops';
  @override String get autoReconnect => 'Reconnect automatically';
  @override String get autoReconnectHint => 'Retries with growing pauses. Traffic stays blocked while it retries.';
  @override String get reconnectAttempts => 'Attempts';
  @override String get unlimited => 'No limit';
  @override String get reconnectMaxDelay => 'Longest pause';
  @override String seconds(int value) => value >= 60 && value % 60 == 0 ? '${value ~/ 60} min' : '$value s';
  @override String get onDemand => 'On Demand';
  @override String get onDemandHint => 'Lets the system restart the VPN after it stops unexpectedly.';
  @override String get protection => 'Protection';
  @override String get protectionHint => 'Keeping traffic inside the tunnel';
  @override String get killSwitchNote => 'Kill switch is always on in VPN mode: if the connection drops, traffic is blocked until it comes back or you disconnect.';
  @override String alwaysOnStatus(bool enabled, bool lockdown) => !enabled
      ? 'Always-on VPN: off'
      : (lockdown ? 'Always-on VPN: on, blocking connections without VPN' : 'Always-on VPN: on');
  @override String get requireAlwaysOn => 'Require Always-on VPN';
  @override String get requireAlwaysOnHint => "Don't connect unless Always-on is set for this app. Only that also blocks traffic if the whole VPN process is killed.";
  @override String get openVpnSettings => 'Open system VPN settings';
  @override String get systemControls => 'System controls';
  @override String get systemControlsHint => 'Notification and quick toggle';
  @override String get notificationButton => 'Notification button';
  @override String get notifDisconnect => 'Disconnect';
  @override String get notifOpenApp => 'Open app';
  @override String get notifNone => 'None';
  @override String get quickAccess => 'Quick toggle';
  @override String quickAccessHint(String platform) => switch (platform) {
        'Android' => 'A Quick Settings tile that connects the last server.',
        'macOS' => 'A menu bar item that connects the last server.',
        'Windows' => 'A tray icon that connects the last server.',
        _ => 'A Control Center button that connects the last server.',
      };
  @override String get quickAccessUnlock => 'Require unlock';
  @override String get quickAccessUnlockHint => 'Ask for the device unlock before switching.';
  @override String get quickAccessAction => 'Tapping it';
  @override String get quickToggle => 'Connects / disconnects';
  @override String get quickOpenApp => 'Opens the app';
  @override String get addTile => 'Add tile to Quick Settings';
  @override String get tileAdded => 'Tile added.';
  @override String get tileAlreadyAdded => 'The tile is already there.';
  @override String get tileDeclined => 'Tile not added.';
  @override String get clearQuickProfile => 'Forget saved quick profile';
  @override String get quickProfileCleared => 'Forgotten. Connect once from the app to use the quick toggle again.';
  @override String get quickUnavailable => 'Not available on this device.';
  @override String optionsRefused(String detail) => 'The engine refused these options and is using its defaults: $detail';
  @override String get diagnostics => 'Diagnostics';
  @override String get diagnosticsHint => 'For troubleshooting. Contains no configs or passwords.';
  @override String get collectLogs => 'Keep a connection log';
  @override String get viewLog => 'View log';
  @override String get copy => 'Copy';
  @override String get copied => 'Copied';
  @override String get logEmpty => 'Nothing logged yet. Connect once, then look again.';
  @override String get testConnection => 'Test connection';
  @override String get testConnectionHint => 'A real request through the running tunnel.';
  @override String connectionOk(String ms) => 'Working, $ms';
  @override String get connectionFailed => 'No answer through the tunnel.';
  @override String get xrayCore => 'Xray core';
  @override String get checking => 'Checking…';
  @override String get editSubscription => 'Edit subscription';
  @override String get save => 'Save';
  @override String get autoUpdate => 'Auto update';
  @override String get autoUpdateHint => "Runs while the app is open, and when you come back to it. Phones don't update in the background.";
  @override String get updateOff => 'Off';
  @override String get updateProvider => 'As the subscription says';
  @override String updateProviderHint(String fallback) => 'Uses the interval the panel sends. Every $fallback when it sends none.';
  @override String providerSays(String every) => 'This subscription asks for every $every.';
  @override String updateEvery(String every) => 'Every $every';
  @override String get updateCustom => 'Custom';
  @override String get updateHoursLabel => 'Hours between updates';
  @override String get errHours => 'Use 1 to 168 hours.';
  @override String hoursShort(double hours) {
    if (hours < 1) return '${(hours * 60).round()} min';
    final whole = hours == hours.roundToDouble();
    return '${whole ? hours.round() : hours.toStringAsFixed(1)} h';
  }
  @override String autoShort(String every) => 'auto $every';
  @override String get tunEngine => 'TUN engine';
  @override String get tunEngineFast => 'sing-box (fast)';
  @override String get tunEngineStrict => 'flutter_vless (kill switch)';
  @override String get tunEngineFastHint => 'Connects in a few seconds. No kill switch: if the VPN process stops, traffic goes out directly.';
  @override String get tunEngineStrictHint => 'If the VPN drops, all traffic is blocked until it reconnects or you disconnect. Connecting takes about 10 seconds.';
  @override String get killSwitchFastNote => 'The sing-box TUN engine has no kill switch: if the VPN process stops, traffic goes out directly. Choose flutter_vless as the TUN engine in Settings → Connection to block it instead.';
  @override String get searchLocations => 'Search locations';
  @override String get noMatches => 'No locations match your search.';
  @override String get manageServers => 'Add or edit subscriptions';
}

class _Fa extends S {
  const _Fa();
  @override bool get isFa => true;


  @override String get showPassword => rtl('نمایش رمز');
  @override String get hidePassword => rtl('پنهان کردن رمز');

  @override String get navHome => rtl('خانه');
  @override String get navServers => rtl('سرورها');
  @override String get navSettings => rtl('تنظیمات');
  @override String get homeSubtitle => rtl('وضعیت اتصال و مصرف');
  @override String get serversSubtitle => rtl('کشوری که می‌خوای ازش وصل بشی رو انتخاب کن');
  @override String get settingsSubtitle => rtl('ظاهر، اتصال و زبان');

  @override String get connect => rtl('اتصال');
  @override String get disconnect => rtl('قطع اتصال');
  @override String get statusConnected => rtl('وصل');
  @override String get statusConnecting => rtl('در حال اتصال…');
  @override String get statusDisconnecting => rtl('در حال قطع…');
  @override String get statusDisconnected => rtl('وصل نیستی');
  @override String get hintTapConnect => rtl('برای اتصال بزن');
  @override String get hintTapDisconnect => rtl('برای قطع اتصال بزن');
  @override String get hintTapCancel => rtl('برای لغو بزن');
  @override String get location => rtl('لوکیشن');
  @override String get fastestLocation => rtl('سریع‌ترین لوکیشن');
  @override String get fastestLocationHint => rtl('با کمترین پینگ انتخاب می‌شه');
  @override String get change => rtl('تغییر');
  @override String get downloadSpeed => rtl('دانلود');
  @override String get uploadSpeed => rtl('آپلود');
  @override String get sessionData => rtl('این جلسه');
  @override String get ping => rtl('پینگ');
  @override String get planTitle => rtl('اشتراک تو');
  @override String planUsed(String used, String total) => rtl('$used از $total مصرف شده');
  @override String planUnlimited(String used) => rtl('$used مصرف شده، بدون محدودیت حجم');
  @override String planExpiresIn(int days) => rtl(days == 1 ? 'فردا تموم می‌شه' : '${n('$days')} روز تا پایان اشتراک');
  @override String get planExpiresToday => rtl('امروز تموم می‌شه');
  @override String get planExpired => rtl('منقضی شده');
  @override String get planNoExpiry => rtl('بدون تاریخ انقضا');
  @override String unsupportedPlatform(String platform) => rtl('flutter_vless برای $platform موتور VPN نداره، پس اتصال اینجا خاموشه. لیست سرورها واقعیه و اگه فایل xray کنار اپ یا توی PATH باشه، پینگ هم کار می‌کنه.');
  @override String notAvailableOn(String platform) => rtl('روی $platform در دسترس نیست');
  @override String get errPermission => rtl('اجازه‌ی VPN داده نشد. برای اتصال اجازه بده.');
  @override String get errConnect => rtl('اتصال برقرار نشد. یه لوکیشن دیگه رو امتحان کن.');
  @override String get errTimeout => rtl('سرور به‌موقع جواب نداد. یه لوکیشن دیگه رو امتحان کن یا اینترنتت رو چک کن.');
  @override String get errNeedsAdmin => rtl('حالت VPN روی ویندوز دسترسی ادمین می‌خواد. اپ رو با Run as administrator باز کن، یا توی تنظیمات «فقط پروکسی» رو روشن کن.');
  @override String get errNoServers => rtl('هنوز سروری نیست. توی سرورها اشتراک یا کانفیگ اضافه کن.');

  @override String get refresh => rtl('به‌روزرسانی');
  @override String get testPing => rtl('تست پینگ');
  @override String locationsCount(int count) => rtl('${n('$count')} لوکیشن');
  @override String serversCount(int count) => rtl('${n('$count')} سرور');
  @override String updatedAt(String time) => rtl('به‌روزرسانی ساعت ${n(time)}');
  @override String get staleList => rtl('لیست ذخیره‌شده رو می‌بینی. اشتراک به‌روز نشد.');
  @override String get subFailedTitle => rtl('سرورها لود نشدن');
  @override String get subFailedBody => rtl('اینترنتت رو چک کن و دوباره امتحان کن.');
  @override String get tryAgain => rtl('دوباره امتحان کن');
  @override String get emptyServers => rtl('توی این اشتراک سروری که اپ بتونه استفاده کنه نیست.');
  @override String get pingTimeout => rtl('بدون پاسخ');
  @override String get otherLocations => rtl('سایر');
  @override String get addServers => rtl('افزودن سرور');
  @override String get add => rtl('افزودن');
  @override String get cancel => rtl('انصراف');
  @override String get remove => rtl('حذف');
  @override String get tabSubscription => rtl('اشتراک');
  @override String get tabConfig => rtl('کانفیگ');
  @override String get subName => rtl('اسم (اختیاری)');
  @override String get subUrl => rtl('لینک اشتراک');
  @override String get configText => rtl('کانفیگ‌ها');
  @override String get configHint => 'vless://, vmess://, trojan://, ss://, hy2://, wireguard://, WireGuard .conf, JSON, Clash YAML';
  @override String get paste => rtl('چسباندن');
  @override String get errInvalidUrl => rtl('یه لینک وارد کن که با http:// یا https:// شروع بشه.');
  @override String get errDuplicateSub => rtl('این اشتراک قبلاً اضافه شده.');
  @override String get errNoConfigs => rtl('توی این متن کانفیگ جدید قابل‌استفاده‌ای پیدا نشد.');
  @override String configsAdded(int count) => rtl('${n('$count')} کانفیگ اضافه شد');
  @override String get localConfigs => rtl('کانفیگ‌های دستی');
  @override String get noServersTitle => rtl('هنوز سروری نداری');
  @override String get noServersBody => rtl('یه لینک اشتراک اضافه کن یا کانفیگ‌هات رو بچسبون.');
  @override String get refreshFailed => rtl('به‌روز نشد، لیست ذخیره‌شده رو می‌بینی');
  @override String get loadFailed => rtl('این اشتراک لود نشد');
  @override String get loadingServers => rtl('در حال گرفتن سرورها…');
  @override String removeTitle(String name) => rtl('$name حذف بشه؟');
  @override String get removeSourceBody => rtl('سرورهاش از لیست حذف می‌شن.');
  @override String get removeConfig => rtl('حذف کانفیگ');

  @override String get appearance => rtl('ظاهر');
  @override String get appearanceSubtitle => rtl('تم، رنگ اصلی و افکت شیشه');
  @override String get themeLight => rtl('روشن');
  @override String get themeDark => rtl('تیره');
  @override String get themeSystem => rtl('سیستم');
  @override String get accentColor => rtl('رنگ اصلی');
  @override String accentSwatch(int n) => rtl('رنگ ${this.n('$n')}');
  @override String get glassMode => rtl('افکت شیشه‌ای');
  @override String get glassModeHint => rtl('سطح‌های شفاف و رنگی روی پس‌زمینه‌ی رنگی.');
  @override String get language => rtl('زبان');
  @override String get languageSubtitle => rtl('چیدمان صفحه توی هر دو زبان یکیه');
  @override String get changeTheme => rtl('تغییر تم');
  @override String version(String v) => rtl('نسخه ${n(v)}');

  @override String get tabConnection => rtl('اتصال');
  @override String get tabGeneral => rtl('عمومی');
  @override String get connectionMode => rtl('حالت اتصال');
  @override String get connectionModeHint => rtl('اپ ترافیک رو چطوری از سرور رد کنه');
  @override String get modeTun => 'VPN (TUN)';
  @override String get modeTunHint => rtl('همه‌ی اپ‌ها از تونل رد می‌شن.');
  @override String get modeProxy => rtl('فقط پروکسی');
  @override String modeProxyHint(int port) => rtl('VPN روشن نمی‌شه. یه پروکسی SOCKS5 روی 127.0.0.1:$port بالا میاد که توی هر اپی بخوای تنظیمش کنی.');
  @override String modeProxyHintWindows(int port) => rtl('VPN روشن نمی‌شه. 127.0.0.1:$port به‌عنوان پروکسی سیستم ویندوز تنظیم می‌شه؛ اپ‌هایی که پروکسی سیستم رو نادیده می‌گیرن مستقیم وصل می‌شن.');
  @override String get modeTunHintWindows => rtl('همه‌ی اپ‌ها از تونل رد می‌شن. اپ باید با دسترسی Administrator اجرا بشه.');
  @override String get socksPort => rtl('پورت SOCKS5 محلی');
  @override String get errPort => rtl('یه پورت بین ۱۰۲۴ تا ۶۵۵۳۵ بذار.');
  @override String get perApp => rtl('پروکسی برای هر اپ');
  @override String get perAppHint => rtl('انتخاب کن کدوم اپ‌ها از تونل رد بشن');
  @override String get perAppOff => rtl('همه‌ی اپ‌ها');
  @override String get perAppBypass => rtl('به‌جز انتخابی‌ها');
  @override String get perAppOnly => rtl('فقط انتخابی‌ها');
  @override String chooseApps(int count) => rtl(count == 0 ? 'انتخاب اپ‌ها' : 'انتخاب اپ‌ها (${n('$count')} تا)');
  @override String get perAppOnlyNote => rtl('سرویس‌های سیستمی که آیکون ندارن همچنان از تونل رد می‌شن.');
  @override String get perAppProxyNote => rtl('پروکسی برای هر اپ توی حالت VPN کار می‌کنه.');
  @override String get searchApps => rtl('جستجوی اپ');
  @override String get appsFailed => rtl('لیست اپ‌ها خونده نشد.');
  @override String get noAppsFound => rtl('اپی پیدا نشد.');
  @override String get bypassLan => rtl('دور زدن شبکه‌ی محلی');
  @override String get bypassLanHint => rtl('آدرس‌های شبکه‌ی محلی (مودم، پرینتر) بیرون از تونل می‌مونن.');
  @override String get dnsTunnel => rtl('DNS از داخل تونل');
  @override String get dnsTunnelHint => rtl('جلوی نشت درخواست‌های DNS به شبکه‌ی محلی رو می‌گیره.');
  @override String get applyOnReconnect => rtl('تغییرات از اتصال بعدی اعمال می‌شن.');
  @override String get reconnectNow => rtl('الان دوباره وصل شو');
  @override String get done => rtl('تأیید');
  @override String get about => rtl('درباره');
  @override String get engine => rtl('موتور');
  @override String get errConfigRejected => rtl('Xray نتونست کانفیگ این سرور رو اجرا کنه. یه لوکیشن دیگه رو امتحان کن یا اشتراک رو به‌روز کن.');
  @override String get errRouting => rtl('مسیریابی این سرور روی این دستگاه اجرا نمی‌شه. یه لوکیشن دیگه رو امتحان کن.');
  @override String get errAlwaysOnRequired => rtl('تنظیمات، VPN همیشه‌روشن رو لازم داره. توی تنظیمات VPN سیستم روشنش کن، یا این گزینه رو توی تنظیمات ← پیشرفته خاموش کن.');
  @override String get errAlwaysOnManaged => rtl('VPN همیشه‌روشنِ اندروید این اتصال رو نگه داشته. برای قطع، توی تنظیمات VPN سیستم خاموشش کن.');
  @override String get errKeychain => rtl('پروفایل VPN خونده نشد. قفل گوشی رو باز کن و دوباره امتحان کن؛ اگه تکرار شد، اپ رو دوباره نصب کن.');

  @override String get tabAdvanced => rtl('پیشرفته');
  @override String get optAuto => rtl('خودکار');
  @override String get optOn => rtl('روشن');
  @override String get optOff => rtl('خاموش');
  @override String get dnsServer => rtl('سرور DNS');
  @override String get dnsServerHint => rtl('«خودکار» همون DNS خود سرور رو نگه می‌داره (از داخل پروکسی).');
  @override String get dnsCustom => rtl('دلخواه');
  @override String get dnsCustomHint => rtl('آی‌پی، یا آدرسی مثل https://dns.example/dns-query');
  @override String get errDns => rtl('یه آی‌پی یا آدرس DNS وارد کن.');
  @override String get routing => rtl('مسیریابی');
  @override String get routingHint => rtl('چی از سرور رد بشه و چی مستقیم وصل بشه');
  @override String get bypassIran => rtl('سایت‌های ایرانی مستقیم');
  @override String get bypassIranHint => rtl('سایت‌های .ir و آی‌پی‌های ایران بدون سرور و مستقیم وصل می‌شن.');
  @override String get bypassIranAppleNote => rtl('روی آیفون و مک فقط دامنه‌های .ir رو شامل می‌شه (اونجا فایل GeoIP نیست).');
  @override String get blockAds => rtl('مسدود کردن تبلیغات و ردیاب‌ها');
  @override String get blockAdsHint => rtl('دامنه‌های شناخته‌شده‌ی تبلیغاتی و ردیاب رو می‌بنده.');
  @override String get fragment => rtl('فرگمنت TLS');
  @override String get fragmentHint => rtl('دست‌دهی TLS رو تکه‌تکه می‌فرسته تا از فیلترینگ SNI رد بشه. فقط برای سرورهای TLS؛ ممکنه اتصال اول کمی کندتر بشه.');
  @override String get reconnect => rtl('اتصال دوباره');
  @override String get reconnectHint => rtl('وقتی اتصال قطع می‌شه چی بشه');
  @override String get autoReconnect => rtl('اتصال دوباره‌ی خودکار');
  @override String get autoReconnectHint => rtl('با فاصله‌های بیشتر و بیشتر دوباره تلاش می‌کنه. تا اون موقع ترافیک بسته می‌مونه.');
  @override String get reconnectAttempts => rtl('تعداد تلاش');
  @override String get unlimited => rtl('بی‌نهایت');
  @override String get reconnectMaxDelay => rtl('بیشترین مکث');
  @override String seconds(int value) => rtl(value >= 60 && value % 60 == 0 ? '${n('${value ~/ 60}')} دقیقه' : '${n('$value')} ثانیه');
  @override String get onDemand => 'On Demand';
  @override String get onDemandHint => rtl('اگه VPN یهو بسته بشه، سیستم خودش دوباره روشنش می‌کنه.');
  @override String get protection => rtl('محافظت');
  @override String get protectionHint => rtl('نگه داشتن ترافیک داخل تونل');
  @override String get killSwitchNote => rtl('کیل‌سوییچ توی حالت VPN همیشه روشنه: اگه اتصال قطع بشه، ترافیک بسته می‌مونه تا دوباره وصل بشه یا خودت قطع کنی.');
  @override String alwaysOnStatus(bool enabled, bool lockdown) => rtl(!enabled
      ? 'VPN همیشه‌روشن: خاموش'
      : (lockdown ? 'VPN همیشه‌روشن: روشن، اتصال بدون VPN بسته‌ست' : 'VPN همیشه‌روشن: روشن'));
  @override String get requireAlwaysOn => rtl('VPN همیشه‌روشن الزامی باشه');
  @override String get requireAlwaysOnHint => rtl('تا وقتی همیشه‌روشن برای این اپ تنظیم نشده، وصل نشو. فقط این حالت، اگه کل پروسه‌ی VPN بسته بشه هم ترافیک رو می‌بنده.');
  @override String get openVpnSettings => rtl('باز کردن تنظیمات VPN سیستم');
  @override String get systemControls => rtl('کنترل‌های سیستم');
  @override String get systemControlsHint => rtl('نوتیفیکیشن و دکمه‌ی سریع');
  @override String get notificationButton => rtl('دکمه‌ی نوتیفیکیشن');
  @override String get notifDisconnect => rtl('قطع اتصال');
  @override String get notifOpenApp => rtl('باز کردن اپ');
  @override String get notifNone => rtl('هیچی');
  @override String get quickAccess => rtl('دکمه‌ی سریع');
  @override String quickAccessHint(String platform) => rtl(switch (platform) {
        'Android' => 'یه کاشی توی Quick Settings که به آخرین سرور وصل می‌شه.',
        'macOS' => 'یه آیتم توی منوبار که به آخرین سرور وصل می‌شه.',
        'Windows' => 'یه آیکون توی سینی سیستم که به آخرین سرور وصل می‌شه.',
        _ => 'یه دکمه توی Control Center که به آخرین سرور وصل می‌شه.',
      });
  @override String get quickAccessUnlock => rtl('باز کردن قفل لازم باشه');
  @override String get quickAccessUnlockHint => rtl('قبل از وصل یا قطع، قفل دستگاه رو بپرسه.');
  @override String get quickAccessAction => rtl('با زدنش');
  @override String get quickToggle => rtl('وصل / قطع می‌شه');
  @override String get quickOpenApp => rtl('اپ باز می‌شه');
  @override String get addTile => rtl('اضافه کردن کاشی به Quick Settings');
  @override String get tileAdded => rtl('کاشی اضافه شد.');
  @override String get tileAlreadyAdded => rtl('کاشی از قبل اضافه شده.');
  @override String get tileDeclined => rtl('کاشی اضافه نشد.');
  @override String get clearQuickProfile => rtl('فراموش کردن پروفایل دکمه‌ی سریع');
  @override String get quickProfileCleared => rtl('فراموش شد. یه بار از توی اپ وصل شو تا دکمه‌ی سریع دوباره کار کنه.');
  @override String get quickUnavailable => rtl('روی این دستگاه در دسترس نیست.');
  @override String optionsRefused(String detail) => rtl('موتور این تنظیمات رو قبول نکرد و با پیش‌فرض‌ها کار می‌کنه: $detail');
  @override String get diagnostics => rtl('عیب‌یابی');
  @override String get diagnosticsHint => rtl('برای پیدا کردن مشکل. کانفیگ و رمزی توش نیست.');
  @override String get collectLogs => rtl('ثبت لاگ اتصال');
  @override String get viewLog => rtl('دیدن لاگ');
  @override String get copy => rtl('کپی');
  @override String get copied => rtl('کپی شد');
  @override String get logEmpty => rtl('هنوز چیزی ثبت نشده. یه بار وصل شو و دوباره ببین.');
  @override String get testConnection => rtl('تست اتصال');
  @override String get testConnectionHint => rtl('یه درخواست واقعی از داخل تونلِ روشن.');
  @override String connectionOk(String ms) => rtl('کار می‌کنه، $ms');
  @override String get connectionFailed => rtl('از داخل تونل جوابی نیومد.');
  @override String get xrayCore => rtl('هسته‌ی Xray');
  @override String get checking => rtl('در حال بررسی…');
  @override String get editSubscription => rtl('ویرایش اشتراک');
  @override String get save => rtl('ذخیره');
  @override String get autoUpdate => rtl('به‌روزرسانی خودکار');
  @override String get autoUpdateHint => rtl('وقتی اپ بازه، و هر بار که برمی‌گردی بهش انجام می‌شه. گوشی‌ها توی پس‌زمینه به‌روزرسانی نمی‌کنن.');
  @override String get updateOff => rtl('خاموش');
  @override String get updateProvider => rtl('طبق خود اشتراک');
  @override String updateProviderHint(String fallback) => rtl('از فاصله‌ای که پنل می‌فرسته استفاده می‌کنه. اگه نفرسته، هر $fallback.');
  @override String providerSays(String every) => rtl('این اشتراک می‌گه هر $every.');
  @override String updateEvery(String every) => rtl('هر $every');
  @override String get updateCustom => rtl('دلخواه');
  @override String get updateHoursLabel => rtl('فاصله‌ی به‌روزرسانی (ساعت)');
  @override String get errHours => rtl('یه عدد بین ۱ تا ۱۶۸ ساعت بذار.');
  @override String hoursShort(double hours) {
    if (hours < 1) return n('${(hours * 60).round()} دقیقه');
    final whole = hours == hours.roundToDouble();
    return n('${whole ? hours.round() : hours.toStringAsFixed(1)} ساعت');
  }
  @override String autoShort(String every) => rtl('خودکار $every');
  @override String get tunEngine => rtl('موتور TUN');
  @override String get tunEngineFast => rtl('sing-box (سریع)');
  @override String get tunEngineStrict => rtl('flutter_vless (کیل‌سوییچ)');
  @override String get tunEngineFastHint => rtl('چند ثانیه‌ای وصل می‌شه. کیل‌سوییچ نداره: اگه پروسه‌ی VPN بسته بشه، ترافیک مستقیم می‌ره.');
  @override String get tunEngineStrictHint => rtl('اگه VPN قطع بشه، همه‌ی ترافیک بسته می‌مونه تا دوباره وصل بشه یا خودت قطع کنی. اتصال حدود ۱۰ ثانیه طول می‌کشه.');
  @override String get killSwitchFastNote => rtl('موتور TUN با sing-box کیل‌سوییچ نداره: اگه پروسه‌ی VPN بسته بشه، ترافیک مستقیم می‌ره. برای بستنش، توی تنظیمات ← اتصال موتور TUN رو flutter_vless بذار.');
  @override String get searchLocations => rtl('جستجوی لوکیشن');
  @override String get noMatches => rtl('لوکیشنی با این جستجو پیدا نشد.');
  @override String get manageServers => rtl('افزودن یا ویرایش اشتراک‌ها');
}
