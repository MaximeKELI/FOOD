from django.db.models import Count, Exists, OuterRef, Q
from django.shortcuts import get_object_or_404
from rest_framework import generics, permissions, status
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.views import APIView

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


class PostListCreateView(generics.ListCreateAPIView):
    parser_classes = [MultiPartParser, FormParser]

    def get_queryset(self):
        qs = Post.objects.select_related("author").all()
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
    queryset = Post.objects.select_related("author").all()
    serializer_class = PostSerializer
    permission_classes = [permissions.IsAuthenticatedOrReadOnly, IsAuthorOrReadOnly]


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
