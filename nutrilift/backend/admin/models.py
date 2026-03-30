from django.db import models
import uuid


class FAQ(models.Model):
    """Frequently Asked Questions managed by admin"""
    CATEGORY_CHOICES = [
        ('general', 'General'),
        ('getting_started', 'Getting Started'),
        ('nutrition', 'Nutrition Tracking'),
        ('workout', 'Workout Tracking'),
        ('challenges', 'Challenges'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    category = models.CharField(max_length=50, choices=CATEGORY_CHOICES)
    question = models.CharField(max_length=500)
    answer = models.TextField()
    order = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'faqs'
        ordering = ['category', 'order', '-created_at']
        verbose_name = 'FAQ'
        verbose_name_plural = 'FAQs'
    
    def __str__(self):
        return f'[{self.category}] {self.question}'
