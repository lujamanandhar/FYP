# NutriLift - Running Instructions

This guide will help you run both the Django backend and Flutter frontend together.

## Prerequisites

- Python 3.8+ installed
- Flutter SDK installed
- Git installed

## Backend Setup (Django)

### 1. Navigate to Backend Directory
```bash
cd backend
```

### 2. Create and Activate Virtual Environment
```bash
# Create virtual environment
python -m venv .venv

# Activate virtual environment (Windows)
.venv\Scripts\activate

# Activate virtual environment (macOS/Linux)
source .venv/bin/activate
```

### 3. Install Dependencies
```bash
pip install -r requirements.txt
```

### 4. Run Database Migrations
```bash
python manage.py migrate
```

### 5. Create a Test User (Optional)
```bash
python manage.py shell -c "from authentications.models import User; User.objects.create_user(email='test@example.com', password='testpass123', name='Test User')"
```

### 6. Create Superuser (Optional)
```bash
python manage.py createsuperuser
```

### 7. Start Django Development Server
```bash
python manage.py runserver
```

The backend will be available at: `http://127.0.0.1:8000/`

**API Documentation:** `http://127.0.0.1:8000/api/auth/`

## Frontend Setup (Flutter)

### 1. Open New Terminal/Command Prompt
Keep the backend terminal running and open a new terminal.

### 2. Navigate to Frontend Directory
```bash
cd frontend
```

### 3. Get Flutter Dependencies
```bash
flutter pub get
```

### 4. Run Flutter App
```bash
flutter run
```

Choose your target device when prompted (Chrome for web, connected device for mobile).

## Testing the Integration

### 1. Backend API Endpoints
- **API Root:** `http://127.0.0.1:8000/api/auth/`
- **Register:** `http://127.0.0.1:8000/api/auth/register/`
- **Login:** `http://127.0.0.1:8000/api/auth/login/`
- **Profile:** `http://127.0.0.1:8000/api/auth/me/`
- **Update Profile:** `http://127.0.0.1:8000/api/auth/profile/`

### 2. Flutter App Features
- User Registration
- User Login
- Profile Management
- Home Dashboard
- Workout Tracking
- Nutrition Tracking
- Community Feed
- **Gym Finder** (newly integrated)

### 3. Test Gym Finder
1. Open the Flutter app
2. Navigate to the "Gym Finder" tab (last tab in bottom navigation)
3. Browse gyms, search, and filter
4. Tap on any gym to view detailed information
5. Test the booking functionality

## Troubleshooting

### Backend Issues

#### Database Connection Error
If you get PostgreSQL connection errors, the settings have been updated to use SQLite for development. Just run:
```bash
python manage.py migrate
```

#### Port Already in Use
If port 8000 is busy, run on a different port:
```bash
python manage.py runserver 8001
```
Then update the Flutter API base URL in `frontend/lib/services/api_client.dart`.

#### CORS Issues
CORS is already configured for `http://localhost:*` in the Django settings.

### Frontend Issues

#### Flutter Dependencies
If you get dependency errors:
```bash
flutter clean
flutter pub get
```

#### API Connection Issues
1. Ensure backend is running on `http://127.0.0.1:8000/`
2. Check the API base URL in `frontend/lib/services/api_client.dart`
3. Verify CORS settings in Django

#### Device Selection
For web development:
```bash
flutter run -d chrome
```

For Android emulator:
```bash
flutter run -d android
```

## Development Workflow

### 1. Start Both Services
```bash
# Terminal 1 - Backend
cd backend
.venv\Scripts\activate  # Windows
python manage.py runserver

# Terminal 2 - Frontend  
cd frontend
flutter run
```

### 2. Making Changes
- **Backend changes:** Django auto-reloads, no restart needed
- **Frontend changes:** Flutter hot reload with `r` key
- **Database changes:** Run `python manage.py makemigrations` then `python manage.py migrate`

### 3. Testing Authentication Flow
1. Register a new user in the Flutter app
2. Login with the credentials
3. Update profile information
4. Navigate through all tabs including Gym Finder

## Production Notes

For production deployment:
1. Switch back to PostgreSQL in `backend/backend/settings.py`
2. Update environment variables in `.env`
3. Set `DEBUG = False` in Django settings
4. Configure proper CORS origins
5. Use `flutter build` for production builds

## API Documentation

Visit `http://127.0.0.1:8000/api/auth/` in your browser for interactive API documentation with examples and testing interface.