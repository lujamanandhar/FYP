# NutriLift Backend Deployment Guide

This guide covers deploying the NutriLift Django backend to various platforms including Railway, Heroku, and Docker-based deployments.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Local Development Setup](#local-development-setup)
- [Docker Deployment](#docker-deployment)
- [Railway Deployment](#railway-deployment)
- [Heroku Deployment](#heroku-deployment)
- [Database Migrations](#database-migrations)
- [Environment Variables](#environment-variables)
- [Post-Deployment Tasks](#post-deployment-tasks)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

- Python 3.11+
- PostgreSQL 14+
- Docker and Docker Compose (for containerized deployment)
- Git
- Railway CLI or Heroku CLI (for platform-specific deployments)

---

## Local Development Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd backend
```

### 2. Create Virtual Environment

```bash
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Configure Environment Variables

```bash
cp .env.example .env
# Edit .env with your local database credentials
```

### 5. Set Up Database

```bash
# Create PostgreSQL database
createdb nutrilift_db

# Run migrations
python manage.py migrate

# Seed exercise data
python manage.py seed_exercises

# Create superuser (optional)
python manage.py createsuperuser
```

### 6. Run Development Server

```bash
python manage.py runserver
```

The API will be available at `http://localhost:8000/api/`

---

## Docker Deployment

### Using Docker Compose (Recommended for Local Development)

Docker Compose sets up both PostgreSQL and Django in containers.

#### 1. Configure Environment

```bash
cp .env.example .env
# Edit .env if needed (defaults work for Docker Compose)
```

#### 2. Build and Start Services

```bash
docker-compose up --build
```

This will:
- Start PostgreSQL container
- Build Django backend container
- Run migrations automatically
- Seed exercise data
- Start development server on port 8000

#### 3. Access the Application

- API: `http://localhost:8000/api/`
- Admin: `http://localhost:8000/admin/`

#### 4. Stop Services

```bash
docker-compose down
```

#### 5. Stop and Remove Volumes (Clean Slate)

```bash
docker-compose down -v
```

### Using Docker Only (Production)

#### 1. Build the Image

```bash
docker build -t nutrilift-backend .
```

#### 2. Run the Container

```bash
docker run -d \
  --name nutrilift-backend \
  -p 8000:8000 \
  -e DATABASE_URL="postgresql://user:password@host:5432/dbname" \
  -e SECRET_KEY="your-secret-key" \
  -e DEBUG="False" \
  -e ALLOWED_HOSTS="yourdomain.com,www.yourdomain.com" \
  nutrilift-backend
```

---

## Railway Deployment

Railway provides automatic deployments from Git with built-in PostgreSQL.

### 1. Install Railway CLI

```bash
npm install -g @railway/cli
# or
brew install railway
```

### 2. Login to Railway

```bash
railway login
```

### 3. Initialize Project

```bash
railway init
```

### 4. Add PostgreSQL Database

```bash
railway add --plugin postgresql
```

Railway will automatically set the `DATABASE_URL` environment variable.

### 5. Configure Environment Variables

In the Railway dashboard or via CLI:

```bash
railway variables set SECRET_KEY="your-production-secret-key"
railway variables set DEBUG="False"
railway variables set ALLOWED_HOSTS="your-app.railway.app"
railway variables set JWT_SECRET_KEY="your-jwt-secret-key"
railway variables set CORS_ALLOW_ALL_ORIGINS="False"
```

### 6. Deploy

```bash
railway up
```

Or connect your GitHub repository for automatic deployments:
1. Go to Railway dashboard
2. Select your project
3. Connect GitHub repository
4. Railway will auto-deploy on every push to main branch

### 7. Run Migrations

```bash
railway run python manage.py migrate
railway run python manage.py seed_exercises
```

### 8. Create Superuser

```bash
railway run python manage.py createsuperuser
```

### 9. Access Your Application

Railway will provide a URL like: `https://your-app.railway.app`

---

## Heroku Deployment

### 1. Install Heroku CLI

```bash
# macOS
brew tap heroku/brew && brew install heroku

# Windows
# Download from https://devcenter.heroku.com/articles/heroku-cli

# Linux
curl https://cli-assets.heroku.com/install.sh | sh
```

### 2. Login to Heroku

```bash
heroku login
```

### 3. Create Heroku App

```bash
heroku create nutrilift-backend
```

### 4. Add PostgreSQL Add-on

```bash
heroku addons:create heroku-postgresql:mini
```

This automatically sets the `DATABASE_URL` environment variable.

### 5. Configure Environment Variables

```bash
heroku config:set SECRET_KEY="your-production-secret-key"
heroku config:set DEBUG="False"
heroku config:set ALLOWED_HOSTS="nutrilift-backend.herokuapp.com"
heroku config:set JWT_SECRET_KEY="your-jwt-secret-key"
heroku config:set CORS_ALLOW_ALL_ORIGINS="False"
```

### 6. Create Procfile

Create a `Procfile` in the backend directory:

```
web: gunicorn backend.wsgi:application --bind 0.0.0.0:$PORT --workers 3
release: python manage.py migrate --noinput && python manage.py seed_exercises
```

### 7. Deploy to Heroku

```bash
git add .
git commit -m "Configure for Heroku deployment"
git push heroku main
```

### 8. Scale Dynos

```bash
heroku ps:scale web=1
```

### 9. Create Superuser

```bash
heroku run python manage.py createsuperuser
```

### 10. Access Your Application

```bash
heroku open
```

Your API will be at: `https://nutrilift-backend.herokuapp.com/api/`

---

## Database Migrations

### Creating Migrations

When you modify models:

```bash
python manage.py makemigrations
```

### Applying Migrations

#### Local Development

```bash
python manage.py migrate
```

#### Docker

```bash
docker-compose exec backend python manage.py migrate
```

#### Railway

```bash
railway run python manage.py migrate
```

#### Heroku

```bash
heroku run python manage.py migrate
```

### Viewing Migration Status

```bash
python manage.py showmigrations
```

### Rolling Back Migrations

```bash
# Rollback to specific migration
python manage.py migrate workouts 0004

# Rollback all migrations for an app
python manage.py migrate workouts zero
```

---

## Environment Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@host:5432/db` |
| `SECRET_KEY` | Django secret key | `django-insecure-...` |
| `DEBUG` | Debug mode (False in production) | `False` |
| `ALLOWED_HOSTS` | Comma-separated allowed hosts | `yourdomain.com,www.yourdomain.com` |
| `JWT_SECRET_KEY` | JWT signing key | `your-jwt-secret` |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DB_NAME` | Database name (if not using DATABASE_URL) | `nutrilift_db` |
| `DB_USER` | Database user | `postgres` |
| `DB_PASSWORD` | Database password | - |
| `DB_HOST` | Database host | `localhost` |
| `DB_PORT` | Database port | `5432` |
| `DB_CONN_MAX_AGE` | Connection pool max age | `600` |
| `CORS_ALLOW_ALL_ORIGINS` | Allow all CORS origins | `False` |
| `CORS_ALLOWED_ORIGINS` | Specific allowed origins | - |

### Generating Secret Keys

#### Django SECRET_KEY

```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

#### JWT_SECRET_KEY

```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

---

## Post-Deployment Tasks

### 1. Seed Exercise Database

```bash
# Local
python manage.py seed_exercises

# Docker
docker-compose exec backend python manage.py seed_exercises

# Railway
railway run python manage.py seed_exercises

# Heroku
heroku run python manage.py seed_exercises
```

### 2. Create Superuser

```bash
# Local
python manage.py createsuperuser

# Docker
docker-compose exec backend python manage.py createsuperuser

# Railway
railway run python manage.py createsuperuser

# Heroku
heroku run python manage.py createsuperuser
```

### 3. Collect Static Files (if serving static files)

```bash
python manage.py collectstatic --noinput
```

### 4. Test API Endpoints

```bash
# Health check
curl https://your-domain.com/api/health/

# List exercises
curl https://your-domain.com/api/exercises/

# Register user
curl -X POST https://your-domain.com/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"testpass123"}'
```

---

## Troubleshooting

### Database Connection Issues

**Problem**: `django.db.utils.OperationalError: could not connect to server`

**Solutions**:
1. Verify DATABASE_URL or DB_* environment variables are correct
2. Check if PostgreSQL is running
3. Verify network connectivity to database host
4. Check firewall rules

### Migration Errors

**Problem**: `django.db.migrations.exceptions.InconsistentMigrationHistory`

**Solutions**:
1. Check migration files are committed to Git
2. Ensure all migrations are applied in order
3. If necessary, fake migrations: `python manage.py migrate --fake`

### Static Files Not Loading

**Problem**: Static files return 404 in production

**Solutions**:
1. Run `python manage.py collectstatic`
2. Configure web server (nginx/Apache) to serve static files
3. Use WhiteNoise for serving static files in Django:
   ```bash
   pip install whitenoise
   ```
   Add to `MIDDLEWARE` in settings.py:
   ```python
   'whitenoise.middleware.WhiteNoiseMiddleware',
   ```

### Memory Issues on Heroku

**Problem**: R14 - Memory quota exceeded

**Solutions**:
1. Reduce number of Gunicorn workers
2. Upgrade to larger dyno
3. Optimize database queries
4. Enable query caching

### CORS Errors

**Problem**: Frontend can't access API due to CORS

**Solutions**:
1. Add frontend domain to `CORS_ALLOWED_ORIGINS`
2. Set `CORS_ALLOW_ALL_ORIGINS=True` for development only
3. Verify CORS middleware is installed and configured

### Rate Limiting Issues

**Problem**: API returns 429 Too Many Requests

**Solutions**:
1. Adjust throttle rates in settings.py
2. Implement caching to reduce API calls
3. Use authenticated requests (higher rate limits)

---

## Security Checklist

Before deploying to production:

- [ ] Set `DEBUG=False`
- [ ] Use strong, unique `SECRET_KEY`
- [ ] Use strong, unique `JWT_SECRET_KEY`
- [ ] Configure `ALLOWED_HOSTS` with your domain
- [ ] Set `CORS_ALLOW_ALL_ORIGINS=False`
- [ ] Configure specific `CORS_ALLOWED_ORIGINS`
- [ ] Use HTTPS (SSL/TLS certificates)
- [ ] Enable database backups
- [ ] Set up monitoring and logging
- [ ] Configure rate limiting
- [ ] Review and update security headers
- [ ] Keep dependencies updated

---

## Monitoring and Logging

### View Logs

#### Railway
```bash
railway logs
```

#### Heroku
```bash
heroku logs --tail
```

#### Docker
```bash
docker-compose logs -f backend
```

### Database Backups

#### Railway
Automatic backups are included with PostgreSQL plugin.

#### Heroku
```bash
heroku pg:backups:capture
heroku pg:backups:download
```

---

## Additional Resources

- [Django Deployment Checklist](https://docs.djangoproject.com/en/5.2/howto/deployment/checklist/)
- [Railway Documentation](https://docs.railway.app/)
- [Heroku Python Documentation](https://devcenter.heroku.com/categories/python-support)
- [Docker Documentation](https://docs.docker.com/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

## Support

For issues or questions:
- Check the [Troubleshooting](#troubleshooting) section
- Review application logs
- Consult platform-specific documentation
- Contact the development team

---

**Last Updated**: January 2025
