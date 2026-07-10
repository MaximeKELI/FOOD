import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/support_api.dart';
import '../../auth/auth_scope.dart';
import '../../l10n/app_strings.dart';
import '../../services/app_media_picker.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/food_network_image.dart';

/// Horizontal stories strip for home / social feed.
class StoriesBar extends StatefulWidget {
  const StoriesBar({super.key});

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  List<StoryView> _stories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stories = await SupportApi.instance.fetchStoriesFeed();
      if (!mounted) return;
      setState(() {
        _stories = stories;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _addStory() async {
    final auth = AuthScope.of(context);
    if (!auth.isAuthed) return;
    final path = await AppMediaPicker.instance.pickPhotoFromGallery();
    if (path == null || !mounted) return;
    try {
      await SupportApi.instance.createStory(mediaPath: path.path);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    }
  }

  void _openStory(StoryView story) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 9 / 16,
              child: FoodNetworkImage(
                url: story.mediaUrl,
                fit: BoxFit.cover,
              ),
            ),
            if (story.caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  story.caption,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('action.close')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _stories.isEmpty) {
      return const SizedBox(height: 88);
    }
    final authed = AuthScope.of(context).isAuthed;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _stories.length + (authed ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          if (authed && i == 0) {
            return GestureDetector(
              onTap: _addStory,
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ChezMamaTheme.brandOrange,
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: ChezMamaTheme.brandOrange),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr('stories.add'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }
          final story = _stories[authed ? i - 1 : i];
          return GestureDetector(
            onTap: () => _openStory(story),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ChezMamaTheme.brandOrange,
                      width: 2.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: FoodNetworkImage(
                      url: story.mediaUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 70,
                  child: Text(
                    story.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
