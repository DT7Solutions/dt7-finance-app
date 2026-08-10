from rest_framework import serializers
from django.contrib.auth.models import User
from django.db.models import Sum
from .models import UserProfile, Role, Category, BudgetAllocation, Expense, BudgetRequest, ActivityLog

class RoleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Role
        fields = [
            'id', 'name', 'code', 'description', 'is_system_role',
            'can_view_all_expenses', 'can_approve_expenses', 'can_allocate_budget',
            'can_manage_users', 'can_view_analytics'
        ]


class UserProfileSerializer(serializers.ModelSerializer):
    role_details = RoleSerializer(source='role_fk', read_only=True)

    class Meta:
        model = UserProfile
        fields = ['role', 'role_fk', 'role_details', 'department', 'employee_id', 'phone', 'join_date', 'allocated_budget']


class UserDetailSerializer(serializers.ModelSerializer):
    profile = UserProfileSerializer(read_only=True)
    allocated_amount = serializers.SerializerMethodField()
    used_amount = serializers.SerializerMethodField()
    remaining_amount = serializers.SerializerMethodField()
    role = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name', 'role', 'profile', 'allocated_amount', 'used_amount', 'remaining_amount']

    def get_role(self, obj):
        if hasattr(obj, 'profile') and obj.profile.role:
            return obj.profile.role
        return 'ADMIN' if (obj.is_superuser or obj.username in ['admin', 'founder', 'diya_founder']) else 'EMPLOYEE'

    def get_allocated_amount(self, obj):
        alloc_sum = BudgetAllocation.objects.filter(employee=obj).aggregate(total=Sum('allocated_amount'))['total']
        alloc_val = float(alloc_sum) if alloc_sum is not None else 0.0
        prof_val = float(obj.profile.allocated_budget) if (hasattr(obj, 'profile') and obj.profile and obj.profile.allocated_budget) else 0.0
        return max(alloc_val, prof_val)

    def get_used_amount(self, obj):
        used = Expense.objects.filter(user=obj, status='APPROVED').aggregate(total=Sum('amount'))['total']
        return float(used or 0.00)

    def get_remaining_amount(self, obj):
        return self.get_allocated_amount(obj) - self.get_used_amount(obj)


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name', 'type', 'icon', 'color', 'is_custom']


class BudgetAllocationSerializer(serializers.ModelSerializer):
    employee_name = serializers.CharField(source='employee.username', read_only=True)
    allocated_by_name = serializers.CharField(source='allocated_by.username', read_only=True)

    class Meta:
        model = BudgetAllocation
        fields = ['id', 'employee', 'employee_name', 'allocated_amount', 'note', 'allocated_by', 'allocated_by_name', 'created_at']
        read_only_fields = ['id', 'created_at']


from django.utils import timezone

class ExpenseSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.username', read_only=True)
    category_name = serializers.CharField(source='category.name', read_only=True)
    category_color = serializers.CharField(source='category.color', read_only=True)
    date_time = serializers.DateTimeField(required=False, default=timezone.now)
    category = serializers.PrimaryKeyRelatedField(queryset=Category.objects.all(), required=False, allow_null=True)
    user = serializers.PrimaryKeyRelatedField(queryset=User.objects.all(), required=False, allow_null=True)

    class Meta:
        model = Expense
        fields = [
            'id', 'title', 'amount', 'category', 'category_name', 'category_color',
            'user', 'user_name', 'description', 'date_time', 'status',
            'payment_mode', 'receipt_image', 'approved_by', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class BudgetRequestSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.username', read_only=True)
    category_name = serializers.CharField(source='category.name', read_only=True)

    class Meta:
        model = BudgetRequest
        fields = ['id', 'user', 'user_name', 'request_amount', 'category', 'category_name', 'reason', 'status', 'created_at']
        read_only_fields = ['id', 'created_at']


class ActivityLogSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.username', read_only=True)

    class Meta:
        model = ActivityLog
        fields = ['id', 'user', 'user_name', 'title', 'description', 'timestamp', 'log_type']
