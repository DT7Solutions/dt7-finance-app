from rest_framework import viewsets, generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Sum, Q
from django.utils import timezone
from datetime import datetime
from .models import Category, Account, Transaction, Budget
from .serializers import (
    UserSerializer, RegisterSerializer, CategorySerializer,
    AccountSerializer, TransactionSerializer, BudgetSerializer
)

class RegisterView(generics.CreateAPIView):
    permission_classes = [permissions.AllowAny]
    serializer_class = RegisterSerializer


class UserProfileView(generics.RetrieveUpdateAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = UserSerializer

    def get_object(self):
        return self.request.user


class CategoryViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = CategorySerializer

    def get_queryset(self):
        return Category.objects.filter(
            Q(is_custom=False) | Q(user=self.request.user)
        )

    def perform_create(self, serializer):
        serializer.save(is_custom=True, user=self.request.user)


class AccountViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = AccountSerializer

    def get_queryset(self):
        return Account.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class TransactionViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = TransactionSerializer

    def get_queryset(self):
        queryset = Transaction.objects.filter(user=self.request.user)
        account_id = self.request.query_params.get('account')
        transaction_type = self.request.query_params.get('type')
        month_year = self.request.query_params.get('month_year')

        if account_id:
            queryset = queryset.filter(account_id=account_id)
        if transaction_type:
            queryset = queryset.filter(transaction_type=transaction_type)
        if month_year:
            queryset = queryset.filter(date__startswith=month_year)

        return queryset

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class BudgetViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = BudgetSerializer

    def get_queryset(self):
        return Budget.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class AnalyticsSummaryView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        month_year = request.query_params.get('month_year', timezone.now().strftime('%Y-%m'))

        # Accounts total balance
        total_balance = float(Account.objects.filter(user=user).aggregate(total=Sum('balance'))['total'] or 0)

        # Monthly income & expense
        monthly_tx = Transaction.objects.filter(user=user, date__startswith=month_year)
        total_income = float(monthly_tx.filter(transaction_type='INCOME').aggregate(total=Sum('amount'))['total'] or 0)
        total_expense = float(monthly_tx.filter(transaction_type='EXPENSE').aggregate(total=Sum('amount'))['total'] or 0)

        # Category breakdown for expenses
        expense_by_category = (
            monthly_tx.filter(transaction_type='EXPENSE')
            .values('category__name', 'category__color')
            .annotate(total=Sum('amount'))
            .order_by('-total')
        )

        return Response({
            'month_year': month_year,
            'total_balance': total_balance,
            'total_income': total_income,
            'total_expense': total_expense,
            'net_savings': total_income - total_expense,
            'category_breakdown': list(expense_by_category)
        })
