# Medicine Identification Backend

A comprehensive FastAPI backend for medicine identification, search, and management with OCR capabilities, user authentication, and cloud synchronization.

## Features

### 🔍 Medicine Management
- **CRUD Operations**: Create, read, update, and delete medicines
- **Advanced Search**: Text-based search with confidence scoring
- **Barcode Support**: Search medicines by barcode
- **Bulk Operations**: Import medicines from CSV files
- **Duplicate Detection**: Prevent duplicate medicine entries
- **Validation**: Comprehensive input validation and barcode format validation

### 📊 Analytics & Statistics
- **Medicine Statistics**: Total medicines, manufacturers, generic names
- **Search Analytics**: Most searched terms, recent activity
- **User Activity**: Detailed user engagement metrics
- **Trend Analysis**: Search patterns and usage trends

### 🔐 Authentication & Authorization
- **JWT Authentication**: Secure token-based authentication
- **User Management**: User registration, login, and profile management
- **Role-based Access**: Admin and regular user roles
- **Password Security**: Secure password hashing and validation
- **API Key Support**: Generate and manage API keys

### 📸 OCR & Image Processing
- **Text Extraction**: Extract text from medicine images
- **Image Preprocessing**: Enhance image quality for better OCR results
- **Medicine Recognition**: Identify medicines from extracted text
- **Confidence Scoring**: Rate the accuracy of OCR results
- **Multiple Formats**: Support for various image formats

### ☁️ Cloud Integration
- **Firebase Integration**: Sync data with Firebase Firestore
- **Backup & Restore**: Cloud backup and restoration capabilities
- **Real-time Sync**: Keep local and cloud data synchronized
- **Offline Support**: Work with local data when offline

### 📈 User Analytics
- **Activity Tracking**: Monitor user search and OCR activity
- **Usage Statistics**: Track user engagement and preferences
- **Performance Metrics**: Monitor system performance and usage

## Project Structure

```
backend/
├── database/
│   ├── database.py          # Database connection and session management
│   └── models.py            # SQLAlchemy models
├── services/
│   ├── medicine_service.py  # Medicine management and search
│   ├── user_service.py      # User management and analytics
│   ├── auth_service.py      # Authentication and authorization
│   ├── ocr_service.py       # OCR and image processing
│   └── firebase_service.py  # Cloud synchronization
├── schemas/
│   ├── medicine.py          # Medicine Pydantic schemas
│   └── user.py              # User Pydantic schemas
├── main.py                  # FastAPI application entry point
├── requirements.txt         # Python dependencies
└── README.md               # This file
```

## Services Overview

### MedicineService
The core service for medicine management with the following key methods:

- `get_medicines()` - Retrieve medicines with pagination
- `search_medicines()` - Basic text search
- `advanced_search_medicines()` - Search with multiple filters
- `search_medicines_with_confidence()` - Search with confidence scoring
- `create_medicine()` - Add new medicine
- `update_medicine()` - Update existing medicine
- `delete_medicine()` - Remove medicine
- `bulk_create_medicines()` - Import multiple medicines
- `import_from_csv()` - Import from CSV file
- `get_medicine_stats()` - Get statistics
- `get_detailed_analytics()` - Comprehensive analytics
- `sync_to_cloud()` / `sync_from_cloud()` - Cloud synchronization
- `backup_to_cloud()` / `restore_from_cloud()` - Backup operations

### UserService
Comprehensive user management with analytics:

- `create_user()` - User registration
- `authenticate_user()` - User authentication
- `get_user_stats()` - User statistics
- `get_user_activity()` - Detailed activity tracking
- `get_users_by_activity()` - Most active users
- `delete_user_data()` - GDPR-compliant data deletion
- `promote_to_admin()` / `demote_from_admin()` - Role management

### AuthService
Secure authentication and authorization:

- `login_user()` - User login with JWT tokens
- `create_access_token()` / `create_refresh_token()` - Token generation
- `verify_token()` - Token validation
- `refresh_access_token()` - Token refresh
- `get_user_permissions()` - Permission management
- `check_permission()` - Permission validation

### OCRService
Advanced image processing and text extraction:

- `extract_text_from_image()` - OCR text extraction
- `preprocess_image()` - Image enhancement
- `extract_medicine_info()` - Medicine information extraction
- `search_medicines_by_ocr_text()` - OCR-based medicine search
- `process_image_file()` - File-based processing
- `process_base64_image()` - Base64 image processing
- `enhance_image_quality()` - Image quality improvement

### FirebaseService
Cloud synchronization and backup:

- `upload_medicines()` - Upload to cloud
- `download_medicines()` - Download from cloud
- `backup_database()` - Create cloud backup
- `restore_database()` - Restore from backup
- `search_medicines()` - Cloud-based search

## Database Models

### Core Models
- **User**: User accounts and profiles
- **Medicine**: Medicine information and details
- **SearchLog**: Search activity tracking
- **OCRLog**: OCR scan history
- **Manufacturer**: Medicine manufacturers
- **GenericName**: Generic medicine names
- **SideEffect**: Medicine side effects
- **Warning**: Medicine warnings

## API Endpoints

### Authentication
- `POST /auth/login` - User login
- `POST /auth/register` - User registration
- `POST /auth/refresh` - Refresh access token
- `POST /auth/logout` - User logout
- `POST /auth/change-password` - Change password

