from django.conf import settings
from django.db.models import Count, Exists, OuterRef, Q
from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from drf_spectacular.utils import extend_schema, extend_schema_view
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
from rest_framework import generics, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .models import Follow, SellerProfile
from .serializers import (
    RegisterSerializer,
    PublicSellerSerializer,
    SellerLocationSerializer,
    SellerProfileSerializer,
    UserSerializer,
    UserUpdateSerializer,
)

User = get_user_model()


def tokens_for(user):
    refresh = RefreshToken.for_user(user)
    return {"refresh": str(refresh), "access": str(refresh.access_token)}


@extend_schema(tags=["auth"])
class RegisterView(generics.GenericAPIView):
    serializer_class = RegisterSerializer
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(
            {
                "user": UserSerializer(user).data,
                "tokens": tokens_for(user),
            },
            status=status.HTTP_201_CREATED,
        )


@extend_schema(tags=["auth"], summary="Sign in or register with Google ID token")
class GoogleAuthView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        token = request.data.get("id_token")
        if not token:
            return Response(
                {"detail": "id_token requis."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        client_id = settings.GOOGLE_OAUTH_CLIENT_ID
        if not client_id:
            return Response(
                {"detail": "Connexion Google non configurée sur le serveur."},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )
        try:
            idinfo = google_id_token.verify_oauth2_token(
                token, google_requests.Request(), client_id
            )
        except ValueError:
            return Response(
                {"detail": "Token Google invalide."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        email = (idinfo.get("email") or "").lower()
        if not email:
            return Response(
                {"detail": "Email Google manquant."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        name = idinfo.get("name") or email.split("@")[0]
        user, created = User.objects.get_or_create(
            email=email,
            defaults={"display_name": name},
        )
        if not created and not user.display_name and name:
            user.display_name = name
            user.save(update_fields=["display_name"])
        SellerProfile.objects.get_or_create(user=user)

        return Response(
            {
                "user": UserSerializer(user).data,
                "tokens": tokens_for(user),
            },
            status=status.HTTP_200_OK if not created else status.HTTP_201_CREATED,
        )


class SellerDetailView(generics.RetrieveAPIView):
    """Public read-only profile of a seller."""

    serializer_class = PublicSellerSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        qs = User.objects.filter(
            Q(meals__isnull=False) | Q(seller_profile__shop_name__gt="")
        ).select_related("seller_profile")
        request = self.request
        if request.user.is_authenticated:
            qs = qs.annotate(
                followers_count_annotated=Count("followers", distinct=True),
                meals_count_annotated=Count("meals", distinct=True),
                followed_by_me_annotated=Exists(
                    Follow.objects.filter(
                        seller_id=OuterRef("pk"), follower_id=request.user.id
                    )
                ),
            )
        else:
            qs = qs.annotate(
                followers_count_annotated=Count("followers", distinct=True),
                meals_count_annotated=Count("meals", distinct=True),
            )
        return qs.distinct()


class SellerLocationListView(generics.ListAPIView):
    """Public list of sellers that have set a map location."""

    serializer_class = SellerLocationSerializer
    permission_classes = [AllowAny]
    pagination_class = None

    def get_queryset(self):
        return SellerProfile.objects.filter(
            latitude__isnull=False, longitude__isnull=False
        ).select_related("user")


@extend_schema_view(
    get=extend_schema(tags=["auth"], summary="Current user profile"),
    put=extend_schema(tags=["auth"], summary="Update current user"),
    patch=extend_schema(tags=["auth"], summary="Partial update current user"),
)
class MeView(generics.RetrieveUpdateAPIView):
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user

    def get_serializer_class(self):
        if self.request.method in ("PUT", "PATCH"):
            return UserUpdateSerializer
        return UserSerializer

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop("partial", False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        return Response(UserSerializer(instance, context={"request": request}).data)


@extend_schema_view(
    get=extend_schema(tags=["auth"], summary="Seller shop profile"),
    put=extend_schema(tags=["auth"], summary="Update seller profile"),
    patch=extend_schema(tags=["auth"], summary="Partial update seller profile"),
)
class MyProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = SellerProfileSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        profile, _ = SellerProfile.objects.get_or_create(user=self.request.user)
        return profile


@extend_schema(tags=["auth"], summary="Toggle follow on a vendor")
class FollowToggleView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, seller_id):
        seller = get_object_or_404(User, pk=seller_id)
        if seller == request.user:
            return Response(
                {"detail": "Impossible de s'abonner à soi-même."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        follow, created = Follow.objects.get_or_create(
            follower=request.user, seller=seller
        )
        if not created:
            follow.delete()
            return Response({"following": False})
        from notifications.models import Notification, notify

        notify(
            seller,
            Notification.Kind.FOLLOW,
            "Nouvel abonné",
            f"{request.user.name} s'est abonné à votre boutique.",
            related_id=request.user.id,
            link="follower",
        )
        return Response({"following": True})
