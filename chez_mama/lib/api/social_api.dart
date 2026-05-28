import 'package:dio/dio.dart';

import 'api_client.dart';
import 'api_config.dart';

class ApiComment {
  ApiComment({
    required this.id,
    required this.text,
    required this.authorName,
    required this.parentId,
  });

  final int id;
  final String text;
  final String authorName;
  final int? parentId;

  factory ApiComment.fromJson(Map<String, dynamic> json) {
    return ApiComment(
      id: json['id'] as int,
      text: json['text'] as String? ?? '',
      authorName: json['author_name'] as String? ?? 'Utilisateur',
      parentId: json['parent'] as int?,
    );
  }
}

class ApiPost {
  ApiPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.caption,
    required this.mediaUrl,
    required this.isShort,
    required this.isVideo,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
    required this.favoritedByMe,
  });

  final int id;
  final int authorId;
  final String authorName;
  final String caption;
  final String mediaUrl;
  final bool isShort;
  final bool isVideo;
  int likeCount;
  int commentCount;
  bool likedByMe;
  bool favoritedByMe;

  factory ApiPost.fromJson(Map<String, dynamic> json) {
    return ApiPost(
      id: json['id'] as int,
      authorId: json['author'] as int? ?? 0,
      authorName: json['author_name'] as String? ?? 'Utilisateur',
      caption: json['caption'] as String? ?? '',
      mediaUrl: _absolute(json['media'] as String? ?? ''),
      isShort: json['kind'] == 'short',
      isVideo: json['media_type'] == 'video',
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      likedByMe: json['liked_by_me'] as bool? ?? false,
      favoritedByMe: json['favorited_by_me'] as bool? ?? false,
    );
  }

  static String _absolute(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http')) return url;
    return '${ApiConfig.baseUrl}$url';
  }
}

class SocialApi {
  SocialApi._();
  static final SocialApi instance = SocialApi._();

  final _dio = ApiClient.instance.dio;

  Future<List<ApiPost>> fetchPosts({required bool isShort}) async {
    final res = await _dio.get(
      '/social/posts/',
      queryParameters: {'kind': isShort ? 'short' : 'video'},
    );
    final results = (res.data['results'] as List?) ?? const [];
    return results
        .map((e) => ApiPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ApiPost> createPost({
    required String caption,
    required bool isShort,
    required bool isVideo,
    required String mediaPath,
  }) async {
    final form = FormData.fromMap({
      'caption': caption,
      'kind': isShort ? 'short' : 'video',
      'media_type': isVideo ? 'video' : 'image',
      'media': await MultipartFile.fromFile(mediaPath),
    });
    final res = await _dio.post('/social/posts/', data: form);
    return ApiPost.fromJson(res.data as Map<String, dynamic>);
  }

  Future<({bool liked, int likeCount})> toggleLike(int postId) async {
    final res = await _dio.post('/social/posts/$postId/like/');
    return (
      liked: res.data['liked'] as bool? ?? false,
      likeCount: res.data['like_count'] as int? ?? 0,
    );
  }

  Future<bool> toggleFavorite(int postId) async {
    final res = await _dio.post('/social/posts/$postId/favorite/');
    return res.data['favorited'] as bool? ?? false;
  }

  Future<List<ApiComment>> fetchComments(int postId) async {
    final res = await _dio.get('/social/posts/$postId/comments/');
    final data = res.data;
    final results =
        data is Map ? (data['results'] as List? ?? const []) : (data as List);
    return results
        .map((e) => ApiComment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ApiComment> addComment(
    int postId,
    String text, {
    int? parentId,
  }) async {
    final res = await _dio.post(
      '/social/posts/$postId/comments/',
      data: {'text': text, if (parentId != null) 'parent': parentId},
    );
    return ApiComment.fromJson(res.data as Map<String, dynamic>);
  }

  Future<bool> toggleFollow(int sellerId) async {
    final res = await _dio.post('/auth/sellers/$sellerId/follow/');
    return res.data['following'] as bool? ?? false;
  }
}
