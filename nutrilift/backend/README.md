# NutriLift Backend API

Django REST Framework backend for the NutriLift workout tracking system.

## Quick Start

### Local Development

1. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your database credentials
   ```

3. **Run migrations**:
   ```bash
   python manage.py migrate
   python manage.py seed_exercises
   ```

4. **Start server**:
   ```bash
   python manage.py runserver
   ```

### Docker Development

1. **Start services**:
   ```bash
   docker-compose up --build
   ```

2. **Access API**:
   - API: http://localhost:8000/api/
   - Admin: http://localhost:8000/admin/

## API Endpoints

### Authentication
- `POST /api/auth/register/` - Register new user
- `POST /api/auth/login/` - Login and get JWT token
- `POST /api/auth/refresh/` - Refresh JWT token

### Workouts
- `GET /api/workouts/history/` - Get workout history
- `POST /api/workouts/log/` - Log new workout
- `GET /api/workouts/statistics/` - Get workout statistics

### Exercises
- `GET /api/exercises/` - List exercises (with filters)
- `GET /api/exercises/{id}/` - Get exercise details

### Personal Records
- `GET /api/personal-records/` - Get user's personal records

## Environment Variables

See `.env.example` for all available configuration options.

Required variables:
- `DB_NAME` - Database name
- `DB_USER` - Database user
- `DB_PASSWORD` - Database password
- `DB_HOST` - Database host
- `DB_PORT` - Database port
- `SECRET_KEY` - Django secret key
- `JWT_SECRET_KEY` - JWT signing key

## Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed deployment instructions for:
- Railway
- Heroku
- Docker
- Local production setup

## Testing

Run tests:
```bash
pytest
```

Run with coverage:
```bash
pytest --cov=workouts --cov=authentications
```

## Project Structure

```
backend/
├── authentications/     # User authentication app
├── workouts/           # Workout tracking app
├── backend/            # Django project settings
├── logs/              # Application logs
├── Dockerfile         # Docker configuration
├── docker-compose.yml # Docker Compose configuration
├── requirements.txt   # Python dependencies
├── .env.example       # Environment variables template
└── DEPLOYMENT.md      # Deployment guide
```

## Features

- JWT authentication
- Automatic personal record detection
- Exercise library with 100+ exercises
- Workout history with filtering
- Statistics and analytics
- Rate limiting
- Caching
- Transaction handling
- Audit logging

## Tech Stack

- Django 5.2.8
- Django REST Framework 3.15.2
- PostgreSQL 14+
- JWT Authentication
- Gunicorn (production server)
- Docker & Docker Compose

## License

Proprietary - NutriLift
