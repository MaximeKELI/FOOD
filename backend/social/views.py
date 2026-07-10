from django.db.models import Count, Exists, OuterRef, Q
from django.shortcuts import get_object_or_404
from drf_spectacular.utils import extend_schema, extend_schema_view
from rest_framework import generics, permissions, status
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.permissions import IsVendor

from .models import Comment, Favorite, Like, Post
from .serializers import (
    CommentSerializer,
    PostCreateSerializer,
    PostSerializer,
)


class IsAuthorOrReadOnly(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return obj.author_id == request.user.id


@extend_schema_view(
    get=extend_schema(tags=["social"], summary="List video/short posts"),
    post=extend_schema(tags=["social"], summary="Publish a post"),
)
class PostListCreateView(generics.ListCreateAPIView):
    parser_classes = [MultiPartParser, FormParser]
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsVendor]

    def get_queryset(self):
        qs = Post.objects.select_related("author").all()
        user = self.request.user
        qs = qs.annotate(
            likes_count_annotated=Count("likes", distinct=True),
            comments_count_annotated=Count("comments", distinct=True),
        )
        if user.is_authenticated:
            qs = qs.annotate(
                liked_by_me_annotated=Exists(
                    Like.objects.filter(post_id=OuterRef("pk"), user_id=user.id)
                ),
                favorited_by_me_annotated=Exists(
                    Favorite.objects.filter(post_id=OuterRef("pk"), user_id=user.id)
                ),
            )
            # Exclude posts from blocked users
            from support.models import UserBlock

            blocked_ids = UserBlock.objects.filter(blocker=user).values_list(
                "blocked_id", flat=True
            )
            qs = qs.exclude(author_id__in=blocked_ids)
            feed = self.request.query_params.get("feed")
            if feed == "following":
                from accounts.models import Follow

                following_ids = Follow.objects.filter(follower=user).values_list(
                    "seller_id", flat=True
                )
                qs = qs.filter(author_id__in=following_ids)
        kind = self.request.query_params.get("kind")
        if kind in (Post.Kind.SHORT, Post.Kind.VIDEO):
            qs = qs.filter(kind=kind)
        author = self.request.query_params.get("author")
        if author:
            qs = qs.filter(author_id=author)
        return qs

    def get_serializer_class(self):
        if self.request.method == "POST":
            return PostCreateSerializer
        return PostSerializer


class PostDetailView(generics.RetrieveDestroyAPIView):
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsAuthorOrReadOnly]

    def get_queryset(self):
        qs = Post.objects.select_related("author").all()
        user = self.request.user
        qs = qs.annotate(
            likes_count_annotated=Count("likes", distinct=True),
            comments_count_annotated=Count("comments", distinct=True),
        )
        if user.is_authenticated:
            qs = qs.annotate(
                liked_by_me_annotated=Exists(
                    Like.objects.filter(post_id=OuterRef("pk"), user_id=user.id)
                ),
                favorited_by_me_annotated=Exists(
                    Favorite.objects.filter(post_id=OuterRef("pk"), user_id=user.id)
                ),
            )
        return qs


class LikeToggleView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, post_id):
        post = get_object_or_404(Post, pk=post_id)
        like, created = Like.objects.get_or_create(post=post, user=request.user)
        if not created:
            like.delete()
            return Response({"liked": False, "like_count": post.like_count})
        return Response({"liked": True, "like_count": post.like_count})


class FavoriteToggleView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, post_id):
        post = get_object_or_404(Post, pk=post_id)
        fav, created = Favorite.objects.get_or_create(post=post, user=request.user)
        if not created:
            fav.delete()
            return Response({"favorited": False})
        return Response({"favorited": True})


class CommentListCreateView(generics.ListCreateAPIView):
    serializer_class = CommentSerializer

    def get_queryset(self):
        return Comment.objects.select_related("author").filter(
            post_id=self.kwargs["post_id"]
        )

    def get_serializer_context(self):
        ctx = super().get_serializer_context()
        ctx["post"] = get_object_or_404(Post, pk=self.kwargs["post_id"])
        return ctx

    def perform_create(self, serializer):
        post = get_object_or_404(Post, pk=self.kwargs["post_id"])
        serializer.save(author=self.request.user, post=post)
