# Firebase Hosting Deployment Guide

This guide explains how to deploy the NutriLift Flutter web application to Firebase Hosting.

## Prerequisites

1. **Firebase CLI**: Install the Firebase CLI globally
   ```bash
   npm install -g firebase-tools
   ```

2. **Firebase Project**: Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)

3. **Flutter Web Build**: Ensure Flutter is installed and web support is enabled
   ```bash
   flutter config --enable-web
   ```

## Configuration Files

### firebase.json
The main Firebase configuration file that defines hosting settings:
- **public**: Points to `frontend/build/web` (Flutter web build output)
- **rewrites**: Routes all requests to index.html for SPA routing
- **headers**: Configures caching for static assets
- **cleanUrls**: Removes .html extensions from URLs
- **trailingSlash**: Removes trailing slashes from URLs

### .firebaserc
Defines the Firebase project to use. Update the project ID to match your Firebase project:
```json
{
  "projects": {
    "default": "your-firebase-project-id"
  }
}
```

## Deployment Steps

### 1. Update Firebase Project ID
Edit `.firebaserc` and replace `nutrilift-workout-tracker` with your actual Firebase project ID.

### 2. Login to Firebase
```bash
firebase login
```

### 3. Initialize Firebase (First Time Only)
If you haven't initialized Firebase in this project:
```bash
firebase init hosting
```
- Select your Firebase project
- Accept the default public directory: `frontend/build/web`
- Configure as a single-page app: **Yes**
- Set up automatic builds with GitHub: **Optional**

### 4. Build Flutter Web App
Navigate to the frontend directory and build for web:
```bash
cd frontend
flutter build web --release
```

This creates optimized production files in `frontend/build/web/`.

### 5. Deploy to Firebase Hosting
From the project root:
```bash
firebase deploy --only hosting
```

Or deploy from a specific project:
```bash
firebase deploy --only hosting --project your-project-id
```

### 6. Access Your Deployed App
After deployment, Firebase will provide a hosting URL:
```
https://your-project-id.web.app
https://your-project-id.firebaseapp.com
```

## Environment Configuration

### API Endpoint Configuration
Before building for production, ensure the API endpoint is configured correctly:

1. Create environment-specific configuration in `frontend/lib/config/`:
   ```dart
   class AppConfig {
     static const String apiBaseUrl = String.fromEnvironment(
       'API_BASE_URL',
       defaultValue: 'https://your-backend-api.com',
     );
   }
   ```

2. Build with environment variables:
   ```bash
   flutter build web --release --dart-define=API_BASE_URL=https://your-backend-api.com
   ```

## CI/CD Integration

### GitHub Actions Example
Create `.github/workflows/firebase-deploy.yml`:

```yaml
name: Deploy to Firebase Hosting

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.8.1'
      
      - name: Install dependencies
        run: |
          cd frontend
          flutter pub get
      
      - name: Build web
        run: |
          cd frontend
          flutter build web --release --dart-define=API_BASE_URL=${{ secrets.API_BASE_URL }}
      
      - name: Deploy to Firebase
        uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          channelId: live
          projectId: your-firebase-project-id
```

## Caching Strategy

The firebase.json configuration includes optimized caching headers:

- **Static Assets** (images, fonts, JS, CSS): 1 year cache (`max-age=31536000`)
- **index.html**: No cache to ensure users get the latest version

## Custom Domain Setup

1. Go to Firebase Console → Hosting → Add custom domain
2. Follow the verification steps
3. Add DNS records as instructed
4. Wait for SSL certificate provisioning (can take up to 24 hours)

## Troubleshooting

### Build Directory Not Found
Ensure you've built the Flutter web app before deploying:
```bash
cd frontend && flutter build web --release
```

### 404 Errors on Refresh
The rewrite rule in firebase.json should handle this. Verify:
```json
"rewrites": [
  {
    "source": "**",
    "destination": "/index.html"
  }
]
```

### CORS Issues
Configure CORS on your backend API to allow requests from your Firebase Hosting domain.

### Deployment Fails
- Check Firebase CLI version: `firebase --version`
- Verify you're logged in: `firebase login --reauth`
- Ensure project ID in .firebaserc matches your Firebase project

## Performance Optimization

1. **Enable Compression**: Firebase Hosting automatically compresses files
2. **Use CDN**: Firebase Hosting uses Google's global CDN
3. **Optimize Images**: Compress images before building
4. **Code Splitting**: Flutter web automatically handles code splitting

## Monitoring

View deployment history and analytics in Firebase Console:
- Hosting → Dashboard
- View traffic, bandwidth usage, and deployment history

## Rollback

To rollback to a previous deployment:
```bash
firebase hosting:clone SOURCE_SITE_ID:SOURCE_CHANNEL_ID TARGET_SITE_ID:live
```

Or use the Firebase Console to restore a previous version.

## Security

1. **Environment Variables**: Never commit sensitive data to firebase.json
2. **Firebase Rules**: Configure security rules if using other Firebase services
3. **HTTPS**: Firebase Hosting automatically provides SSL certificates

## Cost Considerations

Firebase Hosting free tier includes:
- 10 GB storage
- 360 MB/day bandwidth
- Custom domain and SSL

Monitor usage in Firebase Console → Usage and billing.

## Additional Resources

- [Firebase Hosting Documentation](https://firebase.google.com/docs/hosting)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
