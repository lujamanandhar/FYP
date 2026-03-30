from rest_framework.permissions import IsAuthenticated


class IsAdminUser(IsAuthenticated):
    """
    Permission class to check if user is admin/staff.
    Only users with is_staff=True can access admin endpoints.
    """
    def has_permission(self, request, view):
        return super().has_permission(request, view) and request.user.is_staff
