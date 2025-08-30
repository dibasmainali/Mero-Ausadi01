import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../providers/camera_provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/language_provider.dart';
import '../utils/constants.dart';
import 'result_screen.dart';

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

  Widget _buildBody(CameraProvider cameraProvider, LanguageProvider languageProvider) {
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

  Widget _buildErrorView(CameraProvider cameraProvider, LanguageProvider languageProvider) {
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

  Widget _buildCameraView(CameraProvider cameraProvider, LanguageProvider languageProvider) {
    if (cameraProvider.cameraController == null) {
      return const Center(child: Text('Camera not available'));
    }

    return Stack(
      children: [
        // Camera preview
        CameraPreview(cameraProvider.cameraController!),
        
        // Camera overlay
        _buildCameraOverlay(cameraProvider, languageProvider),
        
        // Camera controls
        _buildCameraControls(cameraProvider, languageProvider),
      ],
    );
  }

  Widget _buildCameraOverlay(CameraProvider cameraProvider, LanguageProvider languageProvider) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
      ),
      margin: const EdgeInsets.all(AppSizes.paddingLarge),
      child: Column(
        children: [
          // Top section
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(AppSizes.paddingMedium),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: Center(
                child: Text(
                  'Position medicine label here',
                  style: AppTextStyles.body1.copyWith(
                    color: Colors.white,
                    backgroundColor: Colors.black54,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraControls(CameraProvider cameraProvider, LanguageProvider languageProvider) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Flash toggle
            if (cameraProvider.isFlashAvailable)
              IconButton(
                onPressed: () => cameraProvider.toggleFlash(),
                icon: Icon(
                  cameraProvider.currentFlashMode == FlashMode.off
                      ? Icons.flash_off
                      : cameraProvider.currentFlashMode == FlashMode.auto
                          ? Icons.flash_auto
                          : Icons.flash_on,
                  color: Colors.white,
                  size: AppSizes.iconSizeLarge,
                ),
              ),
            
            // Capture button
            GestureDetector(
              onTap: cameraProvider.isCapturing ? null : _captureImage,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                  color: cameraProvider.isCapturing
                      ? Colors.grey
                      : Colors.white.withOpacity(0.3),
                ),
                child: cameraProvider.isCapturing
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Icon(
                        Icons.camera,
                        color: Colors.white,
                        size: 40,
                      ),
              ),
            ),
            
            // Switch camera
            if (cameraProvider.cameras.length > 1)
              IconButton(
                onPressed: () => cameraProvider.switchCamera(),
                icon: const Icon(
                  Icons.flip_camera_ios,
                  color: Colors.white,
                  size: AppSizes.iconSizeLarge,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreviewView(CameraProvider cameraProvider, LanguageProvider languageProvider) {
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
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingMedium),
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
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingMedium),
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
    final medicineProvider = Provider.of<MedicineProvider>(context, listen: false);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    try {
      // Process image with OCR
      final ocrResult = await cameraProvider.processImageWithOCR();
      
      if (ocrResult != null) {
        // Search medicines using OCR text
        await medicineProvider.searchByOCRText(ocrResult.extractedText);
        
        // Navigate to results screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(
                ocrResult: ocrResult,
                searchResults: medicineProvider.searchResults,
              ),
            ),
          );
        }
      } else {
        // Show error if OCR failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to process image. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
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
