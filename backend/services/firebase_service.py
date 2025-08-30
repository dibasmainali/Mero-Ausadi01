import firebase_admin
from firebase_admin import credentials, firestore
from typing import List, Dict, Any, Optional
import json
import os

class FirebaseService:
    def __init__(self):
        """Initialize Firebase service with credentials"""
        try:
            # Check if Firebase app is already initialized
            if not firebase_admin._apps:
                # Initialize Firebase with credentials
                # You can use service account key file or environment variables
                if os.getenv("FIREBASE_CREDENTIALS"):
                    cred = credentials.Certificate(json.loads(os.getenv("FIREBASE_CREDENTIALS")))
                elif os.path.exists("firebase-credentials.json"):
                    cred = credentials.Certificate("firebase-credentials.json")
                else:
                    # Use default credentials (for development)
                    cred = credentials.ApplicationDefault()
                
                firebase_admin.initialize_app(cred)
            
            self.db = firestore.client()
            self.medicines_collection = self.db.collection('medicines')
            
        except Exception as e:
            print(f"Firebase initialization error: {e}")
            self.db = None
            self.medicines_collection = None

    async def upload_medicines(self, medicines: List[Dict[str, Any]]) -> bool:
        """Upload medicines to Firebase Firestore"""
        try:
            if not self.medicines_collection:
                raise Exception("Firebase not initialized")

            batch = self.db.batch()
            
            for medicine in medicines:
                doc_ref = self.medicines_collection.document(str(medicine['id']))
                batch.set(doc_ref, medicine)
            
            batch.commit()
            return True
            
        except Exception as e:
            print(f"Error uploading medicines to Firebase: {e}")
            return False

    async def download_medicines(self) -> List[Dict[str, Any]]:
        """Download all medicines from Firebase Firestore"""
        try:
            if not self.medicines_collection:
                raise Exception("Firebase not initialized")

            medicines = []
            docs = self.medicines_collection.stream()
            
            for doc in docs:
                medicine_data = doc.to_dict()
                medicines.append(medicine_data)
            
            return medicines
            
        except Exception as e:
            print(f"Error downloading medicines from Firebase: {e}")
            return []

    async def upload_medicine(self, medicine: Dict[str, Any]) -> bool:
        """Upload a single medicine to Firebase"""
        try:
            if not self.medicines_collection:
                raise Exception("Firebase not initialized")

            doc_ref = self.medicines_collection.document(str(medicine['id']))
            doc_ref.set(medicine)
            return True
            
        except Exception as e:
            print(f"Error uploading medicine to Firebase: {e}")
            return False

    async def delete_medicine(self, medicine_id: int) -> bool:
        """Delete a medicine from Firebase"""
        try:
            if not self.medicines_collection:
                raise Exception("Firebase not initialized")

            doc_ref = self.medicines_collection.document(str(medicine_id))
            doc_ref.delete()
            return True
            
        except Exception as e:
            print(f"Error deleting medicine from Firebase: {e}")
            return False

    async def search_medicines(self, query: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Search medicines in Firebase"""
        try:
            if not self.medicines_collection:
                raise Exception("Firebase not initialized")

            # Simple text search - in production, you might want to use Algolia or similar
            medicines = []
            docs = self.medicines_collection.limit(limit).stream()
            
            for doc in docs:
                medicine_data = doc.to_dict()
                if (query.lower() in medicine_data.get('brand_name', '').lower() or
                    query.lower() in medicine_data.get('generic_name', '').lower() or
                    query.lower() in medicine_data.get('manufacturer', '').lower()):
                    medicines.append(medicine_data)
            
            return medicines[:limit]
            
        except Exception as e:
            print(f"Error searching medicines in Firebase: {e}")
            return []

    async def get_medicine_by_barcode(self, barcode: str) -> Optional[Dict[str, Any]]:
        """Get medicine by barcode from Firebase"""
        try:
            if not self.medicines_collection:
                raise Exception("Firebase not initialized")

            docs = self.medicines_collection.where('barcode', '==', barcode).limit(1).stream()
            
            for doc in docs:
                return doc.to_dict()
            
            return None
            
        except Exception as e:
            print(f"Error getting medicine by barcode from Firebase: {e}")
            return None

    async def backup_database(self, medicines: List[Dict[str, Any]]) -> bool:
        """Create a backup of the database in Firebase"""
        try:
            if not self.medicines_collection:
                raise Exception("Firebase not initialized")

            backup_collection = self.db.collection('backups')
            backup_doc = backup_collection.document('latest')
            
            backup_data = {
                'timestamp': firestore.SERVER_TIMESTAMP,
                'total_records': len(medicines),
                'medicines': medicines
            }
            
            backup_doc.set(backup_data)
            return True
            
        except Exception as e:
            print(f"Error creating backup in Firebase: {e}")
            return False

    async def restore_database(self) -> List[Dict[str, Any]]:
        """Restore database from Firebase backup"""
        try:
            if not self.medicines_collection:
                raise Exception("Firebase not initialized")

            backup_collection = self.db.collection('backups')
            backup_doc = backup_collection.document('latest')
            
            backup_data = backup_doc.get()
            if backup_data.exists:
                return backup_data.to_dict().get('medicines', [])
            
            return []
            
        except Exception as e:
            print(f"Error restoring database from Firebase: {e}")
            return []
