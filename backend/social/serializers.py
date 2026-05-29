from rest_framework import serializers

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


class PostSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source="author.name", read_only=True)
    media = serializers.FileField(read_only=True)
    like_count = serializers.IntegerField(read_only=True)
    comment_count = serializers.IntegerField(read_only=True)
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

    def get_liked_by_me(self, obj):
        user = self._user()
        return bool(user and obj.likes.filter(user=user).exists())

    def get_favorited_by_me(self, obj):
        user = self._user()
        return bool(user and obj.favorites.filter(user=user).exists())


class PostCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Post
        fields = ("id", "caption", "kind", "media_type", "media")

    def validate(self, attrs):
        media = attrs.get("media")
        media_type = attrs.get("media_type")
        if media_type == Post.MediaType.VIDEO and media is not None:
            if media.size < 1024:
                raise serializers.ValidationError(
                    {
                        "media": "Fichier vidéo invalide ou trop petit. "
                        "Utilise un vrai fichier mp4, mov ou webm."
                    }
                )
        return attrs

    def create(self, validated_data):
        validated_data["author"] = self.context["request"].user
        return super().create(validated_data)
