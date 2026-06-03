import 'api_client.dart';

class WeatherSuggestion {
  WeatherSuggestion({
    required this.temperatureC,
    required this.isSunny,
    required this.isDay,
    required this.condition,
    required this.title,
    required this.message,
    required this.isHot,
    required this.isCold,
  });

  final double temperatureC;
  final bool isSunny;
  final bool isDay;
  final String condition;
  final String title;
  final String message;
  final bool isHot;
  final bool isCold;

  factory WeatherSuggestion.fromJson(Map<String, dynamic> json) {
    return WeatherSuggestion(
      temperatureC: (json['temperature_c'] as num?)?.toDouble() ?? 25,
      isSunny: json['is_sunny'] as bool? ?? false,
      isDay: json['is_day'] as bool? ?? true,
      condition: json['condition'] as String? ?? 'mild',
      title: json['title'] as String? ?? 'Chez Mama',
      message: json['message'] as String? ?? '',
      isHot: json['is_hot'] as bool? ?? false,
      isCold: json['is_cold'] as bool? ?? false,
    );
  }
}

class WeatherApi {
  WeatherApi._();
  static final WeatherApi instance = WeatherApi._();

  Future<WeatherSuggestion> fetchSuggestion({
    double? latitude,
    double? longitude,
  }) async {
    final query = <String, String>{};
    if (latitude != null && longitude != null) {
      query['latitude'] = '$latitude';
      query['longitude'] = '$longitude';
    }
    final res = await ApiClient.instance.dio.get(
      '/weather/suggestion/',
      queryParameters: query.isEmpty ? null : query,
    );
    return WeatherSuggestion.fromJson(res.data as Map<String, dynamic>);
  }

  /// Demande une notification in-app (+ push FCM si configuré), max 1 / 5 h.
  Future<bool> requestServerNotify({bool force = false}) async {
    try {
      final res = await ApiClient.instance.dio.post(
        '/weather/notify/',
        queryParameters: force ? {'force': '1'} : null,
      );
      return res.data['ok'] == true;
    } catch (_) {
      return false;
    }
  }
}
