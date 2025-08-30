# Medicine Identification Backend - Setup Guide

This guide will help you set up and run the Medicine Identification Backend application.

## Prerequisites

Before you begin, make sure you have the following installed:

### 1. Python 3.8 or higher
```bash
# Check Python version
python --version
# or
python3 --version
```

### 2. PostgreSQL Database
- Install PostgreSQL on your system
- Create a database for the application

### 3. Tesseract OCR (for image processing)
- **Windows**: Download and install from https://github.com/UB-Mannheim/tesseract/wiki
- **macOS**: `brew install tesseract`
- **Linux**: `sudo apt-get install tesseract-ocr`

### 4. Git (optional)
```bash
git --version
```

## Installation Steps

### Step 1: Clone or Download the Project
```bash
# If using git
git clone <repository-url>
cd backend

# Or simply navigate to the backend folder if you already have the files
cd backend
```

### Step 2: Create Virtual Environment
```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate

# On macOS/Linux:
source venv/bin/activate
```

### Step 3: Install Dependencies
```bash
# Install all required packages
pip install -r requirements.txt
```

### Step 4: Set Up Environment Variables
Create a `.env` file in the backend directory:

```bash
# Create .env file
touch .env
```

Add the following content to `.env`:

```env
# Database Configuration
DATABASE_URL=postgresql://username:password@localhost/ausadi_thaha

# JWT Configuration
SECRET_KEY=your-super-secret-key-here-change-this-in-production

# Firebase Configuration (optional - for cloud features)
FIREBASE_CREDENTIALS={"type": "service_account", ...}

# Application Configuration
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# Optional: Development settings
DEBUG=True
LOG_LEVEL=INFO
```

### Step 5: Set Up Database

#### Option A: Using PostgreSQL
1. Create a PostgreSQL database:
```sql
CREATE DATABASE ausadi_thaha;
CREATE USER ausadi_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE ausadi_thaha TO ausadi_user;
```

2. Update your `.env` file with the correct database URL:
```env
DATABASE_URL=postgresql://ausadi_user:your_password@localhost/ausadi_thaha
```

#### Option B: Using SQLite (for development only)
Update your `.env` file:
```env
DATABASE_URL=sqlite:///./ausadi_thaha.db
```

### Step 6: Initialize Database
```bash
# The database tables will be created automatically when you run the application
# But you can also run this to ensure everything is set up:
python -c "from database.database import init_db; init_db()"
```

### Step 7: Create Static Directory
```bash
# Create static files directory
mkdir static
```

## Running the Application

### Method 1: Using Python directly
```bash
# Make sure your virtual environment is activated
python main.py
```

### Method 2: Using Uvicorn
```bash
# Run with uvicorn
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Method 3: Using Docker (if you have Docker installed)
```bash
# Build the Docker image
docker build -t medicine-backend .

# Run the container
docker run -p 8000:8000 medicine-backend
```

## Verifying the Installation

### 1. Check if the server is running
Open your browser and go to: `http://localhost:8000`

You should see:
```json
{
  "message": "Ausadi Thaha API is running"
}
```

### 2. Check the API documentation
Go to: `http://localhost:8000/docs`

This will show you the interactive API documentation (Swagger UI).

### 3. Health check
Go to: `http://localhost:8000/health`

You should see:
```json
{
  "status": "healthy"
}
```

## Creating Your First User

### Using the API
1. Go to `http://localhost:8000/docs`
2. Find the `/auth/register` endpoint
3. Click "Try it out"
4. Enter user details:
```json
{
  "username": "admin",
  "email": "admin@example.com",
  "password": "admin123"
}
```
5. Click "Execute"

### Using curl
```bash
curl -X POST "http://localhost:8000/auth/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "email": "admin@example.com",
    "password": "admin123"
  }'
```

## Testing the Application

### 1. Login
```bash
curl -X POST "http://localhost:8000/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin123"
  }'
```

### 2. Create a Medicine (requires authentication)
```bash
# First, get the access token from login response
TOKEN="your_access_token_here"

curl -X POST "http://localhost:8000/medicines" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "brand_name": "Paracetamol",
    "generic_name": "Acetaminophen",
    "strength": "500mg",
    "manufacturer": "GSK",
    "uses": "Pain relief and fever reduction",
    "side_effects": "Nausea, stomach upset",
    "warnings": "Do not exceed recommended dosage"
  }'
```

### 3. Search Medicines
```bash
curl -X POST "http://localhost:8000/medicines/search" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "paracetamol",
    "limit": 10
  }'
```

## Troubleshooting

### Common Issues

#### 1. Database Connection Error
**Error**: `psycopg2.OperationalError: could not connect to server`
**Solution**: 
- Check if PostgreSQL is running
- Verify database credentials in `.env`
- Ensure database exists

#### 2. Tesseract Not Found
**Error**: `pytesseract.TesseractNotFoundError`
**Solution**:
- Install Tesseract OCR
- For Windows, update the path in `ocr_service.py`:
```python
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'
```

#### 3. Import Errors
**Error**: `ModuleNotFoundError: No module named '...'`
**Solution**:
- Make sure virtual environment is activated
- Reinstall dependencies: `pip install -r requirements.txt`

#### 4. Port Already in Use
**Error**: `OSError: [Errno 98] Address already in use`
**Solution**:
- Change the port: `uvicorn main:app --port 8001`
- Or kill the process using the port

#### 5. Permission Errors
**Error**: `Permission denied`
**Solution**:
- On Linux/macOS: `chmod +x venv/bin/activate`
- Check file permissions for the project directory

### Getting Help

1. Check the logs for detailed error messages
2. Verify all prerequisites are installed
3. Ensure environment variables are set correctly
4. Check the API documentation at `http://localhost:8000/docs`

## Development

### Running in Development Mode
```bash
# Enable debug mode and auto-reload
uvicorn main:app --reload --log-level debug
```

### Running Tests
```bash
# Install test dependencies
pip install pytest pytest-asyncio

# Run tests
pytest
```

### Code Formatting
```bash
# Install formatting tools
pip install black isort

# Format code
black .
isort .
```

## Production Deployment

For production deployment, consider:

1. **Environment Variables**: Use proper secret management
2. **Database**: Use a production-grade database
3. **Security**: Configure CORS properly
4. **Logging**: Set up proper logging
5. **Monitoring**: Add health checks and monitoring
6. **SSL**: Use HTTPS in production

## API Endpoints Overview

- **Authentication**: `/auth/register`, `/auth/login`
- **Medicines**: `/medicines` (CRUD operations)
- **Search**: `/medicines/search`, `/medicines/search/fuzzy`
- **OCR**: `/ocr/process`, `/ocr/search`
- **Admin**: `/admin/medicines/stats`, `/admin/medicines/import`
- **Sync**: `/sync/upload`, `/sync/download`
- **Users**: `/users/me`, `/users/{id}/stats`

For detailed API documentation, visit `http://localhost:8000/docs` when the server is running.
