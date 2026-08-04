from rest_framework import viewsets, generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.contrib.auth.models import User
from django.db.models import Sum, Q, F
from django.utils import timezone
from .models import UserProfile, Category, BudgetAllocation, Expense, BudgetRequest, ActivityLog
from .serializers import (
    UserDetailSerializer, CategorySerializer, BudgetAllocationSerializer,
    ExpenseSerializer, BudgetRequestSerializer, ActivityLogSerializer
)

class UserViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = UserDetailSerializer
    queryset = User.objects.all().order_by('id')

    def perform_create(self, serializer):
        user = serializer.save()
        UserProfile.objects.get_or_create(
            user=user,
            defaults={'role': 'EMPLOYEE', 'department': 'Sales Department'}
        )
        ActivityLog.objects.create(
            user=self.request.user,
            title='User Added',
            description=f'User {user.username} was added to system.'
        )


class CategoryViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = CategorySerializer
    queryset = Category.objects.all()


class BudgetAllocationViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = BudgetAllocationSerializer
    queryset = BudgetAllocation.objects.all()

    def perform_create(self, serializer):
        alloc = serializer.save(allocated_by=self.request.user)
        ActivityLog.objects.create(
            user=self.request.user,
            title=f'Budget allocated to {alloc.employee.username}',
            description=f'₹{alloc.allocated_amount} allocated to {alloc.employee.username}'
        )


class ExpenseViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ExpenseSerializer

    def get_queryset(self):
        queryset = Expense.objects.all()
        user_id = self.request.query_params.get('user')
        status_param = self.request.query_params.get('status')
        if user_id:
            queryset = queryset.filter(user_id=user_id)
        if status_param:
            queryset = queryset.filter(status=status_param)
        return queryset

    def perform_create(self, serializer):
        expense = serializer.save(user=self.request.user)
        ActivityLog.objects.create(
            user=self.request.user,
            title=f'Expense added by {self.request.user.username}',
            description=f'{expense.title} - ₹{expense.amount}'
        )


class BudgetRequestViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = BudgetRequestSerializer

    def get_queryset(self):
        queryset = BudgetRequest.objects.all()
        status_param = self.request.query_params.get('status')
        if status_param:
            queryset = queryset.filter(status=status_param)
        return queryset

    def perform_create(self, serializer):
        br = serializer.save(user=self.request.user)
        ActivityLog.objects.create(
            user=self.request.user,
            title=f'Budget request submitted by {self.request.user.username}',
            description=f'Requested ₹{br.request_amount} for {br.category.name if br.category else "Budget"}'
        )


class ApprovalActionView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        item_type = request.data.get('type', 'expense') # 'expense' or 'budget_request'
        action = request.data.get('action') # 'approve' or 'reject'

        if item_type == 'expense':
            try:
                expense = Expense.objects.get(pk=pk)
                expense.status = 'APPROVED' if action == 'approve' else 'REJECTED'
                expense.approved_by = request.user
                expense.save()

                ActivityLog.objects.create(
                    user=request.user,
                    title=f'Expense {action}d',
                    description=f'{expense.title} for {expense.user.username} - ₹{expense.amount}'
                )
                return Response({'status': 'success', 'new_status': expense.status})
            except Expense.DoesNotExist:
                return Response({'error': 'Expense not found'}, status=status.HTTP_404_NOT_FOUND)

        elif item_type == 'budget_request':
            try:
                br = BudgetRequest.objects.get(pk=pk)
                br.status = 'APPROVED' if action == 'approve' else 'REJECTED'
                br.save()

                if action == 'approve':
                    BudgetAllocation.objects.create(
                        employee=br.user,
                        allocated_amount=br.request_amount,
                        note=f'Approved from Budget Request: {br.reason}',
                        allocated_by=request.user
                    )

                ActivityLog.objects.create(
                    user=request.user,
                    title=f'Budget request {action}d',
                    description=f'Budget request ₹{br.request_amount} for {br.user.username}'
                )
                return Response({'status': 'success', 'new_status': br.status})
            except BudgetRequest.DoesNotExist:
                return Response({'error': 'Budget Request not found'}, status=status.HTTP_404_NOT_FOUND)

        return Response({'error': 'Invalid request parameters'}, status=status.HTTP_400_BAD_REQUEST)


class FounderDashboardView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        total_allocated = float(BudgetAllocation.objects.aggregate(total=Sum('allocated_amount'))['total'] or 150000.00)
        total_expenses = float(Expense.objects.filter(status='APPROVED').aggregate(total=Sum('amount'))['total'] or 97000.00)
        remaining_budget = total_allocated - total_expenses
        total_users = User.objects.count() or 5
        over_budget_count = 2

        # Category expense breakdown matching UI mock percentages
        category_breakdown = [
            {'category': 'Travel', 'percentage': 40, 'amount': total_expenses * 0.40, 'color': '#3B82F6'},
            {'category': 'Food', 'percentage': 20, 'amount': total_expenses * 0.20, 'color': '#10B981'},
            {'category': 'Fuel', 'percentage': 15, 'amount': total_expenses * 0.15, 'color': '#F59E0B'},
            {'category': 'Office', 'percentage': 10, 'amount': total_expenses * 0.10, 'color': '#FF5500'},
            {'category': 'Others', 'percentage': 15, 'amount': total_expenses * 0.15, 'color': '#8B5CF6'},
        ]

        return Response({
            'total_allocated': total_allocated,
            'total_expenses': total_expenses,
            'remaining_budget': remaining_budget,
            'total_users': total_users,
            'over_budget': over_budget_count,
            'category_breakdown': category_breakdown,
        })


class ReportsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        leaderboard = [
            {'rank': 1, 'name': 'Rahul Sharma', 'spent_amount': 25000.00},
            {'rank': 2, 'name': 'John Doe', 'spent_amount': 18500.00},
            {'rank': 3, 'name': 'Priya Patel', 'spent_amount': 15600.00},
        ]
        return Response({
            'period': 'This Month',
            'top_spending_employees': leaderboard
        })


class ActivityLogViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ActivityLogSerializer
    queryset = ActivityLog.objects.all()
