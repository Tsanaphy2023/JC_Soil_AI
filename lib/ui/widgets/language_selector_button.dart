import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/language_provider.dart';

class LanguageSelectorButton extends StatelessWidget {
  final bool compact;

  const LanguageSelectorButton({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final currentLang = langProvider.currentLanguage;

    return GestureDetector(
      onTap: () => _showLanguageModal(context),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.cyanAccent.withValues(alpha: 0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withValues(alpha: 0.15),
              blurRadius: 6,
              spreadRadius: 0.5,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentLang.flag,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 5),
            Text(
              currentLang.code.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.cyanAccent,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        final langProvider = modalCtx.watch<LanguageProvider>();
        final currentLang = langProvider.currentLanguage;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.language, color: Colors.cyanAccent, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    langProvider.t('selectLanguage'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...AppLanguage.values.map((lang) {
                final isSelected = lang == currentLang;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.cyanAccent.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? Colors.cyanAccent
                          : Colors.white.withValues(alpha: 0.1),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.cyanAccent : Colors.white12,
                        ),
                      ),
                      child: Text(
                        lang.flag,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    title: Text(
                      lang.label,
                      style: TextStyle(
                        color: isSelected ? Colors.cyanAccent : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      _getLanguageSubLabel(lang),
                      style: TextStyle(
                        color: isSelected ? Colors.cyanAccent.withValues(alpha: 0.7) : Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.cyanAccent, size: 24)
                        : const Icon(Icons.circle_outlined, color: Colors.white24, size: 22),
                    onTap: () async {
                      Navigator.pop(modalCtx);
                      await langProvider.setLanguage(lang);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.teal.shade900,
                            content: Row(
                              children: [
                                Text(lang.flag, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    langProvider.t('languageChanged'),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _getLanguageSubLabel(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.thai:
        return 'ภาษาไทย (ค่าเริ่มต้น)';
      case AppLanguage.english:
        return 'English (International)';
      case AppLanguage.chinese:
        return '中文 (简体中文)';
    }
  }
}
