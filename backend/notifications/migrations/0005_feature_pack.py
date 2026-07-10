from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("notifications", "0004_alter_notification_kind"),
    ]

    operations = [
        migrations.AlterField(
            model_name="notification",
            name="kind",
            field=models.CharField(
                choices=[
                    ("order", "Commande"),
                    ("order_status", "Statut commande"),
                    ("follow", "Abonnement"),
                    ("review", "Avis"),
                    ("chat", "Message"),
                    ("weather", "Météo"),
                    ("dispute", "Litige"),
                    ("referral", "Parrainage"),
                    ("system", "Système"),
                ],
                max_length=20,
            ),
        ),
    ]
