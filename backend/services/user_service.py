from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
import hashlib
import secrets

from database.models import User, Medicine, SearchLog, OCRLog
from schemas.user import UserCreate, UserUpdate, UserResponse, UserStats
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

class UserService:
    def __init__(self):
        pass

    def get_users(self, db: Session, skip: int = 0, limit: int = 100) -> List[User]:
        """Get all users with pagination"""
        return db.query(User).offset(skip).limit(limit).all()

    def get_user(self, db: Session, user_id: int) -> Optional[User]:
        """Get user by ID"""
        return db.query(User).filter(User.id == user_id).first()

    def get_user_by_email(self, db: Session, email: str) -> Optional[User]:
        """Get user by email"""
        return db.query(User).filter(User.email == email).first()

    def get_user_by_username(self, db: Session, username: str) -> Optional[User]:
        """Get user by username"""
        return db.query(User).filter(User.username == username).first()

    def create_user(self, db: Session, user: UserCreate) -> User:
        """Create a new user"""
        # Hash the password
        hashed_password = pwd_context.hash(user.password)
        
        db_user = User(
            username=user.username,
            email=user.email,
            hashed_password=hashed_password,
            is_active=True,
            is_admin=False
        )
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        return db_user

    def update_user(self, db: Session, user_id: int, user: UserUpdate) -> Optional[User]:
        """Update user information"""
        db_user = db.query(User).filter(User.id == user_id).first()
        if not db_user:
            return None

        update_data = user.dict(exclude_unset=True)
        
        # Hash password if it's being updated
        if 'password' in update_data:
            update_data['hashed_password'] = pwd_context.hash(update_data.pop('password'))

        for field, value in update_data.items():
            setattr(db_user, field, value)

        db_user.updated_at = datetime.utcnow()
        db.commit()
        db.refresh(db_user)
        return db_user

    def delete_user(self, db: Session, user_id: int) -> bool:
        """Delete a user"""
        db_user = db.query(User).filter(User.id == user_id).first()
        if not db_user:
            return False

        db.delete(db_user)
        db.commit()
        return True

    def authenticate_user(self, db: Session, username: str, password: str) -> Optional[User]:
        """Authenticate user with username/email and password"""
        # Try to find user by username or email
        user = db.query(User).filter(
            (User.username == username) | (User.email == username)
        ).first()
        
        if not user:
            return None
        
        if not pwd_context.verify(password, user.hashed_password):
            return None
        
        return user

    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """Verify a password against its hash"""
        return pwd_context.verify(plain_password, hashed_password)

    def get_password_hash(self, password: str) -> str:
        """Generate password hash"""
        return pwd_context.hash(password)

    def change_password(self, db: Session, user_id: int, old_password: str, new_password: str) -> bool:
        """Change user password"""
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            return False

        if not pwd_context.verify(old_password, user.hashed_password):
            return False

        user.hashed_password = pwd_context.hash(new_password)
        user.updated_at = datetime.utcnow()
        db.commit()
        return True

    def activate_user(self, db: Session, user_id: int) -> bool:
        """Activate a user account"""
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            return False

        user.is_active = True
        user.updated_at = datetime.utcnow()
        db.commit()
        return True

    def deactivate_user(self, db: Session, user_id: int) -> bool:
        """Deactivate a user account"""
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            return False

        user.is_active = False
        user.updated_at = datetime.utcnow()
        db.commit()
        return True

    def promote_to_admin(self, db: Session, user_id: int) -> bool:
        """Promote user to admin"""
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            return False

        user.is_admin = True
        user.updated_at = datetime.utcnow()
        db.commit()
        return True

    def demote_from_admin(self, db: Session, user_id: int) -> bool:
        """Remove admin privileges from user"""
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            return False

        user.is_admin = False
        user.updated_at = datetime.utcnow()
        db.commit()
        return True

    def get_user_stats(self, db: Session, user_id: int) -> UserStats:
        """Get statistics for a specific user"""
        # Get user's medicines
        medicines_count = db.query(func.count(Medicine.id)).filter(
            Medicine.created_by == user_id
        ).scalar()

        # Get user's search history
        searches_count = db.query(func.count(SearchLog.id)).filter(
            SearchLog.user_id == user_id
        ).scalar()

        # Get user's OCR scans
        ocr_scans_count = db.query(func.count(OCRLog.id)).filter(
            OCRLog.user_id == user_id
        ).scalar()

        # Get recent activity (last 30 days)
        thirty_days_ago = datetime.utcnow() - timedelta(days=30)
        recent_searches = db.query(func.count(SearchLog.id)).filter(
            SearchLog.user_id == user_id,
            SearchLog.created_at >= thirty_days_ago
        ).scalar()

        recent_ocr_scans = db.query(func.count(OCRLog.id)).filter(
            OCRLog.user_id == user_id,
            OCRLog.created_at >= thirty_days_ago
        ).scalar()

        # Get most searched terms
        most_searched = db.query(SearchLog.query, func.count(SearchLog.id)).filter(
            SearchLog.user_id == user_id
        ).group_by(SearchLog.query).order_by(
            desc(func.count(SearchLog.id))
        ).limit(5).all()

        most_searched_terms = [term for term, count in most_searched]

        return UserStats(
            user_id=user_id,
            medicines_created=medicines_count,
            total_searches=searches_count,
            total_ocr_scans=ocr_scans_count,
            recent_searches=recent_searches,
            recent_ocr_scans=recent_ocr_scans,
            most_searched_terms=most_searched_terms
        )

    def get_user_activity(self, db: Session, user_id: int, days: int = 30) -> Dict[str, Any]:
        """Get detailed user activity"""
        start_date = datetime.utcnow() - timedelta(days=days)
        
        # Get search activity
        search_activity = db.query(
            func.date(SearchLog.created_at),
            func.count(SearchLog.id)
        ).filter(
            SearchLog.user_id == user_id,
            SearchLog.created_at >= start_date
        ).group_by(
            func.date(SearchLog.created_at)
        ).order_by(
            func.date(SearchLog.created_at)
        ).all()

        # Get OCR activity
        ocr_activity = db.query(
            func.date(OCRLog.created_at),
            func.count(OCRLog.id)
        ).filter(
            OCRLog.user_id == user_id,
            OCRLog.created_at >= start_date
        ).group_by(
            func.date(OCRLog.created_at)
        ).order_by(
            func.date(OCRLog.created_at)
        ).all()

        # Get medicines created
        medicines_created = db.query(
            func.date(Medicine.created_at),
            func.count(Medicine.id)
        ).filter(
            Medicine.created_by == user_id,
            Medicine.created_at >= start_date
        ).group_by(
            func.date(Medicine.created_at)
        ).order_by(
            func.date(Medicine.created_at)
        ).all()

        return {
            "search_activity": [
                {"date": str(date), "count": count} for date, count in search_activity
            ],
            "ocr_activity": [
                {"date": str(date), "count": count} for date, count in ocr_activity
            ],
            "medicines_created": [
                {"date": str(date), "count": count} for date, count in medicines_created
            ]
        }

    def get_user_medicines(self, db: Session, user_id: int, skip: int = 0, limit: int = 50) -> List[Medicine]:
        """Get medicines created by a specific user"""
        return db.query(Medicine).filter(
            Medicine.created_by == user_id
        ).offset(skip).limit(limit).all()

    def get_user_search_history(self, db: Session, user_id: int, skip: int = 0, limit: int = 50) -> List[SearchLog]:
        """Get search history for a specific user"""
        return db.query(SearchLog).filter(
            SearchLog.user_id == user_id
        ).order_by(desc(SearchLog.created_at)).offset(skip).limit(limit).all()

    def get_user_ocr_history(self, db: Session, user_id: int, skip: int = 0, limit: int = 50) -> List[OCRLog]:
        """Get OCR scan history for a specific user"""
        return db.query(OCRLog).filter(
            OCRLog.user_id == user_id
        ).order_by(desc(OCRLog.created_at)).offset(skip).limit(limit).all()

    def delete_user_data(self, db: Session, user_id: int) -> bool:
        """Delete all data associated with a user (GDPR compliance)"""
        try:
            # Delete user's medicines
            db.query(Medicine).filter(Medicine.created_by == user_id).delete()
            
            # Delete user's search logs
            db.query(SearchLog).filter(SearchLog.user_id == user_id).delete()
            
            # Delete user's OCR logs
            db.query(OCRLog).filter(OCRLog.user_id == user_id).delete()
            
            # Delete the user
            db.query(User).filter(User.id == user_id).delete()
            
            db.commit()
            return True
            
        except Exception as e:
            db.rollback()
            print(f"Error deleting user data: {e}")
            return False

    def get_admin_users(self, db: Session) -> List[User]:
        """Get all admin users"""
        return db.query(User).filter(User.is_admin == True).all()

    def get_active_users(self, db: Session) -> List[User]:
        """Get all active users"""
        return db.query(User).filter(User.is_active == True).all()

    def get_users_by_activity(self, db: Session, days: int = 30, limit: int = 10) -> List[Dict[str, Any]]:
        """Get most active users"""
        start_date = datetime.utcnow() - timedelta(days=days)
        
        # Get users with their activity counts
        active_users = db.query(
            User,
            func.count(SearchLog.id).label('search_count'),
            func.count(OCRLog.id).label('ocr_count')
        ).outerjoin(SearchLog, User.id == SearchLog.user_id).outerjoin(
            OCRLog, User.id == OCRLog.user_id
        ).filter(
            (SearchLog.created_at >= start_date) | (OCRLog.created_at >= start_date)
        ).group_by(User.id).order_by(
            desc(func.count(SearchLog.id) + func.count(OCRLog.id))
        ).limit(limit).all()

        return [
            {
                "user": user,
                "search_count": search_count,
                "ocr_count": ocr_count,
                "total_activity": search_count + ocr_count
            }
            for user, search_count, ocr_count in active_users
        ]

    def generate_api_key(self, db: Session, user_id: int) -> Optional[str]:
        """Generate a new API key for a user"""
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            return None

        # Generate a secure API key
        api_key = secrets.token_urlsafe(32)
        
        # In a real implementation, you might want to store this in a separate table
        # For now, we'll just return it
        return api_key

    def validate_api_key(self, api_key: str) -> Optional[int]:
        """Validate an API key and return user ID"""
        # In a real implementation, you would validate against stored API keys
        # For now, this is a placeholder
        return None
