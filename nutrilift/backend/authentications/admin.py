from django.contrib import admin
from .models import User, SupportTicket


@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ['email', 'name', 'fitness_level', 'is_staff', 'created_at']
    list_filter = ['is_staff', 'fitness_level', 'gender']
    search_fields = ['email', 'name']
    ordering = ['-created_at']


@admin.register(SupportTicket)
class SupportTicketAdmin(admin.ModelAdmin):
    list_display = ['subject', 'name', 'email', 'status', 'created_at']
    list_filter = ['status', 'created_at']
    list_editable = ['status']
    search_fields = ['name', 'email', 'subject', 'message']
    readonly_fields = ['id', 'user', 'name', 'email', 'subject', 'message', 'created_at']
    ordering = ['-created_at']
    fieldsets = (
        ('Ticket Info', {'fields': ('id', 'user', 'name', 'email', 'subject', 'message', 'created_at')}),
        ('Admin', {'fields': ('status', 'admin_notes')}),
    )
