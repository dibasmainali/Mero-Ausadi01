import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../utils/constants.dart';

class MedicineDetailScreen extends StatelessWidget {
  final Medicine medicine;

  const MedicineDetailScreen({
    super.key,
    required this.medicine,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(medicine.brandName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine Image
            if (medicine.imageUrl != null)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  color: AppColors.background,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  child: Image.network(
                    medicine.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.medication,
                          size: 80,
                          color: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  color: AppColors.background,
                ),
                child: const Center(
                  child: Icon(
                    Icons.medication,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
              ),

            const SizedBox(height: AppSizes.paddingLarge),

            // Medicine Information
            _buildInfoSection('Brand Name', medicine.brandName),
            _buildInfoSection('Generic Name', medicine.genericName),
            _buildInfoSection('Strength', medicine.strength),
            _buildInfoSection('Manufacturer', medicine.manufacturer),

            const SizedBox(height: AppSizes.paddingMedium),

            // Uses
            _buildDetailSection('Uses', medicine.uses),

            const SizedBox(height: AppSizes.paddingMedium),

            // Side Effects
            _buildDetailSection('Side Effects', medicine.sideEffects),

            const SizedBox(height: AppSizes.paddingMedium),

            // Warnings
            _buildDetailSection('Warnings', medicine.warnings),

            const SizedBox(height: AppSizes.paddingLarge),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                border: Border.all(color: AppColors.warning),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Disclaimer',
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingSmall),
                  const Text(
                    'This information is for educational purposes only. Always consult with a healthcare professional before taking any medication.',
                    style: AppTextStyles.body2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.paddingSmall),
          Text(
            value,
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading2,
        ),
        const SizedBox(height: AppSizes.paddingSmall),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text(
            content,
            style: AppTextStyles.body2,
          ),
        ),
      ],
    );
  }
}
