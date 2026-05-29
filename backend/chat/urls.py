from django.urls import path

from .views import (
    ConversationListView,
    ConversationStartView,
    MessageListCreateView,
    UnreadCountView,
)

urlpatterns = [
    path("chat/conversations/", ConversationListView.as_view(), name="conversations"),
    path("chat/conversations/start/", ConversationStartView.as_view(), name="conversation_start"),
    path("chat/unread/", UnreadCountView.as_view(), name="chat_unread"),
    path(
        "chat/conversations/<int:pk>/messages/",
        MessageListCreateView.as_view(),
        name="conversation_messages",
    ),
]
