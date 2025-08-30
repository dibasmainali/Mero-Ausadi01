import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/language_provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import 'camera_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);
    await medicineProvider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final appProvider = Provider.of<AppProvider>(context);
    final medicineProvider = Provider.of<MedicineProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.getString('app_name'),
          style: AppTextStyles.heading1.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                child: Column(
                  children: [
                    const Icon(
                      Icons.medication,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: AppSizes.paddingMedium),
                    Text(
                      languageProvider.getString('app_name'),
                      style: AppTextStyles.heading1.copyWith(
                        color: Colors.white,
                        fontSize: 28,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    Text(
                      'Identify medicines with ease',
                      style: AppTextStyles.body1.copyWith(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppSizes.radiusLarge),
                      topRight: Radius.circular(AppSizes.radiusLarge),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingLarge),
                    child: Column(
                      children: [
                        // Scan Medicine Card
                        _buildActionCard(
                          icon: Icons.camera_alt,
                          title: languageProvider.getString('scan_medicine'),
                          subtitle: 'Take a photo of medicine label',
                          color: AppColors.primary,
                          onTap: () => _navigateToCamera(),
                        ),
                        
                        const SizedBox(height: AppSizes.paddingMedium),
                        
                        // Search Medicine Card
                        _buildActionCard(
                          icon: Icons.search,
                          title: languageProvider.getString('search_medicine'),
                          subtitle: 'Search by medicine name',
                          color: AppColors.secondary,
                          onTap: () => _navigateToSearch(),
                        ),
                        
                        const SizedBox(height: AppSizes.paddingLarge),
                        
                        // Stats section
                        if (medicineProvider.medicines.isNotEmpty)
                          _buildStatsSection(medicineProvider),
                        
                        const Spacer(),
                        
                        // Footer
                        _buildFooter(languageProvider),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                ),
                child: Icon(
                  icon,
                  size: AppSizes.iconSizeLarge,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSizes.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.heading2.copyWith(color: color),
                    ),
                    const SizedBox(height: AppSizes.paddingSmall),
                    Text(
                      subtitle,
                      style: AppTextStyles.body2,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondary,
                size: AppSizes.iconSizeSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(MedicineProvider medicineProvider) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.medication,
            label: 'Medicines',
            value: '${medicineProvider.medicines.length}',
          ),
          _buildStatItem(
            icon: Icons.search,
            label: 'Searches',
            value: '${medicineProvider.searchResults.length}',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: AppSizes.iconSizeMedium,
        ),
        const SizedBox(height: AppSizes.paddingSmall),
        Text(
          value,
          style: AppTextStyles.heading2,
        ),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  Widget _buildFooter(LanguageProvider languageProvider) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: AppSizes.paddingMedium),
        Text(
          'Version ${AppConfig.appVersion}',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: AppSizes.paddingSmall),
        Text(
          'Made with ❤️ for Nepal',
          style: AppTextStyles.caption,
        ),
      ],
    );
  }

  void _navigateToCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchScreen()),
    );
  }
}
