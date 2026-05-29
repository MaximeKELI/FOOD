from rest_framework import generics, permissions
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Notification
from .serializers import NotificationSerializer


class NotificationListView(generics.ListAPIView):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(recipient=self.request.user)

    def list(self, request, *args, **kwargs):
        qs = self.filter_queryset(self.get_queryset())
        unread = qs.filter(is_read=False).count()
        page = self.paginate_queryset(qs)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            response = self.get_paginated_response(serializer.data)
            response.data["unread"] = unread
            return response
        serializer = self.get_serializer(qs, many=True)
        return Response({"unread": unread, "results": serializer.data})


class NotificationMarkReadView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        Notification.objects.filter(
            recipient=request.user, is_read=False
        ).update(is_read=True)
        return Response({"ok": True})


class NotificationMarkOneReadView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        updated = Notification.objects.filter(
            recipient=request.user, pk=pk, is_read=False
        ).update(is_read=True)
        if not updated:
            return Response({"detail": "Notification introuvable."}, status=404)
        return Response({"ok": True})
