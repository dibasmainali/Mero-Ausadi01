from fastapi import FastAPI, HTTPException, Depends, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from typing import List, Optional
import uvicorn
import os
from dotenv import load_dotenv

from database.database import get_db, engine
from database.models import Base
from schemas.medicine import MedicineCreate, MedicineUpdate, MedicineResponse, MedicineSearch
from schemas.user import UserCreate, UserLogin, UserResponse
from services.medicine_service import MedicineService
from services.user_service import UserService
from services.auth_service import AuthService, get_current_user, get_current_active_user, get_current_admin_user
from services.ocr_service import OCRService
from services.search_service import SearchService

# Load environment variables
load_dotenv()

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Ausadi Thaha API",
    description="Medicine identification and management API",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount static files
app.mount("/static", StaticFiles(directory="static"), name="static")

# Initialize services
medicine_service = MedicineService()
user_service = UserService()
auth_service = AuthService()
ocr_service = OCRService()
search_service = SearchService()

@app.get("/")
async def root():
    return {"message": "Ausadi Thaha API is running"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

# Authentication endpoints
@app.post("/auth/register", response_model=UserResponse)
async def register(user: UserCreate, db: Session = Depends(get_db)):
    return user_service.create_user(db, user)

@app.post("/auth/login")
async def login(user: UserLogin, db: Session = Depends(get_db)):
    return auth_service.login_user(db, user.username, user.password)

# Medicine endpoints
@app.get("/medicines", response_model=List[MedicineResponse])
async def get_medicines(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    return medicine_service.get_medicines(db, skip=skip, limit=limit)

@app.get("/medicines/{medicine_id}", response_model=MedicineResponse)
async def get_medicine(
    medicine_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    medicine = medicine_service.get_medicine(db, medicine_id)
    if not medicine:
        raise HTTPException(status_code=404, detail="Medicine not found")
    return medicine

@app.post("/medicines", response_model=MedicineResponse)
async def create_medicine(
    medicine: MedicineCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    return medicine_service.create_medicine(db, medicine, current_user.id)

@app.put("/medicines/{medicine_id}", response_model=MedicineResponse)
async def update_medicine(
    medicine_id: int,
    medicine: MedicineUpdate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    updated_medicine = medicine_service.update_medicine(db, medicine_id, medicine)
    if not updated_medicine:
        raise HTTPException(status_code=404, detail="Medicine not found")
    return updated_medicine

@app.delete("/medicines/{medicine_id}")
async def delete_medicine(
    medicine_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    success = medicine_service.delete_medicine(db, medicine_id)
    if not success:
        raise HTTPException(status_code=404, detail="Medicine not found")
    return {"message": "Medicine deleted successfully"}

# Search endpoints
@app.post("/medicines/search")
async def search_medicines(
    search: MedicineSearch,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    return search_service.search_medicines(db, search.query, search.limit)

@app.post("/medicines/search/fuzzy")
async def fuzzy_search_medicines(
    search: MedicineSearch,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    return search_service.fuzzy_search_medicines(db, search.query, search.limit)

# OCR endpoints
@app.post("/ocr/process")
async def process_image_ocr(
    file: UploadFile = File(...),
    current_user = Depends(get_current_active_user)
):
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    try:
        extracted_text, medicine_info = ocr_service.process_image_file(file)
        return {
            "extracted_text": extracted_text,
            "medicine_info": medicine_info
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"OCR processing failed: {str(e)}")

@app.post("/ocr/search")
async def search_by_ocr(
    file: UploadFile = File(...),
    limit: int = Form(3),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    try:
        # Process OCR
        extracted_text, medicine_info = ocr_service.process_image_file(file)
        
        # Search medicines using OCR text
        search_results = search_service.search_by_ocr_text(db, extracted_text, limit)
        
        return {
            "extracted_text": extracted_text,
            "medicine_info": medicine_info,
            "search_results": search_results
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"OCR search failed: {str(e)}")

# Admin endpoints
@app.get("/admin/medicines/stats")
async def get_medicine_stats(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_admin_user)
):
    return medicine_service.get_medicine_stats(db)

@app.post("/admin/medicines/bulk")
async def bulk_create_medicines(
    medicines: List[MedicineCreate],
    db: Session = Depends(get_db),
    current_user = Depends(get_current_admin_user)
):
    return medicine_service.bulk_create_medicines(db, medicines, current_user.id)

@app.post("/admin/medicines/import")
async def import_medicines_from_file(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user = Depends(get_current_admin_user)
):
    if not file.filename.endswith('.csv'):
        raise HTTPException(status_code=400, detail="File must be a CSV")
    
    try:
        result = await medicine_service.import_from_csv(db, file)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Import failed: {str(e)}")

# Sync endpoints
@app.post("/sync/upload")
async def upload_to_cloud(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    try:
        result = await medicine_service.sync_to_cloud(db)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Sync failed: {str(e)}")

@app.post("/sync/download")
async def download_from_cloud(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    try:
        result = await medicine_service.sync_from_cloud(db)
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Download failed: {str(e)}")

# User endpoints
@app.get("/users/me", response_model=UserResponse)
async def get_current_user_profile(current_user = Depends(get_current_active_user)):
    return current_user

@app.get("/users/{user_id}/stats")
async def get_user_stats(
    user_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_active_user)
):
    if current_user.id != user_id and not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Not authorized")
    return user_service.get_user_stats(db, user_id)

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
