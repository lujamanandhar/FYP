from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model

User = get_user_model()


class Command(BaseCommand):
    help = 'Reset admin password'

    def handle(self, *args, **options):
        admin_email = 'admin@nutrilift.com'
        admin_password = 'Nutrilift@admin2026'
        
        try:
            user = User.objects.get(email=admin_email)
            user.set_password(admin_password)
            user.is_staff = True
            user.is_superuser = True
            user.is_active = True
            user.save()
            
            self.stdout.write(
                self.style.SUCCESS(f'Successfully reset admin password!')
            )
            self.stdout.write(
                self.style.SUCCESS(f'Email: {admin_email}')
            )
            self.stdout.write(
                self.style.SUCCESS(f'Password: {admin_password}')
            )
        except User.DoesNotExist:
            self.stdout.write(
                self.style.ERROR(f'Admin user does not exist. Run create_admin first.')
            )
