from django.core.management.base import BaseCommand
from nutrition.models import FoodItem
from nutrition.food_image_map import get_food_image_url


class Command(BaseCommand):
    help = 'Adds image URLs to all food items that are missing one'

    def handle(self, *args, **kwargs):
        self.stdout.write('Adding image URLs to food items without images...')

        foods = FoodItem.objects.filter(image_url__isnull=True) | FoodItem.objects.filter(image_url='')
        total = foods.count()
        self.stdout.write(f'Found {total} food items without images')

        updated = 0
        for food in foods:
            food.image_url = get_food_image_url(food.name)
            food.save(update_fields=['image_url'])
            updated += 1
            if updated % 100 == 0:
                self.stdout.write(f'  Updated {updated}/{total}...')

        self.stdout.write(self.style.SUCCESS(f'Done. Updated {updated} food items.'))
