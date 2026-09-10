import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_hub_app/features/career/presentation/widgets/career_pathfinder_sheet.dart';
import 'package:campus_hub_app/features/career/data/career_repository.dart';
import 'package:campus_hub_app/features/career/domain/career_models.dart';

class FakeCareerRepository extends Fake implements CareerRepository {
  @override
  Future<PathfinderChatResponse> startPathfinderSession({bool resumeActive = true}) async {
    return PathfinderChatResponse(
      conversationId: 'mock-conv-1',
      message: 'Hello! I am EVA, your personal Career & Learning Architect.',
      suggestedChips: ['Flutter & Mobile Apps', 'Backend APIs & Cloud'],
    );
  }

  @override
  Future<PathfinderChatResponse> pathfinderChat({
    required String message,
    String? conversationId,
  }) async {
    return PathfinderChatResponse(
      conversationId: 'mock-conv-1',
      message: 'Great choice targeting Flutter Mobile Architect!',
      suggestedChips: ['Built 1-2 small projects', 'Starting from scratch'],
      profileSummary: {
        'target_role': 'Flutter Mobile Architect',
        'current_level': 'Intermediate',
        'daily_hours': 2,
        'preferred_language': 'English',
        'goal': 'Campus Placement Readiness',
      },
      careerMatches: [
        CareerDirectionMatchModel(
          role: 'Flutter Mobile Architect',
          matchScore: 94,
          rationale: 'High alignment with your mobile product interest.',
          evidence: ['Interest in mobile apps'],
          gaps: ['Riverpod 2.0', 'Offline SQLite'],
          nextSteps: ['Dart 3 Concurrency', 'State Mutations'],
        ),
      ],
    );
  }

  @override
  Future<Map<String, dynamic>> confirmPathfinderJourney({
    required String conversationId,
    String? selectedDirection,
  }) async {
    return {'status': 'success'};
  }
}

void main() {
  testWidgets('CareerPathfinderSheet initializes and displays EVA greeting and chips', (WidgetTester tester) async {
    final fakeRepo = FakeCareerRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          careerRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CareerPathfinderSheet(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('AI Career Pathfinder'), findsOneWidget);
    expect(find.textContaining('Hello! I am EVA'), findsOneWidget);
    expect(find.text('Flutter & Mobile Apps'), findsOneWidget);
    expect(find.text('Backend APIs & Cloud'), findsOneWidget);
  });

  testWidgets('CareerPathfinderSheet displays career matches and summary card on response', (WidgetTester tester) async {
    final fakeRepo = FakeCareerRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          careerRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CareerPathfinderSheet(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on chip to send message
    await tester.tap(find.text('Flutter & Mobile Apps'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.textContaining('Personalized Career Track Matches'), findsOneWidget);
    expect(find.text('94% Match'), findsOneWidget);
    expect(find.text("Here's What I Understood About You"), findsOneWidget);
    expect(find.text('Confirm & Generate My Roadmap'), findsOneWidget);
  });
}
