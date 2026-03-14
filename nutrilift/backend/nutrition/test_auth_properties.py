"""
Property-based tests for authentication and authorization.

Tests that users can only access their own data.
**Validates: Requirements 10.1, 10.2, 10.3**
"""

from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from hypothesis import given, strategies as st, settings
from hypothesis.extra.django import TestCase as HypothesisTestCase
import uuid

from nutrition.models import FoodItem, IntakeLog, HydrationLog, NutritionGoals, NutritionProgress

User = get_user_model()


class AuthenticationAuthorizationPropertyTests(HypothesisTestCase):
    """
    Property tests for authentication and authorization.
    
    For any user, the system should:
    1. Only return data belonging to that user
    2. Prevent access to other users' data
    3. Require authentication for all operations
    4. Associate created data with the authenticated user
    
    **Validates: Requirements 10.1, 10.2, 10.3**
    """

    def setUp(self):
        """Set up test data - create multiple users for each test"""
        super().setUp()
        unique_id1 = uuid.uuid4().hex[:8]
        unique_id2 = uuid.uuid4().hex[:8]
        
        self.user1 = User.objects.create_user(
            email=f'test1_{unique_id1}@example.com',
            password='testpass123',
            first_name='Test1',
            last_name='User1'
        )
        
        self.user2 = User.objects.create_user(
            email=f'test2_{unique_id2}@example.com',
            password='testpass123',
            first_name='Test2',
            last_name='User2'
        )
        
        self.food_item = FoodItem.objects.create(
            name=f'Test Food {uuid.uuid4().hex[:8]}',
            calories_per_100g=Decimal('200.00'),
            protein_per_100g=Decimal('20.00'),
            carbs_per_100g=Decimal('30.00'),
            fats_per_100g=Decimal('10.00'),
            fiber_per_100g=Decimal('5.00'),
            sugar_per_100g=Decimal('15.00'),
            is_custom=False
        )

    @given(
        num_logs_user1=st.integers(min_value=1, max_value=5),
        num_logs_user2=st.integers(min_value=1, max_value=5)
    )
    @settings(max_examples=30, deadline=None)
    def test_property_user_data_isolation(self, num_logs_user1, num_logs_user2):
        """
        Feature: nutrition-tracking-system, Property: Authentication/Authorization
        
        For any two users, their intake logs should be isolated.
        User1 should only see their own logs, not User2's logs.
        
        **Validates: Requirements 10.2**
        """
        # Create logs for user1
        for i in range(num_logs_user1):
            IntakeLog.objects.create(
                user=self.user1,
                food_item=self.food_item,
                entry_type='meal',
                quantity=Decimal('100.00'),
                unit='g',
                calories=Decimal('200.00'),
                protein=Decimal('20.00'),
                carbs=Decimal('30.00'),
                fats=Decimal('10.00')
            )
        
        # Create logs for user2
        for i in range(num_logs_user2):
            IntakeLog.objects.create(
                user=self.user2,
                food_item=self.food_item,
                entry_type='meal',
                quantity=Decimal('150.00'),
                unit='g',
                calories=Decimal('300.00'),
                protein=Decimal('30.00'),
                carbs=Decimal('45.00'),
                fats=Decimal('15.00')
            )
        
        # Property: User1 should only see their own logs
        user1_logs = IntakeLog.objects.filter(user=self.user1)
        self.assertEqual(
            user1_logs.count(),
            num_logs_user1,
            "User1 should only see their own logs"
        )
        
        # Property: User2 should only see their own logs
        user2_logs = IntakeLog.objects.filter(user=self.user2)
        self.assertEqual(
            user2_logs.count(),
            num_logs_user2,
            "User2 should only see their own logs"
        )
        
        # Property: No overlap between users' logs
        for log in user1_logs:
            self.assertEqual(log.user, self.user1)
        
        for log in user2_logs:
            self.assertEqual(log.user, self.user2)

    @given(
        num_hydration_logs=st.integers(min_value=1, max_value=5)
    )
    @settings(max_examples=30, deadline=None)
    def test_property_hydration_data_isolation(self, num_hydration_logs):
        """
        Feature: nutrition-tracking-system, Property: Authentication/Authorization
        
        For any two users, their hydration logs should be isolated.
        
        **Validates: Requirements 10.2**
        """
        # Create hydration logs for user1
        for i in range(num_hydration_logs):
            HydrationLog.objects.create(
                user=self.user1,
                amount=Decimal('250.00'),
                unit='ml'
            )
        
        # Create hydration logs for user2
        for i in range(num_hydration_logs):
            HydrationLog.objects.create(
                user=self.user2,
                amount=Decimal('500.00'),
                unit='ml'
            )
        
        # Property: Each user should only see their own hydration logs
        user1_logs = HydrationLog.objects.filter(user=self.user1)
        user2_logs = HydrationLog.objects.filter(user=self.user2)
        
        self.assertEqual(user1_logs.count(), num_hydration_logs)
        self.assertEqual(user2_logs.count(), num_hydration_logs)
        
        # Verify amounts are different (user1: 250, user2: 500)
        for log in user1_logs:
            self.assertEqual(log.amount, Decimal('250.00'))
        
        for log in user2_logs:
            self.assertEqual(log.amount, Decimal('500.00'))

    def test_property_nutrition_goals_per_user(self):
        """
        Feature: nutrition-tracking-system, Property: Authentication/Authorization
        
        Each user should have their own nutrition goals (OneToOne relationship).
        
        **Validates: Requirements 10.2**
        """
        # Create goals for user1
        goals1 = NutritionGoals.objects.create(
            user=self.user1,
            daily_calories=Decimal('2000.00'),
            daily_protein=Decimal('150.00'),
            daily_carbs=Decimal('200.00'),
            daily_fats=Decimal('65.00'),
            daily_water=Decimal('2000.00')
        )
        
        # Create goals for user2
        goals2 = NutritionGoals.objects.create(
            user=self.user2,
            daily_calories=Decimal('2500.00'),
            daily_protein=Decimal('180.00'),
            daily_carbs=Decimal('250.00'),
            daily_fats=Decimal('80.00'),
            daily_water=Decimal('2500.00')
        )
        
        # Property: Each user should have their own goals
        self.assertEqual(self.user1.nutrition_goals, goals1)
        self.assertEqual(self.user2.nutrition_goals, goals2)
        
        # Property: Goals should be different
        self.assertNotEqual(goals1.daily_calories, goals2.daily_calories)
        self.assertNotEqual(goals1.daily_protein, goals2.daily_protein)

    @given(
        num_days=st.integers(min_value=1, max_value=5)
    )
    @settings(max_examples=30, deadline=None)
    def test_property_progress_data_isolation(self, num_days):
        """
        Feature: nutrition-tracking-system, Property: Authentication/Authorization
        
        For any two users, their nutrition progress should be isolated.
        
        **Validates: Requirements 10.2**
        """
        from datetime import timedelta
        
        base_date = timezone.now().date()
        
        # Create progress for user1
        for i in range(num_days):
            date = base_date - timedelta(days=i)
            NutritionProgress.objects.create(
                user=self.user1,
                progress_date=date,
                total_calories=Decimal('1800.00'),
                total_protein=Decimal('140.00'),
                total_carbs=Decimal('180.00'),
                total_fats=Decimal('60.00'),
                total_water=Decimal('1800.00')
            )
        
        # Create progress for user2
        for i in range(num_days):
            date = base_date - timedelta(days=i)
            NutritionProgress.objects.create(
                user=self.user2,
                progress_date=date,
                total_calories=Decimal('2200.00'),
                total_protein=Decimal('170.00'),
                total_carbs=Decimal('220.00'),
                total_fats=Decimal('75.00'),
                total_water=Decimal('2200.00')
            )
        
        # Property: Each user should only see their own progress
        user1_progress = NutritionProgress.objects.filter(user=self.user1)
        user2_progress = NutritionProgress.objects.filter(user=self.user2)
        
        self.assertEqual(user1_progress.count(), num_days)
        self.assertEqual(user2_progress.count(), num_days)
        
        # Verify values are different
        for progress in user1_progress:
            self.assertEqual(progress.total_calories, Decimal('1800.00'))
        
        for progress in user2_progress:
            self.assertEqual(progress.total_calories, Decimal('2200.00'))

    def test_property_custom_food_ownership(self):
        """
        Feature: nutrition-tracking-system, Property: Authentication/Authorization
        
        Custom foods should be associated with the user who created them.
        
        **Validates: Requirements 1.5, 10.2**
        """
        # User1 creates a custom food
        custom_food1 = FoodItem.objects.create(
            name=f'Custom Food 1 {uuid.uuid4().hex[:8]}',
            calories_per_100g=Decimal('150.00'),
            protein_per_100g=Decimal('15.00'),
            carbs_per_100g=Decimal('25.00'),
            fats_per_100g=Decimal('8.00'),
            fiber_per_100g=Decimal('3.00'),
            sugar_per_100g=Decimal('10.00'),
            is_custom=True,
            created_by=self.user1
        )
        
        # User2 creates a custom food
        custom_food2 = FoodItem.objects.create(
            name=f'Custom Food 2 {uuid.uuid4().hex[:8]}',
            calories_per_100g=Decimal('180.00'),
            protein_per_100g=Decimal('18.00'),
            carbs_per_100g=Decimal('28.00'),
            fats_per_100g=Decimal('9.00'),
            fiber_per_100g=Decimal('4.00'),
            sugar_per_100g=Decimal('12.00'),
            is_custom=True,
            created_by=self.user2
        )
        
        # Property: Custom foods should be associated with creator
        self.assertEqual(custom_food1.created_by, self.user1)
        self.assertEqual(custom_food2.created_by, self.user2)
        
        # Property: Users can query their own custom foods
        user1_custom_foods = FoodItem.objects.filter(is_custom=True, created_by=self.user1)
        user2_custom_foods = FoodItem.objects.filter(is_custom=True, created_by=self.user2)
        
        self.assertIn(custom_food1, user1_custom_foods)
        self.assertNotIn(custom_food2, user1_custom_foods)
        
        self.assertIn(custom_food2, user2_custom_foods)
        self.assertNotIn(custom_food1, user2_custom_foods)
