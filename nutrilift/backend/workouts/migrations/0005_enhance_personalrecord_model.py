# Generated migration for PersonalRecord model enhancement

from django.db import migrations, models
import django.db.models.deletion
import django.core.validators


class Migration(migrations.Migration):

    dependencies = [
        ('workouts', '0004_workoutexercise'),
    ]

    operations = [
        # First, remove the old unique_together constraint
        migrations.AlterUniqueTogether(
            name='personalrecord',
            unique_together=set(),
        ),
        
        # Remove old fields
        migrations.RemoveField(
            model_name='personalrecord',
            name='record_type',
        ),
        migrations.RemoveField(
            model_name='personalrecord',
            name='value',
        ),
        migrations.RemoveField(
            model_name='personalrecord',
            name='unit',
        ),
        migrations.RemoveField(
            model_name='personalrecord',
            name='notes',
        ),
        migrations.RemoveField(
            model_name='personalrecord',
            name='achieved_at',
        ),
        
        # Add new fields
        migrations.AddField(
            model_name='personalrecord',
            name='max_weight',
            field=models.DecimalField(
                decimal_places=2,
                max_digits=6,
                validators=[django.core.validators.MinValueValidator(0.0)],
                default=0.0
            ),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='personalrecord',
            name='max_reps',
            field=models.IntegerField(
                validators=[django.core.validators.MinValueValidator(1)],
                default=1
            ),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='personalrecord',
            name='max_volume',
            field=models.DecimalField(
                decimal_places=2,
                max_digits=10,
                validators=[django.core.validators.MinValueValidator(0.0)],
                default=0.0
            ),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='personalrecord',
            name='achieved_date',
            field=models.DateTimeField(auto_now_add=True, null=True),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='personalrecord',
            name='previous_max_weight',
            field=models.DecimalField(
                blank=True,
                decimal_places=2,
                max_digits=6,
                null=True,
                validators=[django.core.validators.MinValueValidator(0.0)]
            ),
        ),
        migrations.AddField(
            model_name='personalrecord',
            name='previous_max_reps',
            field=models.IntegerField(
                blank=True,
                null=True,
                validators=[django.core.validators.MinValueValidator(1)]
            ),
        ),
        migrations.AddField(
            model_name='personalrecord',
            name='previous_max_volume',
            field=models.DecimalField(
                blank=True,
                decimal_places=2,
                max_digits=10,
                null=True,
                validators=[django.core.validators.MinValueValidator(0.0)]
            ),
        ),
        
        # Update Meta - set new unique_together
        migrations.AlterUniqueTogether(
            name='personalrecord',
            unique_together={('user', 'exercise')},
        ),
        migrations.AlterIndexTogether(
            name='personalrecord',
            index_together=set(),
        ),
        migrations.AddIndex(
            model_name='personalrecord',
            index=models.Index(fields=['user', 'exercise'], name='personal_re_user_id_e8c9a5_idx'),
        ),
        migrations.AlterModelOptions(
            name='personalrecord',
            options={'ordering': ['-achieved_date']},
        ),
    ]
