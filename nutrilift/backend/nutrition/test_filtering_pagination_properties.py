"""
Property-based tests for filtering and pagination.

Tests that date filtering and pagination work correctly.
**Validates: Requirements 2.10, 4.3, 12.5**
"""

from decimal import Decimal
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.utils import timezone
from datetime import datetime, timedelta
from hypothesis import given, strategies as st, settings
from hypothesis.extra.django import TestCase as HypothesisTestCase
import uuid

from nutrition.models import FoodItem, IntakeLog, HydrationLog

User = get_user_model()


class FilteringPaginationPropertyTests(HypothesisTestCase):
    """
    Property tests for filtering and pagination.
    
    For any date range and dataset, the system should:
    1. Return only logs within the specified date range
    2. Exclude logs outside the date range
    3. Handle pagination correctly
    4. Maintain data integrity across pages
    
    **Validates: Requirements 2.10, 4.3, 12.5**
    """

    def setUp(self):
        """Set up test data - create fresh user and food item for each test"""
        super().setUp()
        unique_email = f'test_{uuid.uuid4().hex[:8]}@example.com'
        self.user = User.objects.create_user(
            email=unique_email,
            password='testpass123',
            first_name='Test',
            last_name='User'
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
        num_days=st.integers(min_value=1, max_value=10),
        logs_per_day=st.integers(min_value=1, max_value=5)
    )
    @settings(max_examples=30, deadline=None)
    def test_property_date_filtering_intake_logs(self, num_days, logs_per_day):
        """
        Feature: nutrition-tracking-system, Property: Filtering
        
        For any date range, the system should return only logs
        within that range and exclude logs outside it.
        
        **Validates: Requirements 2.10**
        """
        base_date = timezone.now().date()
        
        # Create logs across multiple days
        for day_offset in range(num_days):
            date = base_date - timedelta(days=day_offset)
            for i in range(logs_per_day):
                IntakeLog.objects.create(
                    user=self.user,
                    food_item=self.food_item,
                    entry_type='meal',
                    quantity=Decimal('100.00'),
                    unit='g',
                    calories=Decimal('200.00'),
                    protein=Decimal('20.00'),
                    carbs=Decimal('30.00'),
                    fats=Decimal('10.00'),
                    logged_at=timezone.make_aware(datetime.combine(date, datetime.min.time()))
                )
        
        # Test filtering for a specific date
        target_date = base_date - timedelta(days=num_days // 2)
        filtered_logs = IntakeLog.objects.filter(
            user=self.user,
            logged_at__date=target_date
        )
        
        # Property: Should return exactly logs_per_day logs for target date
        self.assertEqual(
            filtered_logs.count(),
            logs_per_day,
            f"Should return {logs_per_day} logs for date {target_date}"
        )
        
        # Property: All returned logs should be from target date
        for log in filtered_logs:
            self.assertEqual(log.logged_at.date(), target_date)

    @given(
        num_days_in_range=st.integers(min_value=2, max_value=7),
        logs_per_day=st.integers(min_value=1, max_value=3)
    )
    @settings(max_examples=30, deadline=None)
    def test_property_date_range_filtering(self, num_days_in_range, logs_per_day):
        """
        Feature: nutrition-tracking-system, Property: Filtering
        
        For any date range, the system should return all logs
        within that range and none outside it.
        
        **Validates: Requirements 2.10**
        """
        base_date = timezone.now().date()
        
        # Create logs for 10 days
        for day_offset in range(10):
            date = base_date - timedelta(days=day_offset)
            for i in range(logs_per_day):
                IntakeLog.objects.create(
                    user=self.user,
                    food_item=self.food_item,
                    entry_type='meal',
                    quantity=Decimal('100.00'),
                    unit='g',
                    calories=Decimal('200.00'),
                    protein=Decimal('20.00'),
                    carbs=Decimal('30.00'),
                    fats=Decimal('10.00'),
                    logged_at=timezone.make_aware(datetime.combine(date, datetime.min.time()))
                )
        
        # Filter for a specific range
        date_from = base_date - timedelta(days=num_days_in_range - 1)
        date_to = base_date
        
        filtered_logs = IntakeLog.objects.filter(
            user=self.user,
            logged_at__date__gte=date_from,
            logged_at__date__lte=date_to
        )
        
        # Property: Should return logs_per_day * num_days_in_range logs
        expected_count = logs_per_day * num_days_in_range
        self.assertEqual(
            filtered_logs.count(),
            expected_count,
            f"Should return {expected_count} logs for {num_days_in_range} days"
        )
        
        # Property: All logs should be within date range
        for log in filtered_logs:
            self.assertGreaterEqual(log.logged_at.date(), date_from)
            self.assertLessEqual(log.logged_at.date(), date_to)

    @given(
        num_logs=st.integers(min_value=5, max_value=20)
    )
    @settings(max_examples=30, deadline=None)
    def test_property_hydration_date_filtering(self, num_logs):
        """
        Feature: nutrition-tracking-system, Property: Filtering
        
        Hydration logs should be filterable by date.
        
        **Validates: Requirements 4.3**
        """
        base_date = timezone.now().date()
        
        # Create hydration logs across 3 days
        for day_offset in range(3):
            date = base_date - timedelta(days=day_offset)
            for i in range(num_logs):
                HydrationLog.objects.create(
                    user=self.user,
                    amount=Decimal('250.00'),
                    unit='ml',
                    logged_at=timezone.make_aware(datetime.combine(date, datetime.min.time()))
                )
        
        # Filter for middle day
        target_date = base_date - timedelta(days=1)
        filtered_logs = HydrationLog.objects.filter(
            user=self.user,
            logged_at__date=target_date
        )
        
        # Property: Should return exactly num_logs for target date
        self.assertEqual(
            filtered_logs.count(),
            num_logs,
            f"Should return {num_logs} hydration logs for date {target_date}"
        )

    @given(
        total_logs=st.integers(min_value=10, max_value=50),
        page_size=st.integers(min_value=5, max_value=15)
    )
    @settings(max_examples=20, deadline=None)
    def test_property_pagination_completeness(self, total_logs, page_size):
        """
        Feature: nutrition-tracking-system, Property: Pagination
        
        For any dataset and page size, pagination should return
        all records exactly once across all pages.
        
        **Validates: Requirements 12.5**
        """
        # Create logs
        for i in range(total_logs):
            IntakeLog.objects.create(
                user=self.user,
                food_item=self.food_item,
                entry_type='meal',
                quantity=Decimal('100.00'),
                unit='g',
                calories=Decimal('200.00'),
                protein=Decimal('20.00'),
                carbs=Decimal('30.00'),
                fats=Decimal('10.00')
            )
        
        # Simulate pagination
        all_logs = IntakeLog.objects.filter(user=self.user).order_by('-id')
        
        collected_ids = set()
        offset = 0
        
        while offset < total_logs:
            page_logs = all_logs[offset:offset + page_size]
            for log in page_logs:
                collected_ids.add(log.id)
            offset += page_size
        
        # Property: Should collect all log IDs exactly once
        self.assertEqual(
            len(collected_ids),
            total_logs,
            "Pagination should return all logs exactly once"
        )

    @given(
        num_logs=st.integers(min_value=5, max_value=20)
    )
    @settings(max_examples=30, deadline=None)
    def test_property_ordering_consistency(self, num_logs):
        """
        Feature: nutrition-tracking-system, Property: Filtering
        
        Logs should be ordered consistently (most recent first).
        
        **Validates: Requirements 2.10**
        """
        # Create logs with different timestamps
        logs_created = []
        for i in range(num_logs):
            log = IntakeLog.objects.create(
                user=self.user,
                food_item=self.food_item,
                entry_type='meal',
                quantity=Decimal('100.00'),
                unit='g',
                calories=Decimal('200.00'),
                protein=Decimal('20.00'),
                carbs=Decimal('30.00'),
                fats=Decimal('10.00'),
                logged_at=timezone.now() - timedelta(minutes=i)
            )
            logs_created.append(log)
        
        # Query with ordering
        ordered_logs = list(IntakeLog.objects.filter(user=self.user).order_by('-logged_at'))
        
        # Property: Logs should be in descending order by logged_at
        for i in range(len(ordered_logs) - 1):
            self.assertGreaterEqual(
                ordered_logs[i].logged_at,
                ordered_logs[i + 1].logged_at,
                "Logs should be ordered by logged_at descending"
            )
