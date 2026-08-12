from django.db import models
from django.contrib.auth.models import User

class Role(models.Model):
    name = models.CharField(max_length=100)
    code = models.CharField(max_length=50, unique=True)
    description = models.TextField(blank=True, default='')
    is_system_role = models.BooleanField(default=False)
    
    # Permission Flags
    can_view_all_expenses = models.BooleanField(default=False)
    can_approve_expenses = models.BooleanField(default=False)
    can_allocate_budget = models.BooleanField(default=False)
    can_manage_users = models.BooleanField(default=False)
    can_view_analytics = models.BooleanField(default=False)

    class Meta:
        ordering = ['id']

    def __str__(self):
        return f"{self.name} ({self.code})"


class UserProfile(models.Model):
    ROLE_CHOICES = (
        ('FOUNDER', 'Founder'),
        ('ADMIN', 'Admin'),
        ('EMPLOYEE', 'Employee'),
    )

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    role = models.CharField(max_length=50, choices=ROLE_CHOICES, default='EMPLOYEE')
    role_fk = models.ForeignKey(Role, on_delete=models.SET_NULL, null=True, blank=True, related_name='profiles')
    department = models.CharField(max_length=100, default='Sales Department')
    employee_id = models.CharField(max_length=50, blank=True, default='')
    phone = models.CharField(max_length=20, default='+91 98765 43210')
    join_date = models.DateField(auto_now_add=True)
    allocated_budget = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)

    def save(self, *args, **kwargs):
        if not self.employee_id or self.employee_id == 'DT7EMP001':
            target_id = self.user.id if self.user and self.user.id else (self.id or 1)
            self.employee_id = f"DT7EMP{target_id:03d}"
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.user.username} ({self.role})"


class Category(models.Model):
    TYPE_CHOICES = (
        ('INCOME', 'Income'),
        ('EXPENSE', 'Expense'),
    )

    name = models.CharField(max_length=100)
    type = models.CharField(max_length=10, choices=TYPE_CHOICES, default='EXPENSE')
    icon = models.CharField(max_length=50, default='category')
    color = models.CharField(max_length=20, default='#FF5500')
    is_custom = models.BooleanField(default=False)

    class Meta:
        verbose_name_plural = 'Categories'
        ordering = ['name']

    def __str__(self):
        return self.name


class BudgetAllocation(models.Model):
    employee = models.ForeignKey(User, on_delete=models.CASCADE, related_name='budget_allocations')
    allocated_amount = models.DecimalField(max_digits=12, decimal_places=2)
    note = models.TextField(blank=True, null=True)
    allocated_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name='allocations_made')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Allocated ₹{self.allocated_amount} to {self.employee.username}"


class Expense(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'Pending'),
        ('APPROVED', 'Approved'),
        ('REJECTED', 'Rejected'),
    )

    title = models.CharField(max_length=200)
    amount = models.DecimalField(max_digits=12, decimal_places=2)
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, related_name='expenses')
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='expenses')
    description = models.TextField(blank=True, null=True)
    date_time = models.DateTimeField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    payment_mode = models.CharField(max_length=50, default='Cash')
    receipt_image = models.CharField(max_length=255, blank=True, null=True)
    approved_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='expenses_approved')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-date_time', '-created_at']

    def __str__(self):
        return f"{self.title} - ₹{self.amount} ({self.get_status_display()})"


class BudgetRequest(models.Model):
    STATUS_CHOICES = (
        ('PENDING', 'Pending'),
        ('APPROVED', 'Approved'),
        ('REJECTED', 'Rejected'),
    )

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='budget_requests')
    request_amount = models.DecimalField(max_digits=12, decimal_places=2)
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, related_name='budget_requests')
    reason = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"Budget Request ₹{self.request_amount} by {self.user.username}"


class ActivityLog(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='activity_logs')
    title = models.CharField(max_length=200)
    description = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)
    log_type = models.CharField(max_length=50, default='INFO')

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        return f"{self.title} - {self.timestamp.strftime('%d %b %Y, %I:%M %p')}"


class EmailOTP(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, null=True, blank=True, related_name='otps')
    email = models.EmailField(max_length=255)
    otp = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)

    class Meta:
        ordering = ['-created_at']

    def is_valid(self):
        from django.utils import timezone
        return not self.is_used and timezone.now() <= self.expires_at

    def __str__(self):
        return f"OTP for {self.email} ({'Used' if self.is_used else 'Active'})"


from django.db.models.signals import post_save
from django.dispatch import receiver

@receiver(post_save, sender=User)
def create_or_update_user_profile(sender, instance, created, **kwargs):
    if created:
        if instance.is_superuser or instance.username.lower() in ['founder', 'diya', 'diya_founder']:
            role = 'FOUNDER'
        elif instance.is_staff or instance.username.lower() in ['admin', 'admin2']:
            role = 'ADMIN'
        else:
            role = 'EMPLOYEE'
        UserProfile.objects.get_or_create(user=instance, defaults={'role': role})
    else:
        if hasattr(instance, 'profile'):
            instance.profile.save()


