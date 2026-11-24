from django.db import migrations


def seed(apps, schema_editor):
    LoyaltyTier = apps.get_model("ops", "LoyaltyTier")
    LoyaltyReward = apps.get_model("ops", "LoyaltyReward")
    PlatformSettings = apps.get_model("ops", "PlatformSettings")
    if not LoyaltyTier.objects.exists():
        LoyaltyTier.objects.bulk_create(
            [
                LoyaltyTier(name="Bronze", min_points=0, perk="Accueil fidélité", order=0),
                LoyaltyTier(name="Argent", min_points=100, perk="5% points bonus", order=1),
                LoyaltyTier(name="Or", min_points=300, perk="Livraison prioritaire", order=2),
            ]
        )
    if not LoyaltyReward.objects.exists():
        LoyaltyReward.objects.bulk_create(
            [
                LoyaltyReward(title="Boisson offerte", description="-500 FCFA", points_cost=50),
                LoyaltyReward(title="Dessert", description="-1000 FCFA", points_cost=100),
            ]
        )
    PlatformSettings.objects.get_or_create(pk=1)


def unseed(apps, schema_editor):
    pass


class Migration(migrations.Migration):
    dependencies = [
        ("ops", "0001_feature_pack_20"),
    ]

    operations = [
        migrations.RunPython(seed, unseed),
    ]
