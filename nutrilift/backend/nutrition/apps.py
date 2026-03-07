from django.apps import AppConfig


class NutritionConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'nutrition'
    
    def ready(self):
        """Import signals when app is ready."""
        import nutrition.signals
