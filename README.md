# Ausadi Thaha - Medicine Identification App

A cross-platform Flutter mobile application that identifies medicines from text printed on medicine strips or boxes using OCR technology and provides detailed information in both Nepali and English.

## Features

- **Cross-platform**: Works on both Android and iOS
- **Offline OCR**: Uses Google ML Kit for text extraction without internet
- **Image Preprocessing**: Automatic contrast, sharpness, and brightness adjustment
- **Fuzzy Search**: Handles minor OCR spelling errors
- **Offline Database**: SQLite for core data with Firebase sync
- **Multilingual**: Supports Nepali and English
- **High Accuracy**: Confidence scoring with multiple match suggestions
- **Admin Panel**: Web-based interface for medicine data management

## Architecture

### Frontend (Flutter)
- Camera integration with image preprocessing
- OCR processing using Google ML Kit
- Local SQLite database for offline functionality
- Fuzzy search implementation
- Multilingual UI (Nepali/English)

### Backend (Python FastAPI)
- RESTful API for medicine database
- Admin panel for data management
- Firebase integration for data sync
- PostgreSQL database for cloud storage

### Database Schema
- Medicines table with comprehensive drug information
- Manufacturers table
- Generic names table
- Side effects and warnings tables

## Project Structure

```
ausadi_thaha/
├── flutter_app/          # Flutter mobile application
├── backend/              # Python FastAPI backend
├── admin_panel/          # Web-based admin interface
├── database/             # Database schemas and sample data
└── docs/                 # Documentation and deployment guides
```

## Quick Start

1. **Setup Flutter App**:
   ```bash
   cd flutter_app
   flutter pub get
   flutter run
   ```

2. **Setup Backend**:
   ```bash
   cd backend
   pip install -r requirements.txt
   uvicorn main:app --reload
   ```

3. **Setup Database**:
   ```bash
   cd database
   python setup_database.py
   ```

## Deployment

- **Mobile Apps**: Google Play Store and Apple App Store
- **Backend**: Firebase Functions + PostgreSQL
- **Admin Panel**: Firebase Hosting

## Technologies Used

- **Frontend**: Flutter, Dart, Google ML Kit
- **Backend**: Python, FastAPI, PostgreSQL
- **Cloud**: Firebase (Functions, Hosting, Firestore)
- **Database**: SQLite (local), PostgreSQL (cloud)
- **OCR**: Google ML Kit Text Recognition
- **AI**: Gemini AI API for enhanced text processing

## License

MIT License - see LICENSE file for details
