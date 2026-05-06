from django.core.management.base import BaseCommand
from nutrition.models import FoodItem
from nutrition.food_image_map import get_food_image_url


class Command(BaseCommand):
    help = 'Adds accurate image URLs to food items — specific items matched before generic ones'

    def add_arguments(self, parser):
        parser.add_argument(
            '--overwrite',
            action='store_true',
            help='Overwrite existing image URLs',
        )

    def handle(self, *args, **options):
        overwrite = options.get('overwrite', False)
        self.stdout.write('Adding image URLs to food items...')

        all_foods = FoodItem.objects.all()
        total = all_foods.count()
        self.stdout.write(f'Found {total} food items')

        updated = 0
        skipped = 0

        for food in all_foods:
            if food.image_url and food.image_url.strip() and not overwrite:
                skipped += 1
                continue

            food.image_url = get_food_image_url(food.name)
            food.save(update_fields=['image_url'])
            updated += 1

            if updated % 100 == 0:
                self.stdout.write(f'  Updated {updated}/{total}...')

        self.stdout.write(self.style.SUCCESS(f'Done. Updated: {updated}, Skipped: {skipped}'))
