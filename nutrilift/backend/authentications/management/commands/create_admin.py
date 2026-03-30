from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model

User = get_user_model()


class Command(BaseCommand):
    help = 'Create the fixed admin account for NutriLift'

    def handle(self, *args, **options):
        admin_email = 'admin@nutrilift.com'
        admin_password = 'Nutrilift@admin2026'
        
        # Check if admin already exists
        if User.objects.filter(email=admin_email).exists():
            self.stdout.write(
                self.style.WARNING(f'Admin account {admin_email} already exists!')
            )
            return
        
        # Create admin user
        admin_user = User.objects.create_user(
            email=admin_email,
            password=admin_password,
            name='NutriLift Admin',
            is_staff=True,
            is_superuser=True,
            is_active=True,
        )
        
        self.stdout.write(
            self.style.SUCCESS(f'Successfully created admin account!')
        )
        self.stdout.write(
            self.style.SUCCESS(f'Email: {admin_email}')
        )
        self.stdout.write(
            self.style.SUCCESS(f'Password: {admin_password}')
        )
