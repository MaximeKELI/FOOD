from rest_framework import serializers

from .models import Conversation, Message


class MessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = ("id", "sender", "text", "is_read", "created_at")
        read_only_fields = ("sender", "is_read", "created_at")

    def validate_text(self, value):
        text = (value or "").strip()
        if not text:
            raise serializers.ValidationError("Le message est vide.")
        if len(text) > 4000:
            raise serializers.ValidationError("Message trop long (max 4000).")
        return text


class ConversationSerializer(serializers.ModelSerializer):
    other_id = serializers.SerializerMethodField()
    other_name = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    unread = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = (
            "id",
            "other_id",
            "other_name",
            "last_message",
            "unread",
            "updated_at",
        )

    def _other(self, obj):
        user = self.context["request"].user
        return obj.other(user)

    def get_other_id(self, obj):
        return self._other(obj).id

    def get_other_name(self, obj):
        return self._other(obj).name

    def get_last_message(self, obj):
        messages = getattr(obj, "_prefetched_objects_cache", {}).get("messages")
        if messages is not None:
            return messages[0].text if messages else ""
        msg = obj.messages.order_by("-created_at").first()
        return msg.text if msg else ""

    def get_unread(self, obj):
        if hasattr(obj, "unread_count_annotated"):
            return obj.unread_count_annotated
        user = self.context["request"].user
        return obj.messages.filter(is_read=False).exclude(sender=user).count()
