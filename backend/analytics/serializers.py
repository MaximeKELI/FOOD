from rest_framework import serializers


class ClientContextSerializer(serializers.Serializer):
    session_id = serializers.CharField(required=False, allow_blank=True)
    latitude = serializers.FloatField(required=False, allow_null=True)
    longitude = serializers.FloatField(required=False, allow_null=True)
    city = serializers.CharField(required=False, allow_blank=True)
    country = serializers.CharField(required=False, allow_blank=True)
    region = serializers.CharField(required=False, allow_blank=True)
    device_time = serializers.DateTimeField(required=False, allow_null=True)
    timezone = serializers.CharField(required=False, allow_blank=True)
    brightness = serializers.FloatField(required=False, allow_null=True)
    platform = serializers.CharField(required=False, allow_blank=True)
    device_model = serializers.CharField(required=False, allow_blank=True)
    os_version = serializers.CharField(required=False, allow_blank=True)
    app_version = serializers.CharField(required=False, allow_blank=True)
    connection_type = serializers.CharField(required=False, allow_blank=True)
    battery_level = serializers.FloatField(required=False, allow_null=True)


class AnalyticsEventInputSerializer(ClientContextSerializer):
    name = serializers.CharField(max_length=120)
    screen = serializers.CharField(required=False, allow_blank=True)
    element = serializers.CharField(required=False, allow_blank=True)
    event_type = serializers.CharField(required=False, allow_blank=True)
    metadata = serializers.JSONField(required=False)
    meta = serializers.CharField(required=False, allow_blank=True)


class AnalyticsBatchSerializer(serializers.Serializer):
    session_id = serializers.CharField(required=False, allow_blank=True)
    context = ClientContextSerializer(required=False)
    events = AnalyticsEventInputSerializer(many=True)

    def validate_events(self, value):
        if not value:
            raise serializers.ValidationError("Au moins un événement requis.")
        if len(value) > 100:
            raise serializers.ValidationError("Maximum 100 événements par lot.")
        return value


class ContentEngagementInputSerializer(ClientContextSerializer):
    content_type = serializers.ChoiceField(
        choices=["meal", "video", "short"],
    )
    content_id = serializers.IntegerField(min_value=1)
    content_title = serializers.CharField(required=False, allow_blank=True, max_length=200)
    duration_seconds = serializers.IntegerField(min_value=1, max_value=86400)


class ContentEngagementBatchSerializer(serializers.Serializer):
    session_id = serializers.CharField(required=False, allow_blank=True)
    context = ClientContextSerializer(required=False)
    engagements = ContentEngagementInputSerializer(many=True)

    def validate_engagements(self, value):
        if not value:
            raise serializers.ValidationError("Au moins un engagement requis.")
        if len(value) > 50:
            raise serializers.ValidationError("Maximum 50 engagements par lot.")
        return value
