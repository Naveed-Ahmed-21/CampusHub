import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_hub_app/features/chat/domain/chat_models.dart';
import 'package:campus_hub_app/features/chat/presentation/views/chat_request_composer_dialog.dart';
import 'package:campus_hub_app/features/chat/presentation/views/chat_requests_view.dart';
import 'package:campus_hub_app/features/chat/presentation/providers/chat_provider.dart';

void main() {
  group('Student Messaging Request Models Tests', () {
    test('StudentChatSettingsModel fromJson & toJson', () {
      final json = {
        'require_student_conversation_approval': true,
        'isEligible': true,
      };
      final model = StudentChatSettingsModel.fromJson(json);
      expect(model.requireStudentConversationApproval, true);
      expect(model.isEligible, true);
      expect(model.toJson()['requireStudentConversationApproval'], true);
    });

    test('ChatPermissionResult fromJson handles all actions', () {
      final jsonDirect = {
        'action': 'ALLOW_DIRECT_CHAT',
        'roomId': 'room-123',
        'isBlockedByYou': false,
        'isBlockedByThem': false,
      };
      final resDirect = ChatPermissionResult.fromJson(jsonDirect);
      expect(resDirect.action, ChatPermissionAction.allowDirectChat);
      expect(resDirect.roomId, 'room-123');

      final jsonReq = {
        'action': 'REQUIRE_CHAT_REQUEST',
        'targetUser': {
          'id': 'user-target',
          'firstName': 'Sarah',
          'lastName': 'Connor',
          'email': 'sarah@college.edu',
          'role': 'STUDENT',
        },
      };
      final resReq = ChatPermissionResult.fromJson(jsonReq);
      expect(resReq.action, ChatPermissionAction.requireChatRequest);
      expect(resReq.targetUser?.fullName, 'Sarah Connor');

      final jsonPending = {
        'action': 'REQUEST_PENDING',
        'requestId': 'req-999',
      };
      final resPending = ChatPermissionResult.fromJson(jsonPending);
      expect(resPending.action, ChatPermissionAction.requestPending);
      expect(resPending.requestId, 'req-999');

      final jsonBlocked = {
        'action': 'BLOCKED',
        'isBlockedByYou': true,
        'isBlockedByThem': false,
      };
      final resBlocked = ChatPermissionResult.fromJson(jsonBlocked);
      expect(resBlocked.action, ChatPermissionAction.blocked);
      expect(resBlocked.isBlockedByYou, true);
    });

    test('ChatRequestModel fromJson & status parsing', () {
      final json = {
        'id': 'req-1',
        'sender_id': 'sender-1',
        'recipient_id': 'recipient-1',
        'introductory_message': 'Hi! I am working on the distributed systems project.',
        'status': 'PENDING',
        'created_at': '2026-09-20T10:00:00.000Z',
        'sender': {
          'id': 'sender-1',
          'first_name': 'Naveed',
          'last_name': 'Ahmed',
          'email': 'naveed@college.edu',
          'role': 'STUDENT',
        },
      };

      final req = ChatRequestModel.fromJson(json);
      expect(req.id, 'req-1');
      expect(req.status, ChatRequestStatus.pending);
      expect(req.status.label, 'Pending');
      expect(req.introductoryMessage, 'Hi! I am working on the distributed systems project.');
      expect(req.sender?.fullName, 'Naveed Ahmed');
    });

    test('BlockedUserModel fromJson', () {
      final json = {
        'id': 'block-1',
        'blocker_id': 'user-1',
        'blocked_id': 'user-2',
        'created_at': '2026-09-20T10:00:00.000Z',
        'blocked': {
          'id': 'user-2',
          'first_name': 'Blocked',
          'last_name': 'Student',
          'email': 'blocked@college.edu',
          'role': 'STUDENT',
        },
      };

      final blocked = BlockedUserModel.fromJson(json);
      expect(blocked.id, 'block-1');
      expect(blocked.blockerId, 'user-1');
      expect(blocked.blockedId, 'user-2');
      expect(blocked.blockedUser?.fullName, 'Blocked Student');
    });
  });

  group('ChatRequestComposerDialog Widget Tests', () {
    testWidgets('renders title, counter, and Send Request button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ChatRequestComposerDialog(
                targetUserId: 'target-student-1',
                targetUserName: 'Sarah Connor',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Send Chat Request to Sarah Connor'), findsOneWidget);
      expect(
        find.text(
          'Sarah Connor requires chat requests for new student conversations. Faculty and staff can message directly.',
        ),
        findsOneWidget,
      );
      expect(find.text('0/300'), findsOneWidget);
      expect(find.text('Send Request'), findsOneWidget);

      // Typing in introductory message updates counter
      await tester.enterText(find.byType(TextField), 'Hello, can we collaborate?');
      await tester.pump();

      expect(find.text('26/300'), findsOneWidget);
    });
  });

  group('ChatRequestsView Widget Tests', () {
    testWidgets('renders Incoming and Sent tabs cleanly', (tester) async {
      final incomingReq = ChatRequestModel(
        id: 'req-in-1',
        senderId: 'student-2',
        recipientId: 'me',
        introductoryMessage: 'Hey! Are you available for the AI project discussion?',
        status: ChatRequestStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        sender: ChatParticipantUser(
          id: 'student-2',
          firstName: 'Alex',
          lastName: 'Rivera',
          email: 'alex@college.edu',
          departmentName: 'Computer Science',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            incomingChatRequestsProvider.overrideWith(() => _MockIncomingNotifier([incomingReq])),
            sentChatRequestsProvider.overrideWith(() => _MockSentNotifier([])),
          ],
          child: const MaterialApp(
            home: ChatRequestsView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Message Requests'), findsOneWidget);
      expect(find.text('Incoming'), findsOneWidget);
      expect(find.text('Sent'), findsOneWidget);

      // Incoming card should display sender details & introductory message
      expect(find.text('Alex Rivera'), findsOneWidget);
      expect(find.text('Hey! Are you available for the AI project discussion?'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });
  });
}

class _MockIncomingNotifier extends AutoDisposeAsyncNotifier<List<ChatRequestModel>>
    implements IncomingChatRequestsNotifier {
  final List<ChatRequestModel> _initial;

  _MockIncomingNotifier(this._initial);

  @override
  Future<List<ChatRequestModel>> build() async => _initial;

  @override
  Future<void> refresh() async {}

  @override
  Future<Map<String, dynamic>> acceptRequest(String requestId) async {
    return {'requestId': requestId, 'roomId': 'room-new-123'};
  }

  @override
  Future<void> declineRequest(String requestId) async {}
}

class _MockSentNotifier extends AutoDisposeAsyncNotifier<List<ChatRequestModel>>
    implements SentChatRequestsNotifier {
  final List<ChatRequestModel> _initial;

  _MockSentNotifier(this._initial);

  @override
  Future<List<ChatRequestModel>> build() async => _initial;

  @override
  Future<void> refresh() async {}

  @override
  Future<void> cancelRequest(String requestId) async {}
}
