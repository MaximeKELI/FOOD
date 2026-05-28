from django.core.management.base import BaseCommand

from catalog.models import Category

CATEGORIES = ["Plats", "Soupes", "Grillades", "Snacks", "Boissons"]


class Command(BaseCommand):
    help = "Crée les catégories de plats par défaut."

    def handle(self, *args, **options):
        for index, name in enumerate(CATEGORIES):
            obj, created = Category.objects.get_or_create(
                name=name, defaults={"order": index}
            )
            if not created and obj.order != index:
                obj.order = index
                obj.save(update_fields=["order"])
            self.stdout.write(
                self.style.SUCCESS(f"{'Créé' if created else 'OK'}: {name}")
            )
