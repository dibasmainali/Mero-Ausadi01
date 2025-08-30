import 'package:fuzzy/fuzzy.dart';
import '../models/medicine.dart';
import '../utils/constants.dart';

class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  List<MedicineSearchResult> searchMedicines(List<Medicine> medicines, String query) {
    if (query.trim().isEmpty) return [];

    final List<MedicineSearchResult> results = [];
    final String cleanQuery = query.toLowerCase().trim();

    // Create searchable text for each medicine
    for (final Medicine medicine in medicines) {
      final String searchableText = _createSearchableText(medicine);
      final double confidence = _calculateConfidence(cleanQuery, searchableText, medicine);
      
      if (confidence > 0.0) {
        results.add(MedicineSearchResult(
          medicine: medicine,
          confidenceScore: confidence,
          matchedText: _findMatchedText(cleanQuery, searchableText),
        ));
      }
    }

    // Sort by confidence score (highest first)
    results.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));

    // Return top results based on configuration
    return results.take(AppConfig.maxSearchResults).toList();
  }

  String _createSearchableText(Medicine medicine) {
    final List<String> searchableParts = [
      medicine.brandName,
      medicine.genericName,
      medicine.manufacturer,
      medicine.strength,
    ];

    return searchableParts
        .where((part) => part.isNotEmpty)
        .join(' ')
        .toLowerCase();
  }

  double _calculateConfidence(String query, String searchableText, Medicine medicine) {
    double confidence = 0.0;

    // Exact match gets highest confidence
    if (searchableText.contains(query)) {
      confidence += 0.8;
    }

    // Brand name exact match
    if (medicine.brandName.toLowerCase().contains(query)) {
      confidence += 0.6;
    }

    // Generic name exact match
    if (medicine.genericName.toLowerCase().contains(query)) {
      confidence += 0.5;
    }

    // Manufacturer match
    if (medicine.manufacturer.toLowerCase().contains(query)) {
      confidence += 0.3;
    }

    // Fuzzy matching using the fuzzy package
    final fuzzy = Fuzzy(
      [searchableText],
      options: FuzzyOptions(
        threshold: 0.3,
        distance: 100,
      ),
    );

    final fuzzyResults = fuzzy.search(query);
    if (fuzzyResults.isNotEmpty) {
      final fuzzyScore = fuzzyResults.first.score;
      confidence += (1.0 - fuzzyScore) * 0.4; // Convert fuzzy score to confidence
    }

    // Word-by-word matching
    final List<String> queryWords = query.split(RegExp(r'\s+'));
    final List<String> textWords = searchableText.split(RegExp(r'\s+'));

    int matchedWords = 0;
    for (final String queryWord in queryWords) {
      if (queryWord.length > 2) { // Only consider words longer than 2 characters
        for (final String textWord in textWords) {
          if (textWord.contains(queryWord) || queryWord.contains(textWord)) {
            matchedWords++;
            break;
          }
        }
      }
    }

    if (queryWords.isNotEmpty) {
      confidence += (matchedWords / queryWords.length) * 0.3;
    }

    // Normalize confidence to 0.0 - 1.0 range
    return confidence.clamp(0.0, 1.0);
  }

  String _findMatchedText(String query, String searchableText) {
    final List<String> words = searchableText.split(RegExp(r'\s+'));
    final List<String> queryWords = query.split(RegExp(r'\s+'));
    final List<String> matchedWords = [];

    for (final String word in words) {
      for (final String queryWord in queryWords) {
        if (word.contains(queryWord) || queryWord.contains(word)) {
          matchedWords.add(word);
          break;
        }
      }
    }

    return matchedWords.join(' ');
  }

  List<MedicineSearchResult> searchByOCRText(List<Medicine> medicines, String ocrText) {
    if (ocrText.trim().isEmpty) return [];

    final List<MedicineSearchResult> results = [];
    final String cleanOcrText = ocrText.toLowerCase().trim();

    // Extract potential medicine names from OCR text
    final List<String> potentialNames = _extractPotentialNames(cleanOcrText);

    for (final String potentialName in potentialNames) {
      final List<MedicineSearchResult> nameResults = searchMedicines(medicines, potentialName);
      results.addAll(nameResults);
    }

    // Remove duplicates and sort by confidence
    final Map<int, MedicineSearchResult> uniqueResults = {};
    for (final result in results) {
      if (!uniqueResults.containsKey(result.medicine.id)) {
        uniqueResults[result.medicine.id!] = result;
      } else if (result.confidenceScore > uniqueResults[result.medicine.id]!.confidenceScore) {
        uniqueResults[result.medicine.id!] = result;
      }
    }

    final List<MedicineSearchResult> finalResults = uniqueResults.values.toList();
    finalResults.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));

    return finalResults.take(AppConfig.maxSearchResults).toList();
  }

  List<String> _extractPotentialNames(String ocrText) {
    final List<String> potentialNames = [];
    final List<String> lines = ocrText.split('\n');

    for (final String line in lines) {
      final String cleanLine = line.trim();
      if (cleanLine.isNotEmpty && cleanLine.length > 2) {
        // Look for lines that might contain medicine names
        if (RegExp(r'^[a-z][a-z\s\-]+$').hasMatch(cleanLine) ||
            RegExp(r'^[a-z][a-z\s\-]+\s+\d+').hasMatch(cleanLine)) {
          potentialNames.add(cleanLine);
        }
      }
    }

    // Also extract individual words that might be medicine names
    final List<String> words = ocrText.split(RegExp(r'\s+'));
    for (final String word in words) {
      final String cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
      if (cleanWord.length > 3 && RegExp(r'^[a-zA-Z]+$').hasMatch(cleanWord)) {
        potentialNames.add(cleanWord);
      }
    }

    return potentialNames.toSet().toList(); // Remove duplicates
  }

  bool isHighConfidenceMatch(MedicineSearchResult result) {
    return result.confidenceScore >= AppConfig.minConfidenceScore;
  }

  String getConfidenceLevel(double confidence) {
    if (confidence >= 0.9) return 'Very High';
    if (confidence >= 0.7) return 'High';
    if (confidence >= 0.5) return 'Medium';
    if (confidence >= 0.3) return 'Low';
    return 'Very Low';
  }
}
