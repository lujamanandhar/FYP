# Generated migration for soft delete functionality

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('workouts', '0007_add_database_indexes'),
    ]

    operations = [
        migrations.AddField(
            model_name='workoutlog',
            name='is_deleted',
            field=models.BooleanField(db_index=True, default=False),
        ),
        migrations.AddField(
            model_name='workoutlog',
            name='deleted_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
    ]
