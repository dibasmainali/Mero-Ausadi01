#!/usr/bin/env python3
"""
Quick start script for Medicine Identification Backend
"""
import os
import sys
import subprocess
from pathlib import Path

def check_python_version():
    """Check if Python version is compatible"""
    if sys.version_info < (3, 8):
        print("❌ Error: Python 3.8 or higher is required")
        print(f"Current version: {sys.version}")
        return False
    print(f"✅ Python version: {sys.version.split()[0]}")
    return True

def check_dependencies():
    """Check if required dependencies are installed"""
    try:
        import fastapi
        import sqlalchemy
        import uvicorn
        print("✅ Required packages are installed")
        return True
    except ImportError as e:
        print(f"❌ Missing dependency: {e}")
        print("Please run: pip install -r requirements.txt")
        return False

def check_env_file():
    """Check if .env file exists"""
    env_file = Path(".env")
    if not env_file.exists():
        print("⚠️  Warning: .env file not found")
        print("Creating a basic .env file...")
        
        env_content = """# Database Configuration
DATABASE_URL=sqlite:///./ausadi_thaha.db

# JWT Configuration
SECRET_KEY=your-super-secret-key-here-change-this-in-production

# Application Configuration
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# Optional: Development settings
DEBUG=True
LOG_LEVEL=INFO
"""
        
        with open(".env", "w") as f:
            f.write(env_content)
        print("✅ Created .env file with default settings")
    else:
        print("✅ .env file found")

def create_static_directory():
    """Create static directory if it doesn't exist"""
    static_dir = Path("static")
    if not static_dir.exists():
        static_dir.mkdir()
        print("✅ Created static directory")
    else:
        print("✅ Static directory exists")

def initialize_database():
    """Initialize the database"""
    try:
        from database.database import init_db
        init_db()
        print("✅ Database initialized")
        return True
    except Exception as e:
        print(f"❌ Database initialization failed: {e}")
        return False

def start_server():
    """Start the FastAPI server"""
    print("\n🚀 Starting Medicine Identification Backend...")
    print("📖 API Documentation will be available at: http://localhost:8000/docs")
    print("🔍 Health check: http://localhost:8000/health")
    print("⏹️  Press Ctrl+C to stop the server\n")
    
    try:
        import uvicorn
        uvicorn.run(
            "main:app",
            host="0.0.0.0",
            port=8000,
            reload=True,
            log_level="info"
        )
    except KeyboardInterrupt:
        print("\n👋 Server stopped")
    except Exception as e:
        print(f"❌ Failed to start server: {e}")

def main():
    """Main function"""
    print("🏥 Medicine Identification Backend - Quick Start")
    print("=" * 50)
    
    # Check prerequisites
    if not check_python_version():
        sys.exit(1)
    
    if not check_dependencies():
        sys.exit(1)
    
    # Setup
    check_env_file()
    create_static_directory()
    
    if not initialize_database():
        print("⚠️  Continuing without database initialization...")
    
    # Start server
    start_server()

if __name__ == "__main__":
    main()
