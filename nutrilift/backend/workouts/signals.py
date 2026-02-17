"""
Signal handlers for automatic personal record detection and updates.
"""
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone
from .models import WorkoutLog, PersonalRecord


@receiver(post_save, sender=WorkoutLog)
def check_personal_records(sender, instance, created, **kwargs):
    """
    Signal handler that triggers PR detection when a WorkoutLog is created.
    
    This handler is called after a WorkoutLog is saved. If it's a new workout
    (created=True), it checks all exercises in the workout to see if any
    personal records were broken.
    """
    if created:
        # Process all workout exercises to check for PRs
        for workout_exercise in instance.workout_exercises.all():
            update_personal_record(instance.user, workout_exercise, instance)


def update_personal_record(user, workout_exercise, workout_log):
    """
    Check and update personal records for a specific exercise in a workout.
    
    This function compares the performance in the workout_exercise against
    the user's existing personal record for that exercise. It checks three
    metrics: max_weight, max_reps, and max_volume.
    
    If any metric exceeds the current PR, the PR is updated and the previous
    value is stored for tracking improvement.
    
    Args:
        user: The user who performed the workout
        workout_exercise: The WorkoutExercise instance containing sets/reps/weight
        workout_log: The WorkoutLog instance this exercise belongs to
    """
    exercise = workout_exercise.exercise
    volume = workout_exercise.calculate_volume()
    
    # Try to get existing PR, or create a new one
    pr, created = PersonalRecord.objects.get_or_create(
        user=user,
        exercise=exercise,
        defaults={
            'max_weight': workout_exercise.weight,
            'max_reps': workout_exercise.reps,
            'max_volume': volume,
            'achieved_date': workout_log.logged_at,
            'workout_log': workout_log
        }
    )
    
    # If PR already existed, check if any metrics were exceeded
    if not created:
        updated = False
        
        # Check if weight PR was broken
        if workout_exercise.weight > pr.max_weight:
            pr.previous_max_weight = pr.max_weight
            pr.max_weight = workout_exercise.weight
            updated = True
        
        # Check if reps PR was broken
        if workout_exercise.reps > pr.max_reps:
            pr.previous_max_reps = pr.max_reps
            pr.max_reps = workout_exercise.reps
            updated = True
        
        # Check if volume PR was broken
        if volume > float(pr.max_volume):
            pr.previous_max_volume = pr.max_volume
            pr.max_volume = volume
            updated = True
        
        # If any PR was broken, update the achieved date and workout log reference
        if updated:
            pr.achieved_date = workout_log.logged_at
            pr.workout_log = workout_log
            pr.save()
