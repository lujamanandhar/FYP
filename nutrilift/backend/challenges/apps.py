from django.apps import AppConfig


class ChallengesConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'challenges'

    def ready(self):
        import challenges.signals  # noqa
        import challenges.reward_signals  # noqa
        challenges.signals.connect_signals()
        challenges.reward_signals.connect_reward_signals()
