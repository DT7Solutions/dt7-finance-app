from rest_framework import serializers
from django.contrib.auth.models import User
from django.db.models import Sum
from .models import Category, Account, Transaction, Budget

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'first_name', 'last_name']


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)

    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'first_name', 'last_name']

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email', ''),
            password=validated_data['password'],
            first_name=validated_data.get('first_name', ''),
            last_name=validated_data.get('last_name', '')
        )
        return user


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name', 'type', 'icon', 'color', 'is_custom']


class AccountSerializer(serializers.ModelSerializer):
    class Meta:
        model = Account
        fields = ['id', 'name', 'account_type', 'balance', 'currency', 'account_number', 'is_active', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']


class TransactionSerializer(serializers.ModelSerializer):
    category_detail = CategorySerializer(source='category', read_only=True)
    account_name = serializers.CharField(source='account.name', read_only=True)

    class Meta:
        model = Transaction
        fields = [
            'id', 'account', 'account_name', 'category', 'category_detail',
            'title', 'amount', 'transaction_type', 'date', 'notes', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']

    def create(self, validated_data):
        transaction = Transaction.objects.create(**validated_data)
        # Update account balance based on transaction
        account = transaction.account
        if transaction.transaction_type == 'INCOME':
            account.balance += transaction.amount
        elif transaction.transaction_type == 'EXPENSE':
            account.balance -= transaction.amount
        account.save()
        return transaction


class BudgetSerializer(serializers.ModelSerializer):
    category_detail = CategorySerializer(source='category', read_only=True)
    spent_amount = serializers.SerializerMethodField()
    remaining_amount = serializers.SerializerMethodField()

    class Meta:
        model = Budget
        fields = ['id', 'category', 'category_detail', 'limit_amount', 'month_year', 'spent_amount', 'remaining_amount']

    def get_spent_amount(self, obj):
        user = self.context['request'].user if 'request' in self.context else obj.user
        spent = Transaction.objects.filter(
            user=user,
            category=obj.category,
            transaction_type='EXPENSE',
            date__startswith=obj.month_year
        ).aggregate(total=Sum('amount'))['total']
        return float(spent or 0.00)

    def get_remaining_amount(self, obj):
        spent = self.get_spent_amount(obj)
        return float(obj.limit_amount) - spent
