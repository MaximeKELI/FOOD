"""Generate monthly SellerInvoice rows from delivered order GMV."""

from calendar import monthrange
from datetime import date

from django.core.management.base import BaseCommand
from django.utils import timezone

from accounts.models import SellerProfile
from ops.models import PlatformSettings, SellerInvoice
from orders.models import Order, OrderItem


class Command(BaseCommand):
    help = "Crée / met à jour les factures commission vendeur pour un mois."

    def add_arguments(self, parser):
        parser.add_argument(
            "--year",
            type=int,
            default=None,
            help="Année (défaut: mois précédent)",
        )
        parser.add_argument(
            "--month",
            type=int,
            default=None,
            help="Mois 1-12 (défaut: mois précédent)",
        )
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Affiche sans écrire",
        )

    def handle(self, *args, **options):
        today = timezone.localdate()
        year = options["year"]
        month = options["month"]
        if year is None or month is None:
            # Previous calendar month
            if today.month == 1:
                year, month = today.year - 1, 12
            else:
                year, month = today.year, today.month - 1

        period_start = date(year, month, 1)
        period_end = date(year, month, monthrange(year, month)[1])
        cfg = PlatformSettings.get()
        percent = cfg.commission_percent or 0
        flat = cfg.commission_flat or 0

        sellers = SellerProfile.objects.exclude(shop_name="").select_related("user")
        created = updated = 0
        for profile in sellers:
            seller = profile.user
            lines = OrderItem.objects.filter(
                meal__seller=seller,
                order__status=Order.Status.DELIVERED,
                order__created_at__date__gte=period_start,
                order__created_at__date__lte=period_end,
            )
            gmv = sum(line.line_total for line in lines)
            commission = (gmv * percent) // 100 + (flat if gmv else 0)

            if options["dry_run"]:
                self.stdout.write(
                    f"{seller.email}: GMV={gmv} commission={commission}"
                )
                continue

            obj, was_created = SellerInvoice.objects.update_or_create(
                seller=seller,
                period_start=period_start,
                period_end=period_end,
                defaults={
                    "gmv": gmv,
                    "commission": commission,
                    "status": SellerInvoice.Status.DUE if gmv else SellerInvoice.Status.DRAFT,
                },
            )
            if was_created:
                created += 1
            else:
                updated += 1

        self.stdout.write(
            self.style.SUCCESS(
                f"Période {period_start}→{period_end}: "
                f"créées={created} maj={updated} dry_run={options['dry_run']}"
            )
        )
