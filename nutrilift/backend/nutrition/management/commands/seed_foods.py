from django.core.management.base import BaseCommand
from nutrition.models import FoodItem


class Command(BaseCommand):
    help = 'Seeds the database with common food items'

    def handle(self, *args, **kwargs):
        self.stdout.write('Seeding food items...')
        
        # Check how many system foods exist
        existing_count = FoodItem.objects.filter(is_custom=False).count()
        self.stdout.write(f'Found {existing_count} existing system foods')
        
        foods = self.get_food_data()
        
        created_count = 0
        skipped_count = 0
        for food_data in foods:
            # Check if food already exists
            if not FoodItem.objects.filter(name=food_data['name'], is_custom=False).exists():
                FoodItem.objects.create(**food_data)
                created_count += 1
            else:
                skipped_count += 1
        
        self.stdout.write(self.style.SUCCESS(f'Successfully seeded {created_count} food items'))
        if skipped_count > 0:
            self.stdout.write(self.style.WARNING(f'Skipped {skipped_count} existing food items'))
    
    def get_food_data(self):
        """Returns a list of food items with nutritional data per 100g"""
        return [
            # Fruits
            {'name': 'Apple', 'brand': None, 'calories_per_100g': 52, 'protein_per_100g': 0.3, 'carbs_per_100g': 14, 'fats_per_100g': 0.2, 'fiber_per_100g': 2.4, 'sugar_per_100g': 10, 'is_custom': False},
            {'name': 'Banana', 'brand': None, 'calories_per_100g': 89, 'protein_per_100g': 1.1, 'carbs_per_100g': 23, 'fats_per_100g': 0.3, 'fiber_per_100g': 2.6, 'sugar_per_100g': 12, 'is_custom': False},
            {'name': 'Orange', 'brand': None, 'calories_per_100g': 47, 'protein_per_100g': 0.9, 'carbs_per_100g': 12, 'fats_per_100g': 0.1, 'fiber_per_100g': 2.4, 'sugar_per_100g': 9, 'is_custom': False},
            {'name': 'Strawberry', 'brand': None, 'calories_per_100g': 32, 'protein_per_100g': 0.7, 'carbs_per_100g': 8, 'fats_per_100g': 0.3, 'fiber_per_100g': 2, 'sugar_per_100g': 5, 'is_custom': False},
            {'name': 'Grapes', 'brand': None, 'calories_per_100g': 69, 'protein_per_100g': 0.7, 'carbs_per_100g': 18, 'fats_per_100g': 0.2, 'fiber_per_100g': 0.9, 'sugar_per_100g': 16, 'is_custom': False},
            {'name': 'Watermelon', 'brand': None, 'calories_per_100g': 30, 'protein_per_100g': 0.6, 'carbs_per_100g': 8, 'fats_per_100g': 0.2, 'fiber_per_100g': 0.4, 'sugar_per_100g': 6, 'is_custom': False},
            {'name': 'Mango', 'brand': None, 'calories_per_100g': 60, 'protein_per_100g': 0.8, 'carbs_per_100g': 15, 'fats_per_100g': 0.4, 'fiber_per_100g': 1.6, 'sugar_per_100g': 14, 'is_custom': False},
            {'name': 'Pineapple', 'brand': None, 'calories_per_100g': 50, 'protein_per_100g': 0.5, 'carbs_per_100g': 13, 'fats_per_100g': 0.1, 'fiber_per_100g': 1.4, 'sugar_per_100g': 10, 'is_custom': False},
            {'name': 'Blueberry', 'brand': None, 'calories_per_100g': 57, 'protein_per_100g': 0.7, 'carbs_per_100g': 14, 'fats_per_100g': 0.3, 'fiber_per_100g': 2.4, 'sugar_per_100g': 10, 'is_custom': False},
            {'name': 'Peach', 'brand': None, 'calories_per_100g': 39, 'protein_per_100g': 0.9, 'carbs_per_100g': 10, 'fats_per_100g': 0.3, 'fiber_per_100g': 1.5, 'sugar_per_100g': 8, 'is_custom': False},
            
            # Vegetables
            {'name': 'Broccoli', 'brand': None, 'calories_per_100g': 34, 'protein_per_100g': 2.8, 'carbs_per_100g': 7, 'fats_per_100g': 0.4, 'fiber_per_100g': 2.6, 'sugar_per_100g': 1.7, 'is_custom': False},
            {'name': 'Carrot', 'brand': None, 'calories_per_100g': 41, 'protein_per_100g': 0.9, 'carbs_per_100g': 10, 'fats_per_100g': 0.2, 'fiber_per_100g': 2.8, 'sugar_per_100g': 5, 'is_custom': False},
            {'name': 'Spinach', 'brand': None, 'calories_per_100g': 23, 'protein_per_100g': 2.9, 'carbs_per_100g': 3.6, 'fats_per_100g': 0.4, 'fiber_per_100g': 2.2, 'sugar_per_100g': 0.4, 'is_custom': False},
            {'name': 'Tomato', 'brand': None, 'calories_per_100g': 18, 'protein_per_100g': 0.9, 'carbs_per_100g': 3.9, 'fats_per_100g': 0.2, 'fiber_per_100g': 1.2, 'sugar_per_100g': 2.6, 'is_custom': False},
            {'name': 'Cucumber', 'brand': None, 'calories_per_100g': 16, 'protein_per_100g': 0.7, 'carbs_per_100g': 3.6, 'fats_per_100g': 0.1, 'fiber_per_100g': 0.5, 'sugar_per_100g': 1.7, 'is_custom': False},
            {'name': 'Bell Pepper', 'brand': None, 'calories_per_100g': 31, 'protein_per_100g': 1, 'carbs_per_100g': 6, 'fats_per_100g': 0.3, 'fiber_per_100g': 2.1, 'sugar_per_100g': 4.2, 'is_custom': False},
            {'name': 'Lettuce', 'brand': None, 'calories_per_100g': 15, 'protein_per_100g': 1.4, 'carbs_per_100g': 2.9, 'fats_per_100g': 0.2, 'fiber_per_100g': 1.3, 'sugar_per_100g': 0.8, 'is_custom': False},
            {'name': 'Onion', 'brand': None, 'calories_per_100g': 40, 'protein_per_100g': 1.1, 'carbs_per_100g': 9, 'fats_per_100g': 0.1, 'fiber_per_100g': 1.7, 'sugar_per_100g': 4.2, 'is_custom': False},
            {'name': 'Potato', 'brand': None, 'calories_per_100g': 77, 'protein_per_100g': 2, 'carbs_per_100g': 17, 'fats_per_100g': 0.1, 'fiber_per_100g': 2.1, 'sugar_per_100g': 0.8, 'is_custom': False},
            {'name': 'Sweet Potato', 'brand': None, 'calories_per_100g': 86, 'protein_per_100g': 1.6, 'carbs_per_100g': 20, 'fats_per_100g': 0.1, 'fiber_per_100g': 3, 'sugar_per_100g': 4.2, 'is_custom': False},
            
            # Proteins
            {'name': 'Chicken Breast', 'brand': None, 'calories_per_100g': 165, 'protein_per_100g': 31, 'carbs_per_100g': 0, 'fats_per_100g': 3.6, 'fiber_per_100g': 0, 'sugar_per_100g': 0, 'is_custom': False},
            {'name': 'Salmon', 'brand': None, 'calories_per_100g': 208, 'protein_per_100g': 20, 'carbs_per_100g': 0, 'fats_per_100g': 13, 'fiber_per_100g': 0, 'sugar_per_100g': 0, 'is_custom': False},
            {'name': 'Tuna', 'brand': None, 'calories_per_100g': 132, 'protein_per_100g': 28, 'carbs_per_100g': 0, 'fats_per_100g': 1.3, 'fiber_per_100g': 0, 'sugar_per_100g': 0, 'is_custom': False},
            {'name': 'Beef Steak', 'brand': None, 'calories_per_100g': 271, 'protein_per_100g': 25, 'carbs_per_100g': 0, 'fats_per_100g': 19, 'fiber_per_100g': 0, 'sugar_per_100g': 0, 'is_custom': False},
            {'name': 'Pork Chop', 'brand': None, 'calories_per_100g': 231, 'protein_per_100g': 25, 'carbs_per_100g': 0, 'fats_per_100g': 14, 'fiber_per_100g': 0, 'sugar_per_100g': 0, 'is_custom': False},
            {'name': 'Eggs', 'brand': None, 'calories_per_100g': 155, 'protein_per_100g': 13, 'carbs_per_100g': 1.1, 'fats_per_100g': 11, 'fiber_per_100g': 0, 'sugar_per_100g': 1.1, 'is_custom': False},
            {'name': 'Greek Yogurt', 'brand': None, 'calories_per_100g': 59, 'protein_per_100g': 10, 'carbs_per_100g': 3.6, 'fats_per_100g': 0.4, 'fiber_per_100g': 0, 'sugar_per_100g': 3.2, 'is_custom': False},
            {'name': 'Cottage Cheese', 'brand': None, 'calories_per_100g': 98, 'protein_per_100g': 11, 'carbs_per_100g': 3.4, 'fats_per_100g': 4.3, 'fiber_per_100g': 0, 'sugar_per_100g': 2.7, 'is_custom': False},
            {'name': 'Tofu', 'brand': None, 'calories_per_100g': 76, 'protein_per_100g': 8, 'carbs_per_100g': 1.9, 'fats_per_100g': 4.8, 'fiber_per_100g': 0.3, 'sugar_per_100g': 0.7, 'is_custom': False},
            
            # Grains & Carbs
            {'name': 'White Rice (cooked)', 'brand': None, 'calories_per_100g': 130, 'protein_per_100g': 2.7, 'carbs_per_100g': 28, 'fats_per_100g': 0.3, 'fiber_per_100g': 0.4, 'sugar_per_100g': 0.1, 'is_custom': False},
            {'name': 'Brown Rice (cooked)', 'brand': None, 'calories_per_100g': 111, 'protein_per_100g': 2.6, 'carbs_per_100g': 23, 'fats_per_100g': 0.9, 'fiber_per_100g': 1.8, 'sugar_per_100g': 0.4, 'is_custom': False},
            {'name': 'Quinoa (cooked)', 'brand': None, 'calories_per_100g': 120, 'protein_per_100g': 4.4, 'carbs_per_100g': 21, 'fats_per_100g': 1.9, 'fiber_per_100g': 2.8, 'sugar_per_100g': 0.9, 'is_custom': False},
            {'name': 'Oatmeal (cooked)', 'brand': None, 'calories_per_100g': 71, 'protein_per_100g': 2.5, 'carbs_per_100g': 12, 'fats_per_100g': 1.5, 'fiber_per_100g': 1.7, 'sugar_per_100g': 0.3, 'is_custom': False},
            {'name': 'Whole Wheat Bread', 'brand': None, 'calories_per_100g': 247, 'protein_per_100g': 13, 'carbs_per_100g': 41, 'fats_per_100g': 3.4, 'fiber_per_100g': 7, 'sugar_per_100g': 6, 'is_custom': False},
            {'name': 'White Bread', 'brand': None, 'calories_per_100g': 265, 'protein_per_100g': 9, 'carbs_per_100g': 49, 'fats_per_100g': 3.2, 'fiber_per_100g': 2.7, 'sugar_per_100g': 5, 'is_custom': False},
            {'name': 'Pasta (cooked)', 'brand': None, 'calories_per_100g': 131, 'protein_per_100g': 5, 'carbs_per_100g': 25, 'fats_per_100g': 1.1, 'fiber_per_100g': 1.8, 'sugar_per_100g': 0.6, 'is_custom': False},
            
            # Nuts & Seeds
            {'name': 'Almonds', 'brand': None, 'calories_per_100g': 579, 'protein_per_100g': 21, 'carbs_per_100g': 22, 'fats_per_100g': 50, 'fiber_per_100g': 12, 'sugar_per_100g': 4.4, 'is_custom': False},
            {'name': 'Walnuts', 'brand': None, 'calories_per_100g': 654, 'protein_per_100g': 15, 'carbs_per_100g': 14, 'fats_per_100g': 65, 'fiber_per_100g': 6.7, 'sugar_per_100g': 2.6, 'is_custom': False},
            {'name': 'Peanuts', 'brand': None, 'calories_per_100g': 567, 'protein_per_100g': 26, 'carbs_per_100g': 16, 'fats_per_100g': 49, 'fiber_per_100g': 8.5, 'sugar_per_100g': 4, 'is_custom': False},
            {'name': 'Peanut Butter', 'brand': None, 'calories_per_100g': 588, 'protein_per_100g': 25, 'carbs_per_100g': 20, 'fats_per_100g': 50, 'fiber_per_100g': 6, 'sugar_per_100g': 9, 'is_custom': False},
            {'name': 'Cashews', 'brand': None, 'calories_per_100g': 553, 'protein_per_100g': 18, 'carbs_per_100g': 30, 'fats_per_100g': 44, 'fiber_per_100g': 3.3, 'sugar_per_100g': 6, 'is_custom': False},
            {'name': 'Chia Seeds', 'brand': None, 'calories_per_100g': 486, 'protein_per_100g': 17, 'carbs_per_100g': 42, 'fats_per_100g': 31, 'fiber_per_100g': 34, 'sugar_per_100g': 0, 'is_custom': False},
            
            # Dairy
            {'name': 'Whole Milk', 'brand': None, 'calories_per_100g': 61, 'protein_per_100g': 3.2, 'carbs_per_100g': 4.8, 'fats_per_100g': 3.3, 'fiber_per_100g': 0, 'sugar_per_100g': 5.1, 'is_custom': False},
            {'name': 'Skim Milk', 'brand': None, 'calories_per_100g': 34, 'protein_per_100g': 3.4, 'carbs_per_100g': 5, 'fats_per_100g': 0.1, 'fiber_per_100g': 0, 'sugar_per_100g': 5, 'is_custom': False},
            {'name': 'Cheddar Cheese', 'brand': None, 'calories_per_100g': 403, 'protein_per_100g': 25, 'carbs_per_100g': 1.3, 'fats_per_100g': 33, 'fiber_per_100g': 0, 'sugar_per_100g': 0.5, 'is_custom': False},
            {'name': 'Mozzarella Cheese', 'brand': None, 'calories_per_100g': 280, 'protein_per_100g': 28, 'carbs_per_100g': 2.2, 'fats_per_100g': 17, 'fiber_per_100g': 0, 'sugar_per_100g': 1, 'is_custom': False},
            {'name': 'Butter', 'brand': None, 'calories_per_100g': 717, 'protein_per_100g': 0.9, 'carbs_per_100g': 0.1, 'fats_per_100g': 81, 'fiber_per_100g': 0, 'sugar_per_100g': 0.1, 'is_custom': False},
            
            # Nepali Foods
            {'name': 'Dal Bhat (Rice & Lentils)', 'brand': None, 'calories_per_100g': 120, 'protein_per_100g': 4.5, 'carbs_per_100g': 22, 'fats_per_100g': 1.2, 'fiber_per_100g': 3.5, 'sugar_per_100g': 0.5, 'is_custom': False},
            {'name': 'Momo (Steamed)', 'brand': None, 'calories_per_100g': 180, 'protein_per_100g': 8, 'carbs_per_100g': 25, 'fats_per_100g': 5, 'fiber_per_100g': 1.5, 'sugar_per_100g': 1, 'is_custom': False},
            {'name': 'Momo (Fried)', 'brand': None, 'calories_per_100g': 250, 'protein_per_100g': 8, 'carbs_per_100g': 26, 'fats_per_100g': 12, 'fiber_per_100g': 1.5, 'sugar_per_100g': 1, 'is_custom': False},
            {'name': 'Sel Roti', 'brand': None, 'calories_per_100g': 320, 'protein_per_100g': 5, 'carbs_per_100g': 55, 'fats_per_100g': 9, 'fiber_per_100g': 1.2, 'sugar_per_100g': 15, 'is_custom': False},
            {'name': 'Dhido', 'brand': None, 'calories_per_100g': 95, 'protein_per_100g': 2.5, 'carbs_per_100g': 20, 'fats_per_100g': 0.5, 'fiber_per_100g': 3, 'sugar_per_100g': 0.3, 'is_custom': False},
            {'name': 'Gundruk (Fermented Greens)', 'brand': None, 'calories_per_100g': 25, 'protein_per_100g': 2, 'carbs_per_100g': 4, 'fats_per_100g': 0.3, 'fiber_per_100g': 3.5, 'sugar_per_100g': 0.5, 'is_custom': False},
            {'name': 'Aloo Tama (Potato Bamboo Curry)', 'brand': None, 'calories_per_100g': 85, 'protein_per_100g': 2, 'carbs_per_100g': 15, 'fats_per_100g': 2.5, 'fiber_per_100g': 3, 'sugar_per_100g': 2, 'is_custom': False},
            {'name': 'Chatamari (Nepali Pizza)', 'brand': None, 'calories_per_100g': 200, 'protein_per_100g': 7, 'carbs_per_100g': 30, 'fats_per_100g': 6, 'fiber_per_100g': 2, 'sugar_per_100g': 2, 'is_custom': False},
            {'name': 'Samosa', 'brand': None, 'calories_per_100g': 262, 'protein_per_100g': 5, 'carbs_per_100g': 35, 'fats_per_100g': 12, 'fiber_per_100g': 3, 'sugar_per_100g': 2, 'is_custom': False},
            {'name': 'Chana Masala', 'brand': None, 'calories_per_100g': 140, 'protein_per_100g': 7, 'carbs_per_100g': 20, 'fats_per_100g': 3.5, 'fiber_per_100g': 6, 'sugar_per_100g': 3, 'is_custom': False},
            {'name': 'Paneer', 'brand': None, 'calories_per_100g': 265, 'protein_per_100g': 18, 'carbs_per_100g': 3.6, 'fats_per_100g': 20, 'fiber_per_100g': 0, 'sugar_per_100g': 2.6, 'is_custom': False},
            {'name': 'Roti (Whole Wheat)', 'brand': None, 'calories_per_100g': 260, 'protein_per_100g': 9, 'carbs_per_100g': 50, 'fats_per_100g': 3, 'fiber_per_100g': 6, 'sugar_per_100g': 1, 'is_custom': False},
            {'name': 'Naan', 'brand': None, 'calories_per_100g': 310, 'protein_per_100g': 9, 'carbs_per_100g': 52, 'fats_per_100g': 7, 'fiber_per_100g': 2.5, 'sugar_per_100g': 4, 'is_custom': False},
            {'name': 'Lassi (Plain)', 'brand': None, 'calories_per_100g': 60, 'protein_per_100g': 3, 'carbs_per_100g': 8, 'fats_per_100g': 1.5, 'fiber_per_100g': 0, 'sugar_per_100g': 7, 'is_custom': False},
            {'name': 'Curd (Dahi)', 'brand': None, 'calories_per_100g': 60, 'protein_per_100g': 3.5, 'carbs_per_100g': 4.7, 'fats_per_100g': 3.3, 'fiber_per_100g': 0, 'sugar_per_100g': 4.7, 'is_custom': False},
            {'name': 'Chiura (Beaten Rice)', 'brand': None, 'calories_per_100g': 346, 'protein_per_100g': 6.6, 'carbs_per_100g': 77, 'fats_per_100g': 0.6, 'fiber_per_100g': 2.2, 'sugar_per_100g': 0.2, 'is_custom': False},
            {'name': 'Aloo Paratha', 'brand': None, 'calories_per_100g': 290, 'protein_per_100g': 6, 'carbs_per_100g': 42, 'fats_per_100g': 11, 'fiber_per_100g': 3, 'sugar_per_100g': 2, 'is_custom': False},
            {'name': 'Thukpa (Noodle Soup)', 'brand': None, 'calories_per_100g': 95, 'protein_per_100g': 4, 'carbs_per_100g': 15, 'fats_per_100g': 2, 'fiber_per_100g': 2, 'sugar_per_100g': 1.5, 'is_custom': False},
            {'name': 'Yomari', 'brand': None, 'calories_per_100g': 280, 'protein_per_100g': 4, 'carbs_per_100g': 50, 'fats_per_100g': 7, 'fiber_per_100g': 2, 'sugar_per_100g': 20, 'is_custom': False},
            {'name': 'Bara (Lentil Pancake)', 'brand': None, 'calories_per_100g': 150, 'protein_per_100g': 8, 'carbs_per_100g': 18, 'fats_per_100g': 5, 'fiber_per_100g': 4, 'sugar_per_100g': 1, 'is_custom': False},
        ]
