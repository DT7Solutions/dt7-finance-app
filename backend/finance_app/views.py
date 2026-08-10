from rest_framework import viewsets, generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.contrib.auth.models import User
from django.db.models import Sum, Q, F
from django.utils import timezone
from .models import UserProfile, Role, Category, BudgetAllocation, Expense, BudgetRequest, ActivityLog
from .serializers import (
    UserDetailSerializer, RoleSerializer, CategorySerializer, BudgetAllocationSerializer,
    ExpenseSerializer, BudgetRequestSerializer, ActivityLogSerializer
)

class RoleViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.AllowAny]
    serializer_class = RoleSerializer
    queryset = Role.objects.all()

    def get_queryset(self):
        self._ensure_default_roles()
        return Role.objects.all().order_by('id')

    def _ensure_default_roles(self):
        if not Role.objects.exists():
            default_roles = [
                {
                    'name': 'Admin / Founder',
                    'code': 'ADMIN',
                    'description': 'Full administrative control over all finances, users, approvals, and system settings.',
                    'is_system_role': True,
                    'can_view_all_expenses': True,
                    'can_approve_expenses': True,
                    'can_allocate_budget': True,
                    'can_manage_users': True,
                    'can_view_analytics': True,
                },
                {
                    'name': 'Staff',
                    'code': 'STAFF',
                    'description': 'General staff member access to submit expenses and request budget allocations.',
                    'is_system_role': True,
                    'can_view_all_expenses': False,
                    'can_approve_expenses': False,
                    'can_allocate_budget': False,
                    'can_manage_users': False,
                    'can_view_analytics': False,
                },
                {
                    'name': 'Accountant',
                    'code': 'ACCOUNTANT',
                    'description': 'Access to view financial reports, audit logs, and approve expense entries.',
                    'is_system_role': True,
                    'can_view_all_expenses': True,
                    'can_approve_expenses': True,
                    'can_allocate_budget': False,
                    'can_manage_users': False,
                    'can_view_analytics': True,
                },
                {
                    'name': 'Finance Manager',
                    'code': 'MANAGER',
                    'description': 'Can manage team budgets, view all expenses, and approve budget requests.',
                    'is_system_role': True,
                    'can_view_all_expenses': True,
                    'can_approve_expenses': True,
                    'can_allocate_budget': True,
                    'can_manage_users': False,
                    'can_view_analytics': True,
                },
                {
                    'name': 'Finance Auditor',
                    'code': 'FINANCE',
                    'description': 'View-only access to financial reports, analytics, and expense audit logs.',
                    'is_system_role': True,
                    'can_view_all_expenses': True,
                    'can_approve_expenses': False,
                    'can_allocate_budget': False,
                    'can_manage_users': False,
                    'can_view_analytics': True,
                },
                {
                    'name': 'Employee',
                    'code': 'EMPLOYEE',
                    'description': 'Standard employee access to submit expenses, request budgets, and view personal wallet.',
                    'is_system_role': True,
                    'can_view_all_expenses': False,
                    'can_approve_expenses': False,
                    'can_allocate_budget': False,
                    'can_manage_users': False,
                    'can_view_analytics': False,
                },
            ]
            for r in default_roles:
                Role.objects.get_or_create(code=r['code'], defaults=r)


class UserViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.AllowAny]
    serializer_class = UserDetailSerializer
    queryset = User.objects.all().order_by('id')

    def get_queryset(self):
        qs = User.objects.all().order_by('id')
        for user in qs:
            profile, _ = UserProfile.objects.get_or_create(user=user)
            expected_emp_id = f"DT7EMP{user.id:03d}"
            if profile.employee_id != expected_emp_id:
                profile.employee_id = expected_emp_id
                profile.save()
        return qs

    def create(self, request, *args, **kwargs):
        data = request.data.copy()
        raw_password = data.pop('password', None)
        role_str = str(data.pop('role', 'EMPLOYEE')).upper()
        dept_str = data.pop('department', 'Operations')
        init_amount = float(data.pop('initial_allocated_amount', None) or data.pop('allocated_amount', None) or 0.0)
        
        serializer = self.get_serializer(data=data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        
        if raw_password and isinstance(raw_password, str) and raw_password.strip():
            user.set_password(raw_password.strip())
            user.save()
            
        profile, _ = UserProfile.objects.get_or_create(user=user)
        role_obj = Role.objects.filter(Q(code__iexact=role_str) | Q(name__iexact=role_str)).first()
        if not role_obj and role_str in ['ADMIN', 'FOUNDER']:
            role_obj = Role.objects.filter(code='ADMIN').first()
        
        profile.role = role_str if role_str else (role_obj.code if role_obj else 'EMPLOYEE')
        if role_obj:
            profile.role_fk = role_obj
        if dept_str:
            profile.department = str(dept_str)
        if init_amount > 0:
            profile.allocated_budget = init_amount
        profile.save()

        if init_amount > 0:
            admin_user = request.user if (request.user and request.user.is_authenticated) else User.objects.filter(is_superuser=True).first() or user
            BudgetAllocation.objects.create(
                employee=user,
                allocated_amount=init_amount,
                note='Initial budget allocation on user creation',
                allocated_by=admin_user
            )

        headers = self.get_success_headers(serializer.data)
        return Response(self.get_serializer(user).data, status=status.HTTP_201_CREATED, headers=headers)

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        user = self.get_object()
        data = request.data.copy()
        
        role_str = data.pop('role', None)
        allocated_amount = data.pop('allocated_amount', None)
        raw_password = data.pop('password', None)

        serializer = self.get_serializer(user, data=data, partial=partial)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        if raw_password and isinstance(raw_password, str) and raw_password.strip():
            user.set_password(raw_password.strip())
            user.save()

        profile, _ = UserProfile.objects.get_or_create(user=user)
        if role_str:
            role_code = str(role_str).upper()
            role_obj = Role.objects.filter(Q(code__iexact=role_code) | Q(name__iexact=role_code)).first()
            profile.role = role_code
            if role_obj:
                profile.role_fk = role_obj
        
        if allocated_amount is not None:
            amt = float(allocated_amount)
            profile.allocated_budget = amt
            profile.save()
            admin_user = request.user if (request.user and request.user.is_authenticated) else User.objects.filter(is_superuser=True).first() or user
            current_sum = BudgetAllocation.objects.filter(employee=user).aggregate(total=Sum('allocated_amount'))['total'] or 0.0
            diff = amt - float(current_sum)
            if diff != 0:
                BudgetAllocation.objects.create(
                    employee=user,
                    allocated_amount=diff,
                    note=f'Budget set to ₹{amt:.2f}',
                    allocated_by=admin_user
                )
        profile.save()

        return Response(self.get_serializer(user).data)


class CategoryViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.AllowAny]
    serializer_class = CategorySerializer
    queryset = Category.objects.all()

    def get_queryset(self):
        self._ensure_default_categories()
        return Category.objects.all().order_by('id')

    def _ensure_default_categories(self):
        defaults = [
            {'name': 'Software & SaaS Subscriptions', 'type': 'EXPENSE', 'icon': 'computer', 'color': '#8B5CF6', 'is_custom': False},
            {'name': 'Cloud Hosting & Infrastructure (AWS/Azure/GCP)', 'type': 'EXPENSE', 'icon': 'cloud', 'color': '#0EA5E9', 'is_custom': False},
            {'name': 'AI Tools & API Subscriptions (OpenAI/Claude)', 'type': 'EXPENSE', 'icon': 'psychology', 'color': '#EC4899', 'is_custom': False},
            {'name': 'Purchase of Domain or SSL Certificates', 'type': 'EXPENSE', 'icon': 'dns', 'color': '#2563EB', 'is_custom': False},
            {'name': 'Hardware & Dev Peripherals (Laptops/Monitors)', 'type': 'EXPENSE', 'icon': 'devices', 'color': '#6366F1', 'is_custom': False},
            {'name': 'Cybersecurity & Antivirus Software', 'type': 'EXPENSE', 'icon': 'security', 'color': '#EF4444', 'is_custom': False},
            {'name': 'DevOps & CI/CD Tools (GitHub/Docker)', 'type': 'EXPENSE', 'icon': 'integration_instructions', 'color': '#10B981', 'is_custom': False},
            {'name': 'IT Consultancy & Technical Services', 'type': 'EXPENSE', 'icon': 'engineering', 'color': '#F59E0B', 'is_custom': False},
            {'name': 'Network & High-Speed Internet', 'type': 'EXPENSE', 'icon': 'wifi', 'color': '#14B8A6', 'is_custom': False},
            {'name': 'Office Supplies & Tech Utilities', 'type': 'EXPENSE', 'icon': 'shopping_bag', 'color': '#64748B', 'is_custom': False},
            {'name': 'Travel & Client On-site Visits', 'type': 'EXPENSE', 'icon': 'directions_car', 'color': '#D97706', 'is_custom': False},
            {'name': 'Meals & Team Offsites', 'type': 'EXPENSE', 'icon': 'restaurant', 'color': '#F43F5E', 'is_custom': False},
            {'name': 'Others', 'type': 'EXPENSE', 'icon': 'more_horiz', 'color': '#9CA3AF', 'is_custom': False},
        ]
        for c in defaults:
            Category.objects.get_or_create(name=c['name'], defaults=c)


class BudgetAllocationViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.AllowAny]
    serializer_class = BudgetAllocationSerializer
    queryset = BudgetAllocation.objects.all()

    def perform_create(self, serializer):
        user = self.request.user if (self.request.user and self.request.user.is_authenticated) else User.objects.filter(is_superuser=True).first() or User.objects.first()
        alloc = serializer.save(allocated_by=user)
        if alloc.employee and hasattr(alloc.employee, 'profile'):
            total_sum = BudgetAllocation.objects.filter(employee=alloc.employee).aggregate(t=Sum('allocated_amount'))['t'] or 0.0
            alloc.employee.profile.allocated_budget = float(total_sum)
            alloc.employee.profile.save()
        if user:
            ActivityLog.objects.create(
                user=user,
                title=f'Budget allocated to {alloc.employee.username}',
                description=f'₹{alloc.allocated_amount} allocated to {alloc.employee.username}'
            )


class ExpenseViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.AllowAny]
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

    def create(self, request, *args, **kwargs):
        data = request.data.copy()
        dt_val = data.get('date_time') or data.get('date')
        if dt_val and isinstance(dt_val, str):
            try:
                from dateutil import parser
                parsed_dt = parser.parse(dt_val)
                data['date_time'] = parsed_dt.isoformat()
            except Exception:
                data.pop('date_time', None)
                data.pop('date', None)

        cat_val = data.get('category')
        if not (isinstance(cat_val, int) and Category.objects.filter(pk=cat_val).exists()):
            cat_name = data.get('category_name') or 'General'
            cat_obj = Category.objects.filter(name__iexact=cat_name).first()
            if not cat_obj:
                cat_obj = Category.objects.create(name=cat_name, type='EXPENSE', color='#8B5CF6')
            data['category'] = cat_obj.id

        user_val = data.get('user')
        if not (isinstance(user_val, int) and User.objects.filter(pk=user_val).exists()):
            u_name = data.get('user_name')
            user_obj = None
            if u_name:
                user_obj = User.objects.filter(Q(username__iexact=u_name) | Q(first_name__iexact=u_name) | Q(email__iexact=u_name)).first()
            if not user_obj and request.user and request.user.is_authenticated:
                user_obj = request.user
            if not user_obj:
                user_obj = User.objects.first()
            if user_obj:
                data['user'] = user_obj.id

        serializer = self.get_serializer(data=data)
        if not serializer.is_valid():
            print("ExpenseSerializer Errors:", serializer.errors)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        data = request.data.copy()

        appr_val = data.get('approved_by') or data.get('reviewed_by')
        if isinstance(appr_val, str):
            data.pop('approved_by', None)
            data.pop('reviewed_by', None)

        serializer = self.get_serializer(instance, data=data, partial=partial)
        serializer.is_valid(raise_exception=True)
        expense = serializer.save()

        new_status = data.get('status')
        if new_status in ['APPROVED', 'REJECTED']:
            expense.status = new_status
            if request.user and request.user.is_authenticated:
                expense.approved_by = request.user
            else:
                expense.approved_by = User.objects.filter(is_superuser=True).first() or User.objects.first()
            expense.save()

        return Response(self.get_serializer(expense).data)

    def perform_create(self, serializer):
        user = self.request.user if (self.request.user and self.request.user.is_authenticated) else User.objects.filter(is_superuser=True).first() or User.objects.first()
        
        category_name = self.request.data.get('category_name') or self.request.data.get('category')
        category_obj = None
        if isinstance(category_name, str) and category_name.strip():
            category_obj, _ = Category.objects.get_or_create(
                name=category_name.strip(),
                defaults={'type': 'EXPENSE', 'color': '#FF5500'}
            )
        elif isinstance(category_name, int):
            category_obj = Category.objects.filter(pk=category_name).first()

        expense = serializer.save(
            user=serializer.validated_data.get('user') or user,
            category=category_obj or serializer.validated_data.get('category')
        )
        if user:
            ActivityLog.objects.create(
                user=user,
                title=f'Expense added by {user.username}',
                description=f'{expense.title} - ₹{expense.amount}'
            )


