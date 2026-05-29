from rest_framework import generics, permissions, status
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


class PushDeviceRegisterView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        token = (request.data.get("token") or "").strip()
        if not token:
            return Response(
                {"detail": "Token FCM requis."}, status=status.HTTP_400_BAD_REQUEST
            )
        platform = (request.data.get("platform") or "").strip()
        from .models import PushDevice

        device, _ = PushDevice.objects.update_or_create(
            token=token,
            defaults={"user": request.user, "platform": platform},
        )
        return Response({"ok": True, "id": device.id})

    def delete(self, request):
        token = (request.data.get("token") or "").strip()
        if token:
            from .models import PushDevice

            PushDevice.objects.filter(user=request.user, token=token).delete()
        return Response({"ok": True})

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        updated = Notification.objects.filter(
            recipient=request.user, pk=pk, is_read=False
        ).update(is_read=True)
        if not updated:
            return Response({"detail": "Notification introuvable."}, status=404)
        return Response({"ok": True})
