from django.urls import path

from .views import (
    CommentListCreateView,
    FavoriteToggleView,
    LikeToggleView,
    PostDetailView,
    PostListCreateView,
)

urlpatterns = [
    path("posts/", PostListCreateView.as_view(), name="posts"),
    path("posts/<int:pk>/", PostDetailView.as_view(), name="post_detail"),
    path("posts/<int:post_id>/like/", LikeToggleView.as_view(), name="post_like"),
    path(
        "posts/<int:post_id>/favorite/",
        FavoriteToggleView.as_view(),
        name="post_favorite",
    ),
    path(
        "posts/<int:post_id>/comments/",
        CommentListCreateView.as_view(),
        name="post_comments",
    ),
]
