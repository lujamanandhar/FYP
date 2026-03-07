from django.core.management.base import BaseCommand
from nutrition.models import FoodItem
import re


class Command(BaseCommand):
    help = 'Adds image URLs to ALL food items in the database'

    def handle(self, *args, **kwargs):
        self.stdout.write('Adding image URLs to all food items...')
        
        # Get all food items
        all_foods = FoodItem.objects.all()
        total_count = all_foods.count()
        
        self.stdout.write(f'Found {total_count} total food items')
        
        updated_count = 0
        skipped_count = 0
        
        for food in all_foods:
            # Skip if already has an image
            if food.image_url and food.image_url.strip():
                skipped_count += 1
                continue
            
            # Get image URL based on food category
            image_url = self.get_food_image_url(food.name)
            food.image_url = image_url
            food.save()
            updated_count += 1
            
            if updated_count % 100 == 0:
                self.stdout.write(f'Updated {updated_count}/{total_count} items...')
        
        self.stdout.write(self.style.SUCCESS(f'Successfully updated {updated_count} food items with images'))
        if skipped_count > 0:
            self.stdout.write(self.style.WARNING(f'Skipped {skipped_count} items that already had images'))
    
    def get_food_image_url(self, food_name):
        """
        Get appropriate image URL based on food category.
        Uses Unsplash for real food images with fallback categories.
        """
        name_lower = food_name.lower()
        
        # Specific mappings for common foods
        specific_images = {
            # Fruits
            'apple': 'https://images.unsplash.com/photo-1568702846914-96b305d2aaeb?w=200',
            'banana': 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=200',
            'orange': 'https://images.unsplash.com/photo-1580052614034-c55d20bfee3b?w=200',
            'strawberry': 'https://images.unsplash.com/photo-1464965911861-746a04b4bca6?w=200',
            'grape': 'https://images.unsplash.com/photo-1599819177626-c0d3b8d6c7e1?w=200',
            'watermelon': 'https://images.unsplash.com/photo-1587049352846-4a222e784422?w=200',
            'mango': 'https://images.unsplash.com/photo-1553279768-865429fa0078?w=200',
            'pineapple': 'https://images.unsplash.com/photo-1550258987-190a2d41a8ba?w=200',
            'blueberry': 'https://images.unsplash.com/photo-1498557850523-fd3d118b962e?w=200',
            'peach': 'https://images.unsplash.com/photo-1629828874514-d05e24e0c32f?w=200',
            'pear': 'https://images.unsplash.com/photo-1568471173238-64ed8e7e9d6e?w=200',
            'cherry': 'https://images.unsplash.com/photo-1528821128474-27f963b062bf?w=200',
            'kiwi': 'https://images.unsplash.com/photo-1585059895524-72359e06133a?w=200',
            'avocado': 'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=200',
            'lemon': 'https://images.unsplash.com/photo-1590502593747-42a996133562?w=200',
            'lime': 'https://images.unsplash.com/photo-1582169296194-e4d644c48063?w=200',
            
            # Vegetables
            'broccoli': 'https://images.unsplash.com/photo-1459411621453-7b03977f4bfc?w=200',
            'carrot': 'https://images.unsplash.com/photo-1598170845058-32b9d6a5da37?w=200',
            'spinach': 'https://images.unsplash.com/photo-1576045057995-568f588f82fb?w=200',
            'tomato': 'https://images.unsplash.com/photo-1546470427-227e9e3e0e4e?w=200',
            'cucumber': 'https://images.unsplash.com/photo-1604977042946-1eecc30f269e?w=200',
            'pepper': 'https://images.unsplash.com/photo-1563565375-f3fdfdbefa83?w=200',
            'lettuce': 'https://images.unsplash.com/photo-1622206151226-18ca2c9ab4a1?w=200',
            'onion': 'https://images.unsplash.com/photo-1618512496248-a07fe83aa8cb?w=200',
            'potato': 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=200',
            'mushroom': 'https://images.unsplash.com/photo-1565688534245-05d6b5be184a?w=200',
            'cauliflower': 'https://images.unsplash.com/photo-1568584711271-e88a6c3d6b8e?w=200',
            'cabbage': 'https://images.unsplash.com/photo-1594282486552-05b4d80fbb9f?w=200',
            'kale': 'https://images.unsplash.com/photo-1560493676-04071c5f467b?w=200',
            'asparagus': 'https://images.unsplash.com/photo-1550870405-6a0f8df07f8c?w=200',
            'zucchini': 'https://images.unsplash.com/photo-1597362925123-77861d3fbac7?w=200',
            'eggplant': 'https://images.unsplash.com/photo-1659261200833-ec8761558af7?w=200',
            'corn': 'https://images.unsplash.com/photo-1551754655-cd27e38d2076?w=200',
            'peas': 'https://images.unsplash.com/photo-1587735243615-c03f25aaff15?w=200',
            
            # Proteins
            'chicken': 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?w=200',
            'beef': 'https://images.unsplash.com/photo-1588168333986-5078d3ae3976?w=200',
            'pork': 'https://images.unsplash.com/photo-1602470520998-f4a52199a3d6?w=200',
            'turkey': 'https://images.unsplash.com/photo-1574672280600-4accfa5b6f98?w=200',
            'lamb': 'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=200',
            'salmon': 'https://images.unsplash.com/photo-1485921325833-c519f76c4927?w=200',
            'tuna': 'https://images.unsplash.com/photo-1580959375944-0b7b9e7d1e5e?w=200',
            'shrimp': 'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?w=200',
            'fish': 'https://images.unsplash.com/photo-1534604973900-c43ab4c2e0ab?w=200',
            'egg': 'https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=200',
            'tofu': 'https://images.unsplash.com/photo-1587741049254-8f4e8c3f0c8e?w=200',
            'beans': 'https://images.unsplash.com/photo-1589367920969-ab8e050bbb04?w=200',
            'lentil': 'https://images.unsplash.com/photo-1596797038530-2c107229654b?w=200',
            
            # Grains
            'rice': 'https://images.unsplash.com/photo-1516684732162-798a0062be99?w=200',
            'bread': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=200',
            'pasta': 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=200',
            'oat': 'https://images.unsplash.com/photo-1517673132405-a56a62b18caf?w=200',
            'quinoa': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=200',
            'cereal': 'https://images.unsplash.com/photo-1590137876181-b26f0a10e0d3?w=200',
            
            # Dairy
            'milk': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=200',
            'yogurt': 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=200',
            'cheese': 'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?w=200',
            'butter': 'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?w=200',
            'cream': 'https://images.unsplash.com/photo-1628088062854-d1870b4553da?w=200',
            
            # Nuts & Seeds
            'almond': 'https://images.unsplash.com/photo-1508747703725-719777637510?w=200',
            'walnut': 'https://images.unsplash.com/photo-1622484211850-1d1e0e1e1e1e?w=200',
            'peanut': 'https://images.unsplash.com/photo-1582037928769-181f2644ecb7?w=200',
            'cashew': 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=200',
            'seed': 'https://images.unsplash.com/photo-1606787366850-de6330128bfc?w=200',
        }
        
        # Check for specific matches first
        for keyword, url in specific_images.items():
            if keyword in name_lower:
                return url
        
        # Category-based fallback
        if any(word in name_lower for word in ['fruit', 'berry', 'melon']):
            return 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b?w=200'
        elif any(word in name_lower for word in ['vegetable', 'veggie', 'green']):
            return 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=200'
        elif any(word in name_lower for word in ['meat', 'steak', 'chop']):
            return 'https://images.unsplash.com/photo-1588168333986-5078d3ae3976?w=200'
        elif any(word in name_lower for word in ['grain', 'cereal', 'flour']):
            return 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=200'
        elif any(word in name_lower for word in ['nut', 'seed']):
            return 'https://images.unsplash.com/photo-1508747703725-719777637510?w=200'
        elif any(word in name_lower for word in ['dairy', 'milk', 'yogurt', 'cheese']):
            return 'https://images.unsplash.com/photo-1628088062854-d1870b4553da?w=200'
        elif any(word in name_lower for word in ['drink', 'juice', 'beverage', 'soda', 'coffee', 'tea']):
            return 'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=200'
        elif any(word in name_lower for word in ['dessert', 'cake', 'cookie', 'candy', 'chocolate']):
            return 'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=200'
        else:
            # Generic food image
            return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=200'
