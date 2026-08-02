import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_capabilities.dart';
import '../l10n/app_localizations.dart';
import '../models/color_theme.dart';
import '../models/font_settings.dart';
import '../providers/color_theme_provider.dart';
import '../providers/font_settings_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/audio_download_provider.dart';
import '../providers/audio_store_provider.dart';
import '../providers/bible_provider.dart';
import '../providers/bible_store_provider.dart';
import '../providers/engagement_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/user_preferences_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/design/bp_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<ThemeProvider>();
    final readerTheme = context.watch<ColorThemeProvider>();
    final fonts = context.watch<FontSettingsProvider>();
    final capabilities = context.watch<AppCapabilities>();
    final prefs = context.watch<UserPreferencesProvider>();
    final bibleStore = context.watch<BibleStoreProvider>();
    final audioStore = context.watch<AudioStoreProvider>();
    final bible = context.watch<BibleProvider>();
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
    final amharic = prefs.appLanguageCode == 'am';
    String text(String english, String amharicText) =>
        amharic ? amharicText : english;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.appBgDark : AppTheme.appBgLight,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Row(
                  children: [
                    if (Navigator.of(context).canPop()) ...[
                      BpIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        tooltip: l10n.close,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      l10n.settings,
                      style: AppTheme.brandTitle(fontSize: 22, color: ink),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SettingsSection(
                  header: l10n.appearance,
                  children: [
                    SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: const Icon(Icons.brightness_auto_rounded),
                          label: Text(l10n.system),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: const Icon(Icons.light_mode_rounded),
                          label: Text(l10n.light),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: const Icon(Icons.dark_mode_rounded),
                          label: Text(l10n.dark),
                        ),
                      ],
                      selected: {appTheme.themeMode},
                      onSelectionChanged: (selection) async {
                        final mode = selection.first;
                        await appTheme.setThemeMode(mode);
                        if (!context.mounted) return;
                        final isDark = mode == ThemeMode.dark ||
                            (mode == ThemeMode.system &&
                                WidgetsBinding.instance.platformDispatcher
                                        .platformBrightness ==
                                    Brightness.dark);
                        await readerTheme.syncWithAppBrightness(isDark);
                      },
                    ),
                  ],
                ),
                _SettingsSection(
                  header: l10n.appLanguage,
                  children: [
                    Text(
                      l10n.preferredLanguageSubtitle,
                      style: AppTheme.ui(
                        fontSize: 12.5,
                        color: isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InputDecorator(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark
                            ? AppTheme.surfaceDark
                            : AppTheme.surfaceLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppTheme.borderDark
                                : AppTheme.borderLight,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppTheme.borderDark
                                : AppTheme.borderLight,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: prefs.appLanguageCode,
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(
                                value: 'en', child: Text(l10n.english)),
                            DropdownMenuItem(
                                value: 'am', child: Text(l10n.amharic)),
                            DropdownMenuItem(
                                value: 'om', child: Text(l10n.afaanOromo)),
                            DropdownMenuItem(
                                value: 'ti', child: Text(l10n.tigrinya)),
                            DropdownMenuItem(
                                value: 'so', child: Text(l10n.somali)),
                          ],
                          onChanged: (value) async {
                            if (value == null) return;
                            await prefs.setAppLanguage(value);
                            await appTheme.setLocale(Locale(value));
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                _SettingsSection(
                  header: l10n.preferredBible,
                  children: [
                    Text(
                      l10n.preferredBibleSubtitle,
                      style: AppTheme.ui(
                        fontSize: 12.5,
                        color: isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.scriptureLanguageNote,
                      style: AppTheme.ui(
                        fontSize: 12.5,
                        color: isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        bibleStore.catalog
                                .where((p) =>
                                    p.versionId ==
                                    prefs.preferredBibleVersionId)
                                .map((p) => p.name)
                                .firstOrNull ??
                            prefs.preferredBibleVersionId,
                        style: AppTheme.ui(
                          fontSize: 14,
                          weight: FontWeight.w600,
                          color: ink,
                        ),
                      ),
                      subtitle: Text(
                        bible.currentVersion,
                        style: AppTheme.ui(
                          fontSize: 12,
                          color:
                              isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, '/bible_store'),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/bible_store'),
                        child: Text(l10n.openBibleStore),
                      ),
                    ),
                  ],
                ),
                _SettingsSection(
                  header: l10n.preferredAudio,
                  children: [
                    Text(
                      l10n.preferredAudioSubtitle,
                      style: AppTheme.ui(
                        fontSize: 12.5,
                        color: isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.audioSetupNote,
                      style: AppTheme.ui(
                        fontSize: 12.5,
                        color: isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        prefs.preferredAudioPackageId.isEmpty
                            ? l10n.notSet
                            : (audioStore.catalog
                                    .where((p) =>
                                        p.id == prefs.preferredAudioPackageId)
                                    .map((p) => p.name)
                                    .firstOrNull ??
                                prefs.preferredAudioPackageId),
                        style: AppTheme.ui(
                          fontSize: 14,
                          weight: FontWeight.w600,
                          color: ink,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.pushNamed(context, '/audio_store'),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/audio_store'),
                        child: Text(l10n.openAudioStore),
                      ),
                    ),
                  ],
                ),
                _SettingsSection(
                  header: l10n.readerTheme,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: readerTheme.availableThemes.map((theme) {
                          final selected =
                              readerTheme.currentTheme.id == theme.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _ReaderThemeSwatch(
                              theme: theme,
                              selected: selected,
                              onTap: () => readerTheme.setTheme(theme.id),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      text('Font style', 'የፊደል ቅጥ'),
                      style: AppTheme.ui(
                        fontSize: 13,
                        weight: FontWeight.w600,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final selectedFontId = fonts.fontSettings.useSystemFont
                            ? 'system'
                            : AvailableFont.defaultFonts
                                    .where(
                                      (f) =>
                                          f.fontFamily == fonts.fontFamily &&
                                          f.id != 'system',
                                    )
                                    .map((f) => f.id)
                                    .firstOrNull ??
                                'merriweather';
                        return InputDecorator(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark
                                ? AppTheme.surfaceDark
                                : AppTheme.surfaceLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppTheme.borderDark
                                    : AppTheme.borderLight,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: isDark
                                    ? AppTheme.borderDark
                                    : AppTheme.borderLight,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedFontId,
                              isExpanded: true,
                              items: [
                                for (final font in AvailableFont.defaultFonts)
                                  DropdownMenuItem(
                                    value: font.id,
                                    child: Text(
                                      font.name,
                                      style: AppTheme.scripture(
                                        fontSize: 15,
                                        fontFamily: font.fontFamily,
                                        useSystemFont: font.id == 'system',
                                      ),
                                    ),
                                  ),
                              ],
                              onChanged: (id) async {
                                if (id == null) return;
                                final font = AvailableFont.defaultFonts
                                    .firstWhere((f) => f.id == id);
                                await fonts.setAvailableFont(font);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _SliderSetting(
                      label: text('Scripture text size', 'የቅዱስ ጽሑፍ መጠን'),
                      valueLabel: fonts.fontSize.round().toString(),
                      value: fonts.fontSize.clamp(14, 30).toDouble(),
                      min: 14,
                      max: 30,
                      divisions: 16,
                      onChanged: fonts.setFontSize,
                    ),
                    _SliderSetting(
                      label: text('Line spacing', 'የመስመር ክፍተት'),
                      valueLabel: fonts.lineHeight.toStringAsFixed(1),
                      value: fonts.lineHeight.clamp(1.2, 2).toDouble(),
                      min: 1.2,
                      max: 2,
                      divisions: 8,
                      onChanged: fonts.setLineHeight,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: fonts.resetToDefaults,
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: Text(
                          text('Reset reader text', 'የንባብ ጽሑፍ ዳግም አስጀምር'),
                        ),
                      ),
                    ),
                  ],
                ),
                _SettingsSection(
                  header: text('Feature availability', 'የባህሪ ተገኝነት'),
                  children: [
                    _ConnectedSet(
                      children: [
                        _SetRow(
                          position: _RowPosition.first,
                          child: _Capability(
                            label: text(
                              'Cloud account and sync',
                              'የደመና መለያ እና ማመሳሰል',
                            ),
                            available: capabilities.cloud,
                          ),
                        ),
                        _SetRow(
                          position: _RowPosition.middle,
                          child: _Capability(
                            label: text('Chapter audio', 'የምዕራፍ ድምጽ'),
                            available: capabilities.audio,
                          ),
                        ),
                        _SetRow(
                          position: _RowPosition.middle,
                          child: _Capability(
                            label: text('Daily reminders', 'ዕለታዊ ማስታወሻዎች'),
                            available: capabilities.notifications,
                          ),
                        ),
                        _SetRow(
                          position: _RowPosition.last,
                          child: _Capability(
                            label: text(
                              'Wallpaper export',
                              'የግድግዳ ወረቀት ማስቀመጥ',
                            ),
                            available: capabilities.wallpaperExport,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (capabilities.audio) _AudioStorageSection(text: text),
                if (capabilities.notifications)
                  _ThemeNotificationSection(text: text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _RowPosition { first, middle, last, only }

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.header, required this.children});

  final String header;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BpGroupHeader(header),
          ...children,
        ],
      ),
    );
  }
}

class _ConnectedSet extends StatelessWidget {
  const _ConnectedSet({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(children: children);
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({required this.position, required this.child});

  final _RowPosition position;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight;
    final border = isDark ? AppTheme.borderDark : AppTheme.borderLight;

    BorderRadius radius;
    switch (position) {
      case _RowPosition.first:
        radius = const BorderRadius.vertical(top: Radius.circular(14));
      case _RowPosition.last:
        radius = const BorderRadius.vertical(bottom: Radius.circular(14));
      case _RowPosition.only:
        radius = BorderRadius.circular(14);
      case _RowPosition.middle:
        radius = BorderRadius.zero;
    }

    return Material(
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _ReaderThemeSwatch extends StatelessWidget {
  const _ReaderThemeSwatch({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final ReaderColorTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final faint = isDark ? AppTheme.inkFaintDark : AppTheme.inkFaint;

    return Semantics(
      label: '${theme.name} reader theme',
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? AppTheme.gold
                      : (isDark ? AppTheme.borderDark : AppTheme.borderLight),
                  width: selected ? 2.5 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppTheme.gold.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  'Aa',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              theme.name,
              style: AppTheme.ui(
                fontSize: 10,
                weight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? AppTheme.gold : faint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeNotificationSection extends StatelessWidget {
  const _ThemeNotificationSection({required this.text});

  final String Function(String english, String amharic) text;

  @override
  Widget build(BuildContext context) {
    final reminders = context.watch<ReminderProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final soft = isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft;

    return _SettingsSection(
      header: text('Daily streak & verse', 'ዕለታዊ ስትሪክ እና ቃል'),
      children: [
        Text(
          text(
            'Morning: Verse of the Day and Daily Prayer. Evening (~7:00): a friendly nudge to keep your reading streak.',
            'ጠዋት፦ የዛሬው ቃል እና ዕለታዊ ጸሎት። ማታ (~7:00)፦ የንባብ ስትሪክ ማሳሰቢያ።',
          ),
          style: AppTheme.ui(fontSize: 13, color: soft),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            text('Verse + streak reminders', 'ቃል እና ስትሪክ ማሳወቂያዎች'),
            style: AppTheme.ui(fontSize: 14, weight: FontWeight.w600),
          ),
          subtitle: Text(
            reminders.enabled
                ? text(
                    'On · verse ${reminders.hour.toString().padLeft(2, '0')}:${reminders.minute.toString().padLeft(2, '0')} · streak 19:00',
                    'በርቷል · ቃል ${reminders.hour.toString().padLeft(2, '0')}:${reminders.minute.toString().padLeft(2, '0')} · ስትሪክ 19:00',
                  )
                : text('Off', 'ጠፍቷል'),
            style: AppTheme.ui(fontSize: 12, color: soft),
          ),
          value: reminders.enabled,
          onChanged: (value) async {
            if (value) {
              final engagement = context.read<EngagementProvider>();
              final enabled = await reminders.scheduleDailyVerseReminder(
                hour: 8,
                minute: 0,
                requestPermission: true,
                streak: engagement.streakWithGrace(),
                readToday: engagement.hasReadToday(),
              );
              if (!enabled && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      text(
                        'Could not enable reminders. Check notification permission.',
                        'ማሳወቂያ ማንቃት አልተቻለም። ፈቃድ ያረጋግጡ።',
                      ),
                    ),
                  ),
                );
              }
            } else {
              await reminders.disableDailyVerseReminder();
            }
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            text('Daily prayer reminder', 'ዕለታዊ ጸሎት ማሳወቂያ'),
            style: AppTheme.ui(fontSize: 14, weight: FontWeight.w600),
          ),
          subtitle: Text(
            reminders.prayerEnabled
                ? text(
                    'On · ${reminders.prayerHour.toString().padLeft(2, '0')}:${reminders.prayerMinute.toString().padLeft(2, '0')} · opens Daily Prayer',
                    'በርቷል · ${reminders.prayerHour.toString().padLeft(2, '0')}:${reminders.prayerMinute.toString().padLeft(2, '0')}',
                  )
                : text('Off', 'ጠፍቷል'),
            style: AppTheme.ui(fontSize: 12, color: soft),
          ),
          value: reminders.prayerEnabled,
          onChanged: (value) async {
            if (value) {
              final enabled = await reminders.scheduleDailyPrayerReminder(
                hour: 7,
                minute: 30,
                requestPermission: true,
              );
              if (!enabled && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      text(
                        'Could not enable prayer reminder. Check notification permission.',
                        'የጸሎት ማሳወቂያ ማንቃት አልተቻለም። ፈቃድ ያረጋግጡ።',
                      ),
                    ),
                  ),
                );
              }
            } else {
              await reminders.disableDailyPrayerReminder();
            }
          },
        ),
        const SizedBox(height: 8),
        Text(
          text(
            'Optional theme label for the notification title:',
            'ለማሳወቂያው አርዕስት አማራጭ ጭብጥ፦',
          ),
          style: AppTheme.ui(fontSize: 12, color: soft),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final theme in ReminderProvider.themes)
              ChoiceChip(
                label: Text(theme),
                selected: reminders.theme == theme,
                onSelected: (_) async {
                  final enabled = await reminders.enableThemeNotification(
                    theme: theme,
                    hour: reminders.hour,
                    minute: reminders.minute,
                  );
                  if (!enabled && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Notification permission or Scripture is unavailable.',
                        ),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _AudioStorageSection extends StatelessWidget {
  const _AudioStorageSection({required this.text});

  final String Function(String english, String amharic) text;

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<AudioDownloadProvider>();
    final sizeMb = downloads.cacheSizeBytes / (1024 * 1024);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final soft = isDark ? AppTheme.inkSoftDark : AppTheme.inkSoft;

    return _SettingsSection(
      header: text('Offline audio', 'ከመስመር ውጭ ድምጽ'),
      children: [
        _ConnectedSet(
          children: [
            _SetRow(
              position: _RowPosition.first,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: Text(text('Wi-Fi only downloads', 'በWi-Fi ብቻ አውርድ')),
                subtitle: Text(
                  text(
                    'Streaming-only filesets are never cached.',
                    'ለማውረድ ያልተፈቀዱ ድምጾች አይቀመጡም።',
                  ),
                  style: AppTheme.ui(fontSize: 12, color: soft),
                ),
                value: downloads.wifiOnly,
                onChanged: downloads.downloading ? null : downloads.setWifiOnly,
              ),
            ),
            _SetRow(
              position: _RowPosition.middle,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                leading:
                    const Icon(Icons.storage_rounded, color: AppTheme.teal),
                title: Text(text('Downloaded audio', 'የወረደ ድምጽ')),
                subtitle: Text('${sizeMb.toStringAsFixed(1)} MB'),
                trailing: TextButton(
                  onPressed: downloads.downloading
                      ? null
                      : () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(
                                text('Clear audio?', 'ድምጹን ይሰርዙ?'),
                              ),
                              content: Text(
                                text(
                                  'Downloaded chapters will need to be downloaded again.',
                                  'የወረዱ ምዕራፎች እንደገና መውረድ ይኖርባቸዋል።',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(text('Cancel', 'ይቅር')),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(text('Clear', 'ሰርዝ')),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) await downloads.clearCache();
                        },
                  child: Text(text('Clear', 'ሰርዝ')),
                ),
              ),
            ),
            _SetRow(
              position: _RowPosition.last,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                leading: const Icon(
                  Icons.download_for_offline_rounded,
                  color: AppTheme.teal,
                ),
                title: Text(
                  text('Download whole Bible audio', 'ሙሉ የመጽሐፍ ቅዱስ ድምጽ'),
                ),
                subtitle: Text(
                  text(
                    'Only starts when the selected fileset is download-permitted.',
                    'የድምጽ ስብስቡ ለማውረድ ከተፈቀደ ብቻ ይጀምራል።',
                  ),
                  style: AppTheme.ui(fontSize: 12, color: soft),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? AppTheme.inkFaintDark : AppTheme.inkFaint,
                ),
                onTap: downloads.downloading
                    ? null
                    : () async {
                        final books = context.read<BibleProvider>().books;
                        final versionId =
                            context.read<BibleProvider>().currentVersion;
                        if (books.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                text(
                                  'Bible books are not ready yet. Try again in a moment.',
                                  'መጻሕፍት ገና አልተዘጋጁም። ትንሽ ቆይተው እንደገና ይሞክሩ።',
                                ),
                              ),
                            ),
                          );
                          return;
                        }
                        final chapterCount =
                            books.fold<int>(0, (sum, b) => sum + b.chapters);
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              text('Download all audio?', 'ሁሉንም ድምጽ ያውርዱ?'),
                            ),
                            content: Text(
                              text(
                                '$chapterCount chapters will download offline, '
                                    'like installing a full Bible translation.',
                                '$chapterCount ምዕራፎች ከመስመር ውጭ ይወርዳሉ።',
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(text('Cancel', 'ይቅር')),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(text('Download', 'አውርድ')),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          await downloads.downloadFullBible(
                            versionId: versionId,
                            books: [
                              for (final book in books)
                                (bookId: book.id, chapterCount: book.chapters),
                            ],
                          );
                          if (!context.mounted) return;
                          final message = downloads.error ??
                              text(
                                'Audio download finished.',
                                'የድምጽ ማውረድ ተጠናቋል።',
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(message)),
                          );
                        }
                      },
              ),
            ),
          ],
        ),
        if (downloads.downloading) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(value: downloads.progress),
          const SizedBox(height: 8),
          Text(
            '${downloads.completedChapters}/${downloads.totalChapters} chapters',
            style: AppTheme.ui(fontSize: 12, color: soft),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: downloads.pause,
              icon: const Icon(Icons.pause_rounded),
              label: Text(text('Pause download', 'ማውረዱን አቁም')),
            ),
          ),
        ],
        if (downloads.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              downloads.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}

class _SliderSetting extends StatelessWidget {
  const _SliderSetting({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;

    return Semantics(
      label: label,
      value: valueLabel,
      slider: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label · $valueLabel',
            style:
                AppTheme.ui(fontSize: 13, weight: FontWeight.w500, color: ink),
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: valueLabel,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _Capability extends StatelessWidget {
  const _Capability({required this.label, required this.available});

  final String label;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppTheme.inkDark : AppTheme.ink;
    final faint = isDark ? AppTheme.inkFaintDark : AppTheme.inkFaint;

    return ListTile(
      minTileHeight: 48,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Icon(
        available ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
        color: available ? AppTheme.teal : faint,
      ),
      title: Text(label, style: AppTheme.ui(fontSize: 14, color: ink)),
      trailing: Text(
        available ? 'Available' : 'Not configured',
        style: AppTheme.ui(
          fontSize: 11,
          weight: FontWeight.w500,
          color: faint,
        ),
      ),
    );
  }
}
