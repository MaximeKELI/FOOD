from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from rest_framework.test import APITestCase

from accounts.models import Follow, SellerProfile
from social.models import Comment, Favorite, Like, Post

User = get_user_model()

# Minimal valid JPEG
_JPEG = bytes(
    [
        0xFF,
        0xD8,
        0xFF,
        0xE0,
        0x00,
        0x10,
        0x4A,
        0x46,
        0x49,
        0x46,
        0x00,
        0x01,
        0x01,
        0x00,
        0x00,
        0x01,
        0x00,
        0x01,
        0x00,
        0x00,
        0xFF,
        0xDB,
        0x00,
        0x43,
        0x00,
        0x08,
        0x06,
        0x06,
        0x07,
        0x06,
        0x05,
        0x08,
        0x07,
        0x07,
        0x07,
        0x09,
        0x09,
        0x08,
        0x0A,
        0x0C,
        0x14,
        0x0D,
        0x0C,
        0x0B,
        0x0B,
        0x0C,
        0x19,
        0x12,
        0x13,
        0x0F,
        0x14,
        0x1D,
        0x1A,
        0x1F,
        0x1E,
        0x1D,
        0x1A,
        0x1C,
        0x1C,
        0x20,
        0x24,
        0x2E,
        0x27,
        0x20,
        0x22,
        0x2C,
        0x23,
        0x1C,
        0x1C,
        0x28,
        0x37,
        0x29,
        0x2C,
        0x30,
        0x31,
        0x34,
        0x34,
        0x34,
        0x1F,
        0x27,
        0x39,
        0x3D,
        0x38,
        0x32,
        0x3C,
        0x2E,
        0x33,
        0x34,
        0x32,
        0xFF,
        0xC0,
        0x00,
        0x0B,
        0x08,
        0x00,
        0x01,
        0x00,
        0x01,
        0x01,
        0x01,
        0x11,
        0x00,
        0xFF,
        0xC4,
        0x00,
        0x14,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x08,
        0xFF,
        0xC4,
        0x00,
        0x14,
        0x10,
        0x01,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0x00,
        0xFF,
        0xDA,
        0x00,
        0x08,
        0x01,
        0x01,
        0x00,
        0x00,
        0x3F,
        0x00,
        0x7B,
        0xDF,
        0xFF,
        0xD9,
    ]
)


class SocialSocialFlowTests(APITestCase):
    def setUp(self):
        self.seller = User.objects.create_user(
            email="seller_social@test.local", password="secret1234", display_name="Seller"
        )
        SellerProfile.objects.create(user=self.seller, shop_name="Boutique Test")
        self.client_user = User.objects.create_user(
            email="client_social@test.local", password="secret1234", display_name="Client"
        )
        post = Post(
            author=self.seller,
            caption="Hello",
            kind=Post.Kind.VIDEO,
            media_type=Post.MediaType.IMAGE,
        )
        post.media.save("p.jpg", SimpleUploadedFile("p.jpg", _JPEG, "image/jpeg"), save=False)
        post.save()
        self.post = post

    def _login(self, user):
        res = self.client.post(
            "/api/auth/login/",
            {"email": user.email, "password": "secret1234"},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {res.data['access']}")

    def test_like_follow_favorite_comment(self):
        self._login(self.client_user)

        res = self.client.post(f"/api/social/posts/{self.post.id}/like/")
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res.data["liked"])
        self.assertEqual(res.data["like_count"], 1)
        self.assertTrue(Like.objects.filter(post=self.post, user=self.client_user).exists())

        res = self.client.post(f"/api/social/posts/{self.post.id}/like/")
        self.assertEqual(res.status_code, 200)
        self.assertFalse(res.data["liked"])

        res = self.client.post(f"/api/auth/sellers/{self.seller.id}/follow/")
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res.data["following"])
        self.assertTrue(
            Follow.objects.filter(follower=self.client_user, seller=self.seller).exists()
        )

        res = self.client.get("/api/social/posts/?kind=video")
        self.assertEqual(res.status_code, 200)
        row = res.data["results"][0]
        self.assertTrue(row["author_followed_by_me"])

        res = self.client.post(f"/api/social/posts/{self.post.id}/favorite/")
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res.data["favorited"])
        self.assertTrue(
            Favorite.objects.filter(post=self.post, user=self.client_user).exists()
        )

        res = self.client.post(
            f"/api/social/posts/{self.post.id}/comments/",
            {"text": "Super !"},
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        self.assertEqual(Comment.objects.filter(post=self.post).count(), 1)

    def test_like_requires_auth(self):
        res = self.client.post(f"/api/social/posts/{self.post.id}/like/")
        self.assertEqual(res.status_code, 401)

    def test_following_feed_empty_when_anonymous(self):
        res = self.client.get("/api/social/posts/?kind=video&feed=following")
        self.assertEqual(res.status_code, 200)
        results = res.data["results"] if isinstance(res.data, dict) else res.data
        self.assertEqual(results, [])

    def test_discover_ranks_by_engagement(self):
        quiet = Post(
            author=self.seller,
            caption="Quiet",
            kind=Post.Kind.VIDEO,
            media_type=Post.MediaType.IMAGE,
        )
        quiet.media.save(
            "q.jpg", SimpleUploadedFile("q.jpg", _JPEG, "image/jpeg"), save=False
        )
        quiet.save()

        hot = Post(
            author=self.seller,
            caption="Hot",
            kind=Post.Kind.VIDEO,
            media_type=Post.MediaType.IMAGE,
        )
        hot.media.save(
            "h.jpg", SimpleUploadedFile("h.jpg", _JPEG, "image/jpeg"), save=False
        )
        hot.save()
        Like.objects.create(post=hot, user=self.client_user)
        Comment.objects.create(post=hot, author=self.client_user, text="🔥")

        res = self.client.get("/api/social/posts/?kind=video&feed=discover")
        self.assertEqual(res.status_code, 200)
        ids = [row["id"] for row in res.data["results"]]
        self.assertLess(ids.index(hot.id), ids.index(quiet.id))
