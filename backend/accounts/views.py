from django.contrib.auth import get_user_model
from django.shortcuts import get_object_or_404
from rest_framework import generics, status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .models import Follow, SellerProfile
from .serializers import (
    RegisterSerializer,
    SellerLocationSerializer,
    SellerProfileSerializer,
    UserSerializer,
)

User = get_user_model()


def tokens_for(user):
    refresh = RefreshToken.for_user(user)
    return {"refresh": str(refresh), "access": str(refresh.access_token)}


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


class SellerDetailView(generics.RetrieveAPIView):
    """Public read-only profile of a seller."""

    serializer_class = UserSerializer
    permission_classes = [AllowAny]
    queryset = User.objects.all()


class SellerLocationListView(generics.ListAPIView):
    """Public list of sellers that have set a map location."""

    serializer_class = SellerLocationSerializer
    permission_classes = [AllowAny]
    pagination_class = None

    def get_queryset(self):
        return SellerProfile.objects.filter(
            latitude__isnull=False, longitude__isnull=False
        ).select_related("user")


class MeView(generics.RetrieveUpdateAPIView):
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user


class MyProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = SellerProfileSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        profile, _ = SellerProfile.objects.get_or_create(user=self.request.user)
        return profile


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
        return Response({"following": True})
