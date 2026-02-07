import 'package:flutter/material.dart';
import 'package:twende/l10n/l10n.dart';

class LanguagePickerWidget extends StatelessWidget {
  final Function(Locale) onLocaleChanged;

  const LanguagePickerWidget({
    Key? key,
    required this.onLocaleChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);

    return DropdownButton<Locale>(
      value: locale,
      icon: const Icon(Icons.language, color: Colors.white),
      underline: Container(),
      dropdownColor: const Color(0xFFF5141E),
      items: L10n.all.map<DropdownMenuItem<Locale>>(
        (Locale locale) {
          final flag = L10n.getFlag(locale.languageCode);
          return DropdownMenuItem<Locale>(
            value: locale,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  locale.languageCode.toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        },
      ).toList(),
      onChanged: (Locale? newLocale) {
        if (newLocale != null) {
          onLocaleChanged(newLocale);
        }
      },
    );
  }
}
  }
}
