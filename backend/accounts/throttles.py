from rest_framework.throttling import AnonRateThrottle


class AuthRateThrottle(AnonRateThrottle):
    """Stricter limit for login/register/google to slow credential stuffing."""

    scope = "auth"
