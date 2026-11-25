"""Delete stories past expires_at."""

from django.core.management.base import BaseCommand
from django.utils import timezone

from support.models import Story


class Command(BaseCommand):
    help = "Supprime les stories expirées."

    def add_arguments(self, parser):
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Compte sans supprimer",
        )

    def handle(self, *args, **options):
        qs = Story.objects.filter(expires_at__lt=timezone.now())
        count = qs.count()
        if options["dry_run"]:
            self.stdout.write(f"{count} stories expirées (dry-run)")
            return
        deleted, _ = qs.delete()
        self.stdout.write(self.style.SUCCESS(f"Supprimées: {deleted}"))
