from django.test import TestCase
from django.contrib.auth.models import User
from rest_framework.test import APIClient
from rest_framework import status
from .models import Category, Account, Transaction, Budget

class FinanceAppTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username='testuser', password='password123', email='test@dt7.com')
        self.client.force_authenticate(user=self.user)

        self.category = Category.objects.create(name='Groceries', type='EXPENSE', icon='shopping_cart', color='#FF0000')
        self.account = Account.objects.create(user=self.user, name='Main Checking', account_type='CHECKING', balance=1500.00)

    def test_account_creation(self):
        response = self.client.post('/api/v1/accounts/', {
            'name': 'Savings Goal',
            'account_type': 'SAVINGS',
            'balance': 5000.00,
            'currency': 'USD'
        })
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(Account.objects.filter(user=self.user).count(), 2)

    def test_transaction_creation_and_balance_update(self):
        response = self.client.post('/api/v1/transactions/', {
            'account': self.account.id,
            'category': self.category.id,
            'title': 'Supermarket Purchase',
            'amount': 150.00,
            'transaction_type': 'EXPENSE',
            'date': '2026-08-04'
        })
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.account.refresh_from_db()
        self.assertEqual(float(self.account.balance), 1350.00)

    def test_analytics_summary(self):
        Transaction.objects.create(
            user=self.user,
            account=self.account,
            category=self.category,
            title='Test Income',
            amount=2000.00,
            transaction_type='INCOME',
            date='2026-08-04'
        )
        response = self.client.get('/api/v1/analytics/summary/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('total_balance', response.data)
        self.assertIn('total_income', response.data)
        self.assertEqual(response.data['total_income'], 2000.00)
