from abc import ABC, abstractmethod
from dataclasses import dataclass

from decouple import config

from ..models import PaymentIntent


@dataclass
class InitiateResult:
    external_id: str
    checkout_url: str
    status: str
    client_secret: str = ""
    publishable_key: str = ""


class PaymentProvider(ABC):
    @abstractmethod
    def initiate(self, intent: PaymentIntent) -> InitiateResult:
        raise NotImplementedError

    @abstractmethod
    def verify_webhook(self, header_secret: str) -> bool:
        raise NotImplementedError

    def confirm_paid(self, intent: PaymentIntent) -> bool:
        """
        Ask the provider whether this intent is actually paid.
        Default: False (subclasses must implement for live money).
        """
        return False


def callback_base() -> str:
    return config("PAYMENT_CALLBACK_BASE_URL", default="http://127.0.0.1:8000").rstrip(
        "/"
    )
