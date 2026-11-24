from django.core.management.base import BaseCommand

from weather.locks import redis_lock
from weather.tasks import send_all_weather_nudges


class Command(BaseCommand):
    help = "Envoie les notifications météo (max 1 / utilisateur / 5 h)."

    def handle(self, *args, **options):
        with redis_lock("food:weather:nudges", ttl_seconds=600) as acquired:
            if not acquired:
                self.stdout.write(
                    self.style.WARNING("Skip: un autre worker détient déjà le lock météo.")
                )
                return
            count = send_all_weather_nudges()
            self.stdout.write(
                self.style.SUCCESS(f"Notifications météo envoyées : {count}")
            )
