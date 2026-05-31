import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/paginated_response.dart';

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return LearningRepository(ref.watch(dioProvider));
});

final categoriesProvider = FutureProvider.autoDispose<List<LearningCategory>>((
  ref,
) {
  return ref.watch(learningRepositoryProvider).fetchCategories();
});

final articlesProvider = FutureProvider.autoDispose<List<Article>>((ref) {
  return ref.watch(learningRepositoryProvider).fetchArticles();
});

final learningMaterialsProvider =
    FutureProvider.autoDispose<List<LearningMaterial>>((ref) {
      return ref.watch(learningRepositoryProvider).fetchMaterials();
    });

class LearningRepository {
  const LearningRepository(this._dio);

  final Dio _dio;

  Future<List<LearningCategory>> fetchCategories() async {
    final response = await _dio.get<Object>('/learning/categories/');
    return readListPayload(
      response.data,
    ).map(LearningCategory.fromJson).toList(growable: false);
  }

  Future<List<Article>> fetchArticles() async {
    final response = await _dio.get<Object>(
      '/learning/articles/',
      queryParameters: {'limit': 20, 'ordering': '-published_at'},
    );
    return readListPayload(
      response.data,
    ).map(Article.fromJson).toList(growable: false);
  }

  Future<List<LearningMaterial>> fetchMaterials() async {
    final response = await _dio.get<Object>(
      '/learning/materials/',
      queryParameters: {'limit': 20, 'ordering': '-published_at'},
    );
    return readListPayload(
      response.data,
    ).map(LearningMaterial.fromJson).toList(growable: false);
  }

  Future<void> bookmarkArticle(int articleId) async {
    await _dio.post<void>(
      '/learning/bookmarks/',
      data: {'article_id': articleId},
    );
  }
}

class LearningCategory {
  const LearningCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
  });

  final int id;
  final String name;
  final String slug;
  final String description;

  factory LearningCategory.fromJson(Map<String, dynamic> json) {
    return LearningCategory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class Article {
  const Article({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    required this.category,
    required this.readTimeMinutes,
    required this.isBookmarked,
  });

  final int id;
  final String title;
  final String summary;
  final String body;
  final String category;
  final int readTimeMinutes;
  final bool isBookmarked;

  factory Article.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    return Article(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      category: category is Map<String, dynamic>
          ? category['name']?.toString() ?? ''
          : '',
      readTimeMinutes: (json['read_time_minutes'] as num?)?.toInt() ?? 5,
      isBookmarked: json['is_bookmarked'] == true,
    );
  }
}

enum LearningMaterialType {
  pdf,
  worksheet,
  audio,
  video,
  slides,
  link,
  unknown;

  String get label {
    return switch (this) {
      LearningMaterialType.pdf => 'PDF',
      LearningMaterialType.worksheet => 'Worksheet',
      LearningMaterialType.audio => 'Audio',
      LearningMaterialType.video => 'Video',
      LearningMaterialType.slides => 'Slides',
      LearningMaterialType.link => 'Link',
      LearningMaterialType.unknown => 'Material',
    };
  }

  static LearningMaterialType fromJson(Object? value) {
    return switch (value?.toString()) {
      'pdf' => LearningMaterialType.pdf,
      'worksheet' => LearningMaterialType.worksheet,
      'audio' => LearningMaterialType.audio,
      'video' => LearningMaterialType.video,
      'slides' => LearningMaterialType.slides,
      'link' => LearningMaterialType.link,
      _ => LearningMaterialType.unknown,
    };
  }
}

class LearningMaterial {
  const LearningMaterial({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.type,
    required this.url,
    required this.estimatedMinutes,
    required this.fileSizeBytes,
  });

  final int id;
  final String title;
  final String summary;
  final String category;
  final LearningMaterialType type;
  final String url;
  final int estimatedMinutes;
  final int fileSizeBytes;

  bool get hasUrl => url.isNotEmpty;

  String get fileSizeLabel {
    if (fileSizeBytes <= 0) return '';
    const kb = 1024;
    const mb = kb * 1024;
    if (fileSizeBytes >= mb) {
      return '${(fileSizeBytes / mb).toStringAsFixed(1)} MB';
    }
    return '${(fileSizeBytes / kb).ceil()} KB';
  }

  factory LearningMaterial.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    return LearningMaterial(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      category: category is Map<String, dynamic>
          ? category['name']?.toString() ?? ''
          : '',
      type: LearningMaterialType.fromJson(json['material_type']),
      url: json['material_url']?.toString() ?? '',
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 5,
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt() ?? 0,
    );
  }
}
