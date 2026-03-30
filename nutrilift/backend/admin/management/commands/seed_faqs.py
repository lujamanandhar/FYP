from django.core.management.base import BaseCommand
from admin.models import FAQ


class Command(BaseCommand):
    help = 'Seed initial FAQs for NutriLift'

    def handle(self, *args, **options):
        faqs = [
            # Getting Started
            {
                'category': 'getting_started',
                'question': 'How do I create an account?',
                'answer': 'Tap "Sign Up" on the login screen, enter your email and password, then complete your profile with basic information like age, gender, and fitness level.',
                'order': 1,
            },
            {
                'category': 'getting_started',
                'question': 'How do I set my fitness goals?',
                'answer': 'After signing up, you can set your fitness goals in your profile. Go to Profile View and update your fitness level, target weight, and workout preferences.',
                'order': 2,
            },
            {
                'category': 'getting_started',
                'question': 'Is NutriLift free to use?',
                'answer': 'Yes! NutriLift offers a comprehensive free tier with access to workout tracking, nutrition logging, and community features. Premium features may be available in the future.',
                'order': 3,
            },
            
            # Nutrition Tracking
            {
                'category': 'nutrition',
                'question': 'How do I log my meals?',
                'answer': 'Go to the Nutrition tab, select the meal type (Breakfast, Lunch, Dinner, or Snacks), tap "Add Food", search for the food item, and enter the quantity.',
                'order': 1,
            },
            {
                'category': 'nutrition',
                'question': 'Can I add custom foods?',
                'answer': 'Yes! If you can\'t find a food in our database, tap "Add Custom Food" and enter the nutritional information manually.',
                'order': 2,
            },
            {
                'category': 'nutrition',
                'question': 'How do I set my calorie goals?',
                'answer': 'Your calorie goals are automatically calculated based on your profile information. You can adjust them in the Nutrition Goals section.',
                'order': 3,
            },
            {
                'category': 'nutrition',
                'question': 'What are macros and how do I track them?',
                'answer': 'Macros (macronutrients) are protein, carbohydrates, and fats. NutriLift automatically tracks these for every food you log. View your daily macro breakdown in the Nutrition tab.',
                'order': 4,
            },
            
            # Workout Tracking
            {
                'category': 'workout',
                'question': 'How do I start a workout?',
                'answer': 'Go to the Workout tab, choose between Body Focus (target specific muscle groups) or Guided Workouts (follow pre-designed programs), select your workout, and tap "Start".',
                'order': 1,
            },
            {
                'category': 'workout',
                'question': 'What is a Personal Record (PR)?',
                'answer': 'A PR is your best performance for an exercise. NutriLift automatically tracks when you lift heavier weights or complete more reps than before.',
                'order': 2,
            },
            {
                'category': 'workout',
                'question': 'Can I create custom workouts?',
                'answer': 'Yes! Tap "Create Workout" in the Workout tab, add exercises from our library, and save it as a template for future use.',
                'order': 3,
            },
            
            # Challenges
            {
                'category': 'challenges',
                'question': 'How do I join a challenge?',
                'answer': 'Go to the Challenge tab, browse available challenges, tap on one that interests you, and hit "Join Challenge". Track your progress and compete with others!',
                'order': 1,
            },
            {
                'category': 'challenges',
                'question': 'What are streaks?',
                'answer': 'Streaks track consecutive days you\'ve completed workouts. Keep your streak alive by working out every day! Tap the fire icon to see your streak calendar.',
                'order': 2,
            },
            {
                'category': 'challenges',
                'question': 'Can I create my own challenge?',
                'answer': 'Yes! In the Challenge tab, tap "Create Challenge", set the challenge details, duration, and goals, then invite others to join.',
                'order': 3,
            },
        ]
        
        created_count = 0
        for faq_data in faqs:
            faq, created = FAQ.objects.get_or_create(
                category=faq_data['category'],
                question=faq_data['question'],
                defaults={
                    'answer': faq_data['answer'],
                    'order': faq_data['order'],
                    'is_active': True,
                }
            )
            if created:
                created_count += 1
                self.stdout.write(self.style.SUCCESS(f'Created FAQ: {faq.question}'))
            else:
                self.stdout.write(f'FAQ already exists: {faq.question}')
        
        self.stdout.write(self.style.SUCCESS(f'\nSeeded {created_count} new FAQs'))
