from django.apps import AppConfig


class WorkoutsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'workouts'

    def ready(self):
        """
        Import signal handlers when the app is ready.
        This ensures signals are registered when Django starts.
        """
        import workouts.signals  # noqa: F401
