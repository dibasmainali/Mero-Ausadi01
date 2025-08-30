from datetime import datetime, timedelta
from typing import Optional, Union
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from database.models import User
from services.user_service import UserService
from database.database import get_db

# Configuration
SECRET_KEY = "your-secret-key-here"  # In production, use environment variable
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
REFRESH_TOKEN_EXPIRE_DAYS = 7

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Security scheme
security = HTTPBearer()

class AuthService:
    def __init__(self):
        self.user_service = UserService()

    def create_access_token(self, data: dict, expires_delta: Optional[timedelta] = None) -> str:
        """Create a new access token"""
        to_encode = data.copy()
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        
        to_encode.update({"exp": expire, "type": "access"})
        encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
        return encoded_jwt

    def create_refresh_token(self, data: dict) -> str:
        """Create a new refresh token"""
        to_encode = data.copy()
        expire = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
        to_encode.update({"exp": expire, "type": "refresh"})
        encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
        return encoded_jwt

    def verify_token(self, token: str) -> Optional[dict]:
        """Verify and decode a JWT token"""
        try:
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            return payload
        except JWTError:
            return None

    def authenticate_user(self, db: Session, username: str, password: str) -> Optional[User]:
        """Authenticate user with username/email and password"""
        return self.user_service.authenticate_user(db, username, password)

    def get_current_user(self, db: Session, token: str) -> Optional[User]:
        """Get current user from token"""
        payload = self.verify_token(token)
        if payload is None:
            return None
        
        username: str = payload.get("sub")
        if username is None:
            return None
        
        user = self.user_service.get_user_by_username(db, username)
        if user is None:
            return None
        
        return user

    def get_current_active_user(self, db: Session, token: str) -> Optional[User]:
        """Get current active user from token"""
        user = self.get_current_user(db, token)
        if user is None:
            return None
        
        if not user.is_active:
            return None
        
        return user

    def refresh_access_token(self, db: Session, refresh_token: str) -> Optional[str]:
        """Refresh access token using refresh token"""
        payload = self.verify_token(refresh_token)
        if payload is None:
            return None
        
        token_type = payload.get("type")
        if token_type != "refresh":
            return None
        
        username: str = payload.get("sub")
        if username is None:
            return None
        
        user = self.user_service.get_user_by_username(db, username)
        if user is None or not user.is_active:
            return None
        
        # Create new access token
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = self.create_access_token(
            data={"sub": user.username}, expires_delta=access_token_expires
        )
        
        return access_token

    def login_user(self, db: Session, username: str, password: str) -> Optional[dict]:
        """Login user and return tokens"""
        user = self.authenticate_user(db, username, password)
        if not user:
            return None
        
        if not user.is_active:
            return None
        
        # Create access token
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = self.create_access_token(
            data={"sub": user.username}, expires_delta=access_token_expires
        )
        
        # Create refresh token
        refresh_token = self.create_refresh_token(data={"sub": user.username})
        
        return {
            "access_token": access_token,
            "refresh_token": refresh_token,
            "token_type": "bearer",
            "expires_in": ACCESS_TOKEN_EXPIRE_MINUTES * 60,
            "user": {
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "is_active": user.is_active,
                "is_admin": user.is_admin
            }
        }

    def logout_user(self, token: str) -> bool:
        """Logout user (in a real implementation, you might want to blacklist the token)"""
        # For now, we just return True
        # In production, you might want to add the token to a blacklist
        return True

    def change_password(self, db: Session, user_id: int, old_password: str, new_password: str) -> bool:
        """Change user password"""
        return self.user_service.change_password(db, user_id, old_password, new_password)

    def reset_password_request(self, db: Session, email: str) -> bool:
        """Request password reset (send email with reset link)"""
        user = self.user_service.get_user_by_email(db, email)
        if not user:
            return False
        
        # In a real implementation, you would:
        # 1. Generate a password reset token
        # 2. Send an email with the reset link
        # 3. Store the token with expiration time
        
        # For now, we just return True
        return True

    def reset_password(self, db: Session, reset_token: str, new_password: str) -> bool:
        """Reset password using reset token"""
        # In a real implementation, you would:
        # 1. Verify the reset token
        # 2. Find the user associated with the token
        # 3. Update the password
        # 4. Invalidate the reset token
        
        # For now, we just return True
        return True

    def verify_email(self, db: Session, verification_token: str) -> bool:
        """Verify user email using verification token"""
        # In a real implementation, you would:
        # 1. Verify the verification token
        # 2. Find the user associated with the token
        # 3. Mark the email as verified
        
        # For now, we just return True
        return True

    def send_verification_email(self, db: Session, user_id: int) -> bool:
        """Send verification email to user"""
        user = self.user_service.get_user(user_id)
        if not user:
            return False
        
        # In a real implementation, you would:
        # 1. Generate a verification token
        # 2. Send an email with the verification link
        
        # For now, we just return True
        return True

    def create_api_token(self, db: Session, user_id: int, token_name: str) -> Optional[str]:
        """Create an API token for a user"""
        user = self.user_service.get_user(db, user_id)
        if not user:
            return None
        
        # In a real implementation, you would:
        # 1. Generate a secure API token
        # 2. Store it in the database with user association
        # 3. Return the token
        
        # For now, we just return a placeholder
        return f"api_token_{user_id}_{token_name}"

    def revoke_api_token(self, db: Session, user_id: int, token_id: str) -> bool:
        """Revoke an API token"""
        # In a real implementation, you would:
        # 1. Find the token in the database
        # 2. Mark it as revoked or delete it
        
        # For now, we just return True
        return True

    def get_user_permissions(self, user: User) -> list:
        """Get user permissions"""
        permissions = []
        
        if user.is_admin:
            permissions.extend([
                "read:all",
                "write:all",
                "delete:all",
                "admin:all"
            ])
        else:
            permissions.extend([
                "read:own",
                "write:own"
            ])
        
        return permissions

    def check_permission(self, user: User, permission: str) -> bool:
        """Check if user has a specific permission"""
        permissions = self.get_user_permissions(user)
        return permission in permissions

    def require_permission(self, permission: str):
        """Decorator to require a specific permission"""
        def decorator(func):
            def wrapper(*args, **kwargs):
                # This would be implemented in the actual endpoint
                # For now, it's just a placeholder
                return func(*args, **kwargs)
            return wrapper
        return decorator

# Dependency functions for FastAPI
def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> User:
    """Dependency to get current user from token"""
    auth_service = AuthService()
    user = auth_service.get_current_user(db, credentials.credentials)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user

def get_current_active_user(
    current_user: User = Depends(get_current_user)
) -> User:
    """Dependency to get current active user"""
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    return current_user

def get_current_admin_user(
    current_user: User = Depends(get_current_active_user)
) -> User:
    """Dependency to get current admin user"""
    if not current_user.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions"
        )
    return current_user

def require_permission(permission: str):
    """Dependency to require a specific permission"""
    def dependency(current_user: User = Depends(get_current_active_user)) -> User:
        auth_service = AuthService()
        if not auth_service.check_permission(current_user, permission):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Permission '{permission}' required"
            )
        return current_user
    return dependency
