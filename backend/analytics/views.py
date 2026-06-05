from drf_spectacular.utils import extend_schema
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.authentication import JWTAuthentication

from .serializers import (
    AnalyticsBatchSerializer,
    AnalyticsEventInputSerializer,
    ContentEngagementBatchSerializer,
    ContentEngagementInputSerializer,
)
from .services import record_content_engagement, record_event


class AnalyticsEventView(APIView):
    """Record a single analytics event (click, screen view, etc.)."""

    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.AllowAny]

    @extend_schema(
        request=AnalyticsEventInputSerializer,
        responses={201: {"type": "object", "properties": {"ok": {"type": "boolean"}}}},
        tags=["analytics"],
        summary="Enregistrer un événement",
    )
    def post(self, request):
        serializer = AnalyticsEventInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        record_event(
            user=request.user,
            data=serializer.validated_data,
            request=request,
        )
        return Response({"ok": True}, status=status.HTTP_201_CREATED)


class AnalyticsBatchView(APIView):
    """Record multiple events in one request."""

    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.AllowAny]

    @extend_schema(
        request=AnalyticsBatchSerializer,
        responses={201: {"type": "object", "properties": {"ok": {"type": "boolean"}, "count": {"type": "integer"}}}},
        tags=["analytics"],
        summary="Enregistrer un lot d'événements",
    )
    def post(self, request):
        serializer = AnalyticsBatchSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        base = {}
        if data.get("session_id"):
            base["session_id"] = data["session_id"]
        if data.get("context"):
            base["context"] = data["context"]

        count = 0
        for event_data in data["events"]:
            payload = {**base, **event_data}
            record_event(user=request.user, data=payload, request=request)
            count += 1

        return Response({"ok": True, "count": count}, status=status.HTTP_201_CREATED)


class ContentEngagementView(APIView):
    """Record time spent on a meal, video or short."""

    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.AllowAny]

    @extend_schema(
        request=ContentEngagementInputSerializer,
        responses={201: {"type": "object", "properties": {"ok": {"type": "boolean"}}}},
        tags=["analytics"],
        summary="Enregistrer le temps passé sur un contenu",
    )
    def post(self, request):
        serializer = ContentEngagementInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        record_content_engagement(
            user=request.user,
            data=serializer.validated_data,
            request=request,
        )
        return Response({"ok": True}, status=status.HTTP_201_CREATED)


class ContentEngagementBatchView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [permissions.AllowAny]

    @extend_schema(
        request=ContentEngagementBatchSerializer,
        tags=["analytics"],
        summary="Enregistrer plusieurs engagements contenu",
    )
    def post(self, request):
        serializer = ContentEngagementBatchSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        base: dict = {}
        if data.get("session_id"):
            base["session_id"] = data["session_id"]
        if data.get("context"):
            base["context"] = data["context"]
        count = 0
        for item in data["engagements"]:
            record_content_engagement(
                user=request.user,
                data={**base, **item},
                request=request,
            )
            count += 1
        return Response({"ok": True, "count": count}, status=status.HTTP_201_CREATED)
