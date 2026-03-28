"""
Signal handlers for automatic point and achievement rewards.
Phase 3 - Reward System
"""
import logging
from django.db.models.signals import post_save
from django.dispatch import receiver

logger = logging.getLogger(__name__)


def _award_points(user, points, source, description, reference_id=None):
    """Award points to a user and create transaction record"""
    from .reward_models import UserPoints, PointTransaction
    
    user_points, created = UserPoints.objects.get_or_create(
        user=user,
        defaults={'total_points': 0, 'lifetime_points': 0, 'points_spent': 0, 'level': 1}
    )
    
    user_points.total_points += points
    user_points.lifetime_points += points
    
    # Level up every 1000 points
    new_level = (user_points.lifetime_points // 1000) + 1
    if new_level > user_points.level:
        user_points.level = new_level
    
    user_points.save()
    
    # Create transaction record
    PointTransaction.objects.create(
        user=user,
        transaction_type='EARN',
        source=source,
        points=points,
        description=description,
        reference_id=reference_id
    )
    
    logger.info(f"Awarded {points} points to {user.email} for {source}")


def _check_achievements(user):
    """Check and unlock achievements for user"""
    from .reward_models import Achievement, UserAchievement
    from .models import ChallengeParticipant, Streak
    from workouts.models import WorkoutLog
    from nutrition.models import IntakeLog
    
    # Get user stats
    total_workouts = WorkoutLog.objects.filter(user=user, is_deleted=False).count()
    total_nutrition_logs = IntakeLog.objects.filter(user=user).count()
    completed_challenges = ChallengeParticipant.objects.filter(user=user, completed=True).count()
    
    try:
        current_streak = Streak.objects.get(user=user).current_streak
    except Streak.DoesNotExist:
        current_streak = 0
    
    # Check workout achievements
    workout_milestones = [
        (10, 'First 10 Workouts'),
        (50, '50 Workouts Strong'),
        (100, 'Century Club'),
        (500, 'Workout Warrior'),
    ]
    
    for milestone, name in workout_milestones:
        if total_workouts >= milestone:
            achievement = Achievement.objects.filter(
                name=name,
                category='WORKOUT',
                is_active=True
            ).first()
            
            if achievement:
                user_achievement, created = UserAchievement.objects.get_or_create(
                    user=user,
                    achievement=achievement,
                    defaults={'is_completed': True, 'progress': milestone}
                )
                
                if created:
                    _award_points(
                        user,
                        achievement.points_reward,
                        'CHALLENGE',
                        f'Achievement unlocked: {name}',
                        str(achievement.id)
                    )
    
    # Check streak achievements
    streak_milestones = [
        (7, '7 Day Streak'),
        (30, '30 Day Streak'),
        (100, '100 Day Streak'),
    ]
    
    for milestone, name in streak_milestones:
        if current_streak >= milestone:
            achievement = Achievement.objects.filter(
                name=name,
                category='STREAK',
                is_active=True
            ).first()
            
            if achievement:
                user_achievement, created = UserAchievement.objects.get_or_create(
                    user=user,
                    achievement=achievement,
                    defaults={'is_completed': True, 'progress': milestone}
                )
                
                if created:
                    _award_points(
                        user,
                        achievement.points_reward,
                        'STREAK',
                        f'Achievement unlocked: {name}',
                        str(achievement.id)
                    )


def handle_workout_completed(sender, instance, created, **kwargs):
    """Award points when workout is logged"""
    if not created:
        return
    
    try:
        # Base points for completing workout
        base_points = 10
        
        # Bonus points for duration (1 point per 10 minutes)
        duration_bonus = instance.duration_minutes // 10
        
        total_points = base_points + duration_bonus
        
        _award_points(
            user=instance.user,
            points=total_points,
            source='WORKOUT',
            description=f'Completed workout: {instance.workout_name}',
            reference_id=str(instance.id)
        )
        
        _check_achievements(instance.user)
    except Exception:
        logger.error(
            "Error in handle_workout_completed for WorkoutLog pk=%s",
            instance.pk,
            exc_info=True
        )


def handle_nutrition_logged(sender, instance, created, **kwargs):
    """Award points when nutrition is logged"""
    if not created:
        return
    
    try:
        # Award 5 points for logging nutrition
        _award_points(
            user=instance.user,
            points=5,
            source='NUTRITION',
            description='Logged nutrition entry',
            reference_id=str(instance.id)
        )
        
        _check_achievements(instance.user)
    except Exception:
        logger.error(
            "Error in handle_nutrition_logged for IntakeLog pk=%s",
            instance.pk,
            exc_info=True
        )


def handle_challenge_completed(sender, instance, **kwargs):
    """Award points when challenge is completed"""
    if not instance.completed:
        return
    
    try:
        # Award points based on challenge difficulty
        challenge = instance.challenge
        base_points = 100
        
        # Bonus for official challenges
        if challenge.is_official:
            base_points += 50
        
        _award_points(
            user=instance.user,
            points=base_points,
            source='CHALLENGE',
            description=f'Completed challenge: {challenge.name}',
            reference_id=str(challenge.id)
        )
        
        _check_achievements(instance.user)
    except Exception:
        logger.error(
            "Error in handle_challenge_completed for ChallengeParticipant pk=%s",
            instance.pk,
            exc_info=True
        )


def connect_reward_signals():
    """Connect reward signal handlers"""
    from django.apps import apps
    
    WorkoutLog = apps.get_model('workouts', 'WorkoutLog')
    IntakeLog = apps.get_model('nutrition', 'IntakeLog')
    ChallengeParticipant = apps.get_model('challenges', 'ChallengeParticipant')
    
    post_save.connect(handle_workout_completed, sender=WorkoutLog)
    post_save.connect(handle_nutrition_logged, sender=IntakeLog)
    post_save.connect(handle_challenge_completed, sender=ChallengeParticipant)
