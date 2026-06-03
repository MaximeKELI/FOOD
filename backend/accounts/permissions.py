from rest_framework import permissions


def user_is_vendor(user) -> bool:
    """True when the user completed a seller shop profile (shop name set)."""
    if not user.is_authenticated:
        return False
    profile = getattr(user, "seller_profile", None)
    if profile is None:
        return False
    return bool((profile.shop_name or "").strip())


class IsVendor(permissions.BasePermission):
    """Allows publishing only for users with a configured seller shop."""

    message = "Profil vendeur requis. Complète ta boutique pour publier."

    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        return user_is_vendor(request.user)
