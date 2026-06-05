from django.urls import path

from .views import (
    AnalyticsBatchView,
    AnalyticsEventView,
    ContentEngagementBatchView,
    ContentEngagementView,
)

urlpatterns = [
    path("analytics/events/", AnalyticsEventView.as_view(), name="analytics_event"),
    path(
        "analytics/events/batch/",
        AnalyticsBatchView.as_view(),
        name="analytics_batch",
    ),
    path(
        "analytics/engagement/",
        ContentEngagementView.as_view(),
        name="analytics_engagement",
    ),
    path(
        "analytics/engagement/batch/",
        ContentEngagementBatchView.as_view(),
        name="analytics_engagement_batch",
    ),
]
