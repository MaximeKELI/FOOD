from django.urls import path

from .views import WeatherNotifyMeView, WeatherSuggestionView

urlpatterns = [
    path("weather/suggestion/", WeatherSuggestionView.as_view(), name="weather_suggestion"),
    path("weather/notify/", WeatherNotifyMeView.as_view(), name="weather_notify"),
]
