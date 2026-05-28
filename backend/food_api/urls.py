from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.http import JsonResponse
from django.urls import include, path


def api_root(_request):
    return JsonResponse(
        {
            "name": "Food API",
            "version": "1.0",
            "endpoints": {
                "auth": "/api/auth/",
                "catalog": "/api/catalog/",
                "social": "/api/social/",
                "admin": "/admin/",
            },
        }
    )


urlpatterns = [
    path("", api_root),
    path("admin/", admin.site.urls),
    path("api/auth/", include("accounts.urls")),
    path("api/catalog/", include("catalog.urls")),
    path("api/social/", include("social.urls")),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
