from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Notification
from .serializers import NotificationSerializer


class NotificationListView(generics.ListAPIView):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None

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
        action = (request.data.get("action") or request.query_params.get("action") or "").strip()
        if action in ("clear", "delete_all"):
            deleted, _ = Notification.objects.filter(recipient=request.user).delete()
            return Response({"ok": True, "deleted": deleted})

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
        platform = (request.data.get("platform") or "").strip()[:32]
        from .models import PushDevice

        existing = PushDevice.objects.filter(token=token).first()
        if existing is not None and existing.user_id != request.user.id:
            return Response(
                {"detail": "Ce token est déjà enregistré pour un autre compte."},
                status=status.HTTP_403_FORBIDDEN,
            )
        device, _ = PushDevice.objects.update_or_create(
            user=request.user,
            token=token,
            defaults={"platform": platform},
        )
        return Response({"ok": True, "id": device.id})

    def delete(self, request):
        token = (request.data.get("token") or "").strip()
        if token:
            from .models import PushDevice

            PushDevice.objects.filter(user=request.user, token=token).delete()
        return Response({"ok": True})


class NotificationMarkOneReadView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        action = (request.data.get("action") or request.query_params.get("action") or "").strip()
        qs = Notification.objects.filter(recipient=request.user, pk=pk)
        if not qs.exists():
            return Response({"detail": "Notification introuvable."}, status=404)

        if action == "delete":
            deleted, _ = qs.delete()
            return Response({"ok": True, "deleted": deleted})

        qs.filter(is_read=False).update(is_read=True)
        return Response({"ok": True})


class NotificationDeleteOneView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def _remove_one(self, user, pk):
        deleted, _ = Notification.objects.filter(recipient=user, pk=pk).delete()
        if not deleted:
            return Response({"detail": "Notification introuvable."}, status=404)
        return Response({"ok": True, "deleted": deleted})

    def delete(self, request, pk):
        return self._remove_one(request.user, pk)

    def post(self, request, pk):
        """POST fallback for clients that block DELETE."""
        return self._remove_one(request.user, pk)


class NotificationClearView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def _clear_all(self, user):
        deleted, _ = Notification.objects.filter(recipient=user).delete()
        return Response({"ok": True, "deleted": deleted})

    def delete(self, request):
        return self._clear_all(request.user)

    def post(self, request):
        return self._clear_all(request.user)
