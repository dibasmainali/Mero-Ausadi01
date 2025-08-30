import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medicine.dart';
import '../providers/medicine_provider.dart';
import '../providers/language_provider.dart';
import '../utils/constants.dart';
import 'medicine_detail_screen.dart';

class ResultScreen extends StatelessWidget {
  final OCRResult ocrResult;
  final List<MedicineSearchResult> searchResults;

  const ResultScreen({
    super.key,
    required this.ocrResult,
    required this.searchResults,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final medicineProvider = Provider.of<MedicineProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getString('medicine_found')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(context, languageProvider, medicineProvider),
    );
  }

  Widget _buildBody(BuildContext context, LanguageProvider languageProvider, MedicineProvider medicineProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // OCR Results Section
          _buildOCRResultsSection(context, languageProvider),
          
          const SizedBox(height: AppSizes.paddingLarge),
          
          // Search Results Section
          _buildSearchResultsSection(context, languageProvider, medicineProvider),
          
          const SizedBox(height: AppSizes.paddingLarge),
          
          // Action Buttons
          _buildActionButtons(context, languageProvider),
        ],
      ),
    );
  }

  Widget _buildOCRResultsSection(BuildContext context, LanguageProvider languageProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.text_fields, color: AppColors.primary),
                const SizedBox(width: AppSizes.paddingSmall),
                Text(
                  'Extracted Text',
                  style: AppTextStyles.heading2,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                ocrResult.extractedText.isNotEmpty 
                    ? ocrResult.extractedText 
                    : 'No text detected',
                style: AppTextStyles.body1,
              ),
            ),
            const SizedBox(height: AppSizes.paddingSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Confidence: ${(ocrResult.confidence * 100).toStringAsFixed(1)}%',
                  style: AppTextStyles.caption,
                ),
                Text(
                  'Text Blocks: ${ocrResult.textBlocks.length}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsSection(BuildContext context, LanguageProvider languageProvider, MedicineProvider medicineProvider) {
    if (searchResults.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Column(
            children: [
              const Icon(
                Icons.search_off,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSizes.paddingMedium),
              Text(
                languageProvider.getString('no_results'),
                style: AppTextStyles.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.paddingSmall),
              Text(
                'No medicines found matching the extracted text. Try taking a clearer photo or search manually.',
                style: AppTextStyles.body2,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${searchResults.length} Medicine${searchResults.length > 1 ? 's' : ''} Found',
          style: AppTextStyles.heading2,
        ),
        const SizedBox(height: AppSizes.paddingMedium),
        ...searchResults.map((result) => _buildMedicineCard(context, result, languageProvider, medicineProvider)),
      ],
    );
  }

  Widget _buildMedicineCard(BuildContext context, MedicineSearchResult result, LanguageProvider languageProvider, MedicineProvider medicineProvider) {
    final bool isHighConfidence = medicineProvider.isHighConfidenceMatch(result);
    final String confidenceLevel = medicineProvider.getConfidenceLevel(result.confidenceScore);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      child: InkWell(
        onTap: () => _navigateToMedicineDetail(context, result.medicine),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with confidence indicator
              Row(
                children: [
                  Expanded(
                    child: Text(
                      result.medicine.brandName,
                      style: AppTextStyles.heading2,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.paddingSmall,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isHighConfidence ? AppColors.success : AppColors.warning,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    ),
                    child: Text(
                      confidenceLevel,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppSizes.paddingSmall),
              
              // Medicine details
              Text(
                'Generic: ${result.medicine.genericName}',
                style: AppTextStyles.body1,
              ),
              Text(
                'Strength: ${result.medicine.strength}',
                style: AppTextStyles.body1,
              ),
              Text(
                'Manufacturer: ${result.medicine.manufacturer}',
                style: AppTextStyles.body2,
              ),
              
              const SizedBox(height: AppSizes.paddingSmall),
              
              // Confidence score
              Row(
                children: [
                  Text(
                    'Confidence: ${(result.confidenceScore * 100).toStringAsFixed(1)}%',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: result.confidenceScore,
                      backgroundColor: AppColors.divider,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isHighConfidence ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (result.matchedText.isNotEmpty) ...[
                const SizedBox(height: AppSizes.paddingSmall),
                Text(
                  'Matched: "${result.matchedText}"',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, LanguageProvider languageProvider) {
    return Column(
      children: [
        // Try again button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.camera_alt),
            label: Text('Scan Another Medicine'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingMedium),
            ),
          ),
        ),
        
        const SizedBox(height: AppSizes.paddingMedium),
        
        // Manual search button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _navigateToManualSearch(context),
            icon: const Icon(Icons.search),
            label: Text(languageProvider.getString('manual_search')),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingMedium),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToMedicineDetail(BuildContext context, Medicine medicine) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicineDetailScreen(medicine: medicine),
      ),
    );
  }

  void _navigateToManualSearch(BuildContext context) {
    Navigator.pop(context); // Go back to camera screen
    // The camera screen will handle navigation to search
  }
}