### Medicines
- `GET /medicines` - List medicines
- `GET /medicines/{id}` - Get medicine by ID
- `POST /medicines` - Create medicine
- `PUT /medicines/{id}` - Update medicine
- `DELETE /medicines/{id}` - Delete medicine
- `GET /medicines/search` - Search medicines
- `POST /medicines/import` - Import from CSV
- `GET /medicines/stats` - Get statistics
- `GET /medicines/analytics` - Get detailed analytics

### OCR
- `POST /ocr/process` - Process image for OCR
- `POST /ocr/search` - Search medicines using OCR
- `POST /ocr/enhance` - Enhance image quality

### Users
- `GET /users` - List users (admin only)
- `GET /users/{id}` - Get user profile
- `PUT /users/{id}` - Update user profile
- `GET /users/{id}/stats` - Get user statistics
- `GET /users/{id}/activity` - Get user activity

### Cloud Sync
- `POST /sync/upload` - Upload to cloud
- `POST /sync/download` - Download from cloud
- `POST /sync/backup` - Create backup
- `POST /sync/restore` - Restore from backup

## Installation & Setup

### Prerequisites
- Python 3.8+
- PostgreSQL
- Tesseract OCR
- Firebase project (for cloud features)

### Installation
1. Clone the repository
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Set up environment variables:
   ```bash
   export DATABASE_URL="postgresql://user:password@localhost/medicine_db"
   export SECRET_KEY="your-secret-key"
   export FIREBASE_CREDENTIALS="your-firebase-credentials"
   ```

4. Initialize the database:
   ```bash
   alembic upgrade head
   ```

5. Run the application:
   ```bash
   uvicorn main:app --reload
   ```

## Configuration

### Environment Variables
- `DATABASE_URL`: PostgreSQL connection string
- `SECRET_KEY`: JWT secret key
- `FIREBASE_CREDENTIALS`: Firebase service account credentials
- `ACCESS_TOKEN_EXPIRE_MINUTES`: JWT token expiration time
- `REFRESH_TOKEN_EXPIRE_DAYS`: Refresh token expiration time

### Firebase Setup
1. Create a Firebase project
2. Download service account key
3. Set `FIREBASE_CREDENTIALS` environment variable
4. Enable Firestore in your Firebase project

### Tesseract Setup
1. Install Tesseract OCR
2. For Windows: Set path in `ocr_service.py`
3. For Linux/Mac: Install via package manager

## Usage Examples

### Medicine Search
```python
# Basic search
medicines = medicine_service.search_medicines(db, "paracetamol", limit=10)

# Advanced search with filters
medicines = medicine_service.advanced_search_medicines(
    db, 
    "paracetamol", 
    filters={"manufacturer": "GSK", "strength": "500mg"}
)

# Search with confidence scoring
results = medicine_service.search_medicines_with_confidence(db, "aspirin", limit=5)
```

### OCR Processing
```python
# Process image file
extracted_text, medicine_info = ocr_service.process_image_file(image_file)

# Search medicines using OCR text
results = ocr_service.search_medicines_by_ocr_text(db, extracted_text, limit=10)
```

### User Analytics
```python
# Get user statistics
stats = user_service.get_user_stats(db, user_id)

# Get detailed activity
activity = user_service.get_user_activity(db, user_id, days=30)

# Get most active users
active_users = user_service.get_users_by_activity(db, days=7, limit=10)
```

### Cloud Synchronization
```python
# Sync to cloud
result = await medicine_service.sync_to_cloud(db)

# Backup to cloud
result = await medicine_service.backup_to_cloud(db)

# Restore from cloud
result = await medicine_service.restore_from_cloud(db)
```

## Security Features

- **Password Hashing**: Bcrypt password hashing
- **JWT Tokens**: Secure token-based authentication
- **Input Validation**: Comprehensive Pydantic validation
- **SQL Injection Protection**: SQLAlchemy ORM protection
- **CORS Support**: Configurable CORS policies
- **Rate Limiting**: API rate limiting (can be implemented)
- **Audit Logging**: User activity tracking

## Performance Optimizations

- **Database Indexing**: Optimized database queries
- **Connection Pooling**: Efficient database connections
- **Caching**: Redis caching support (can be implemented)
- **Pagination**: Efficient data pagination
- **Async Operations**: Non-blocking async operations
- **Batch Processing**: Bulk operations for efficiency

## Testing

### Unit Tests
```bash
pytest tests/unit/
```

### Integration Tests
```bash
pytest tests/integration/
```

### API Tests
```bash
pytest tests/api/
```

## Deployment

### Docker Deployment
```bash
docker build -t medicine-backend .
docker run -p 8000:8000 medicine-backend
```

### Production Considerations
- Use environment variables for sensitive data
- Set up proper logging and monitoring
- Configure database connection pooling
- Set up SSL/TLS certificates
- Implement rate limiting
- Set up backup strategies
- Monitor performance metrics

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

## Roadmap

- [ ] Real-time notifications
- [ ] Advanced image recognition
- [ ] Multi-language support
- [ ] Mobile app integration
- [ ] Advanced analytics dashboard
- [ ] Machine learning improvements
- [ ] API rate limiting
- [ ] Redis caching
- [ ] WebSocket support
- [ ] GraphQL API
