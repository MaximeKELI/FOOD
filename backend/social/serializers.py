from rest_framework import serializers

from food_api.validators import validate_video_upload

from .models import Comment, Favorite, Like, Post


class CommentSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source="author.name", read_only=True)

    class Meta:
        model = Comment
        fields = (
            "id",
            "post",
            "parent",
            "text",
            "author",
            "author_name",
            "created_at",
        )
        read_only_fields = ("author", "post")

    def validate(self, attrs):
        post = self.context.get("post")
        parent = attrs.get("parent")
        if parent is not None and post is not None and parent.post_id != post.id:
            raise serializers.ValidationError(
                {"parent": "Commentaire parent invalide pour cette publication."}
            )
        text = (attrs.get("text") or "").strip()
        if not text:
            raise serializers.ValidationError({"text": "Le commentaire est vide."})
        if len(text) > 2000:
            raise serializers.ValidationError(
                {"text": "Commentaire trop long (max 2000)."}
            )
        attrs["text"] = text
        return attrs


class PostSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source="author.name", read_only=True)
    media = serializers.FileField(read_only=True)
    like_count = serializers.SerializerMethodField()
    comment_count = serializers.SerializerMethodField()
    liked_by_me = serializers.SerializerMethodField()
    favorited_by_me = serializers.SerializerMethodField()

    class Meta:
        model = Post
        fields = (
            "id",
            "caption",
            "kind",
            "media_type",
            "media",
            "author",
            "author_name",
            "like_count",
            "comment_count",
            "liked_by_me",
            "favorited_by_me",
            "created_at",
        )
        read_only_fields = ("author",)

    def _user(self):
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            return request.user
        return None

    def get_like_count(self, obj):
        if hasattr(obj, "likes_count_annotated"):
            return obj.likes_count_annotated
        return obj.like_count

    def get_comment_count(self, obj):
        if hasattr(obj, "comments_count_annotated"):
            return obj.comments_count_annotated
        return obj.comment_count

    def get_liked_by_me(self, obj):
        if hasattr(obj, "liked_by_me_annotated"):
            return obj.liked_by_me_annotated
        user = self._user()
        return bool(user and obj.likes.filter(user=user).exists())

    def get_favorited_by_me(self, obj):
        if hasattr(obj, "favorited_by_me_annotated"):
            return obj.favorited_by_me_annotated
        user = self._user()
        return bool(user and obj.favorites.filter(user=user).exists())


class PostCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Post
        fields = ("id", "caption", "kind", "media_type", "media")

    def validate(self, attrs):
        media = attrs.get("media")
        media_type = attrs.get("media_type")
        if media_type == Post.MediaType.VIDEO:
            validate_video_upload(media)
        elif media is not None:
            from food_api.validators import validate_image_upload

            validate_image_upload(media)
        return attrs

    def create(self, validated_data):
        validated_data["author"] = self.context["request"].user
        return super().create(validated_data)
