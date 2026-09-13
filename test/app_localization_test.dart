import 'package:flutter_test/flutter_test.dart';
import 'package:soil_app/core/localization/app_localizations.dart';
import 'package:soil_app/core/localization/language_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLanguage Enum Tests', () {
    test('Language codes and flags match expectations', () {
      expect(AppLanguage.thai.code, 'th');
      expect(AppLanguage.thai.flag, '🇹🇭');
      expect(AppLanguage.thai.label, 'ไทย');

      expect(AppLanguage.english.code, 'en');
      expect(AppLanguage.english.flag, '🇬🇧');
      expect(AppLanguage.english.label, 'English');

      expect(AppLanguage.chinese.code, 'zh');
      expect(AppLanguage.chinese.flag, '🇨🇳');
      expect(AppLanguage.chinese.label, '中文');
    });

    test('AppLanguage.fromCode parses correctly and defaults to Thai', () {
      expect(AppLanguage.fromCode('th'), AppLanguage.thai);
      expect(AppLanguage.fromCode('en'), AppLanguage.english);
      expect(AppLanguage.fromCode('zh'), AppLanguage.chinese);
      expect(AppLanguage.fromCode('unknown'), AppLanguage.thai);
      expect(AppLanguage.fromCode(null), AppLanguage.thai);
    });
  });

  group('AppLocalizations Dictionary Tests', () {
    test('Default Thai returns expected titles and labels', () {
      const th = AppLocalizations(AppLanguage.thai);
      expect(th.t('appName'), 'SOIL AI ANALYZER');
      expect(th.t('temperature'), 'อุณหภูมิ');
      expect(th.t('moisture'), 'ความชื้น');
      expect(th.t('connected'), 'เชื่อมต่อแล้ว');
      expect(th.t('micOn'), 'เสียงเปิด');
      expect(th.t('micOff'), 'ตัดเสียง');
    });

    test('English dictionary contains proper terms', () {
      const en = AppLocalizations(AppLanguage.english);
      expect(en.t('appName'), 'SOIL AI ANALYZER');
      expect(en.t('temperature'), 'Temperature');
      expect(en.t('moisture'), 'Moisture');
      expect(en.t('connected'), 'CONNECTED');
      expect(en.t('micOn'), 'MIC ON');
      expect(en.t('micOff'), 'NOISE CUT');
    });

    test('Chinese dictionary contains proper terms', () {
      const zh = AppLocalizations(AppLanguage.chinese);
      expect(zh.t('appName'), 'SOIL AI ANALYZER');
      expect(zh.t('temperature'), '土壤温度');
      expect(zh.t('moisture'), '土壤水分');
      expect(zh.t('connected'), '已连接');
      expect(zh.t('micOn'), '声音开启');
      expect(zh.t('micOff'), '消除噪音');
    });

    test('All 8 sensor parameters exist in all 3 languages', () {
      final keys = [
        'moisture',
        'temperature',
        'conductivity',
        'ph',
        'nitrogen',
        'phosphorus',
        'potassium',
        'fertility',
      ];

      for (final lang in AppLanguage.values) {
        final loc = AppLocalizations(lang);
        for (final key in keys) {
          final val = loc.t(key);
          expect(val, isNotEmpty, reason: 'Key "$key" should not be empty for $lang');
          expect(val, isNot(equals(key)), reason: 'Key "$key" must have a defined translation for $lang');
        }
      }
    });
  });

  group('LanguageProvider Tests', () {
    test('Initializes with Thai as default', () {
      final provider = LanguageProvider();
      expect(provider.currentLanguage, AppLanguage.thai);
      expect(provider.currentFlag, '🇹🇭');
      expect(provider.currentLabel, 'ไทย');
      expect(provider.t('temperature'), 'อุณหภูมิ');
    });

    test('setLanguage updates state and helper methods', () async {
      final provider = LanguageProvider();
      bool notified = false;
      provider.addListener(() => notified = true);

      await provider.setLanguage(AppLanguage.english);
      expect(provider.currentLanguage, AppLanguage.english);
      expect(provider.currentFlag, '🇬🇧');
      expect(provider.currentLabel, 'English');
      expect(provider.t('temperature'), 'Temperature');
      expect(notified, isTrue);

      notified = false;
      await provider.setLanguage(AppLanguage.chinese);
      expect(provider.currentLanguage, AppLanguage.chinese);
      expect(provider.currentFlag, '🇨🇳');
      expect(provider.currentLabel, '中文');
      expect(provider.t('temperature'), '土壤温度');
      expect(notified, isTrue);
    });
  });
}
