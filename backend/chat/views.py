from django.contrib.auth import get_user_model
from django.db.models import Count, Prefetch, Q
from django.shortcuts import get_object_or_404
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Conversation, Message
from .serializers import ConversationSerializer, MessageSerializer

User = get_user_model()


class ConversationListView(generics.ListAPIView):
    serializer_class = ConversationSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None

    def get_queryset(self):
        user = self.request.user
        return (
            Conversation.objects.filter(Q(user_low=user) | Q(user_high=user))
            .select_related("user_low", "user_high")
            .prefetch_related(
                Prefetch(
                    "messages",
                    queryset=Message.objects.order_by("-created_at"),
                )
            )
            .annotate(
                unread_count_annotated=Count(
                    "messages",
                    filter=Q(messages__is_read=False) & ~Q(messages__sender=user),
                )
            )
        )


class ConversationStartView(APIView):
    """Get or create the conversation with another user."""

    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        other_id = request.data.get("user")
        if not other_id or str(other_id) == str(request.user.id):
            return Response(
                {"detail": "Destinataire invalide."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        other = get_object_or_404(User, pk=other_id)
        convo = Conversation.between(request.user, other)
        return Response(
            ConversationSerializer(convo, context={"request": request}).data
        )


class MessageListCreateView(generics.ListCreateAPIView):
    serializer_class = MessageSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = None

    def _conversation(self):
        user = self.request.user
        return get_object_or_404(
            Conversation.objects.filter(Q(user_low=user) | Q(user_high=user)),
            pk=self.kwargs["pk"],
        )

    def get_queryset(self):
        convo = self._conversation()
        # Mark incoming messages as read.
        convo.messages.filter(is_read=False).exclude(
            sender=self.request.user
        ).update(is_read=True)
        return convo.messages.all()

    def perform_create(self, serializer):
        convo = self._conversation()
        message = serializer.save(conversation=convo, sender=self.request.user)
        convo.save(update_fields=["updated_at"])
        recipient = (
            convo.user_high
            if convo.user_low_id == self.request.user.id
            else convo.user_low
        )
        if recipient.id != self.request.user.id:
            from notifications.models import Notification, notify

            notify(
                recipient,
                Notification.Kind.CHAT,
                f"Message de {self.request.user.name}",
                message.text[:200],
                related_id=convo.id,
                link="chat",
            )


class UnreadCountView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        count = (
            Message.objects.filter(
                Q(conversation__user_low=user) | Q(conversation__user_high=user),
                is_read=False,
            )
            .exclude(sender=user)
            .count()
        )
        return Response({"unread": count})
