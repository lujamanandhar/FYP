from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion
import uuid


class Migration(migrations.Migration):

    dependencies = [
        ('challenges', '0004_achievement_paymentplan_subscription_userpoints_and_more'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='WorkoutStreak',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('current_streak', models.IntegerField(default=0)),
                ('longest_streak', models.IntegerField(default=0)),
                ('last_active_date', models.DateField(blank=True, null=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('user', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='workout_streak', to=settings.AUTH_USER_MODEL)),
            ],
        ),
        migrations.CreateModel(
            name='NutritionStreak',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('current_streak', models.IntegerField(default=0)),
                ('longest_streak', models.IntegerField(default=0)),
                ('last_active_date', models.DateField(blank=True, null=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('user', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='nutrition_streak', to=settings.AUTH_USER_MODEL)),
            ],
        ),
    ]
