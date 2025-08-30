from sqlalchemy import Column, Integer, String, Text, DateTime, Boolean, ForeignKey, Float
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from datetime import datetime

Base = declarative_base()

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True)
    is_admin = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    medicines = relationship("Medicine", back_populates="created_by_user")

class Medicine(Base):
    __tablename__ = "medicines"

    id = Column(Integer, primary_key=True, index=True)
    brand_name = Column(String(200), nullable=False, index=True)
    generic_name = Column(String(200), nullable=False, index=True)
    strength = Column(String(100), nullable=False)
    manufacturer = Column(String(200), nullable=False, index=True)
    uses = Column(Text, nullable=False)
    side_effects = Column(Text, nullable=False)
    warnings = Column(Text, nullable=False)
    image_url = Column(String(500))
    barcode = Column(String(50), unique=True, index=True)
    created_by = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    created_by_user = relationship("User", back_populates="medicines")

class Manufacturer(Base):
    __tablename__ = "manufacturers"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), unique=True, nullable=False, index=True)
    address = Column(Text)
    phone = Column(String(50))
    email = Column(String(100))
    website = Column(String(200))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

class GenericName(Base):
    __tablename__ = "generic_names"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(200), unique=True, nullable=False, index=True)
    description = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class SideEffect(Base):
    __tablename__ = "side_effects"

    id = Column(Integer, primary_key=True, index=True)
    medicine_id = Column(Integer, ForeignKey("medicines.id"), nullable=False)
    effect = Column(String(500), nullable=False)
    severity = Column(String(50))  # mild, moderate, severe
    frequency = Column(String(50))  # common, uncommon, rare
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class Warning(Base):
    __tablename__ = "warnings"

    id = Column(Integer, primary_key=True, index=True)
    medicine_id = Column(Integer, ForeignKey("medicines.id"), nullable=False)
    warning_text = Column(Text, nullable=False)
    category = Column(String(100))  # pregnancy, driving, alcohol, etc.
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class SearchLog(Base):
    __tablename__ = "search_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    query = Column(String(500), nullable=False)
    search_type = Column(String(50))  # text, ocr, barcode
    results_count = Column(Integer, default=0)
    confidence_score = Column(Float)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class OCRLog(Base):
    __tablename__ = "ocr_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    image_url = Column(String(500))
    extracted_text = Column(Text)
    confidence_score = Column(Float)
    processing_time = Column(Float)  # in seconds
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class SyncLog(Base):
    __tablename__ = "sync_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    sync_type = Column(String(50))  # upload, download
    records_count = Column(Integer, default=0)
    status = Column(String(50))  # success, failed, partial
    error_message = Column(Text)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
