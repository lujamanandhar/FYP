"""
Property-based tests for Exercise model validation.

Tests Properties 16-21 from the workout-tracking-system design document.
"""

from django.test import TestCase
from django.core.exceptions import ValidationError
from hypothesis import given, strategies as st, settings
from hypothesis.extra.django import TestCase as HypothesisTestCase
from workouts.models import Exercise


class ExerciseValidationPropertyTests(HypothesisTestCase):
    """Property-based tests for Exercise model validation."""
    
    @given(category=st.sampled_from(['STRENGTH', 'CARDIO', 'BODYWEIGHT']))
    @settings(max_examples=100)
    def test_property_16_exercise_category_validation_valid(self, category):
        """
        Feature: workout-tracking-system, Property 16: Exercise Category Validation
        For any exercise, the category field should only accept values from the set:
        {STRENGTH, CARDIO, BODYWEIGHT}, and should reject any other values.
        
        **Validates: Requirements 6.2**
        
        This test verifies that valid categories are accepted.
        """
        exercise = Exercise(
            name=f'Test Exercise {category}',
            description='Test description',
            category=category,
            muscle_group='CHEST',
            equipment='FREE_WEIGHTS',
            difficulty='BEGINNER',
            instructions='Test instructions'
        )
        
        # Should not raise ValidationError for valid categories
        try:
            exercise.clean()
        except ValidationError:
            self.fail(f"Valid category '{category}' was rejected")
    
    @given(category=st.text(min_size=1).filter(
        lambda x: x not in ['STRENGTH', 'CARDIO', 'BODYWEIGHT']
    ))
    @settings(max_examples=100)
    def test_property_16_exercise_category_validation_invalid(self, category):
        """
        Feature: workout-tracking-system, Property 16: Exercise Category Validation
        
        This test verifies that invalid categories are rejected.
        """
        exercise = Exercise(
            name=f'Test Exercise Invalid',
            description='Test description',
            category=category,
            muscle_group='CHEST',
            equipment='FREE_WEIGHTS',
            difficulty='BEGINNER',
            instructions='Test instructions'
        )
        
        # Should raise ValidationError for invalid categories
        with self.assertRaises(ValidationError) as context:
            exercise.clean()
        
        self.assertIn('category', context.exception.message_dict)
    
    @given(muscle_group=st.sampled_from([
        'CHEST', 'BACK', 'LEGS', 'CORE', 'ARMS', 'SHOULDERS', 'FULL_BODY'
    ]))
    @settings(max_examples=100)
    def test_property_17_exercise_muscle_group_validation_valid(self, muscle_group):
        """
        Feature: workout-tracking-system, Property 17: Exercise Muscle Group Validation
        For any exercise, the muscle_group field should only accept values from the set:
        {CHEST, BACK, LEGS, CORE, ARMS, SHOULDERS, FULL_BODY}, and should reject any other values.
        
        **Validates: Requirements 6.3**
        
        This test verifies that valid muscle groups are accepted.
        """
        exercise = Exercise(
            name=f'Test Exercise {muscle_group}',
            description='Test description',
            category='STRENGTH',
            muscle_group=muscle_group,
            equipment='FREE_WEIGHTS',
            difficulty='BEGINNER',
            instructions='Test instructions'
        )
        
        # Should not raise ValidationError for valid muscle groups
        try:
            exercise.clean()
        except ValidationError:
            self.fail(f"Valid muscle group '{muscle_group}' was rejected")
    
    @given(muscle_group=st.text(min_size=1).filter(
        lambda x: x not in ['CHEST', 'BACK', 'LEGS', 'CORE', 'ARMS', 'SHOULDERS', 'FULL_BODY']
    ))
    @settings(max_examples=100)
    def test_property_17_exercise_muscle_group_validation_invalid(self, muscle_group):
        """
        Feature: workout-tracking-system, Property 17: Exercise Muscle Group Validation
        
        This test verifies that invalid muscle groups are rejected.
        """
        exercise = Exercise(
            name=f'Test Exercise Invalid',
            description='Test description',
            category='STRENGTH',
            muscle_group=muscle_group,
            equipment='FREE_WEIGHTS',
            difficulty='BEGINNER',
            instructions='Test instructions'
        )
        
        # Should raise ValidationError for invalid muscle groups
        with self.assertRaises(ValidationError) as context:
            exercise.clean()
        
        self.assertIn('muscle_group', context.exception.message_dict)
    
    @given(equipment=st.sampled_from([
        'FREE_WEIGHTS', 'MACHINES', 'BODYWEIGHT', 'RESISTANCE_BANDS', 'CARDIO_EQUIPMENT'
    ]))
    @settings(max_examples=100)
    def test_property_18_exercise_equipment_validation_valid(self, equipment):
        """
        Feature: workout-tracking-system, Property 18: Exercise Equipment Validation
        For any exercise, the equipment field should only accept values from the set:
        {FREE_WEIGHTS, MACHINES, BODYWEIGHT, RESISTANCE_BANDS, CARDIO_EQUIPMENT},
        and should reject any other values.
        
        **Validates: Requirements 6.4**
        
        This test verifies that valid equipment types are accepted.
        """
        exercise = Exercise(
            name=f'Test Exercise {equipment}',
            description='Test description',
            category='STRENGTH',
            muscle_group='CHEST',
            equipment=equipment,
            difficulty='BEGINNER',
            instructions='Test instructions'
        )
        
        # Should not raise ValidationError for valid equipment
        try:
            exercise.clean()
        except ValidationError:
            self.fail(f"Valid equipment '{equipment}' was rejected")
    
    @given(equipment=st.text(min_size=1).filter(
        lambda x: x not in ['FREE_WEIGHTS', 'MACHINES', 'BODYWEIGHT', 'RESISTANCE_BANDS', 'CARDIO_EQUIPMENT']
    ))
    @settings(max_examples=100)
    def test_property_18_exercise_equipment_validation_invalid(self, equipment):
        """
        Feature: workout-tracking-system, Property 18: Exercise Equipment Validation
        
        This test verifies that invalid equipment types are rejected.
        """
        exercise = Exercise(
            name=f'Test Exercise Invalid',
            description='Test description',
            category='STRENGTH',
            muscle_group='CHEST',
            equipment=equipment,
            difficulty='BEGINNER',
            instructions='Test instructions'
        )
        
        # Should raise ValidationError for invalid equipment
        with self.assertRaises(ValidationError) as context:
            exercise.clean()
        
        self.assertIn('equipment', context.exception.message_dict)
    
    @given(difficulty=st.sampled_from(['BEGINNER', 'INTERMEDIATE', 'ADVANCED']))
    @settings(max_examples=100)
    def test_property_19_exercise_difficulty_validation_valid(self, difficulty):
        """
        Feature: workout-tracking-system, Property 19: Exercise Difficulty Validation
        For any exercise, the difficulty field should only accept values from the set:
        {BEGINNER, INTERMEDIATE, ADVANCED}, and should reject any other values.
        
        **Validates: Requirements 6.5**
        
        This test verifies that valid difficulty levels are accepted.
        """
        exercise = Exercise(
            name=f'Test Exercise {difficulty}',
            description='Test description',
            category='STRENGTH',
            muscle_group='CHEST',
            equipment='FREE_WEIGHTS',
            difficulty=difficulty,
            instructions='Test instructions'
        )
        
        # Should not raise ValidationError for valid difficulties
        try:
            exercise.clean()
        except ValidationError:
            self.fail(f"Valid difficulty '{difficulty}' was rejected")
    
    @given(difficulty=st.text(min_size=1).filter(
        lambda x: x not in ['BEGINNER', 'INTERMEDIATE', 'ADVANCED']
    ))
    @settings(max_examples=100)
    def test_property_19_exercise_difficulty_validation_invalid(self, difficulty):
        """
        Feature: workout-tracking-system, Property 19: Exercise Difficulty Validation
        
        This test verifies that invalid difficulty levels are rejected.
        """
        exercise = Exercise(
            name=f'Test Exercise Invalid',
            description='Test description',
            category='STRENGTH',
            muscle_group='CHEST',
            equipment='FREE_WEIGHTS',
            difficulty=difficulty,
            instructions='Test instructions'
        )
        
        # Should raise ValidationError for invalid difficulties
        with self.assertRaises(ValidationError) as context:
            exercise.clean()
        
        self.assertIn('difficulty', context.exception.message_dict)
    
    @given(
        name1=st.text(min_size=1, max_size=50, alphabet=st.characters(
            whitelist_categories=('Lu', 'Ll', 'Nd'), whitelist_characters=' '
        )),
        name2=st.text(min_size=1, max_size=50, alphabet=st.characters(
            whitelist_categories=('Lu', 'Ll', 'Nd'), whitelist_characters=' '
        ))
    )
    @settings(max_examples=100)
    def test_property_21_exercise_name_uniqueness(self, name1, name2):
        """
        Feature: workout-tracking-system, Property 21: Exercise Name Uniqueness
        For any two exercises in the database, they should have different names
        (case-insensitive uniqueness).
        
        **Validates: Requirements 6.8**
        
        This test verifies that exercise names are unique (case-insensitive).
        """
        # Create first exercise
        exercise1 = Exercise.objects.create(
            name=name1,
            description='Test description 1',
            category='STRENGTH',
            muscle_group='CHEST',
            equipment='FREE_WEIGHTS',
            difficulty='BEGINNER',
            instructions='Test instructions 1'
        )
        
        # Try to create second exercise with same name (different case)
        if name1.lower() == name2.lower():
            # Names are the same (case-insensitive), should fail
            exercise2 = Exercise(
                name=name2,
                description='Test description 2',
                category='CARDIO',
                muscle_group='LEGS',
                equipment='BODYWEIGHT',
                difficulty='INTERMEDIATE',
                instructions='Test instructions 2'
            )
            
            with self.assertRaises(ValidationError) as context:
                exercise2.clean()
            
            self.assertIn('name', context.exception.message_dict)
        else:
            # Names are different, should succeed
            exercise2 = Exercise(
                name=name2,
                description='Test description 2',
                category='CARDIO',
                muscle_group='LEGS',
                equipment='BODYWEIGHT',
                difficulty='INTERMEDIATE',
                instructions='Test instructions 2'
            )
            
            try:
                exercise2.clean()
                exercise2.save()
            except ValidationError:
                self.fail(f"Different names '{name1}' and '{name2}' were incorrectly flagged as duplicates")
        
        # Cleanup
        Exercise.objects.all().delete()
