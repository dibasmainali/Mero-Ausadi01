import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/camera_provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/language_provider.dart';
import '../utils/constants.dart';
import 'result_screen.dart';
import 'search_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameraProvider = Provider.of<CameraProvider>(context, listen: false);
    await cameraProvider.initializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    final cameraProvider = Provider.of<CameraProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getString('scan_medicine')),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(cameraProvider, languageProvider),
    );
  }

  Widget _buildBody(
      CameraProvider cameraProvider, LanguageProvider languageProvider) {
    if (cameraProvider.error != null) {
      return _buildErrorView(cameraProvider, languageProvider);
    }

    if (!cameraProvider.isInitialized) {
      return _buildLoadingView();
    }

    if (cameraProvider.capturedImage != null) {
      return _buildImagePreviewView(cameraProvider, languageProvider);
    }

    return _buildCameraView(cameraProvider, languageProvider);
  }

  Widget _buildErrorView(
      CameraProvider cameraProvider, LanguageProvider languageProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            Text(
              cameraProvider.error!,
              style: AppTextStyles.body1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingLarge),
            ElevatedButton(
              onPressed: () => _initializeCamera(),
              child: Text(languageProvider.getString('try_again')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: AppSizes.paddingMedium),
          Text('Initializing camera...'),
        ],
      ),
    );
  }

  Widget _buildCameraView(
      CameraProvider cameraProvider, LanguageProvider languageProvider) {
    // Camera functionality temporarily disabled for web
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt,
              size: 80,
              color: Colors.white54,
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            Text(
              'Camera functionality is not available in web version',
              style: AppTextStyles.body1.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingMedium),
            Text(
              'Please use the search functionality instead',
              style: AppTextStyles.body2.copyWith(
                color: Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.paddingLarge),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
              child: Text(languageProvider.getString('search_medicine')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraOverlay(
      CameraProvider cameraProvider, LanguageProvider languageProvider) {
    // Camera overlay disabled
    return const SizedBox.shrink();
  }

  Widget _buildCameraControls(
      CameraProvider cameraProvider, LanguageProvider languageProvider) {
    // Camera controls disabled
    return const SizedBox.shrink();
  }

  Widget _buildImagePreviewView(
      CameraProvider cameraProvider, LanguageProvider languageProvider) {
    return Column(
      children: [
        // Image preview
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(AppSizes.paddingMedium),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              border: Border.all(color: AppColors.divider),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              child: Image.file(
                cameraProvider.capturedImage!,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),

        // Action buttons
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingLarge),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Retake button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => cameraProvider.retakePhoto(),
                  icon: const Icon(Icons.refresh),
                  label: Text(languageProvider.getString('retake_photo')),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.paddingMedium),
                  ),
                ),
              ),

              const SizedBox(width: AppSizes.paddingMedium),

              // Process button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: cameraProvider.isCapturing ? null : _processImage,
                  icon: cameraProvider.isCapturing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(
                    cameraProvider.isCapturing
                        ? languageProvider.getString('processing')
                        : languageProvider.getString('search'),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSizes.paddingMedium),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _captureImage() async {
    final cameraProvider = Provider.of<CameraProvider>(context, listen: false);
    await cameraProvider.captureImage();
  }

  Future<void> _processImage() async {
    final cameraProvider = Provider.of<CameraProvider>(context, listen: false);
    final medicineProvider =
        Provider.of<MedicineProvider>(context, listen: false);
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    try {
      // Process image with OCR
      await cameraProvider.processImageWithOCR();

      // Since OCR is disabled, show a message to use search instead
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'OCR functionality is not available in web version. Please use manual search instead.'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to search screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SearchScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
