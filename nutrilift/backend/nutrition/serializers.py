from django.utils.html import escape
from rest_framework import serializers
from .models import FoodItem, IntakeLog, HydrationLog, NutritionGoals, NutritionProgress, QuickLog


def sanitize_text_input(text):
    """
    Sanitize text input to prevent XSS and injection attacks.
    Escapes HTML special characters and strips dangerous content.
    
    Requirements: 11.1
    """
    if text is None:
        return None
    
    # Convert to string and strip whitespace
    text = str(text).strip()
    
    # Escape HTML special characters
    text = escape(text)
    
    # Remove null bytes
    text = text.replace('\x00', '')
    
    return text


class FoodItemSerializer(serializers.ModelSerializer):
    """
    Serializer for FoodItem model with field validation.
    
    Requirements: 1.4, 11.1, 11.3, 13.1, 13.8, 13.10
    """
    class Meta:
        model = FoodItem
        fields = [
            'id', 'name', 'brand',
            'calories_per_100g', 'protein_per_100g', 'carbs_per_100g', 
            'fats_per_100g', 'fiber_per_100g', 'sugar_per_100g',
            'is_custom', 'created_by', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_by', 'created_at', 'updated_at']
    
    def validate_name(self, value):
        """
        Sanitize food name to prevent XSS attacks.
        
        Requirements: 11.1
        """
        return sanitize_text_input(value)
    
    def validate(self, data):
        """
        Ensure all nutritional values are non-negative.
        
        Requirements: 1.4, 11.3
        """
        nutritional_fields = [
            'calories_per_100g', 'protein_per_100g', 'carbs_per_100g', 
            'fats_per_100g', 'fiber_per_100g', 'sugar_per_100g'
        ]
        
        for field in nutritional_fields:
            if field in data and data[field] < 0:
                raise serializers.ValidationError({
                    field: "Must be non-negative"
                })
        
        return data


class IntakeLogSerializer(serializers.ModelSerializer):
    """
    Serializer for IntakeLog model with nested food_item details and macro calculation.
    
    Requirements: 2.2-2.5, 2.7, 11.2, 11.4, 13.2, 13.9
    """
    food_item_details = FoodItemSerializer(source='food_item', read_only=True)
    
    class Meta:
        model = IntakeLog
        fields = [
            'id', 'user', 'food_item', 'food_item_details',
            'entry_type', 'description', 'quantity', 'unit',
            'calories', 'protein', 'carbs', 'fats',
            'logged_at', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'user', 'calories', 'protein', 'carbs', 'fats', 'created_at', 'updated_at']
    
    def validate_quantity(self, value):
        """
        Ensure quantity is positive.
        
        Requirements: 11.2
        """
        if value <= 0:
            raise serializers.ValidationError("Quantity must be greater than zero")
        return value
    
    def validate_entry_type(self, value):
        """
        Ensure entry_type is valid.
        
        Requirements: 2.7, 11.4
        """
        valid_types = ['meal', 'snack', 'drink']
        if value not in valid_types:
            raise serializers.ValidationError(f"Must be one of: {', '.join(valid_types)}")
        return value
    
    def create(self, validated_data):
        """
        Calculate macros before saving using formula: (nutrient_per_100g ÷ 100) × quantity
        
        Requirements: 2.2, 2.3, 2.4, 2.5
        """
        food_item = validated_data['food_item']
        quantity = validated_data['quantity']
        
        # Calculate macros: (nutrient_per_100g ÷ 100) × quantity
        multiplier = quantity / 100
        validated_data['calories'] = food_item.calories_per_100g * multiplier
        validated_data['protein'] = food_item.protein_per_100g * multiplier
        validated_data['carbs'] = food_item.carbs_per_100g * multiplier
        validated_data['fats'] = food_item.fats_per_100g * multiplier
        
        return super().create(validated_data)
    
    def update(self, instance, validated_data):
        """
        Recalculate macros when quantity is updated using formula: (nutrient_per_100g ÷ 100) × quantity
        
        Requirements: 2.2, 2.3, 2.4, 2.5
        """
        # Get food_item (either from validated_data or existing instance)
        food_item = validated_data.get('food_item', instance.food_item)
        quantity = validated_data.get('quantity', instance.quantity)
        
        # Recalculate macros: (nutrient_per_100g ÷ 100) × quantity
        multiplier = quantity / 100
        validated_data['calories'] = food_item.calories_per_100g * multiplier
        validated_data['protein'] = food_item.protein_per_100g * multiplier
        validated_data['carbs'] = food_item.carbs_per_100g * multiplier
        validated_data['fats'] = food_item.fats_per_100g * multiplier
        
        return super().update(instance, validated_data)


class HydrationLogSerializer(serializers.ModelSerializer):
    """
    Serializer for HydrationLog model with all required fields.
    
    Requirements: 13.3, 13.8
    """
    class Meta:
        model = HydrationLog
        fields = [
            'id', 'user', 'amount', 'unit',
            'logged_at', 'created_at'
        ]
        read_only_fields = ['id', 'user', 'created_at']
    
    def validate_amount(self, value):
        """
        Ensure amount is positive.
        
        Requirements: 11.2
        """
        if value <= 0:
            raise serializers.ValidationError("Amount must be greater than zero")
        return value


class NutritionGoalsSerializer(serializers.ModelSerializer):
    """
    Serializer for NutritionGoals model with target fields.
    
    Requirements: 13.4, 13.8
    """
    class Meta:
        model = NutritionGoals
        fields = [
            'id', 'user',
            'daily_calories', 'daily_protein', 'daily_carbs', 
            'daily_fats', 'daily_water',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'user', 'created_at', 'updated_at']
    
    def validate(self, data):
        """
        Ensure all goal values are non-negative.
        
        Requirements: 11.3
        """
        goal_fields = [
            'daily_calories', 'daily_protein', 'daily_carbs', 
            'daily_fats', 'daily_water'
        ]
        
        for field in goal_fields:
            if field in data and data[field] < 0:
                raise serializers.ValidationError({
                    field: "Must be non-negative"
                })
        
        return data


class NutritionProgressSerializer(serializers.ModelSerializer):
    """
    Serializer for NutritionProgress model with aggregated fields.
    
    Requirements: 13.5, 13.8
    """
    class Meta:
        model = NutritionProgress
        fields = [
            'id', 'user', 'progress_date',
            'total_calories', 'total_protein', 'total_carbs', 'total_fats', 'total_water',
            'calories_adherence', 'protein_adherence', 'carbs_adherence', 
            'fats_adherence', 'water_adherence',
            'updated_at'
        ]
        read_only_fields = ['id', 'updated_at']


class QuickLogSerializer(serializers.ModelSerializer):
    """
    Serializer for QuickLog model with food_item details.
    
    Requirements: 13.6, 13.8
    """
    class Meta:
        model = QuickLog
        fields = [
            'id', 'user', 'frequent_meals', 'updated_at'
        ]
        read_only_fields = ['id', 'updated_at']
