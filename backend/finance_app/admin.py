from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.contrib.auth.models import User
from .models import UserProfile, Category, BudgetAllocation, Expense, BudgetRequest, ActivityLog

class UserProfileInline(admin.StackedInline):
    model = UserProfile
    can_delete = False
    verbose_name_plural = 'Profile & Role'
    fields = ('role', 'department', 'employee_id', 'phone', 'allocated_budget')

# Unregister default User admin and register customized User admin displaying Role field
admin.site.unregister(User)

@admin.register(User)
class UserAdmin(BaseUserAdmin):
    inlines = (UserProfileInline,)
    list_display = ('username', 'email', 'first_name', 'last_name', 'get_role', 'is_staff', 'is_superuser')
    list_filter = ('is_staff', 'is_superuser', 'is_active', 'profile__role')

    @admin.display(description='Role')
    def get_role(self, obj):
        if hasattr(obj, 'profile'):
            if hasattr(obj.profile, 'get_role_display'):
                return obj.profile.get_role_display()
            return dict(UserProfile.ROLE_CHOICES).get(obj.profile.role, obj.profile.role)
        return 'Founder' if obj.is_superuser else ('Admin' if obj.is_staff else 'Employee')

@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'role', 'department', 'employee_id', 'allocated_budget')
    list_filter = ('role', 'department')
    search_fields = ('user__username', 'employee_id')

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'type', 'icon', 'color', 'is_custom')
    list_filter = ('type', 'is_custom')
    search_fields = ('name',)

@admin.register(BudgetAllocation)
class BudgetAllocationAdmin(admin.ModelAdmin):
    list_display = ('employee', 'allocated_amount', 'allocated_by', 'created_at')
    search_fields = ('employee__username',)

@admin.register(Expense)
class ExpenseAdmin(admin.ModelAdmin):
    list_display = ('title', 'user', 'category', 'amount', 'status', 'date_time')
    list_filter = ('status', 'category')
    search_fields = ('title', 'user__username')

@admin.register(BudgetRequest)
class BudgetRequestAdmin(admin.ModelAdmin):
    list_display = ('user', 'category', 'request_amount', 'status', 'created_at')
    list_filter = ('status',)
    search_fields = ('user__username',)

@admin.register(ActivityLog)
class ActivityLogAdmin(admin.ModelAdmin):
    list_display = ('title', 'user', 'timestamp', 'log_type')
    search_fields = ('title', 'user__username')