class BudgetRequestViewSet(viewsets.ModelViewSet):
    permission_classes = [permissions.AllowAny]
    serializer_class = BudgetRequestSerializer

    def get_queryset(self):
        queryset = BudgetRequest.objects.all().order_by('-created_at')
        status_param = self.request.query_params.get('status')
        if status_param:
            queryset = queryset.filter(status=status_param)
        return queryset

    def create(self, request, *args, **kwargs):
        data = request.data.copy()

        # User resolution
        user = None
        if request.user and request.user.is_authenticated:
            user = request.user
        else:
            uname = data.get('user_name') or data.get('username') or data.get('user')
            if uname:
                user = User.objects.filter(
                    Q(username__iexact=str(uname)) |
                    Q(first_name__iexact=str(uname)) |
                    Q(email__iexact=str(uname))
                ).first()
        if not user:
            user = User.objects.filter(is_superuser=True).first() or User.objects.first()

        # Category resolution
        cat_id = data.get('category')
        category = None
        if cat_id:
            try:
                category = Category.objects.filter(id=int(cat_id)).first()
            except (ValueError, TypeError):
                category = Category.objects.filter(name__iexact=str(cat_id)).first()
        if not category:
            category = Category.objects.first()

        try:
            amount = float(data.get('request_amount') or data.get('amount') or 0.0)
        except (ValueError, TypeError):
            amount = 0.0
        reason = str(data.get('reason') or data.get('description') or '')

        br = BudgetRequest.objects.create(
            user=user,
            category=category,
            request_amount=amount,
            reason=reason,
            status='PENDING'
        )

        if user:
            ActivityLog.objects.create(
                user=user,
                title=f'Budget request submitted by {user.username}',
                description=f'Requested ₹{amount:.0f} for {category.name if category else "Budget"}'
            )

        serializer = self.get_serializer(br)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def perform_create(self, serializer):
        user = None
        if self.request.user and self.request.user.is_authenticated:
            user = self.request.user
        else:
            uname = self.request.data.get('user_name') or self.request.data.get('username') or self.request.data.get('user')
            if uname:
                user = User.objects.filter(Q(username__iexact=str(uname)) | Q(first_name__iexact=str(uname))).first()
        if not user:
            user = User.objects.filter(is_superuser=True).first() or User.objects.first()

        br = serializer.save(user=user)
        if user:
            ActivityLog.objects.create(
                user=user,
                title=f'Budget request submitted by {user.username}',
                description=f'Requested ₹{br.request_amount} for {br.category.name if br.category else "Budget"}'
            )


