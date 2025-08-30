import 'package:flutter/foundation.dart';
import '../models/medicine.dart';
import '../services/database_helper.dart';
import '../services/search_service.dart';
import '../services/ocr_service.dart';

class MedicineProvider with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final SearchService _searchService = SearchService();
  final OCRService _ocrService = OCRService();

  List<Medicine> _medicines = [];
  List<MedicineSearchResult> _searchResults = [];
  Medicine? _selectedMedicine;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Medicine> get medicines => _medicines;
  List<MedicineSearchResult> get searchResults => _searchResults;
  Medicine? get selectedMedicine => _selectedMedicine;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize provider
  Future<void> initialize() async {
    await loadMedicines();
  }

  // Load all medicines from database
  Future<void> loadMedicines() async {
    try {
      _setLoading(true);
      _medicines = await _databaseHelper.getAllMedicines();
      _clearError();
    } catch (e) {
      _setError('Failed to load medicines: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Search medicines by text query
  Future<void> searchMedicines(String query) async {
    try {
      _setLoading(true);
      _searchResults = _searchService.searchMedicines(_medicines, query);
      _clearError();
    } catch (e) {
      _setError('Search failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Search medicines by OCR text
  Future<void> searchByOCRText(String ocrText) async {
    try {
      _setLoading(true);
      final String cleanedText = _ocrService.cleanExtractedText(ocrText);
      _searchResults = _searchService.searchByOCRText(_medicines, cleanedText);
      _clearError();
    } catch (e) {
      _setError('OCR search failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get medicine by ID
  Future<Medicine?> getMedicineById(int id) async {
    try {
      _setLoading(true);
      final medicine = await _databaseHelper.getMedicineById(id);
      if (medicine != null) {
        _selectedMedicine = medicine;
      }
      _clearError();
      return medicine;
    } catch (e) {
      _setError('Failed to get medicine: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Get medicine by barcode
  Future<Medicine?> getMedicineByBarcode(String barcode) async {
    try {
      _setLoading(true);
      final medicine = await _databaseHelper.getMedicineByBarcode(barcode);
      if (medicine != null) {
        _selectedMedicine = medicine;
      }
      _clearError();
      return medicine;
    } catch (e) {
      _setError('Failed to get medicine by barcode: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Add new medicine
  Future<bool> addMedicine(Medicine medicine) async {
    try {
      _setLoading(true);
      final id = await _databaseHelper.insertMedicine(medicine);
      if (id > 0) {
        final newMedicine = medicine.copyWith(id: id);
        _medicines.add(newMedicine);
        _clearError();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to add medicine: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update medicine
  Future<bool> updateMedicine(Medicine medicine) async {
    try {
      _setLoading(true);
      final rowsAffected = await _databaseHelper.updateMedicine(medicine);
      if (rowsAffected > 0) {
        final index = _medicines.indexWhere((m) => m.id == medicine.id);
        if (index != -1) {
          _medicines[index] = medicine;
        }
        if (_selectedMedicine?.id == medicine.id) {
          _selectedMedicine = medicine;
        }
        _clearError();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to update medicine: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete medicine
  Future<bool> deleteMedicine(int id) async {
    try {
      _setLoading(true);
      final rowsAffected = await _databaseHelper.deleteMedicine(id);
      if (rowsAffected > 0) {
        _medicines.removeWhere((m) => m.id == id);
        if (_selectedMedicine?.id == id) {
          _selectedMedicine = null;
        }
        _clearError();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Failed to delete medicine: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Set selected medicine
  void selectMedicine(Medicine medicine) {
    _selectedMedicine = medicine;
    notifyListeners();
  }

  // Clear selected medicine
  void clearSelectedMedicine() {
    _selectedMedicine = null;
    notifyListeners();
  }

  // Clear search results
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  // Get medicine count
  Future<int> getMedicineCount() async {
    return await _databaseHelper.getMedicineCount();
  }

  // Sync with cloud database
  Future<void> syncWithCloud(List<Medicine> cloudMedicines) async {
    try {
      _setLoading(true);
      await _databaseHelper.batchInsertMedicines(cloudMedicines);
      await loadMedicines(); // Reload medicines after sync
      _clearError();
    } catch (e) {
      _setError('Failed to sync with cloud: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Check if search result is high confidence
  bool isHighConfidenceMatch(MedicineSearchResult result) {
    return _searchService.isHighConfidenceMatch(result);
  }

  // Get confidence level string
  String getConfidenceLevel(double confidence) {
    return _searchService.getConfidenceLevel(confidence);
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}
