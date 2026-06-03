from django.core.management.base import BaseCommand

from weather.tasks import send_all_weather_nudges


class Command(BaseCommand):
    help = "Envoie les notifications météo (max 1 / utilisateur / 5 h)."

    def handle(self, *args, **options):
        count = send_all_weather_nudges()
        self.stdout.write(self.style.SUCCESS(f"Notifications météo envoyées : {count}"))
