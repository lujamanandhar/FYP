from django.core.management.base import BaseCommand
from nutrition.models import FoodItem


class Command(BaseCommand):
    help = 'Adds placeholder image URLs to ALL food items in the database'

    def handle(self, *args, **kwargs):
        self.stdout.write('Adding image URLs to all food items...')
        
        # Get all food items without images
        foods_without_images = FoodItem.objects.filter(image_url__isnull=True) | FoodItem.objects.filter(image_url='')
        total_count = foods_without_images.count()
        
        self.stdout.write(f'Found {total_count} food items without images')
        
        updated_count = 0
        for food in foods_without_images:
            # Generate a placeholder image URL based on food name
            # Using a generic food placeholder service
            image_url = self.get_food_image_url(food.name)
            food.image_url = image_url
            food.save()
            updated_count += 1
            
            if updated_count % 100 == 0:
                self.stdout.write(f'Updated {updated_count}/{total_count} items...')
        
        self.stdout.write(self.style.SUCCESS(f'Successfully updated {updated_count} food items with images'))
    
    def get_food_image_url(self, food_name):
        """
        Generate a food image URL using placeholder service.
        Uses a simple placeholder that shows the food name.
        """
        # Clean the food name for URL
        clean_name = food_name.lower().replace(' ', '+').replace(',', '')
        
        # Use a placeholder service that generates food images
        # Option 1: Generic placeholder with food name
        return f'https://via.placeholder.com/200/E53935/FFFFFF?text={clean_name[:20]}'
        
        # Alternative options (uncomment to use):
        # Option 2: Use a food icon service
        # return f'https://source.unsplash.com/200x200/?{clean_name}'
        
        # Option 3: Use a generic food image
        # return 'https://via.placeholder.com/200/E53935/FFFFFF?text=Food'
