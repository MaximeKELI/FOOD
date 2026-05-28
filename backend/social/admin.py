from django.contrib import admin

from .models import Comment, Favorite, Like, Post


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    list_display = ("id", "author", "kind", "media_type", "created_at")
    list_filter = ("kind", "media_type")
    search_fields = ("author__email", "caption")


admin.site.register(Comment)
admin.site.register(Like)
admin.site.register(Favorite)
