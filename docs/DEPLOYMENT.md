# Ausadi Thaha - Deployment Guide

This guide provides step-by-step instructions for deploying the Ausadi Thaha medicine identification app to production.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Backend Deployment](#backend-deployment)
3. [Mobile App Deployment](#mobile-app-deployment)
4. [Firebase Setup](#firebase-setup)
5. [Database Setup](#database-setup)
6. [Environment Configuration](#environment-configuration)
7. [Monitoring and Maintenance](#monitoring-and-maintenance)

## Prerequisites

### Required Accounts
- Google Cloud Platform account
- Firebase account
- Google Play Console account (for Android)
- Apple Developer account (for iOS)
- PostgreSQL database (can use Google Cloud SQL)

### Required Software
- Flutter SDK (latest stable version)
- Python 3.8+
- Node.js 16+
- Git
- Docker (optional)

## Backend Deployment

### Option 1: Google Cloud Run (Recommended)

1. **Setup Google Cloud Project**
   ```bash
   # Install Google Cloud CLI
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   ```

2. **Enable Required APIs**
   ```bash
   gcloud services enable run.googleapis.com
   gcloud services enable cloudbuild.googleapis.com
   gcloud services enable sqladmin.googleapis.com
   ```

3. **Create PostgreSQL Database**
   ```bash
   # Create Cloud SQL instance
   gcloud sql instances create ausadi-thaha-db \
     --database-version=POSTGRES_14 \
     --tier=db-f1-micro \
     --region=us-central1 \
     --root-password=YOUR_ROOT_PASSWORD
   
   # Create database
   gcloud sql databases create ausadi_thaha \
     --instance=ausadi-thaha-db
   ```

4. **Deploy Backend**
   ```bash
   cd backend
   
   # Build and deploy
   gcloud run deploy ausadi-thaha-api \
     --source . \
     --platform managed \
     --region us-central1 \
     --allow-unauthenticated \
     --set-env-vars DATABASE_URL=postgresql://username:password@host/database
   ```

### Option 2: Firebase Functions

1. **Setup Firebase Project**
   ```bash
   npm install -g firebase-tools
   firebase login
   firebase init functions
   ```

2. **Deploy Functions**
   ```bash
   cd backend
   firebase deploy --only functions
   ```

### Option 3: Docker Deployment

1. **Build Docker Image**
   ```bash
   cd backend
   docker build -t ausadi-thaha-api .
   ```

2. **Run Container**
   ```bash
   docker run -d \
     --name ausadi-thaha-api \
     -p 8000:8000 \
     -e DATABASE_URL=postgresql://username:password@host/database \
     ausadi-thaha-api
   ```

## Mobile App Deployment

### Android (Google Play Store)

1. **Setup Flutter for Android**
   ```bash
   cd flutter_app
   flutter build apk --release
   ```

2. **Create Keystore**
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias upload
   ```

3. **Configure Signing**
   Create `android/key.properties`:
   ```properties
   storePassword=<password from previous step>
   keyPassword=<password from previous step>
   keyAlias=upload
   storeFile=<location of the keystore file>
   ```

4. **Build Release APK**
   ```bash
   flutter build appbundle --release
   ```

5. **Upload to Google Play Console**
   - Go to [Google Play Console](https://play.google.com/console)
   - Create new app
   - Upload the generated `.aab` file
   - Fill in app details, screenshots, and description
   - Submit for review

### iOS (App Store)

1. **Setup Flutter for iOS**
   ```bash
   cd flutter_app
   flutter build ios --release
   ```

2. **Open in Xcode**
   ```bash
   open ios/Runner.xcworkspace
   ```

3. **Configure Signing**
   - Select your team in Xcode
   - Update bundle identifier
   - Configure provisioning profiles

4. **Archive and Upload**
   - Product → Archive
   - Upload to App Store Connect
   - Submit for review in App Store Connect

## Firebase Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create new project: `ausadi-thaha`
3. Enable Google Analytics (optional)

### 2. Configure Authentication

1. Go to Authentication → Sign-in method
2. Enable Email/Password authentication
3. Add authorized domains

### 3. Setup Firestore Database

1. Go to Firestore Database
2. Create database in production mode
3. Set up security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /medicines/{medicineId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 4. Setup Storage

1. Go to Storage
2. Create storage bucket
3. Set up security rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /medicines/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
  }
}
```

### 5. Download Configuration Files

1. **Android**: Download `google-services.json` to `android/app/`
2. **iOS**: Download `GoogleService-Info.plist` to `ios/Runner/`

## Database Setup

### PostgreSQL Schema

```sql
-- Create database
CREATE DATABASE ausadi_thaha;

-- Create user
CREATE USER ausadi_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE ausadi_thaha TO ausadi_user;

-- Connect to database and run migrations
\c ausadi_thaha

-- Run Alembic migrations
alembic upgrade head
```

### Sample Data Import

```bash
cd database
python import_sample_data.py
```

## Environment Configuration

### Backend Environment Variables

Create `.env` file in backend directory:

```env
# Database
DATABASE_URL=postgresql://username:password@host/database

# JWT
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# Firebase
FIREBASE_PROJECT_ID=ausadi-thaha
FIREBASE_PRIVATE_KEY_ID=your-private-key-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email
FIREBASE_CLIENT_ID=your-client-id

# API Configuration
API_V1_STR=/api/v1
PROJECT_NAME=Ausadi Thaha API
BACKEND_CORS_ORIGINS=["http://localhost:3000", "https://your-domain.com"]

# OCR Configuration
GOOGLE_CLOUD_VISION_API_KEY=your-vision-api-key
```

### Flutter Environment Variables

Create `.env` file in flutter_app directory:

```env
# API Configuration
API_BASE_URL=https://your-api-domain.com/api
FIREBASE_PROJECT_ID=ausadi-thaha

# OCR Configuration
GOOGLE_ML_KIT_API_KEY=your-ml-kit-api-key
```

## Monitoring and Maintenance

### 1. Application Monitoring

- **Google Cloud Monitoring**: Monitor API performance
- **Firebase Analytics**: Track app usage
- **Sentry**: Error tracking and performance monitoring

### 2. Database Monitoring

```bash
# Monitor database performance
gcloud sql instances describe ausadi-thaha-db

# Check slow queries
gcloud sql logs tail ausadi-thaha-db
```

### 3. Backup Strategy

```bash
# Automated backups
gcloud sql instances patch ausadi-thaha-db \
  --backup-start-time=02:00 \
  --backup-retention-count=7
```

### 4. Scaling

- **Horizontal Scaling**: Use Cloud Run with multiple instances
- **Database Scaling**: Upgrade Cloud SQL instance tier
- **CDN**: Use Cloud CDN for static assets

## Security Checklist

- [ ] Enable HTTPS everywhere
- [ ] Implement proper authentication
- [ ] Set up CORS properly
- [ ] Use environment variables for secrets
- [ ] Enable database encryption
- [ ] Implement rate limiting
- [ ] Set up security headers
- [ ] Regular security updates

## Troubleshooting

### Common Issues

1. **Database Connection Issues**
   ```bash
   # Check database connectivity
   gcloud sql connect ausadi-thaha-db
   ```

2. **API Deployment Issues**
   ```bash
   # Check logs
   gcloud logs read --filter resource.type="cloud_run_revision"
   ```

3. **Mobile App Build Issues**
   ```bash
   # Clean and rebuild
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

### Support

For additional support:
- Check the [GitHub Issues](https://github.com/your-repo/issues)
- Review [Flutter Documentation](https://flutter.dev/docs)
- Check [FastAPI Documentation](https://fastapi.tiangolo.com/)

## Cost Optimization

### Google Cloud Costs

- Use Cloud Run with minimum instances = 0
- Use Cloud SQL with automatic scaling
- Enable Cloud CDN for static assets
- Use Cloud Storage for file storage

### Firebase Costs

- Monitor Firestore read/write operations
- Use Firebase Storage for images
- Enable Firebase Analytics for insights

## Performance Optimization

1. **Database Optimization**
   - Add proper indexes
   - Use connection pooling
   - Implement caching

2. **API Optimization**
   - Use async/await properly
   - Implement pagination
   - Add response caching

3. **Mobile App Optimization**
   - Optimize image sizes
   - Implement lazy loading
   - Use efficient state management
