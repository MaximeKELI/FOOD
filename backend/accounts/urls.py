from django.urls import path
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

from .views import (
    FollowToggleView,
    GoogleAuthView,
    MeView,
    MyProfileView,
    RegisterView,
    SellerDetailView,
    SellerLocationListView,
)

urlpatterns = [
    path("register/", RegisterView.as_view(), name="register"),
    path("google/", GoogleAuthView.as_view(), name="google_auth"),
    path("login/", TokenObtainPairView.as_view(), name="login"),
    path("token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("me/", MeView.as_view(), name="me"),
    path("me/profile/", MyProfileView.as_view(), name="my_profile"),
    path("sellers/", SellerLocationListView.as_view(), name="sellers_map"),
    path("sellers/<int:pk>/", SellerDetailView.as_view(), name="seller_detail"),
    path("sellers/<int:seller_id>/follow/", FollowToggleView.as_view(), name="follow"),
]
