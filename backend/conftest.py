import pytest


@pytest.fixture
def api_client():
    from rest_framework.test import APIClient

    return APIClient()


@pytest.fixture
def customer(db):
    from django.contrib.auth import get_user_model

    User = get_user_model()
    return User.objects.create_user(
        email="customer@test.app",
        password="secret12",
        display_name="Customer",
    )


@pytest.fixture
def seller(db):
    from django.contrib.auth import get_user_model

    from accounts.models import SellerProfile

    User = get_user_model()
    user = User.objects.create_user(
        email="seller@test.app",
        password="secret12",
        display_name="Seller",
    )
    SellerProfile.objects.create(user=user, shop_name="Test Shop")
    return user


@pytest.fixture
def authed_client(api_client, customer):
    api_client.force_authenticate(user=customer)
    return api_client
