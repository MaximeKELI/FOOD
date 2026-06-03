from django.core.management.base import BaseCommand

from notifications.models import Notification
from notifications.text import sanitize_notification_text


class Command(BaseCommand):
    help = "Replace em/en dashes in stored notification title/body."

    def handle(self, *args, **options):
        updated = 0
        for n in Notification.objects.iterator():
            title = sanitize_notification_text(n.title)
            body = sanitize_notification_text(n.body)
            if title != n.title or body != n.body:
                n.title = title
                n.body = body
                n.save(update_fields=["title", "body"])
                updated += 1
        self.stdout.write(self.style.SUCCESS(f"Updated {updated} notification(s)."))