class ApprovalActionView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request, pk=None):
        item_type = request.data.get('type', 'expense')
        action = request.data.get('action', 'approve')
        new_status = 'APPROVED' if action in ['approve', 'APPROVED'] else 'REJECTED'
        user = request.user if (request.user and request.user.is_authenticated) else User.objects.filter(is_superuser=True).first() or User.objects.first()

        if item_type == 'expense':
            try:
                expense = Expense.objects.get(pk=pk)
                expense.status = new_status
                if user:
                    expense.approved_by = user
                expense.save()

                if user:
                    ActivityLog.objects.create(
                        user=user,
                        title=f'Expense {new_status}',
                        description=f'{expense.title} for {expense.user.username} - ₹{expense.amount}'
                    )
                return Response({'status': 'success', 'new_status': expense.status})
            except Expense.DoesNotExist:
                return Response({'error': 'Expense not found'}, status=status.HTTP_404_NOT_FOUND)

        elif item_type == 'budget_request':
            try:
                br = BudgetRequest.objects.get(pk=pk)
                br.status = new_status
                br.save()

                if action in ['approve', 'APPROVED']:
                    admin_user = user or User.objects.filter(is_superuser=True).first() or User.objects.first()
                    BudgetAllocation.objects.create(
                        employee=br.user,
                        allocated_amount=br.request_amount,
                        note=f'Approved from Budget Request: {br.reason}',
                        allocated_by=admin_user
                    )

                if user:
                    ActivityLog.objects.create(
                        user=user,
                        title=f'Budget request {new_status}',
                        description=f'Budget request ₹{br.request_amount} for {br.user.username}'
                    )
                return Response({'status': 'success', 'new_status': br.status})
            except BudgetRequest.DoesNotExist:
                return Response({'error': 'Budget Request not found'}, status=status.HTTP_404_NOT_FOUND)

        return Response({'error': 'Invalid request parameters'}, status=status.HTTP_400_BAD_REQUEST)


class FounderDashboardView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        total_alloc_records = BudgetAllocation.objects.aggregate(total=Sum('allocated_amount'))['total']
        if total_alloc_records is not None and float(total_alloc_records) > 0:
            total_allocated = float(total_alloc_records)
        else:
            total_allocated = float(UserProfile.objects.aggregate(total=Sum('allocated_budget'))['total'] or 0.0)

        active_expenses = Expense.objects.exclude(status='REJECTED')
        total_expenses = float(active_expenses.aggregate(total=Sum('amount'))['total'] or 0.0)
        remaining_budget = total_allocated - total_expenses
        total_users = User.objects.count()

        # Dynamic calculation of users exceeding budget
        over_budget_count = 0
        for u in User.objects.all():
            u_alloc = BudgetAllocation.objects.filter(employee=u).aggregate(total=Sum('allocated_amount'))['total']
            if u_alloc is None and hasattr(u, 'profile'):
                u_alloc = u.profile.allocated_budget
            u_alloc = float(u_alloc or 0.0)
            u_spent = float(Expense.objects.filter(user=u).exclude(status='REJECTED').aggregate(total=Sum('amount'))['total'] or 0.0)
            if u_alloc > 0 and u_spent > u_alloc:
                over_budget_count += 1

        # Dynamic category breakdown from database
        category_totals = {}
        for exp in active_expenses:
            cat_name = exp.category.name if exp.category else 'General'
            cat_color = exp.category.color if (exp.category and exp.category.color) else '#8B5CF6'
            if cat_name not in category_totals:
                category_totals[cat_name] = {'amount': 0.0, 'color': cat_color}
            category_totals[cat_name]['amount'] += float(exp.amount)

        category_breakdown = []
        for cat_name, info in category_totals.items():
            pct = round((info['amount'] / total_expenses * 100)) if total_expenses > 0 else 0
            category_breakdown.append({
                'category': cat_name,
                'percentage': pct,
                'amount': info['amount'],
                'color': info['color']
            })

        category_breakdown.sort(key=lambda x: x['amount'], reverse=True)

        return Response({
            'total_allocated': total_allocated,
            'total_expenses': total_expenses,
            'remaining_budget': remaining_budget,
            'total_users': total_users,
            'over_budget': over_budget_count,
            'category_breakdown': category_breakdown,
        })


class ReportsView(APIView):
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        user_expenses = (
            Expense.objects.filter(status='APPROVED')
            .values('user__first_name', 'user__last_name', 'user__username')
            .annotate(spent_amount=Sum('amount'))
            .order_by('-spent_amount')[:5]
        )
        leaderboard = []
        for rank, item in enumerate(user_expenses, 1):
            name = f"{item['user__first_name']} {item['user__last_name']}".strip() or item['user__username']
            leaderboard.append({
                'rank': rank,
                'name': name,
                'spent_amount': float(item['spent_amount'] or 0.0),
            })
        return Response({
            'period': 'This Month',
            'top_spending_employees': leaderboard
        })


class ActivityLogViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ActivityLogSerializer
    queryset = ActivityLog.objects.all()
