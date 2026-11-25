"""Rebuild Meal.search_vector for full-text search."""

from django.core.management.base import BaseCommand

from catalog.models import Meal


class Command(BaseCommand):
    help = "Reconstruit le search_vector Postgres de tous les plats."

    def handle(self, *args, **options):
        ok = err = 0
        for meal in Meal.objects.iterator():
            try:
                meal.update_search_vector()
                ok += 1
            except Exception as exc:  # noqa: BLE001
                err += 1
                self.stderr.write(f"meal {meal.pk}: {exc}")
        self.stdout.write(self.style.SUCCESS(f"reindex ok={ok} err={err}"))
