"""
Integration tests for PersonalRecord API endpoints.

Tests:
- GET /api/personal-records/ endpoint
- Filter by authenticated user only
- Property 14: User-Scoped Personal Records

Validates: Requirements 4.6, 5.4
"""

from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework import status
from hypothesis import given, strategies as st, settings
from hypothesis.extra.django import TestCase as HypothesisTestCase

from workouts.models import Exercise, PersonalRecord, WorkoutLog

User = get_user_model()


class TestPersonalRecordListEndpoint(TestCase):
    """Test GET /api/personal-records/ endpoint"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.client = APIClient()
        
        # Create two users
        self.user1 = User.objects.create_user(
            email='user1@example.com',
            password='testpass123',
            first_name='User',
            last_name='One'
        )
        self.user2 = User.objects.create_user(
            email='user2@example.com',
            password='testpass123',
            first_name='User',
            last_name='Two'
        )
        
        # Create exercises
        self.exercise1 = Exercise.objects.create(
            name='Bench Press',
            category='STRENGTH',
            muscle_group='CHEST',
            equipment='FREE_WEIGHTS',
            difficulty='INTERMEDIATE',
            description='A compound upper body exercise',
            instructions='Lie on bench, lower bar to chest, press up',
            calories_per_minute=Decimal('8.0')
        )
        
        self.exercise2 = Exercise.objects.create(
            name='Squats',
            category='STRENGTH',
            muscle_group='LEGS',
            equipment='FREE_WEIGHTS',
            difficulty='INTERMEDIATE',
            description='A compound lower body exercise',
            instructions='Stand with bar on shoulders, squat down, stand up',
            calories_per_minute=Decimal('10.0')
        )
        
        # Create workout logs
        self.workout_log1 = WorkoutLog.objects.create(
            user=self.user1,
            workout_name='Push Day',
            duration_minutes=60,
            calories_burned=Decimal('450.00')
        )
        
        self.workout_log2 = WorkoutLog.objects.create(
            user=self.user2,
            workout_name='Leg Day',
            duration_minutes=75,
            calories_burned=Decimal('520.00')
        )
        
        # Create personal records for user1
        self.pr1_user1 = PersonalRecord.objects.create(
            user=self.user1,
            exercise=self.exercise1,
            max_weight=Decimal('120.00'),
            max_reps=10,
            max_volume=Decimal('1200.00'),
            achieved_date=timezone.now(),
            workout_log=self.workout_log1
        )
        
        self.pr2_user1 = PersonalRecord.objects.create(
            user=self.user1,
            exercise=self.exercise2,
            max_weight=Decimal('150.00'),
            max_reps=8,
            max_volume=Decimal('1200.00'),
            achieved_date=timezone.now(),
            workout_log=self.workout_log1
        )
        
        # Create personal records for user2
        self.pr1_user2 = PersonalRecord.objects.create(
            user=self.user2,
            exercise=self.exercise1,
            max_weight=Decimal('100.00'),
            max_reps=12,
            max_volume=Decimal('1200.00'),
            achieved_date=timezone.now(),
            workout_log=self.workout_log2
        )
        
        self.pr2_user2 = PersonalRecord.objects.create(
            user=self.user2,
            exercise=self.exercise2,
            max_weight=Decimal('180.00'),
            max_reps=6,
            max_volume=Decimal('1080.00'),
            achieved_date=timezone.now(),
            workout_log=self.workout_log2
        )
    
    def test_list_personal_records_requires_authentication(self):
        """
        Test that GET /api/personal-records/ requires authentication.
        Validates: Requirements 4.6, 5.4
        """
        response = self.client.get('/api/workouts/personal-records/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
    
    def test_list_personal_records_returns_only_user_prs(self):
        """
        Test that GET /api/personal-records/ returns only authenticated user's PRs.
        Validates: Requirements 4.6, 5.4
        """
        self.client.force_authenticate(user=self.user1)
        response = self.client.get('/api/workouts/personal-records/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 2)
        
        # Verify all returned PRs belong to user1
        for pr in response.data:
            self.assertIn('id', pr)
            self.assertIn('exercise', pr)
            self.assertIn('exercise_name', pr)
            self.assertIn('max_weight', pr)
            self.assertIn('max_reps', pr)
            self.assertIn('max_volume', pr)
            self.assertIn('achieved_date', pr)
            
            # Verify the PR belongs to user1 by checking the exercise
            pr_id = pr['id']
            pr_obj = PersonalRecord.objects.get(id=pr_id)
            self.assertEqual(pr_obj.user, self.user1)
    
    def test_list_personal_records_does_not_return_other_users_prs(self):
        """
        Test that user1 cannot see user2's PRs.
        Validates: Requirements 4.6
        """
        self.client.force_authenticate(user=self.user1)
        response = self.client.get('/api/workouts/personal-records/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Get all PR IDs from response
        returned_pr_ids = [pr['id'] for pr in response.data]
        
        # Verify user2's PRs are not in the response
        self.assertNotIn(self.pr1_user2.id, returned_pr_ids)
        self.assertNotIn(self.pr2_user2.id, returned_pr_ids)
        
        # Verify user1's PRs are in the response
        self.assertIn(self.pr1_user1.id, returned_pr_ids)
        self.assertIn(self.pr2_user1.id, returned_pr_ids)
    
    def test_list_personal_records_includes_exercise_name(self):
        """
        Test that response includes exercise_name field.
        Validates: Requirements 4.2, 5.4
        """
        self.client.force_authenticate(user=self.user1)
        response = self.client.get('/api/workouts/personal-records/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreater(len(response.data), 0)
        
        # Verify exercise_name is included
        pr = response.data[0]
        self.assertIn('exercise_name', pr)
        self.assertIn(pr['exercise_name'], ['Bench Press', 'Squats'])
    
    def test_list_personal_records_includes_improvement_percentage(self):
        """
        Test that response includes improvement_percentage field.
        Validates: Requirements 4.3, 5.4
        """
        # Update a PR with previous values
        self.pr1_user1.previous_max_weight = Decimal('100.00')
        self.pr1_user1.previous_max_reps = 10
        self.pr1_user1.previous_max_volume = Decimal('1000.00')
        self.pr1_user1.save()
        
        self.client.force_authenticate(user=self.user1)
        response = self.client.get('/api/workouts/personal-records/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Find the PR with improvement data
        pr_with_improvement = None
        for pr in response.data:
            if pr['id'] == self.pr1_user1.id:
                pr_with_improvement = pr
                break
        
        self.assertIsNotNone(pr_with_improvement)
        self.assertIn('improvement_percentage', pr_with_improvement)
        self.assertIsNotNone(pr_with_improvement['improvement_percentage'])
        # Weight improved from 100 to 120 = 20% improvement
        self.assertAlmostEqual(
            float(pr_with_improvement['improvement_percentage']),
            20.0,
            places=1
        )
    
    def test_filter_personal_records_by_exercise(self):
        """
        Test that PRs can be filtered by exercise_id.
        Validates: Requirements 4.6, 5.4
        """
        self.client.force_authenticate(user=self.user1)
        response = self.client.get(
            f'/api/workouts/personal-records/?exercise_id={self.exercise1.id}'
        )
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['exercise'], self.exercise1.id)
        self.assertEqual(response.data[0]['exercise_name'], 'Bench Press')
    
    def test_empty_personal_records_for_new_user(self):
        """
        Test that a new user with no PRs gets an empty list.
        Validates: Requirements 4.6, 5.4
        """
        new_user = User.objects.create_user(
            email='newuser@example.com',
            password='testpass123',
            first_name='New',
            last_name='User'
        )
        
        self.client.force_authenticate(user=new_user)
        response = self.client.get('/api/workouts/personal-records/')
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 0)


class TestPersonalRecordUserScopingProperty(HypothesisTestCase):
    """
    Property 14: User-Scoped Personal Records
    
    For any authenticated user requesting personal records, the system should 
    return only PRs belonging to that user and no PRs from other users.
    
    Validates: Requirements 4.6
    """
    
    def setUp(self):
        """Set up test fixtures"""
        self.client = APIClient()
        
        # Create exercises
        self.exercises = []
        for i in range(5):
            exercise = Exercise.objects.create(
                name=f'Exercise {i}',
                category='STRENGTH',
                muscle_group='CHEST',
                equipment='FREE_WEIGHTS',
                difficulty='INTERMEDIATE',
                description=f'Exercise {i} description',
                instructions=f'Exercise {i} instructions',
                calories_per_minute=Decimal('8.0')
            )
            self.exercises.append(exercise)
    
    @given(
        num_users=st.integers(min_value=2, max_value=5),
        prs_per_user=st.integers(min_value=1, max_value=5)
    )
    @settings(max_examples=50, deadline=None)
    def test_property_14_user_scoped_personal_records(self, num_users, prs_per_user):
        """
        Feature: workout-tracking-system, Property 14: User-Scoped Personal Records
        
        For any authenticated user requesting personal records, the system should 
        return only PRs belonging to that user and no PRs from other users.
        
        Validates: Requirements 4.6
        """
        # Create users
        users = []
        for i in range(num_users):
            user = User.objects.create_user(
                email=f'user{i}@example.com',
                password='testpass123',
                first_name=f'User{i}',
                last_name='Test'
            )
            users.append(user)
        
        # Create PRs for each user
        user_prs = {}
        for user in users:
            user_prs[user.id] = []
            
            # Create workout log for this user
            workout_log = WorkoutLog.objects.create(
                user=user,
                workout_name=f'Workout for {user.email}',
                duration_minutes=60,
                calories_burned=Decimal('450.00')
            )
            
            # Create PRs for this user
            for j in range(min(prs_per_user, len(self.exercises))):
                pr = PersonalRecord.objects.create(
                    user=user,
                    exercise=self.exercises[j],
                    max_weight=Decimal('100.00') + Decimal(j * 10),
                    max_reps=10 + j,
                    max_volume=Decimal('1000.00') + Decimal(j * 100),
                    achieved_date=timezone.now(),
                    workout_log=workout_log
                )
                user_prs[user.id].append(pr.id)
        
        # Test each user can only see their own PRs
        for user in users:
            self.client.force_authenticate(user=user)
            response = self.client.get('/api/workouts/personal-records/')
            
            # Verify response is successful
            self.assertEqual(response.status_code, status.HTTP_200_OK)
            
            # Get returned PR IDs
            returned_pr_ids = [pr['id'] for pr in response.data]
            
            # Verify all returned PRs belong to this user
            for pr_id in returned_pr_ids:
                self.assertIn(pr_id, user_prs[user.id])
            
            # Verify no PRs from other users are returned
            for other_user in users:
                if other_user.id != user.id:
                    for other_pr_id in user_prs[other_user.id]:
                        self.assertNotIn(other_pr_id, returned_pr_ids)
            
            # Verify all of this user's PRs are returned
            self.assertEqual(len(returned_pr_ids), len(user_prs[user.id]))
        
        # Clean up
        for user in users:
            user.delete()
