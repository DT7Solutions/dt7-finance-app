from django.contrib import admin
from django.urls import path, include
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

from finance_app.views import CustomTokenObtainPairView, SendOTPView, VerifyOTPView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v1/auth/token/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/v1/auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/v1/auth/send-otp/', SendOTPView.as_view(), name='core_send_otp'),
    path('api/v1/auth/verify-otp/', VerifyOTPView.as_view(), name='core_verify_otp'),
    path('api/v1/token/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair_alias'),
    path('api/v1/token/refresh/', TokenRefreshView.as_view(), name='token_refresh_alias'),
    path('api/v1/', include('finance_app.urls')),
]

