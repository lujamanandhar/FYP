import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from workouts.models import Exercise, WorkoutExercise, PersonalRecord

print("=" * 60)
print("EXERCISE MODEL FIELDS:")
print("=" * 60)
for field in Exercise._meta.get_fields():
    print(f"  - {field.name} ({field.__class__.__name__})")

print("\n" + "=" * 60)
print("WORKOUTEXERCISE MODEL FIELDS:")
print("=" * 60)
for field in WorkoutExercise._meta.get_fields():
    print(f"  - {field.name} ({field.__class__.__name__})")

print("\n" + "=" * 60)
print("PERSONALRECORD MODEL FIELDS:")
print("=" * 60)
for field in PersonalRecord._meta.get_fields():
    print(f"  - {field.name} ({field.__class__.__name__})")

print("\n" + "=" * 60)
print("DATABASE TABLE CHECK:")
print("=" * 60)
print(f"Exercise count: {Exercise.objects.count()}")
print(f"WorkoutExercise count: {WorkoutExercise.objects.count()}")
print(f"PersonalRecord count: {PersonalRecord.objects.count()}")
