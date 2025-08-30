import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getString('settings')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        children: [
          // Language Settings
          Card(
            child: ListTile(
              leading: const Icon(Icons.language, color: AppColors.primary),
              title: Text(languageProvider.getString('language')),
              subtitle: Text(
                languageProvider.currentLocale.languageCode == 'en'
                    ? languageProvider.getString('english')
                    : languageProvider.getString('nepali'),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showLanguageDialog(context, languageProvider);
              },
            ),
          ),

          const SizedBox(height: AppSizes.paddingMedium),

          // About Section
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info, color: AppColors.primary),
                  title: Text(languageProvider.getString('about')),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showAboutDialog(context, languageProvider);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                      const Icon(Icons.privacy_tip, color: AppColors.primary),
                  title: Text(languageProvider.getString('privacy_policy')),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Navigate to privacy policy
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading:
                      const Icon(Icons.description, color: AppColors.primary),
                  title: Text(languageProvider.getString('terms_of_service')),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // TODO: Navigate to terms of service
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(
      BuildContext context, LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(languageProvider.getString('select_language')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text(languageProvider.getString('english')),
                value: 'en',
                groupValue: languageProvider.currentLocale.languageCode,
                onChanged: (String? value) {
                  if (value != null) {
                    languageProvider.setLanguage(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
              RadioListTile<String>(
                title: Text(languageProvider.getString('nepali')),
                value: 'ne',
                groupValue: languageProvider.currentLocale.languageCode,
                onChanged: (String? value) {
                  if (value != null) {
                    languageProvider.setLanguage(value);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAboutDialog(
      BuildContext context, LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(languageProvider.getString('about')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                languageProvider.getString('app_name'),
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: AppSizes.paddingSmall),
              Text(
                  '${languageProvider.getString('version')}: ${AppConfig.appVersion}'),
              const SizedBox(height: AppSizes.paddingSmall),
              const Text(
                'A medicine identification app using OCR technology to help users identify medicines quickly and accurately.',
                style: AppTextStyles.body2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
