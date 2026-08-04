from django.contrib import admin
from .models import Category, Account, Transaction, Budget

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'type', 'icon', 'color', 'is_custom', 'user')
    list_filter = ('type', 'is_custom')
    search_fields = ('name',)

@admin.register(Account)
class AccountAdmin(admin.ModelAdmin):
    list_display = ('name', 'user', 'account_type', 'balance', 'currency', 'is_active')
    list_filter = ('account_type', 'currency', 'is_active')
    search_fields = ('name', 'user__username')

@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ('title', 'user', 'account', 'category', 'amount', 'transaction_type', 'date')
    list_filter = ('transaction_type', 'date', 'category')
    search_fields = ('title', 'notes', 'user__username')

@admin.register(Budget)
class BudgetAdmin(admin.ModelAdmin):
    list_display = ('user', 'category', 'limit_amount', 'month_year')
    list_filter = ('month_year',)
    search_fields = ('user__username', 'category__name')
