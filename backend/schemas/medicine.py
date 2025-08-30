from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class MedicineBase(BaseModel):
    brand_name: str = Field(..., min_length=1, max_length=200)
    generic_name: str = Field(..., min_length=1, max_length=200)
    strength: str = Field(..., min_length=1, max_length=100)
    manufacturer: str = Field(..., min_length=1, max_length=200)
    uses: str = Field(..., min_length=1)
    side_effects: str = Field(..., min_length=1)
    warnings: str = Field(..., min_length=1)
    barcode: Optional[str] = Field(None, max_length=50)
    image_url: Optional[str] = Field(None, max_length=500)

class MedicineCreate(MedicineBase):
    pass

class MedicineUpdate(BaseModel):
    brand_name: Optional[str] = Field(None, min_length=1, max_length=200)
    generic_name: Optional[str] = Field(None, min_length=1, max_length=200)
    strength: Optional[str] = Field(None, min_length=1, max_length=100)
    manufacturer: Optional[str] = Field(None, min_length=1, max_length=200)
    uses: Optional[str] = Field(None, min_length=1)
    side_effects: Optional[str] = Field(None, min_length=1)
    warnings: Optional[str] = Field(None, min_length=1)
    barcode: Optional[str] = Field(None, max_length=50)
    image_url: Optional[str] = Field(None, max_length=500)

class MedicineResponse(MedicineBase):
    id: int
    created_by: Optional[int]
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True

class MedicineSearch(BaseModel):
    query: str = Field(..., min_length=1, max_length=500)
    limit: int = Field(default=10, ge=1, le=100)

class MedicineSearchResult(BaseModel):
    medicine: MedicineResponse
    confidence_score: float = Field(..., ge=0.0, le=1.0)
    matched_text: str

class MedicineStats(BaseModel):
    total_medicines: int
    total_manufacturers: int
    total_generic_names: int
    recent_additions: int
    most_searched: List[str]

class BulkMedicineCreate(BaseModel):
    medicines: List[MedicineCreate]

class MedicineImportResult(BaseModel):
    total_records: int
    successful_imports: int
    failed_imports: int
    errors: List[str]
