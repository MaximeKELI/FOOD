from rest_framework import serializers

from .models import Notification
from .text import sanitize_notification_text


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = (
            "id",
            "kind",
            "title",
            "body",
            "related_id",
            "link",
            "is_read",
            "created_at",
        )
        read_only_fields = fields

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data["title"] = sanitize_notification_text(data.get("title") or "")
        data["body"] = sanitize_notification_text(data.get("body") or "")
        return data
