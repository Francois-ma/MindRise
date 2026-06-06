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

final onlinePractitionersProvider =
    FutureProvider.autoDispose<List<Practitioner>>((ref) {
      return ref
          .watch(supportRepositoryProvider)
          .fetchPractitioners(onlineOnly: true);
    });

final supportThreadsProvider = FutureProvider.autoDispose<List<SupportThread>>((
  ref,
) {
  return ref.watch(supportRepositoryProvider).fetchThreads();
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

  Future<List<Practitioner>> fetchPractitioners({
    bool onlineOnly = false,
  }) async {
    final response = await _dio.get<Object>(
      '/support/practitioners/',
      queryParameters: {
        'limit': onlineOnly ? 30 : 50,
        'ordering': '-is_available,next_available_at',
        if (onlineOnly) 'is_available': true,
      },
    );
    return readListPayload(
      response.data,
    ).map(Practitioner.fromJson).toList(growable: false);
  }

  Future<List<SupportThread>> fetchThreads() async {
    final response = await _dio.get<Object>(
      '/support/threads/',
      queryParameters: {'limit': 50, 'ordering': '-updated_at'},
    );
    return readListPayload(response.data)
        .map(SupportThread.fromJson)
        .where((thread) => thread.threadType == 'practitioner')
        .toList(growable: false);
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
    Practitioner practitioner, {
    SupportContactMethod contactMethod = SupportContactMethod.text,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/support/threads/',
      data: {
        'thread_type': 'practitioner',
        'practitioner_id': practitioner.id,
        'contact_method': contactMethod.apiValue,
        'subject':
            '${contactMethod.label} support with ${practitioner.displayName}',
      },
    );
    final supportThread = SupportThread.fromJson(response.data ?? const {});
    if (supportThread.id <= 0) {
      throw const ApiException('Support thread could not be created.');
    }
    return supportThread;
  }

  Future<Practitioner> updateAvailability({required bool isAvailable}) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/support/practitioners/me/availability/',
      data: {'is_available': isAvailable, 'next_available_at': null},
    );
    return Practitioner.fromJson(response.data ?? const {});
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

enum SupportContactMethod {
  text('text', 'Text', 'Private text conversation'),
  phone('phone', 'Phone call', 'Phone connection'),
  video('video', 'Video call', 'Secure video room');

  const SupportContactMethod(this.apiValue, this.label, this.description);

  final String apiValue;
  final String label;
  final String description;

  static SupportContactMethod fromApi(Object? value) {
    return switch (value?.toString()) {
      'phone' => SupportContactMethod.phone,
      'video' => SupportContactMethod.video,
      _ => SupportContactMethod.text,
    };
  }
}

class SupportThread {
  const SupportThread({
    required this.id,
    required this.subject,
    required this.threadType,
    required this.contactMethod,
    required this.patientId,
    required this.patientName,
    required this.isClosed,
    required this.updatedAt,
    this.practitioner,
    this.latestMessage,
  });

  final int id;
  final String subject;
  final String threadType;
  final SupportContactMethod contactMethod;
  final int patientId;
  final String patientName;
  final Practitioner? practitioner;
  final SupportMessage? latestMessage;
  final bool isClosed;
  final DateTime updatedAt;

  String get displayName {
    if (practitioner?.isMyProfile == true && patientName.isNotEmpty) {
      return patientName;
    }
    return practitioner?.displayName ?? patientName.ifEmpty(subject);
  }

  factory SupportThread.fromJson(Map<String, dynamic> json) {
    final practitionerJson = json['practitioner'];
    final latestMessageJson = json['latest_message'];
    return SupportThread(
      id: (json['id'] as num?)?.toInt() ?? 0,
      subject: json['subject']?.toString() ?? '',
      threadType: json['thread_type']?.toString() ?? 'practitioner',
      contactMethod: SupportContactMethod.fromApi(json['contact_method']),
      patientId: (json['patient_id'] as num?)?.toInt() ?? 0,
      patientName: json['patient_name']?.toString() ?? '',
      practitioner: practitionerJson is Map<String, dynamic>
          ? Practitioner.fromJson(practitionerJson)
          : null,
      latestMessage: latestMessageJson is Map<String, dynamic>
          ? SupportMessage.fromJson(latestMessageJson)
          : null,
      isClosed: json['is_closed'] == true,
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
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
    required this.phoneNumber,
    required this.videoCallUrl,
    required this.canCall,
    required this.canVideoCall,
    required this.isMyProfile,
    this.nextAvailableAt,
  });

  final int id;
  final String displayName;
  final String specialization;
  final String bio;
  final bool isAvailable;
  final String phoneNumber;
  final String videoCallUrl;
  final bool canCall;
  final bool canVideoCall;
  final bool isMyProfile;
  final DateTime? nextAvailableAt;

  factory Practitioner.fromJson(Map<String, dynamic> json) {
    return Practitioner(
      id: (json['id'] as num?)?.toInt() ?? 0,
      displayName: json['display_name']?.toString() ?? '',
      specialization: json['specialization']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      isAvailable: json['is_available'] == true,
      phoneNumber: json['phone_number']?.toString().trim() ?? '',
      videoCallUrl: json['video_call_url']?.toString().trim() ?? '',
      canCall: json['can_call'] == true,
      canVideoCall: json['can_video_call'] == true,
      isMyProfile: json['is_my_profile'] == true,
      nextAvailableAt: DateTime.tryParse(
        json['next_available_at']?.toString() ?? '',
      ),
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

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
