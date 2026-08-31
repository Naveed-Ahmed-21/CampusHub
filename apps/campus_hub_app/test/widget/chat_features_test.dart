import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_hub_app/features/chat/domain/chat_models.dart';
import 'package:campus_hub_app/features/chat/presentation/widgets/reply_preview_bar.dart';
import 'package:campus_hub_app/features/chat/presentation/widgets/message_reaction_picker.dart';
import 'package:campus_hub_app/features/chat/presentation/widgets/message_action_sheet.dart';
import 'package:campus_hub_app/features/chat/presentation/widgets/download_media_button.dart';
import 'package:campus_hub_app/features/chat/presentation/widgets/swipe_to_reply_wrapper.dart';
import 'package:campus_hub_app/features/chat/presentation/widgets/chat_image_attachment_widget.dart';
import 'package:campus_hub_app/features/chat/presentation/widgets/chat_document_attachment_widget.dart';
import 'package:campus_hub_app/features/chat/presentation/widgets/chat_video_attachment_widget.dart';
import 'package:campus_hub_app/core/services/media_storage_service.dart';
import 'package:campus_hub_app/core/services/file_open_service.dart';

void main() {
  group('Chat Features & Components Tests', () {
    testWidgets('ReplyPreviewBar renders message snippet and cancel button', (tester) async {
      bool cancelled = false;

      final testMsg = ChatMessageModel(
        id: 'msg-1',
        roomId: 'room-1',
        senderId: 'user-1',
        senderName: 'Naveed Ahmed',
        message: 'Can you share the notes?',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReplyPreviewBar(
              message: testMsg,
              currentUserId: 'user-2',
              onCancel: () {
                cancelled = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Replying to Naveed Ahmed'), findsOneWidget);
      expect(find.text('Can you share the notes?'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      expect(cancelled, true);
    });

    testWidgets('ReplyPreviewBar renders photo snippet when message has image attachment', (tester) async {
      final imgMsg = ChatMessageModel(
        id: 'msg-img',
        roomId: 'room-1',
        senderId: 'user-1',
        senderName: 'Naveed Ahmed',
        message: '',
        mediaType: 'IMAGE',
        mediaUrl: 'https://example.com/img.jpg',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReplyPreviewBar(
              message: imgMsg,
              currentUserId: 'user-1',
              onCancel: () {},
            ),
          ),
        ),
      );

      expect(find.text('Replying to You'), findsOneWidget);
      expect(find.text('Photo'), findsOneWidget);
      expect(find.byIcon(Icons.photo_camera), findsOneWidget);
    });

    testWidgets('MessageReactionPicker displays 6 allowed emojis and handles selection', (tester) async {
      String? selectedEmoji;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageReactionPicker(
              currentSelectedEmojis: const ['❤️'],
              onSelectEmoji: (emoji) {
                selectedEmoji = emoji;
              },
            ),
          ),
        ),
      );

      expect(find.text('❤️'), findsOneWidget);
      expect(find.text('😂'), findsOneWidget);
      expect(find.text('😮'), findsOneWidget);
      expect(find.text('😢'), findsOneWidget);
      expect(find.text('👍'), findsOneWidget);
      expect(find.text('👎'), findsOneWidget);

      await tester.tap(find.text('👍'));
      await tester.pumpAndSettle();

      expect(selectedEmoji, '👍');
    });

    testWidgets('MessageActionSheet shows Delete for Everyone for recent sender message', (tester) async {
      final recentMsg = ChatMessageModel(
        id: 'msg-sender-recent',
        roomId: 'room-1',
        senderId: 'user-me',
        senderName: 'Myself',
        message: 'Hello everyone',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageActionSheet(
              message: recentMsg,
              currentUserId: 'user-me',
              onSelectEmoji: (_) {},
              onReply: () {},
              onDeleteForMe: () {},
              onDeleteForEveryone: () {},
            ),
          ),
        ),
      );

      expect(find.text('Reply'), findsOneWidget);
      expect(find.text('Delete for Me'), findsOneWidget);
      expect(find.text('Delete for Everyone'), findsOneWidget);
    });

    testWidgets('MessageActionSheet hides Delete for Everyone for old message (>24h)', (tester) async {
      final oldMsg = ChatMessageModel(
        id: 'msg-sender-old',
        roomId: 'room-1',
        senderId: 'user-me',
        senderName: 'Myself',
        message: 'Old message from yesterday',
        createdAt: DateTime.now().subtract(const Duration(hours: 26)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageActionSheet(
              message: oldMsg,
              currentUserId: 'user-me',
              onSelectEmoji: (_) {},
              onReply: () {},
              onDeleteForMe: () {},
              onDeleteForEveryone: () {},
            ),
          ),
        ),
      );

      expect(find.text('Reply'), findsOneWidget);
      expect(find.text('Delete for Me'), findsOneWidget);
      // Delete for everyone is hidden after 24h
      expect(find.text('Delete for Everyone'), findsNothing);
    });

    testWidgets('MessageActionSheet hides Delete for Everyone for received messages', (tester) async {
      final incomingMsg = ChatMessageModel(
        id: 'msg-other',
        roomId: 'room-1',
        senderId: 'user-other',
        senderName: 'Other User',
        message: 'Incoming text',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageActionSheet(
              message: incomingMsg,
              currentUserId: 'user-me',
              onSelectEmoji: (_) {},
              onReply: () {},
              onDeleteForMe: () {},
              onDeleteForEveryone: () {},
            ),
          ),
        ),
      );

      expect(find.text('Reply'), findsOneWidget);
      expect(find.text('Delete for Me'), findsOneWidget);
      expect(find.text('Delete for Everyone'), findsNothing);
    });

    testWidgets('DownloadMediaButton displays Download button initially', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DownloadMediaButton(
                messageId: 'msg-img-download',
                imageUrl: 'https://example.com/test.png',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Download'), findsOneWidget);
      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    // PART 8, 9, 10: Swipe To Reply Tests
    testWidgets('SwipeToReplyWrapper: Incoming message responds to RIGHT swipe', (tester) async {
      bool replied = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeToReplyWrapper(
              isMe: false, // Incoming message
              onReply: () {
                replied = true;
              },
              child: const SizedBox(
                width: 300,
                height: 60,
                child: Text('Incoming message bubble'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Incoming message bubble'), findsOneWidget);

      // Drag right by +70px (beyond 48px threshold)
      await tester.drag(find.text('Incoming message bubble'), const Offset(70, 0));
      await tester.pumpAndSettle();

      expect(replied, true);
    });

    testWidgets('SwipeToReplyWrapper: Incoming message ignores LEFT swipe', (tester) async {
      bool replied = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeToReplyWrapper(
              isMe: false, // Incoming message
              onReply: () {
                replied = true;
              },
              child: const SizedBox(
                width: 300,
                height: 60,
                child: Text('Incoming message bubble'),
              ),
            ),
          ),
        ),
      );

      // Drag left by -70px (wrong direction for incoming message)
      await tester.drag(find.text('Incoming message bubble'), const Offset(-70, 0));
      await tester.pumpAndSettle();

      expect(replied, false);
    });

    testWidgets('SwipeToReplyWrapper: Outgoing message responds to LEFT swipe', (tester) async {
      bool replied = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeToReplyWrapper(
              isMe: true, // Outgoing message
              onReply: () {
                replied = true;
              },
              child: const SizedBox(
                width: 300,
                height: 60,
                child: Text('Outgoing message bubble'),
              ),
            ),
          ),
        ),
      );

      // Drag left by -70px (beyond 48px threshold)
      await tester.drag(find.text('Outgoing message bubble'), const Offset(-70, 0));
      await tester.pumpAndSettle();

      expect(replied, true);
    });

    testWidgets('SwipeToReplyWrapper: Outgoing message ignores RIGHT swipe', (tester) async {
      bool replied = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeToReplyWrapper(
              isMe: true, // Outgoing message
              onReply: () {
                replied = true;
              },
              child: const SizedBox(
                width: 300,
                height: 60,
                child: Text('Outgoing message bubble'),
              ),
            ),
          ),
        ),
      );

      // Drag right by +70px (wrong direction for outgoing message)
      await tester.drag(find.text('Outgoing message bubble'), const Offset(70, 0));
      await tester.pumpAndSettle();

      expect(replied, false);
    });

    testWidgets('SwipeToReplyWrapper: Drag below threshold springs back without triggering reply', (tester) async {
      bool replied = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeToReplyWrapper(
              isMe: false,
              onReply: () {
                replied = true;
              },
              child: const SizedBox(
                width: 300,
                height: 60,
                child: Text('Message'),
              ),
            ),
          ),
        ),
      );

      // Drag right only 20px (below 48px threshold)
      await tester.drag(find.text('Message'), const Offset(20, 0));
      await tester.pumpAndSettle();

      expect(replied, false);
    });

    // PART 2, 3: Receiver Image Privacy & Low-Res Blurred Thumbnail Test
    testWidgets('ChatImageAttachmentWidget shows blurred thumbnail and Download button for receiver', (tester) async {
      final imgMsg = ChatMessageModel(
        id: 'msg-receiver-img-1',
        roomId: 'room-1',
        senderId: 'user-other',
        senderName: 'Sender',
        message: '',
        mediaType: 'IMAGE',
        mediaUrl: 'https://example.com/clear_original.jpg',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ChatImageAttachmentWidget(
                message: imgMsg,
                isMe: false, // Receiver
                allMessages: [imgMsg],
              ),
            ),
          ),
        ),
      );

      // Should show Download button
      expect(find.byType(DownloadMediaButton), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);

      // Low-res blurred thumbnail URL transform was computed
      final transformed = MediaStorageService.getBlurredThumbnailUrl('https://ik.imagekit.io/campushub/test.jpg');
      expect(transformed.contains('tr:w-40,bl-8,q-20') || transformed.contains('tr=w-40,bl-8,q-20'), true);
    });

    testWidgets('ReplyPreviewBar renders video snippet when message has video attachment', (tester) async {
      final videoMsg = ChatMessageModel(
        id: 'msg-video',
        roomId: 'room-1',
        senderId: 'user-1',
        senderName: 'Naveed Ahmed',
        message: '',
        mediaType: 'VIDEO',
        mediaUrl: 'https://example.com/video.mp4',
        fileName: 'demo.mp4',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReplyPreviewBar(
              message: videoMsg,
              currentUserId: 'user-2',
              onCancel: () {},
            ),
          ),
        ),
      );

      expect(find.text('Video'), findsOneWidget);
      expect(find.byIcon(Icons.videocam), findsOneWidget);
    });

    testWidgets('ChatDocumentAttachmentWidget renders document name, type label, size, and download button', (tester) async {
      final docMsg = ChatMessageModel(
        id: 'msg-doc-1',
        roomId: 'room-1',
        senderId: 'user-1',
        senderName: 'Naveed Ahmed',
        message: '',
        mediaType: 'DOCUMENT',
        mediaUrl: 'https://example.com/syllabus.pdf',
        fileName: 'syllabus.pdf',
        fileSize: 1048576, // 1.0 MB
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ChatDocumentAttachmentWidget(
                message: docMsg,
                isMe: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('syllabus.pdf'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('1.0 MB'), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    });

    testWidgets('ChatDocumentAttachmentWidget shows Open for sender and Download for receiver', (tester) async {
      final docMsgSender = ChatMessageModel(
        id: 'msg-doc-sender',
        roomId: 'room-1',
        senderId: 'user-me',
        senderName: 'Naveed Ahmed',
        message: '',
        mediaType: 'DOCUMENT',
        mediaUrl: 'https://example.com/project.pdf',
        fileName: 'project.pdf',
        fileSize: 2048576,
        createdAt: DateTime.now(),
      );

      // 1. Sender: Should show Open, never download icon
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ChatDocumentAttachmentWidget(
                message: docMsgSender,
                isMe: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('project.pdf'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsNothing);

      // 2. Receiver: Should show Download icon
      final docMsgReceiver = ChatMessageModel(
        id: 'msg-doc-receiver',
        roomId: 'room-1',
        senderId: 'user-other',
        senderName: 'Alex Doe',
        message: '',
        mediaType: 'DOCUMENT',
        mediaUrl: 'https://example.com/notes.pdf',
        fileName: 'notes.pdf',
        fileSize: 1048576,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ChatDocumentAttachmentWidget(
                message: docMsgReceiver,
                isMe: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('notes.pdf'), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    });

    testWidgets('ChatVideoAttachmentWidget shows Play for sender and Download for receiver', (tester) async {
      final videoMsgSender = ChatMessageModel(
        id: 'msg-video-sender',
        roomId: 'room-1',
        senderId: 'user-me',
        senderName: 'Naveed Ahmed',
        message: '',
        mediaType: 'VIDEO',
        mediaUrl: 'https://example.com/clip.mp4',
        fileName: 'clip.mp4',
        fileSize: 5242880,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ChatVideoAttachmentWidget(
                message: videoMsgSender,
                isMe: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsNothing);
    });

    test('FileOpenService.getDocumentTypeInfo classifies extensions accurately', () {
      expect(FileOpenService.getDocumentTypeInfo('report.pdf').typeLabel, 'PDF');
      expect(FileOpenService.getDocumentTypeInfo('document.docx').typeLabel, 'WORD');
      expect(FileOpenService.getDocumentTypeInfo('sheet.xlsx').typeLabel, 'EXCEL');
      expect(FileOpenService.getDocumentTypeInfo('data.csv').typeLabel, 'CSV');
      expect(FileOpenService.getDocumentTypeInfo('presentation.pptx').typeLabel, 'PPT');
      expect(FileOpenService.getDocumentTypeInfo('notes.txt').typeLabel, 'TEXT');
      expect(FileOpenService.getDocumentTypeInfo('recording.mp4').typeLabel, 'VIDEO');
      expect(FileOpenService.getDocumentTypeInfo('archive.zip').typeLabel, 'ARCHIVE');
    });
  });
}
