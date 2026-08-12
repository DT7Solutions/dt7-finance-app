from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    UserViewSet, RoleViewSet, CategoryViewSet, BudgetAllocationViewSet,
    ExpenseViewSet, BudgetRequestViewSet, ApprovalActionView,
    FounderDashboardView, ReportsView, ActivityLogViewSet,
    SendOTPView, VerifyOTPView
)

router = DefaultRouter()
router.register(r'users', UserViewSet, basename='user')
router.register(r'roles', RoleViewSet, basename='role')
router.register(r'categories', CategoryViewSet, basename='category')
router.register(r'allocations', BudgetAllocationViewSet, basename='allocation')
router.register(r'expenses', ExpenseViewSet, basename='expense')
router.register(r'budget-requests', BudgetRequestViewSet, basename='budget-request')
router.register(r'activity-logs', ActivityLogViewSet, basename='activity-log')

urlpatterns = [
    path('auth/send-otp/', SendOTPView.as_view(), name='auth-send-otp'),
    path('auth/verify-otp/', VerifyOTPView.as_view(), name='auth-verify-otp'),
    path('send-otp/', SendOTPView.as_view(), name='send-otp-alias'),
    path('verify-otp/', VerifyOTPView.as_view(), name='verify-otp-alias'),
    path('dashboard/founder/', FounderDashboardView.as_view(), name='founder-dashboard'),
    path('reports/', ReportsView.as_view(), name='reports'),
    path('approvals/<int:pk>/action/', ApprovalActionView.as_view(), name='approval-action'),
    path('', include(router.urls)),
]

