from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import TestCase
from rest_framework.test import APIClient

from accounts.models import SellerProfile
from catalog.models import Category, Meal

User = get_user_model()


class CatalogSearchTests(TestCase):
    def setUp(self):
        self.seller = User.objects.create_user(
            email="chef@test.app", password="secret12", display_name="Chef Mafé"
        )
        SellerProfile.objects.create(user=self.seller)
        cat = Category.objects.create(name="Plats")
        image = SimpleUploadedFile("m.jpg", b"x", content_type="image/jpeg")
        Meal.objects.create(
            seller=self.seller,
            category=cat,
            name="Mafé Poulet",
            subtitle="Sauce arachide",
            price=3500,
            image=image,
        )
        self.client = APIClient()

    def test_search_by_name(self):
        res = self.client.get("/api/catalog/meals/", {"q": "Mafé"})
        self.assertEqual(res.status_code, 200)
        self.assertEqual(len(res.data["results"]), 1)

    def test_search_by_seller(self):
        res = self.client.get("/api/catalog/meals/", {"q": "Chef"})
        self.assertEqual(res.status_code, 200)
        self.assertEqual(len(res.data["results"]), 1)
