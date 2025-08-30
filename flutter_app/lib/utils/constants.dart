import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF1976D2);
  static const Color accent = Color(0xFF64B5F6);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFF9800);
  static const Color success = Color(0xFF4CAF50);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFBDBDBD);
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

class AppSizes {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
}

class AppConfig {
  static const String appName = 'Ausadi Thaha';
  static const String appVersion = '1.0.0';
  static const String apiBaseUrl = 'https://your-api-domain.com/api';
  static const String firebaseProjectId = 'ausadi-thaha';
  
  // OCR Configuration
  static const double minConfidenceScore = 0.9;
  static const int maxSearchResults = 3;
  
  // Database Configuration
  static const String databaseName = 'ausadi_thaha.db';
  static const int databaseVersion = 1;
  
  // Camera Configuration
  static const double cameraAspectRatio = 4/3;
  static const Duration cameraTimeout = Duration(seconds: 30);
}

class AppStrings {
  // English Strings
  static const Map<String, String> en = {
    'app_name': 'Ausadi Thaha',
    'scan_medicine': 'Scan Medicine',
    'search_medicine': 'Search Medicine',
    'settings': 'Settings',
    'language': 'Language',
    'english': 'English',
    'nepali': 'Nepali',
    'camera_permission': 'Camera Permission',
    'camera_permission_message': 'This app needs camera access to scan medicine labels.',
    'grant_permission': 'Grant Permission',
    'capture_photo': 'Capture Photo',
    'retake_photo': 'Retake Photo',
    'processing': 'Processing...',
    'scanning_text': 'Scanning text from image...',
    'searching_database': 'Searching database...',
    'medicine_found': 'Medicine Found',
    'medicine_not_found': 'Medicine Not Found',
    'try_again': 'Try Again',
    'manual_search': 'Manual Search',
    'enter_medicine_name': 'Enter medicine name',
    'search': 'Search',
    'no_results': 'No results found',
    'brand_name': 'Brand Name',
    'generic_name': 'Generic Name',
    'strength': 'Strength',
    'manufacturer': 'Manufacturer',
    'uses': 'Uses',
    'side_effects': 'Side Effects',
    'warnings': 'Warnings',
    'disclaimer': 'Disclaimer',
    'confidence_score': 'Confidence Score',
    'possible_matches': 'Possible Matches',
    'select_language': 'Select Language',
    'about': 'About',
    'version': 'Version',
    'developed_by': 'Developed by',
    'privacy_policy': 'Privacy Policy',
    'terms_of_service': 'Terms of Service',
  };
  
  // Nepali Strings
  static const Map<String, String> ne = {
    'app_name': 'औषधी थाहा',
    'scan_medicine': 'औषधी स्क्यान गर्नुहोस्',
    'search_medicine': 'औषधी खोज्नुहोस्',
    'settings': 'सेटिङहरू',
    'language': 'भाषा',
    'english': 'अंग्रेजी',
    'nepali': 'नेपाली',
    'camera_permission': 'क्यामेरा अनुमति',
    'camera_permission_message': 'यो एपले औषधी लेबल स्क्यान गर्न क्यामेरा पहुँच चाहिन्छ।',
    'grant_permission': 'अनुमति दिनुहोस्',
    'capture_photo': 'फोटो लिनुहोस्',
    'retake_photo': 'फोटो पुनः लिनुहोस्',
    'processing': 'प्रक्रिया गर्दै...',
    'scanning_text': 'छविबाट पाठ स्क्यान गर्दै...',
    'searching_database': 'डाटाबेसमा खोज्दै...',
    'medicine_found': 'औषधी फेला पर्यो',
    'medicine_not_found': 'औषधी फेला परेन',
    'try_again': 'पुनः प्रयास गर्नुहोस्',
    'manual_search': 'म्यानुअल खोज',
    'enter_medicine_name': 'औषधीको नाम लेख्नुहोस्',
    'search': 'खोज्नुहोस्',
    'no_results': 'कुनै परिणाम फेला परेन',
    'brand_name': 'ब्रान्ड नाम',
    'generic_name': 'जेनेरिक नाम',
    'strength': 'शक्ति',
    'manufacturer': 'निर्माता',
    'uses': 'प्रयोगहरू',
    'side_effects': 'साइड इफेक्टहरू',
    'warnings': 'चेतावनीहरू',
    'disclaimer': 'छुटकारा',
    'confidence_score': 'विश्वास स्कोर',
    'possible_matches': 'सम्भावित मेलहरू',
    'select_language': 'भाषा छान्नुहोस्',
    'about': 'बारेमा',
    'version': 'संस्करण',
    'developed_by': 'विकसित गर्ने',
    'privacy_policy': 'गोपनीयता नीति',
    'terms_of_service': 'सेवा सर्तहरू',
  };
}
