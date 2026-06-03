"""Payment provider registry."""

from ..models import PaymentIntent
from .base import InitiateResult, PaymentProvider
from .orange import OrangeMoneyProvider
from .stripe_provider import StripeProvider
from .wave import WaveProvider

_REGISTRY: dict[str, PaymentProvider] = {
    PaymentIntent.Provider.STRIPE: StripeProvider(),
    PaymentIntent.Provider.WAVE: WaveProvider(),
    PaymentIntent.Provider.ORANGE_MONEY: OrangeMoneyProvider(),
}


def get_provider(provider: str) -> PaymentProvider:
    impl = _REGISTRY.get(provider)
    if impl is None:
        raise ValueError(f"Provider inconnu: {provider}")
    return impl


def initiate_payment(intent: PaymentIntent) -> InitiateResult:
    return get_provider(intent.provider).initiate(intent)


def verify_webhook_secret(provider: str, header_secret: str) -> bool:
    return get_provider(provider).verify_webhook(header_secret)
