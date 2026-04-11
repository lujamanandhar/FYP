from django.contrib.auth.hashers import PBKDF2PasswordHasher


class FastPBKDF2PasswordHasher(PBKDF2PasswordHasher):
    """
    Reduced-iteration PBKDF2 hasher for development.
    50,000 iterations vs default 720,000 — ~14x faster login.
    Do NOT use in production.
    """
    iterations = 50000
