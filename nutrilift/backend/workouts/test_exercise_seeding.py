"""
Unit and property-based tests for exercise seeding.

Tests Property 20 from the workout-tracking-system design document.
"""

from django.test import TestCase
from django.core.management import call_command
from hypothesis import given, strategies as st, settings
from hypothesis.extra.django import TestCase as HypothesisTestCase
from workouts.models import Exercise


class ExerciseSeedingTests(TestCase):
    """Unit tests for exercise seeding command."""
    
    def setUp(self):
        """Clear exercises before each test."""
        Exercise.objects.all().delete()
    
    def test_seeding_creates_at_least_100_exercises(self):
        """
        Test that seeding creates at least 100 exercises.
        
        **Validates: Requirements 6.7, 3.10**
        """
        # Run the seed command
        call_command('seed_exercises')
        
        # Check that at least 100 exercises were created
        exercise_count = Exercise.objects.count()
        self.assertGreaterEqual(
            exercise_count,
            100,
            f"Expected at least 100 exercises, but got {exercise_count}"
        )
    
    def test_seeding_covers_all_categories(self):
        """
        Test that seeding covers all exercise categories.
        
        **Validates: Requirements 6.7**
        """
        # Run the seed command
        call_command('seed_exercises')
        
        # Get all categories from the model
        valid_categories = [choice[0] for choice in Exercise.CATEGORY_CHOICES]
        
        # Check that each category has at least one exercise
        for category in valid_categories:
            category_count = Exercise.objects.filter(category=category).count()
            self.assertGreater(
                category_count,
                0,
                f"Category '{category}' has no exercises"
            )
    
    def test_seeding_covers_all_difficulty_levels(self):
        """
        Test that seeding covers all difficulty levels.
        
        **Validates: Requirements 6.7**
        """
        # Run the seed command
        call_command('seed_exercises')
        
        # Get all difficulty levels from the model
        valid_difficulties = [choice[0] for choice in Exercise.DIFFICULTY_CHOICES]
        
        # Check that each difficulty level has at least one exercise
        for difficulty in valid_difficulties:
            difficulty_count = Exercise.objects.filter(difficulty=difficulty).count()
            self.assertGreater(
                difficulty_count,
                0,
                f"Difficulty '{difficulty}' has no exercises"
            )


class ExerciseSeedingPropertyTests(HypothesisTestCase):
    """Property-based tests for exercise seeding coverage."""
    
    def setUp(self):
        """Seed exercises once for all property tests."""
        Exercise.objects.all().delete()
        call_command('seed_exercises')
    
    @given(
        category=st.sampled_from(['STRENGTH', 'CARDIO', 'BODYWEIGHT']),
        difficulty=st.sampled_from(['BEGINNER', 'INTERMEDIATE', 'ADVANCED'])
    )
    @settings(max_examples=100)
    def test_property_20_exercise_seeding_coverage(self, category, difficulty):
        """
        Feature: workout-tracking-system, Property 20: Exercise Seeding Coverage
        For any seeded exercise database, there should exist at least one exercise
        for each combination of category and difficulty level.
        
        **Validates: Requirements 6.7**
        """
        # Check that at least one exercise exists for this combination
        exercises = Exercise.objects.filter(
            category=category,
            difficulty=difficulty
        )
        
        self.assertGreater(
            exercises.count(),
            0,
            f"No exercises found for category='{category}' and difficulty='{difficulty}'"
        )
