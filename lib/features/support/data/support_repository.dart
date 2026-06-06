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

final supportThreadProvider = FutureProvider.autoDispose
    .family<SupportThread, int>((ref, threadId) {
      return ref.watch(supportRepositoryProvider).fetchThread(threadId);
    });

final supportCallsProvider = FutureProvider.autoDispose
    .family<List<SupportCall>, int>((ref, threadId) {
      return ref.watch(supportRepositoryProvider).fetchCalls(threadId);
    });

final supportNotificationsProvider =
    FutureProvider.autoDispose<List<SupportNotification>>((ref) {
      return ref.watch(supportRepositoryProvider).fetchNotifications();
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
        'ordering': 'availability_status,next_available_at',
        if (onlineOnly) 'availability_status': 'online',
      },
    );
    return readListPayload(
      response.data,
    ).map(Practitioner.fromJson).toList(growable: false);
  }

  Future<List<SupportThread>> fetchThreads({
    SupportSessionStatus? status,
  }) async {
    final response = await _dio.get<Object>(
      '/support/sessions/',
      queryParameters: {
        'limit': 50,
        'ordering': '-updated_at',
        if (status != null) 'status': status.apiValue,
      },
    );
    return readListPayload(response.data)
        .map(SupportThread.fromJson)
        .where((thread) => thread.threadType == 'practitioner')
        .toList(growable: false);
  }

  Future<SupportThread> fetchThread(int threadId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/support/sessions/$threadId/',
    );
    return SupportThread.fromJson(response.data ?? const {});
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
      '/support/sessions/',
      data: {'thread_type': 'ai', 'subject': 'MindRise Support'},
    );
    final supportThread = SupportThread.fromJson(thread.data ?? const {});
    if (supportThread.id <= 0) {
      throw const ApiException('Support session could not be created.');
    }
    await _dio.post<void>(
      '/support/sessions/${supportThread.id}/messages/',
      data: {'body': message},
    );
    return supportThread;
  }

  Future<SupportThread> startPractitionerThread(
    Practitioner practitioner, {
    SupportContactMethod contactMethod = SupportContactMethod.text,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/support/sessions/',
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
      throw const ApiException('Support request could not be created.');
    }
    return supportThread;
  }

  Future<Practitioner> updateAvailability({
    bool? isAvailable,
    PractitionerAvailabilityStatus? status,
  }) async {
    final nextStatus =
        status ??
        (isAvailable == true
            ? PractitionerAvailabilityStatus.online
            : PractitionerAvailabilityStatus.offline);
    final response = await _dio.patch<Map<String, dynamic>>(
      '/support/practitioners/me/availability/',
      data: {
        'availability_status': nextStatus.apiValue,
        'next_available_at': null,
      },
    );
    return Practitioner.fromJson(response.data ?? const {});
  }

  Future<SupportThread> acceptSession(int threadId) =>
      _sessionAction(threadId, 'accept');
  Future<SupportThread> rejectSession(int threadId) =>
      _sessionAction(threadId, 'reject');

  Future<SupportThread> _sessionAction(int threadId, String action) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/support/sessions/$threadId/$action/',
    );
    return SupportThread.fromJson(response.data ?? const {});
  }

  Future<List<SupportMessage>> fetchMessages(int threadId) async {
    final response = await _dio.get<Object>(
      '/support/sessions/$threadId/messages/',
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
      '/support/sessions/$threadId/messages/',
      data: {'body': body},
    );
    return SupportMessage.fromJson(response.data ?? const {});
  }

  Future<List<SupportCall>> fetchCalls(int threadId) async {
    final response = await _dio.get<Object>(
      '/support/calls/',
      queryParameters: {'limit': 20, 'session': threadId},
    );
    return readListPayload(
      response.data,
    ).map(SupportCall.fromJson).toList(growable: false);
  }

  Future<SupportCall> startCall({
    required int threadId,
    required SupportCallType callType,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/support/calls/',
      data: {'session': threadId, 'call_type': callType.apiValue},
    );
    return SupportCall.fromJson(response.data ?? const {});
  }

  Future<SupportCall> updateCall({
    required int callId,
    required String action,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/support/calls/$callId/$action/',
    );
    return SupportCall.fromJson(response.data ?? const {});
  }

  Future<List<SupportNotification>> fetchNotifications() async {
    final response = await _dio.get<Object>(
      '/support/notifications/',
      queryParameters: {'limit': 40},
    );
    return readListPayload(
      response.data,
    ).map(SupportNotification.fromJson).toList(growable: false);
  }
}

enum PractitionerAvailabilityStatus {
  online('online', 'Online'),
  busy('busy', 'Busy'),
  offline('offline', 'Offline');

  const PractitionerAvailabilityStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static PractitionerAvailabilityStatus fromApi(Object? value) =>
      switch (value?.toString()) {
        'online' => PractitionerAvailabilityStatus.online,
        'busy' => PractitionerAvailabilityStatus.busy,
        _ => PractitionerAvailabilityStatus.offline,
      };
}

enum SupportSessionStatus {
  pending('pending', 'Pending'),
  accepted('accepted', 'Accepted'),
  rejected('rejected', 'Rejected'),
  closed('closed', 'Closed');

