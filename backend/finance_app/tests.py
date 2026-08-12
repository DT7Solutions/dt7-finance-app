from django.test import TestCase
from django.contrib.auth.models import User
from rest_framework.test import APIClient
from rest_framework import status
from .models import UserProfile, Category, BudgetAllocation, Expense, BudgetRequest, ActivityLog

class DT7AgencyFinanceTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username='johndoe', password='password123', email='john.doe@example.com')
        self.client.force_authenticate(user=self.user)

        self.profile, _ = UserProfile.objects.get_or_create(
            user=self.user,
            defaults={'role': 'EMPLOYEE', 'department': 'Sales Department', 'employee_id': 'DT7EMP001'}
        )
        self.category = Category.objects.create(name='Fuel', type='EXPENSE', icon='local_gas_station', color='#F59E0B')

    def test_budget_allocation(self):
        response = self.client.post('/api/v1/allocations/', {
            'employee': self.user.id,
            'allocated_amount': 10000.00,
            'note': 'Initial Monthly Budget'
        })
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(BudgetAllocation.objects.count(), 1)

    def test_expense_creation_and_approval(self):
        expense = Expense.objects.create(
            user=self.user,
            title='Fuel Expense',
            amount=1000.00,
            category=self.category,
            date_time='2026-08-04T05:45:00Z',
            status='PENDING'
        )
        response = self.client.post(f'/api/v1/approvals/{expense.id}/action/', {
            'type': 'expense',
            'action': 'approve'
        })
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        expense.refresh_from_db()
        self.assertEqual(expense.status, 'APPROVED')

    def test_founder_dashboard(self):
        response = self.client.get('/api/v1/dashboard/founder/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('total_allocated', response.data)
        self.assertIn('total_expenses', response.data)
        self.assertIn('category_breakdown', response.data)

    def test_send_and_verify_otp(self):
        # 1. Send OTP
        anon_client = APIClient()
        send_res = anon_client.post('/api/v1/auth/send-otp/', {
            'identifier': 'john.doe@example.com'
        })
        self.assertEqual(send_res.status_code, status.HTTP_200_OK)
        self.assertTrue(send_res.data.get('success'))

        from .models import EmailOTP
        otp_obj = EmailOTP.objects.filter(email='john.doe@example.com').first()
        self.assertIsNotNone(otp_obj)
        otp_code = otp_obj.otp
        self.assertEqual(len(otp_code), 6)

        # 2. Verify OTP with correct code
        verify_res = anon_client.post('/api/v1/auth/verify-otp/', {
            'identifier': 'johndoe',
            'otp': otp_code
        })
        self.assertEqual(verify_res.status_code, status.HTTP_200_OK)
        self.assertIn('access', verify_res.data)
        self.assertEqual(verify_res.data.get('role'), 'EMPLOYEE')

        otp_obj.refresh_from_db()
        self.assertTrue(otp_obj.is_used)

        # 3. Trying to reuse OTP should fail
        reuse_res = anon_client.post('/api/v1/auth/verify-otp/', {
            'identifier': 'johndoe',
            'otp': otp_code
        })
        self.assertEqual(reuse_res.status_code, status.HTTP_400_BAD_REQUEST)

