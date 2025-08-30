from sqlalchemy.orm import Session
from sqlalchemy import func, desc, and_, or_
from typing import List, Optional, Dict, Any
import csv
import io
from datetime import datetime, timedelta
import re

from database.models import Medicine, User, SearchLog, Manufacturer, GenericName, SideEffect, Warning, OCRLog
from schemas.medicine import MedicineCreate, MedicineUpdate, MedicineResponse, MedicineStats
from services.firebase_service import FirebaseService

class MedicineService:
    def __init__(self):
        self.firebase_service = FirebaseService()

    def get_medicines(self, db: Session, skip: int = 0, limit: int = 100) -> List[Medicine]:
        return db.query(Medicine).offset(skip).limit(limit).all()

    def get_medicine(self, db: Session, medicine_id: int) -> Optional[Medicine]:
        return db.query(Medicine).filter(Medicine.id == medicine_id).first()

    def get_medicine_by_barcode(self, db: Session, barcode: str) -> Optional[Medicine]:
        return db.query(Medicine).filter(Medicine.barcode == barcode).first()

    def create_medicine(self, db: Session, medicine: MedicineCreate, user_id: int) -> Medicine:
        db_medicine = Medicine(
            brand_name=medicine.brand_name,
            generic_name=medicine.generic_name,
            strength=medicine.strength,
            manufacturer=medicine.manufacturer,
            uses=medicine.uses,
            side_effects=medicine.side_effects,
            warnings=medicine.warnings,
            barcode=medicine.barcode,
            image_url=medicine.image_url,
            created_by=user_id
        )
        db.add(db_medicine)
        db.commit()
        db.refresh(db_medicine)
        return db_medicine

    def update_medicine(self, db: Session, medicine_id: int, medicine: MedicineUpdate) -> Optional[Medicine]:
        db_medicine = db.query(Medicine).filter(Medicine.id == medicine_id).first()
        if not db_medicine:
            return None

        update_data = medicine.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_medicine, field, value)

        db_medicine.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(db_medicine)
        return db_medicine

    def delete_medicine(self, db: Session, medicine_id: int) -> bool:
        db_medicine = db.query(Medicine).filter(Medicine.id == medicine_id).first()
        if not db_medicine:
            return False

        db.delete(db_medicine)
        db.commit()
        return True

    def search_medicines(self, db: Session, query: str, limit: int = 10) -> List[Medicine]:
        return db.query(Medicine).filter(
            (Medicine.brand_name.ilike(f"%{query}%")) |
            (Medicine.generic_name.ilike(f"%{query}%")) |
            (Medicine.manufacturer.ilike(f"%{query}%"))
        ).limit(limit).all()

    def advanced_search_medicines(self, db: Session, query: str, filters: Dict[str, Any] = None, limit: int = 10) -> List[Medicine]:
        """Advanced search with multiple filters"""
        base_query = db.query(Medicine)
        
        # Text search
        if query:
            base_query = base_query.filter(
                or_(
                    Medicine.brand_name.ilike(f"%{query}%"),
                    Medicine.generic_name.ilike(f"%{query}%"),
                    Medicine.manufacturer.ilike(f"%{query}%"),
                    Medicine.uses.ilike(f"%{query}%")
                )
            )
        
        # Apply filters
        if filters:
            if filters.get('manufacturer'):
                base_query = base_query.filter(Medicine.manufacturer.ilike(f"%{filters['manufacturer']}%"))
            
            if filters.get('strength'):
                base_query = base_query.filter(Medicine.strength.ilike(f"%{filters['strength']}%"))
            
            if filters.get('generic_name'):
                base_query = base_query.filter(Medicine.generic_name.ilike(f"%{filters['generic_name']}%"))
        
        return base_query.limit(limit).all()

    def search_medicines_with_confidence(self, db: Session, query: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Search medicines with confidence scores"""
        medicines = self.search_medicines(db, query, limit)
        results = []
        
        for medicine in medicines:
            confidence = self._calculate_confidence_score(query, medicine)
            results.append({
                'medicine': medicine,
                'confidence_score': confidence,
                'matched_text': self._get_matched_text(query, medicine)
            })
        
        # Sort by confidence score
        results.sort(key=lambda x: x['confidence_score'], reverse=True)
        return results

    def _calculate_confidence_score(self, query: str, medicine: Medicine) -> float:
        """Calculate confidence score for search results"""
        query_lower = query.lower()
        score = 0.0
        
        # Exact matches get highest score
        if medicine.brand_name.lower() == query_lower:
            score += 1.0
        elif medicine.brand_name.lower().startswith(query_lower):
            score += 0.8
        elif query_lower in medicine.brand_name.lower():
            score += 0.6
        
        if medicine.generic_name.lower() == query_lower:
            score += 0.9
        elif medicine.generic_name.lower().startswith(query_lower):
            score += 0.7
        elif query_lower in medicine.generic_name.lower():
            score += 0.5
        
        if medicine.manufacturer.lower() == query_lower:
            score += 0.5
        elif query_lower in medicine.manufacturer.lower():
            score += 0.3
        
        return min(score, 1.0)

    def _get_matched_text(self, query: str, medicine: Medicine) -> str:
        """Get the text that matched the query"""
        query_lower = query.lower()
        
        if query_lower in medicine.brand_name.lower():
            return medicine.brand_name
        elif query_lower in medicine.generic_name.lower():
            return medicine.generic_name
        elif query_lower in medicine.manufacturer.lower():
            return medicine.manufacturer
        
        return ""

    def get_medicine_stats(self, db: Session) -> MedicineStats:
        # Total medicines
        total_medicines = db.query(func.count(Medicine.id)).scalar()

        # Total manufacturers
        total_manufacturers = db.query(func.count(func.distinct(Medicine.manufacturer))).scalar()

        # Total generic names
        total_generic_names = db.query(func.count(func.distinct(Medicine.generic_name))).scalar()

        # Recent additions (last 30 days)
        thirty_days_ago = datetime.utcnow() - timedelta(days=30)
        recent_additions = db.query(func.count(Medicine.id)).filter(
            Medicine.created_at >= thirty_days_ago
        ).scalar()

        # Most searched terms
        most_searched = db.query(SearchLog.query, func.count(SearchLog.id)).group_by(
            SearchLog.query
        ).order_by(desc(func.count(SearchLog.id))).limit(10).all()

        most_searched_terms = [term for term, count in most_searched]

        return MedicineStats(
            total_medicines=total_medicines,
            total_manufacturers=total_manufacturers,
            total_generic_names=total_generic_names,
            recent_additions=recent_additions,
            most_searched=most_searched_terms
        )

    def get_detailed_analytics(self, db: Session) -> Dict[str, Any]:
        """Get detailed analytics about medicines"""
        # Basic stats
        total_medicines = db.query(func.count(Medicine.id)).scalar()
        
        # Medicines by manufacturer
        medicines_by_manufacturer = db.query(
            Medicine.manufacturer,
            func.count(Medicine.id)
        ).group_by(Medicine.manufacturer).order_by(
            desc(func.count(Medicine.id))
        ).limit(10).all()
        
        # Medicines by generic name
        medicines_by_generic = db.query(
            Medicine.generic_name,
            func.count(Medicine.id)
        ).group_by(Medicine.generic_name).order_by(
            desc(func.count(Medicine.id))
        ).limit(10).all()
        
        # Recent activity
        seven_days_ago = datetime.utcnow() - timedelta(days=7)
        recent_searches = db.query(func.count(SearchLog.id)).filter(
            SearchLog.created_at >= seven_days_ago
        ).scalar()
        
        recent_ocr_scans = db.query(func.count(OCRLog.id)).filter(
            OCRLog.created_at >= seven_days_ago
        ).scalar()
        
        # Search trends
        search_trends = db.query(
            func.date(SearchLog.created_at),
            func.count(SearchLog.id)
        ).filter(
            SearchLog.created_at >= seven_days_ago
        ).group_by(
            func.date(SearchLog.created_at)
        ).order_by(
            func.date(SearchLog.created_at)
        ).all()
        
        return {
            "total_medicines": total_medicines,
            "medicines_by_manufacturer": [
                {"manufacturer": m, "count": c} for m, c in medicines_by_manufacturer
            ],
            "medicines_by_generic": [
                {"generic_name": g, "count": c} for g, c in medicines_by_generic
            ],
            "recent_activity": {
                "searches_last_7_days": recent_searches,
                "ocr_scans_last_7_days": recent_ocr_scans
            },
            "search_trends": [
                {"date": str(date), "count": count} for date, count in search_trends
            ]
        }

    def log_search(self, db: Session, user_id: Optional[int], query: str, search_type: str = "text", results_count: int = 0, confidence_score: Optional[float] = None):
        """Log a search query"""
        search_log = SearchLog(
            user_id=user_id,
            query=query,
            search_type=search_type,
            results_count=results_count,
            confidence_score=confidence_score
        )
        db.add(search_log)
        db.commit()

    def log_ocr_scan(self, db: Session, user_id: Optional[int], image_url: str, extracted_text: str):
        """Log an OCR scan"""
        ocr_log = OCRLog(
            user_id=user_id,
            image_url=image_url,
            extracted_text=extracted_text
        )
        db.add(ocr_log)
        db.commit()

    def get_popular_medicines(self, db: Session, limit: int = 10) -> List[Medicine]:
        """Get most popular medicines based on search frequency"""
        # This is a simplified version - in production you might want more sophisticated analytics
        popular_queries = db.query(SearchLog.query, func.count(SearchLog.id)).group_by(
            SearchLog.query
        ).order_by(desc(func.count(SearchLog.id))).limit(limit).all()
        
        medicines = []
        for query, _ in popular_queries:
            medicine = self.get_medicine_by_barcode(db, query)
            if not medicine:
                # Try to find by name
                medicine = db.query(Medicine).filter(
                    Medicine.brand_name.ilike(f"%{query}%")
                ).first()
            
            if medicine and medicine not in medicines:
                medicines.append(medicine)
        
        return medicines[:limit]

    def get_medicines_by_manufacturer(self, db: Session, manufacturer: str, limit: int = 50) -> List[Medicine]:
        """Get all medicines by a specific manufacturer"""
        return db.query(Medicine).filter(
            Medicine.manufacturer.ilike(f"%{manufacturer}%")
        ).limit(limit).all()

    def get_medicines_by_generic_name(self, db: Session, generic_name: str, limit: int = 50) -> List[Medicine]:
        """Get all medicines with a specific generic name"""
        return db.query(Medicine).filter(
            Medicine.generic_name.ilike(f"%{generic_name}%")
        ).limit(limit).all()

    def get_medicines_by_strength(self, db: Session, strength: str, limit: int = 50) -> List[Medicine]:
        """Get all medicines with a specific strength"""
        return db.query(Medicine).filter(
            Medicine.strength.ilike(f"%{strength}%")
        ).limit(limit).all()

    def validate_barcode(self, barcode: str) -> bool:
        """Validate barcode format"""
        if not barcode:
            return True  # Barcode is optional
        
        # Basic validation for common barcode formats
        # Remove spaces and dashes
        clean_barcode = re.sub(r'[\s-]', '', barcode)
        
        # Check if it's numeric and has reasonable length
        if not clean_barcode.isdigit():
            return False
        
        if len(clean_barcode) < 8 or len(clean_barcode) > 13:
            return False
        
        return True

    def check_duplicate_medicine(self, db: Session, medicine: MedicineCreate, exclude_id: Optional[int] = None) -> bool:
        """Check if a medicine already exists"""
        query = db.query(Medicine).filter(
            and_(
                Medicine.brand_name == medicine.brand_name,
                Medicine.generic_name == medicine.generic_name,
                Medicine.strength == medicine.strength,
                Medicine.manufacturer == medicine.manufacturer
            )
        )
        
        if exclude_id:
            query = query.filter(Medicine.id != exclude_id)
        
        return query.first() is not None

    def bulk_create_medicines(self, db: Session, medicines: List[MedicineCreate], user_id: int) -> List[Medicine]:
        db_medicines = []
        for medicine in medicines:
            db_medicine = Medicine(
                brand_name=medicine.brand_name,
                generic_name=medicine.generic_name,
                strength=medicine.strength,
                manufacturer=medicine.manufacturer,
                uses=medicine.uses,
                side_effects=medicine.side_effects,
                warnings=medicine.warnings,
                barcode=medicine.barcode,
                image_url=medicine.image_url,
                created_by=user_id
            )
            db_medicines.append(db_medicine)

        db.add_all(db_medicines)
        db.commit()
        
        for medicine in db_medicines:
            db.refresh(medicine)
        
        return db_medicines

    async def import_from_csv(self, db: Session, file) -> Dict[str, Any]:
        content = await file.read()
        content = content.decode('utf-8')
        
        csv_reader = csv.DictReader(io.StringIO(content))
        
        successful_imports = 0
        failed_imports = 0
        errors = []

        for row_num, row in enumerate(csv_reader, start=2):  # Start from 2 to account for header
            try:
                medicine = MedicineCreate(
                    brand_name=row.get('brand_name', '').strip(),
                    generic_name=row.get('generic_name', '').strip(),
                    strength=row.get('strength', '').strip(),
                    manufacturer=row.get('manufacturer', '').strip(),
                    uses=row.get('uses', '').strip(),
                    side_effects=row.get('side_effects', '').strip(),
                    warnings=row.get('warnings', '').strip(),
                    barcode=row.get('barcode', '').strip() or None,
                    image_url=row.get('image_url', '').strip() or None
                )
                
                # Validate barcode
                if medicine.barcode and not self.validate_barcode(medicine.barcode):
                    errors.append(f"Row {row_num}: Invalid barcode format")
                    failed_imports += 1
                    continue
                
                # Check if medicine already exists
                if self.check_duplicate_medicine(db, medicine):
                    errors.append(f"Row {row_num}: Medicine already exists")
                    failed_imports += 1
                    continue

                db_medicine = Medicine(
                    brand_name=medicine.brand_name,
                    generic_name=medicine.generic_name,
                    strength=medicine.strength,
                    manufacturer=medicine.manufacturer,
                    uses=medicine.uses,
                    side_effects=medicine.side_effects,
                    warnings=medicine.warnings,
                    barcode=medicine.barcode,
                    image_url=medicine.image_url
                )
                
                db.add(db_medicine)
                successful_imports += 1
                
            except Exception as e:
                errors.append(f"Row {row_num}: {str(e)}")
                failed_imports += 1

        db.commit()
        
        return {
            "total_records": successful_imports + failed_imports,
            "successful_imports": successful_imports,
            "failed_imports": failed_imports,
            "errors": errors
        }

    async def sync_to_cloud(self, db: Session) -> Dict[str, Any]:
        try:
            medicines = db.query(Medicine).all()
            medicine_data = []
            
            for medicine in medicines:
                medicine_data.append({
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
                    "created_at": medicine.created_at.isoformat(),
                    "updated_at": medicine.updated_at.isoformat() if medicine.updated_at else None
                })
            
            await self.firebase_service.upload_medicines(medicine_data)
            
            return {
                "status": "success",
                "records_synced": len(medicine_data),
                "message": "Data successfully synced to cloud"
            }
            
        except Exception as e:
            return {
                "status": "failed",
                "error": str(e),
                "message": "Failed to sync data to cloud"
            }

    async def sync_from_cloud(self, db: Session) -> Dict[str, Any]:
        try:
            cloud_medicines = await self.firebase_service.download_medicines()
            
            synced_count = 0
            for medicine_data in cloud_medicines:
                # Check if medicine exists
                existing = db.query(Medicine).filter(Medicine.id == medicine_data["id"]).first()
                
                if existing:
                    # Update existing medicine
                    for key, value in medicine_data.items():
                        if key != "id" and hasattr(existing, key):
                            setattr(existing, key, value)
                else:
                    # Create new medicine
                    medicine = Medicine(
                        id=medicine_data["id"],
                        brand_name=medicine_data["brand_name"],
                        generic_name=medicine_data["generic_name"],
                        strength=medicine_data["strength"],
                        manufacturer=medicine_data["manufacturer"],
                        uses=medicine_data["uses"],
                        side_effects=medicine_data["side_effects"],
                        warnings=medicine_data["warnings"],
                        barcode=medicine_data.get("barcode"),
                        image_url=medicine_data.get("image_url"),
                        created_at=datetime.fromisoformat(medicine_data["created_at"]),
                        updated_at=datetime.fromisoformat(medicine_data["updated_at"]) if medicine_data.get("updated_at") else None
                    )
                    db.add(medicine)
                
                synced_count += 1
            
            db.commit()
            
            return {
                "status": "success",
                "records_synced": synced_count,
                "message": "Data successfully synced from cloud"
            }
            
        except Exception as e:
            return {
                "status": "failed",
                "error": str(e),
                "message": "Failed to sync data from cloud"
            }

    async def backup_to_cloud(self, db: Session) -> Dict[str, Any]:
        """Create a backup of the database in the cloud"""
        try:
            medicines = db.query(Medicine).all()
            medicine_data = []
            
            for medicine in medicines:
                medicine_data.append({
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
                    "created_at": medicine.created_at.isoformat(),
                    "updated_at": medicine.updated_at.isoformat() if medicine.updated_at else None
                })
            
            success = await self.firebase_service.backup_database(medicine_data)
            
            if success:
                return {
                    "status": "success",
                    "records_backed_up": len(medicine_data),
                    "message": "Database successfully backed up to cloud"
                }
            else:
                return {
                    "status": "failed",
                    "message": "Failed to backup database to cloud"
                }
            
        except Exception as e:
            return {
                "status": "failed",
                "error": str(e),
                "message": "Failed to backup database to cloud"
            }

    async def restore_from_cloud(self, db: Session) -> Dict[str, Any]:
        """Restore database from cloud backup"""
        try:
            medicine_data = await self.firebase_service.restore_database()
            
            if not medicine_data:
                return {
                    "status": "failed",
                    "message": "No backup found in cloud"
                }
            
            # Clear existing data
            db.query(Medicine).delete()
            
            # Restore from backup
            restored_count = 0
            for data in medicine_data:
                medicine = Medicine(
                    id=data["id"],
                    brand_name=data["brand_name"],
                    generic_name=data["generic_name"],
                    strength=data["strength"],
                    manufacturer=data["manufacturer"],
                    uses=data["uses"],
                    side_effects=data["side_effects"],
                    warnings=data["warnings"],
                    barcode=data.get("barcode"),
                    image_url=data.get("image_url"),
                    created_at=datetime.fromisoformat(data["created_at"]),
                    updated_at=datetime.fromisoformat(data["updated_at"]) if data.get("updated_at") else None
                )
                db.add(medicine)
                restored_count += 1
            
            db.commit()
            
            return {
                "status": "success",
                "records_restored": restored_count,
                "message": "Database successfully restored from cloud backup"
            }
            
        except Exception as e:
            return {
                "status": "failed",
                "error": str(e),
                "message": "Failed to restore database from cloud"
            }
