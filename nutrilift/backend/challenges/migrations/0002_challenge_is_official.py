from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('challenges', '0001_initial'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.AddField(
            model_name='challenge',
            name='is_official',
            field=models.BooleanField(default=False),
        ),
        migrations.AlterField(
            model_name='challenge',
            name='created_by',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.CASCADE,
                related_name='created_challenges',
                to=settings.AUTH_USER_MODEL,
            ),
        ),
    ]