  const SupportSessionStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static SupportSessionStatus fromApi(Object? value) =>
      switch (value?.toString()) {
        'pending' => SupportSessionStatus.pending,
        'accepted' => SupportSessionStatus.accepted,
        'rejected' => SupportSessionStatus.rejected,
        _ => SupportSessionStatus.closed,
      };
}

enum SupportContactMethod {
  text('text', 'Text', 'Private text conversation'),
  phone('phone', 'Phone call', 'Audio call request'),
  video('video', 'Video call', 'Video call request');

  const SupportContactMethod(this.apiValue, this.label, this.description);
  final String apiValue;
  final String label;
  final String description;

  static SupportContactMethod fromApi(Object? value) =>
      switch (value?.toString()) {
        'phone' => SupportContactMethod.phone,
        'video' => SupportContactMethod.video,
        _ => SupportContactMethod.text,
      };
}

enum SupportCallType {
  audio('audio', 'Audio'),
  video('video', 'Video');

  const SupportCallType(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static SupportCallType fromApi(Object? value) => value?.toString() == 'video'
      ? SupportCallType.video
      : SupportCallType.audio;
}

class SupportThread {
  const SupportThread({
    required this.id,
    required this.subject,
    required this.threadType,
    required this.contactMethod,
    required this.status,
    required this.patientId,
    required this.patientName,
    required this.isClosed,
    required this.canMessage,
    required this.canCall,
    required this.updatedAt,
    this.practitioner,
    this.latestMessage,
  });

  final int id;
  final String subject;
  final String threadType;
  final SupportContactMethod contactMethod;
  final SupportSessionStatus status;
  final int patientId;
  final String patientName;
  final Practitioner? practitioner;
  final SupportMessage? latestMessage;
  final bool isClosed;
  final bool canMessage;
  final bool canCall;
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
      status: SupportSessionStatus.fromApi(json['status']),
      patientId: (json['patient_id'] as num?)?.toInt() ?? 0,
      patientName: json['patient_name']?.toString() ?? '',
      practitioner: practitionerJson is Map<String, dynamic>
          ? Practitioner.fromJson(practitionerJson)
          : null,
      latestMessage: latestMessageJson is Map<String, dynamic>
          ? SupportMessage.fromJson(latestMessageJson)
          : null,
      isClosed: json['is_closed'] == true,
      canMessage: json['can_message'] != false,
      canCall: json['can_call'] == true,
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

  factory SupportMessage.fromJson(Map<String, dynamic> json) => SupportMessage(
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

class Practitioner {
  const Practitioner({
    required this.id,
    required this.displayName,
    required this.specialization,
    required this.bio,
    required this.availabilityStatus,
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
  final PractitionerAvailabilityStatus availabilityStatus;
  final bool isAvailable;
  final String phoneNumber;
  final String videoCallUrl;
  final bool canCall;
  final bool canVideoCall;
  final bool isMyProfile;
  final DateTime? nextAvailableAt;

  factory Practitioner.fromJson(Map<String, dynamic> json) => Practitioner(
    id: (json['id'] as num?)?.toInt() ?? 0,
    displayName: json['display_name']?.toString() ?? '',
    specialization: json['specialization']?.toString() ?? '',
    bio: json['bio']?.toString() ?? '',
    availabilityStatus: PractitionerAvailabilityStatus.fromApi(
      json['availability_status'],
    ),
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

class SupportCall {
  const SupportCall({
    required this.id,
    required this.sessionId,
    required this.startedById,
    required this.startedByName,
    required this.callType,
    required this.status,
    required this.startedAt,
    this.endedAt,
  });
  final int id;
  final int sessionId;
  final int startedById;
  final String startedByName;
  final SupportCallType callType;
  final String status;
  final DateTime startedAt;
  final DateTime? endedAt;

  factory SupportCall.fromJson(Map<String, dynamic> json) => SupportCall(
    id: (json['id'] as num?)?.toInt() ?? 0,
    sessionId: (json['session'] as num?)?.toInt() ?? 0,
    startedById: (json['started_by'] as num?)?.toInt() ?? 0,
    startedByName: json['started_by_name']?.toString() ?? '',
    callType: SupportCallType.fromApi(json['call_type']),
    status: json['status']?.toString() ?? 'ringing',
    startedAt:
        DateTime.tryParse(json['started_at']?.toString() ?? '') ??
        DateTime.now(),
    endedAt: DateTime.tryParse(json['ended_at']?.toString() ?? ''),
  );
}

class SupportNotification {
  const SupportNotification({
    required this.id,
    required this.sessionId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });
  final int id;
  final int sessionId;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  factory SupportNotification.fromJson(Map<String, dynamic> json) =>
      SupportNotification(
        id: (json['id'] as num?)?.toInt() ?? 0,
        sessionId: (json['session'] as num?)?.toInt() ?? 0,
        type: json['notification_type']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        isRead: json['is_read'] == true,
        createdAt:
            DateTime.tryParse(json['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
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

  factory CrisisResource.fromJson(Map<String, dynamic> json) => CrisisResource(
    title: json['title']?.toString() ?? '',
    phoneNumber: json['phone_number']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
  );
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
