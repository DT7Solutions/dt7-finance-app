from django.contrib import admin
from .models import UserProfile, Category, BudgetAllocation, Expense, BudgetRequest, ActivityLog

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
