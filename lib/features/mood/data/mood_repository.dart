import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/paginated_response.dart';

final moodRepositoryProvider = Provider<MoodRepository>((ref) {
  return MoodRepository(ref.watch(dioProvider));
});

final moodEntriesProvider = FutureProvider.autoDispose<List<MoodEntry>>((
  ref,
) async {
  return ref.watch(moodRepositoryProvider).fetchEntries();
});

final moodSummaryProvider = FutureProvider.autoDispose<MoodSummary>((
  ref,
) async {
  return ref.watch(moodRepositoryProvider).fetchSummary();
});

final moodAiInsightsProvider = FutureProvider.autoDispose
    .family<MoodAiInsights, String?>((ref, mood) async {
      return ref.watch(moodRepositoryProvider).fetchAiInsights(mood: mood);
    });

class MoodRepository {
  const MoodRepository(this._dio);

  final Dio _dio;

  Future<List<MoodEntry>> fetchEntries() async {
    final response = await _dio.get<Object>(
      '/wellness/moods/',
      queryParameters: {'limit': 20, 'ordering': '-occurred_at'},
    );
    return readListPayload(
      response.data,
    ).map(MoodEntry.fromJson).toList(growable: false);
  }

  Future<MoodSummary> fetchSummary() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/wellness/moods/summary/',
    );
    return MoodSummary.fromJson(response.data ?? const {});
  }

  Future<MoodAiInsights> fetchAiInsights({String? mood}) async {
    final queryParameters = mood == null ? null : {'mood': mood};
    final response = await _dio.get<Map<String, dynamic>>(
      '/wellness/moods/ai-insights/',
      queryParameters: queryParameters,
    );
    return MoodAiInsights.fromJson(response.data ?? const {});
  }

  Future<MoodEntry> createEntry({
    required String mood,
    required int score,
    required String note,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/wellness/moods/',
      data: {
        'mood': mood,
        'score': score,
        'note': note,
        'occurred_at': DateTime.now().toUtc().toIso8601String(),
      },
    );
    return MoodEntry.fromJson(response.data ?? const {});
  }

  Future<void> createGratitudeEntry({
    required List<String> items,
    String note = '',
  }) async {
    await _dio.post<void>(
      '/wellness/gratitude/',
      data: {'items': items, 'note': note.trim()},
    );
  }

  Future<void> createThoughtReframe({
    required String negativeThought,
    required String reframedThought,
  }) async {
    await _dio.post<void>(
      '/wellness/reframes/',
      data: {
        'negative_thought': negativeThought.trim(),
        'reframed_thought': reframedThought.trim(),
      },
    );
  }

  Future<void> completeMeditation({
    required String title,
    required int durationSeconds,
  }) async {
    await _dio.post<void>(
      '/wellness/meditations/',
      data: {
        'title': title.trim(),
        'duration_seconds': durationSeconds,
        'completed': true,
      },
    );
  }
}

class MoodAiInsights {
  const MoodAiInsights({
    required this.currentMood,
    required this.provider,
    required this.generatedAt,
    required this.cards,
  });

  final String? currentMood;
  final String provider;
  final DateTime generatedAt;
  final List<MoodAiInsightCard> cards;

  factory MoodAiInsights.fromJson(Map<String, dynamic> json) {
    final rawCards = json['cards'];
    return MoodAiInsights(
      currentMood: json['current_mood']?.toString(),
      provider: json['provider']?.toString() ?? 'local',
      generatedAt:
          DateTime.tryParse(json['generated_at']?.toString() ?? '') ??
          DateTime.now(),
      cards: rawCards is List
          ? rawCards
                .whereType<Map<String, dynamic>>()
                .map(MoodAiInsightCard.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}

class MoodAiInsightCard {
  const MoodAiInsightCard({
    required this.title,
    required this.message,
    required this.action,
    required this.tone,
    required this.priority,
  });

  final String title;
  final String message;
  final String action;
  final String tone;
  final String priority;

  factory MoodAiInsightCard.fromJson(Map<String, dynamic> json) {
    return MoodAiInsightCard(
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      tone: json['tone']?.toString() ?? 'supportive',
      priority: json['priority']?.toString() ?? 'medium',
    );
  }
}

class MoodEntry {
  const MoodEntry({
    required this.id,
    required this.mood,
    required this.score,
    required this.note,
    required this.occurredAt,
  });

  final int id;
  final String mood;
  final int score;
  final String note;
  final DateTime occurredAt;

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      mood: json['mood']?.toString() ?? 'neutral',
      score: (json['score'] as num?)?.toInt() ?? 5,
      note: json['note']?.toString() ?? '',
      occurredAt:
          DateTime.tryParse(json['occurred_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class MoodSummary {
  const MoodSummary({
    required this.averageScore,
    required this.totalEntries,
    required this.mostFrequentMood,
    required this.weeklyScores,
  });

  final double averageScore;
  final int totalEntries;
  final String? mostFrequentMood;
  final List<MoodScorePoint> weeklyScores;

  factory MoodSummary.fromJson(Map<String, dynamic> json) {
    final rawScores = json['weekly_scores'];
    return MoodSummary(
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0,
      totalEntries: (json['total_entries'] as num?)?.toInt() ?? 0,
      mostFrequentMood: json['most_frequent_mood']?.toString(),
      weeklyScores: rawScores is List
          ? rawScores
                .whereType<Map<String, dynamic>>()
                .map(MoodScorePoint.fromJson)
                .toList(growable: false)
          : const [],
    );
  }
}

class MoodScorePoint {
  const MoodScorePoint({required this.day, required this.score});

  final DateTime day;
  final double score;

  factory MoodScorePoint.fromJson(Map<String, dynamic> json) {
    return MoodScorePoint(
      day: DateTime.tryParse(json['day']?.toString() ?? '') ?? DateTime.now(),
      score: (json['score'] as num?)?.toDouble() ?? 0,
    );
  }
}
