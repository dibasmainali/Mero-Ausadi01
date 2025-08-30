from sqlalchemy.orm import Session
from typing import List, Dict, Any
from fuzzywuzzy import fuzz, process
from services.medicine_service import MedicineService
from services.ocr_service import OCRService

class SearchService:
    def __init__(self):
        self.medicine_service = MedicineService()
        self.ocr_service = OCRService()

    def search_medicines(self, db: Session, query: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Basic search medicines by text"""
        medicines = self.medicine_service.search_medicines(db, query, limit)
        return [self._format_medicine_result(medicine) for medicine in medicines]

    def fuzzy_search_medicines(self, db: Session, query: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Fuzzy search medicines with confidence scoring"""
        results = self.medicine_service.search_medicines_with_confidence(db, query, limit)
        return [self._format_search_result(result) for result in results]

    def search_by_ocr_text(self, db: Session, text: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Search medicines using OCR extracted text"""
        results = self.ocr_service.search_medicines_by_ocr_text(db, text, limit)
        return [self._format_ocr_result(result) for result in results]

    def search_by_barcode(self, db: Session, barcode: str) -> Dict[str, Any]:
        """Search medicine by barcode"""
        medicine = self.medicine_service.get_medicine_by_barcode(db, barcode)
        if medicine:
            return {
                "medicine": self._format_medicine_result(medicine),
                "confidence_score": 1.0,
                "match_type": "barcode"
            }
        return None

    def advanced_search(self, db: Session, query: str, filters: Dict[str, Any] = None, limit: int = 10) -> List[Dict[str, Any]]:
        """Advanced search with filters"""
        medicines = self.medicine_service.advanced_search_medicines(db, query, filters, limit)
        return [self._format_medicine_result(medicine) for medicine in medicines]

    def search_by_manufacturer(self, db: Session, manufacturer: str, limit: int = 50) -> List[Dict[str, Any]]:
        """Search medicines by manufacturer"""
        medicines = self.medicine_service.get_medicines_by_manufacturer(db, manufacturer, limit)
        return [self._format_medicine_result(medicine) for medicine in medicines]

    def search_by_generic_name(self, db: Session, generic_name: str, limit: int = 50) -> List[Dict[str, Any]]:
        """Search medicines by generic name"""
        medicines = self.medicine_service.get_medicines_by_generic_name(db, generic_name, limit)
        return [self._format_medicine_result(medicine) for medicine in medicines]

    def search_by_strength(self, db: Session, strength: str, limit: int = 50) -> List[Dict[str, Any]]:
        """Search medicines by strength"""
        medicines = self.medicine_service.get_medicines_by_strength(db, strength, limit)
        return [self._format_medicine_result(medicine) for medicine in medicines]

    def get_popular_medicines(self, db: Session, limit: int = 10) -> List[Dict[str, Any]]:
        """Get most popular medicines"""
        medicines = self.medicine_service.get_popular_medicines(db, limit)
        return [self._format_medicine_result(medicine) for medicine in medicines]

    def _format_medicine_result(self, medicine) -> Dict[str, Any]:
        """Format medicine object for API response"""
        return {
            "id": medicine.id,
            "brand_name": medicine.brand_name,
            "generic_name": medicine.generic_name,
            "strength": medicine.strength,
            "manufacturer": medicine.manufacturer,
            "uses": medicine.uses,
            "side_effects": medicine.side_effects,
            "warnings": medicine.warnings,
            "barcode": medicine.barcode,
            "image_url": medicine.image_url,
            "created_at": medicine.created_at.isoformat() if medicine.created_at else None,
            "updated_at": medicine.updated_at.isoformat() if medicine.updated_at else None
        }

    def _format_search_result(self, result: Dict[str, Any]) -> Dict[str, Any]:
        """Format search result with confidence score"""
        return {
            "medicine": self._format_medicine_result(result['medicine']),
            "confidence_score": result['confidence_score'],
            "matched_text": result['matched_text'],
            "match_type": result.get('match_type', 'text')
        }

    def _format_ocr_result(self, result: Dict[str, Any]) -> Dict[str, Any]:
        """Format OCR search result"""
        return {
            "medicine": self._format_medicine_result(result['medicine']),
            "confidence_score": result['confidence_score'],
            "matched_text": result['matched_text'],
            "match_type": result.get('match_type', 'ocr')
        }
