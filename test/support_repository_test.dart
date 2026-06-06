import 'package:flutter_test/flutter_test.dart';
import 'package:mindrise_mobile/features/support/data/support_repository.dart';

void main() {
  test('practitioner parses mobile connection capabilities', () {
    final practitioner = Practitioner.fromJson(const {
      'id': 7,
      'display_name': 'Dr. Aline',
      'specialization': 'Stress and anxiety',
      'bio': 'Youth-friendly support.',
      'is_available': true,
      'phone_number': '+250788000111',
      'video_call_url': 'https://meet.example.com/aline',
      'can_call': true,
      'can_video_call': true,
      'is_my_profile': false,
    });

    expect(practitioner.isAvailable, isTrue);
    expect(practitioner.canCall, isTrue);
    expect(practitioner.canVideoCall, isTrue);
    expect(practitioner.phoneNumber, '+250788000111');
  });

  test(
    'practitioner thread uses patient name for own practitioner profile',
    () {
      final thread = SupportThread.fromJson(const {
        'id': 15,
        'subject': 'Text support',
        'thread_type': 'practitioner',
        'contact_method': 'text',
        'patient_id': 3,
        'patient_name': 'Patient One',
        'is_closed': false,
        'updated_at': '2026-06-06T08:00:00Z',
        'practitioner': {
          'id': 7,
          'display_name': 'Dr. Aline',
          'specialization': 'Stress and anxiety',
          'bio': '',
          'is_available': true,
          'phone_number': '',
          'video_call_url': '',
          'can_call': false,
          'can_video_call': false,
          'is_my_profile': true,
        },
        'latest_message': {
          'id': 2,
          'sender': 3,
          'sender_name': 'Patient One',
          'body': 'Hello, I need support.',
          'is_system': false,
          'created_at': '2026-06-06T08:00:00Z',
        },
      });

      expect(thread.displayName, 'Patient One');
      expect(thread.contactMethod, SupportContactMethod.text);
      expect(thread.latestMessage?.body, 'Hello, I need support.');
    },
  );

  test('patient thread uses practitioner display name', () {
    final thread = SupportThread.fromJson(const {
      'id': 16,
      'subject': 'Video support',
      'thread_type': 'practitioner',
      'contact_method': 'video',
      'patient_id': 3,
      'patient_name': 'Patient One',
      'is_closed': false,
      'updated_at': '2026-06-06T08:00:00Z',
      'practitioner': {
        'id': 7,
        'display_name': 'Dr. Aline',
        'specialization': 'Stress and anxiety',
        'bio': '',
        'is_available': true,
        'phone_number': '',
        'video_call_url': 'https://meet.example.com/aline',
        'can_call': false,
        'can_video_call': true,
        'is_my_profile': false,
      },
    });

    expect(thread.displayName, 'Dr. Aline');
    expect(thread.contactMethod, SupportContactMethod.video);
  });
}
