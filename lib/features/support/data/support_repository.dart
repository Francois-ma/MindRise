import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/paginated_response.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  return SupportRepository(ref.watch(dioProvider));
});

final practitionersProvider = FutureProvider.autoDispose<List<Practitioner>>((
  ref,
) {
  return ref.watch(supportRepositoryProvider).fetchPractitioners();
});

final crisisResourcesProvider =
    FutureProvider.autoDispose<List<CrisisResource>>((ref) {
      return ref.watch(supportRepositoryProvider).fetchCrisisResources();
    });

final supportMessagesProvider = FutureProvider.autoDispose
    .family<List<SupportMessage>, int>((ref, threadId) {
      return ref.watch(supportRepositoryProvider).fetchMessages(threadId);
    });

class SupportRepository {
  const SupportRepository(this._dio);

  final Dio _dio;

  Future<List<Practitioner>> fetchPractitioners() async {
    final response = await _dio.get<Object>(
      '/support/practitioners/',
      queryParameters: {
        'limit': 20,
        'ordering': '-is_available,next_available_at',
      },
    );
    return readListPayload(
      response.data,
    ).map(Practitioner.fromJson).toList(growable: false);
  }

  Future<List<CrisisResource>> fetchCrisisResources() async {
    final response = await _dio.get<Object>(
      '/support/crisis-resources/',
      queryParameters: {'country_code': 'RW'},
    );
    return readListPayload(
      response.data,
    ).map(CrisisResource.fromJson).toList(growable: false);
  }

  Future<SupportThread> startAiThread(String message) async {
    final thread = await _dio.post<Map<String, dynamic>>(
      '/support/threads/',
      data: {'thread_type': 'ai', 'subject': 'MindRise Support'},
    );
    final supportThread = SupportThread.fromJson(thread.data ?? const {});
    if (supportThread.id <= 0) {
      throw const ApiException('Support thread could not be created.');
    }
    await _dio.post<void>(
      '/support/threads/${supportThread.id}/messages/',
      data: {'body': message},
    );
    return supportThread;
  }

  Future<SupportThread> startPractitionerThread(
    Practitioner practitioner,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/support/threads/',
      data: {
        'thread_type': 'practitioner',
        'practitioner_id': practitioner.id,
        'subject': practitioner.displayName,
      },
    );
    final supportThread = SupportThread.fromJson(response.data ?? const {});
    if (supportThread.id <= 0) {
      throw const ApiException('Support thread could not be created.');
    }
    return supportThread;
  }

  Future<List<SupportMessage>> fetchMessages(int threadId) async {
    final response = await _dio.get<Object>(
      '/support/threads/$threadId/messages/',
    );
    return readListPayload(
      response.data,
    ).map(SupportMessage.fromJson).toList(growable: false);
  }

  Future<SupportMessage> sendMessage({
    required int threadId,
    required String body,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/support/threads/$threadId/messages/',
      data: {'body': body},
    );
    return SupportMessage.fromJson(response.data ?? const {});
  }
}

class SupportThread {
  const SupportThread({
    required this.id,
    required this.subject,
    required this.threadType,
    this.practitioner,
  });

  final int id;
  final String subject;
  final String threadType;
  final Practitioner? practitioner;

  String get displayName => practitioner?.displayName ?? subject;

  factory SupportThread.fromJson(Map<String, dynamic> json) {
    final practitionerJson = json['practitioner'];
    return SupportThread(
      id: (json['id'] as num?)?.toInt() ?? 0,
      subject: json['subject']?.toString() ?? '',
      threadType: json['thread_type']?.toString() ?? 'practitioner',
      practitioner: practitionerJson is Map<String, dynamic>
          ? Practitioner.fromJson(practitionerJson)
          : null,
    );
  }
}

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.isSystem,
    required this.createdAt,
  });

  final int id;
  final int senderId;
  final String senderName;
  final String body;
  final bool isSystem;
  final DateTime createdAt;

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      senderId: (json['sender'] as num?)?.toInt() ?? 0,
      senderName: json['sender_name']?.toString() ?? 'MindRise',
      body: json['body']?.toString() ?? '',
      isSystem: json['is_system'] == true,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class Practitioner {
  const Practitioner({
    required this.id,
    required this.displayName,
    required this.specialization,
    required this.bio,
    required this.isAvailable,
  });

  final int id;
  final String displayName;
  final String specialization;
  final String bio;
  final bool isAvailable;

  factory Practitioner.fromJson(Map<String, dynamic> json) {
    return Practitioner(
      id: (json['id'] as num?)?.toInt() ?? 0,
      displayName: json['display_name']?.toString() ?? '',
      specialization: json['specialization']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      isAvailable: json['is_available'] == true,
    );
  }
}

class CrisisResource {
  const CrisisResource({
    required this.title,
    required this.phoneNumber,
    required this.description,
  });

  final String title;
  final String phoneNumber;
  final String description;

  factory CrisisResource.fromJson(Map<String, dynamic> json) {
    return CrisisResource(
      title: json['title']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}
