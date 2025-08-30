import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import '../models/medicine.dart';

class OCRService {
  static final OCRService _instance = OCRService._internal();
  factory OCRService() => _instance;
  OCRService._internal();

  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<OCRResult> processImage(File imageFile) async {
    try {
      // Preprocess the image
      final Uint8List processedImageBytes = await _preprocessImage(imageFile);
      
      // Create InputImage from processed bytes
      final InputImage inputImage = InputImage.fromBytes(
        bytes: processedImageBytes,
        metadata: InputImageMetadata(
          size: Size(processedImageBytes.length.toDouble(), processedImageBytes.length.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: processedImageBytes.length,
        ),
      );

      // Perform OCR
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Extract text blocks and calculate confidence
      final List<TextBlock> textBlocks = [];
      String fullText = '';
      double totalConfidence = 0.0;
      int blockCount = 0;

      for (final TextBlock block in recognizedText.textBlocks) {
        final List<Offset> boundingBox = block.cornerPoints
            .map((point) => Offset(point.x.toDouble(), point.y.toDouble()))
            .toList();

        textBlocks.add(TextBlock(
          text: block.text,
          confidence: block.confidence ?? 0.0,
          boundingBox: boundingBox,
        ));

        fullText += '${block.text}\n';
        totalConfidence += block.confidence ?? 0.0;
        blockCount++;
      }

      final double averageConfidence = blockCount > 0 ? totalConfidence / blockCount : 0.0;

      return OCRResult(
        extractedText: fullText.trim(),
        confidence: averageConfidence,
        textBlocks: textBlocks,
      );
    } catch (e) {
      throw Exception('OCR processing failed: $e');
    }
  }

  Future<Uint8List> _preprocessImage(File imageFile) async {
    try {
      // Read the image
      final Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize image for better OCR performance (max 1024px width)
      if (image.width > 1024) {
        final double scale = 1024 / image.width;
        image = img.copyResize(
          image,
          width: 1024,
          height: (image.height * scale).round(),
        );
      }

      // Convert to grayscale for better text recognition
      image = img.grayscale(image);

      // Enhance contrast
      image = img.contrast(image, 150);

      // Apply sharpening filter
      image = img.sharpen(image, amount: 1.5);

      // Adjust brightness
      image = img.brightness(image, 10);

      // Convert back to bytes
      return Uint8List.fromList(img.encodeJpg(image, quality: 90));
    } catch (e) {
      throw Exception('Image preprocessing failed: $e');
    }
  }

  List<String> extractMedicineKeywords(String text) {
    final List<String> keywords = [];
    final List<String> words = text.toLowerCase().split(RegExp(r'\s+'));
    
    // Common medicine-related keywords
    const List<String> medicineKeywords = [
      'mg', 'mcg', 'ml', 'tablet', 'capsule', 'syrup', 'injection',
      'paracetamol', 'acetaminophen', 'ibuprofen', 'aspirin',
      'amoxicillin', 'penicillin', 'antibiotic', 'antiviral',
      'pharma', 'pharmaceutical', 'ltd', 'pvt', 'company',
      'manufactured', 'manufacturer', 'distributed', 'marketed',
    ];

    for (final String word in words) {
      final String cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
      if (medicineKeywords.contains(cleanWord) || 
          cleanWord.length > 3 && RegExp(r'^[a-zA-Z]+$').hasMatch(cleanWord)) {
        keywords.add(cleanWord);
      }
    }

    return keywords;
  }

  String cleanExtractedText(String text) {
    // Remove common OCR artifacts and clean up text
    return text
        .replaceAll(RegExp(r'[^\w\s\-\.]'), ' ') // Remove special characters except hyphens and dots
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .trim();
  }

  List<String> extractPotentialMedicineNames(String text) {
    final List<String> potentialNames = [];
    final List<String> lines = text.split('\n');
    
    for (final String line in lines) {
      final String cleanLine = line.trim();
      if (cleanLine.isNotEmpty && cleanLine.length > 2) {
        // Look for lines that might contain medicine names
        if (RegExp(r'^[A-Z][a-zA-Z\s\-]+$').hasMatch(cleanLine) ||
            RegExp(r'^[A-Z][a-zA-Z\s\-]+\s+\d+').hasMatch(cleanLine)) {
          potentialNames.add(cleanLine);
        }
      }
    }
    
    return potentialNames;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
