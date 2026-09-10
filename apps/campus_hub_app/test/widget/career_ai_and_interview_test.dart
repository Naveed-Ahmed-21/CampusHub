import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_hub_app/features/career/domain/career_models.dart';
import 'package:campus_hub_app/features/career/presentation/widgets/journey_map_widget.dart';
// import 'package:campus_hub_app/features/career/presentation/widgets/roadmap_changes_dialog.dart';

void main() {
  group('New Career Hub Domain Models Tests', () {
    test('JobReadinessModel with unassessed state returns 0 and Not assessed', () {
      final json = {
        'overallPercent': null,
        'overallStatus': 'Not enough data yet',
        'readinessLevel': 'Not enough data yet',
        'technical': {'score': null, 'status': 'Not assessed', 'evidence': 'No quiz completed.'},
        'projects': {'score': null, 'status': 'Not assessed', 'evidence': 'No project submitted.'},
        'problemSolving': {'score': null, 'status': 'Not assessed', 'evidence': 'No challenge solved.'},
        'interview': {'score': null, 'status': 'Not assessed', 'evidence': 'No interview completed.'},
        'portfolio': {'score': null, 'status': 'Not assessed', 'evidence': 'No portfolio created.'},
        'learningConsistency': {'score': null, 'status': 'Not assessed', 'evidence': 'No sessions logged.'},
        'whyThisScore': ['Complete your first checkpoint quiz to see verified analytics.'],
        'topPriorities': ['Take your first mock interview with EVA AI'],
      };

      final model = JobReadinessModel.fromJson(json);
      expect(model.isAssessed, false);
      expect(model.readinessPercentage, 0);
      expect(model.overallStatus, 'Not enough data yet');
      expect(model.technical.isAssessed, false);
      expect(model.technical.status, 'Not assessed');
      expect(model.whyThisScore.length, 1);
      expect(model.topPriorities.first, 'Take your first mock interview with EVA AI');
    });

    test('RoadmapChangeModel deserializes correctly', () {
      final json = {
        'id': 'change-1',
        'roadmap_id': 'road-123',
        'from_version': 1,
        'to_version': 2,
        'reason': 'Weak score in State Management quiz (40%)',
        'changes_summary': 'Inserted Riverpod deep dive and official docs',
        'weak_topics_detected': ['Riverpod', 'InheritedWidget'],
        'nodes_added': ['Advanced State Management'],
        'nodes_modified': ['Widget Lifecycle'],
        'created_at': '2026-09-07T12:00:00Z',
      };

      final change = RoadmapChangeModel.fromJson(json);
      expect(change.fromVersion, 1);
      expect(change.toVersion, 2);
      expect(change.weakTopicsDetected, contains('Riverpod'));
      expect(change.nodesAdded, contains('Advanced State Management'));
    });

    test('InterviewSessionModel & InterviewTurnModel deserialize correctly', () {
      final turnJson = {
        'turn_number': 1,
        'question': 'How does the Flutter rendering pipeline work?',
        'expected_concepts': ['Widget Tree', 'Element Tree', 'RenderObject Tree'],
        'student_answer': 'Flutter uses three trees: Widget, Element, and RenderObject.',
        'score': 88,
        'detected_concepts': ['Widget Tree', 'Element Tree'],
        'missing_concepts': ['Layout and Paint phases'],
        'feedback': 'Good explanation of the tree trio.',
        'follow_up_question': 'How does InheritedWidget propagate updates?',
      };

      final sessionJson = {
        'id': 'session-xyz',
        'status': 'ACTIVE',
        'target_role': 'Flutter Architect',
        'mode': 'VOICE',
        'current_turn': 1,
        'total_turns': 5,
        'turns': [turnJson],
      };

      final session = InterviewSessionModel.fromJson(sessionJson);
      expect(session.id, 'session-xyz');
      expect(session.targetRole, 'Flutter Architect');
      expect(session.mode, 'VOICE');
      expect(session.turns.length, 1);
      expect(session.turns.first.score, 88);
      expect(session.turns.first.detectedConcepts, contains('Widget Tree'));
    });

    test('PathfinderChatResponse deserializes correctly', () {
      final json = {
        'message': 'Great choice! What is your current level with Flutter?',
        'conversation_id': 'conv-101',
        'detected_intent': 'LEARNING_QUESTION',
        'suggested_chips': ['Beginner / Zero', 'Intermediate', 'College Labs Only'],
        'is_complete': false,
      };

      final resp = PathfinderChatResponse.fromJson(json);
      expect(resp.conversationId, 'conv-101');
      expect(resp.suggestedChips.length, 3);
      expect(resp.isComplete, false);
    });

    test('VerifiedResourceModel deserializes correctly with canonical URL', () {
      final json = {
        'title': 'Flutter Official Architectural Overview',
        'url': 'https://docs.flutter.dev/resources/architectural-overview',
        'canonical_url': 'https://docs.flutter.dev/resources/architectural-overview',
        'platform': 'DOCS',
        'language': 'English',
        'difficulty': 'Intermediate',
      };

      final resource = VerifiedResourceModel.fromJson(json);
      expect(resource.title, contains('Architectural Overview'));
      expect(resource.platform, 'DOCS');
      expect(resource.canonicalUrl, 'https://docs.flutter.dev/resources/architectural-overview');
    });

    test('AdaptiveQuizModel and AdaptiveQuizQuestionModel deserialize correctly with all question types', () {
      final json = {
        'quiz_id': 'quiz-test-123',
        'topic': 'Phase 2 Checkpoint Assessment',
        'phase_number': 2,
        'role': 'Flutter Architect',
        'difficulty': 'Intermediate',
        'total_questions': 2,
        'questions': [
          {
            'id': 'q1',
            'type': 'DEBUGGING',
            'tested_concept': 'State Management',
            'difficulty': 'Intermediate',
            'question': 'Identify why this Provider triggers infinite rebuilds.',
            'code_snippet': 'ref.watch(counterProvider.notifier).increment();',
            'options': [
              'Calling notifier method inside build without user interaction',
              'Counter provider is not disposed',
              'Missing const constructor',
              'ProviderScope is missing in main.dart',
            ],
            'correct_index': 0,
            'explanation': 'Calling state mutation inside build causes a rebuild loop.',
          },
          {
            'id': 'q2',
            'type': 'ARCHITECTURE_TRADEOFF',
            'tested_concept': 'System Architecture',
            'difficulty': 'Advanced',
            'question': 'When is pessimistic concurrency control preferred over optimistic locking?',
            'scenario': 'High contention reservation system for university lab seats during rush hour.',
            'options': [
              'When write collisions are frequent and rollbacks are expensive',
              'When read throughput dominates 99% of requests',
              'When using serverless edge computing',
              'When caching with Redis is enabled',
            ],
            'correct_index': 0,
            'explanation': 'High contention environments suffer from excessive optimistic rollbacks.',
          },
        ],
      };

      final quiz = AdaptiveQuizModel.fromJson(json);
      expect(quiz.quizId, 'quiz-test-123');
      expect(quiz.phaseNumber, 2);
      expect(quiz.role, 'Flutter Architect');
      expect(quiz.questions.length, 2);

      final q1 = quiz.questions[0];
      expect(q1.type, 'DEBUGGING');
      expect(q1.testedConcept, 'State Management');
      expect(q1.codeSnippet, contains('ref.watch'));
      expect(q1.correctIndex, 0);

      final q2 = quiz.questions[1];
      expect(q2.type, 'ARCHITECTURE_TRADEOFF');
      expect(q2.scenario, contains('High contention'));
      expect(q2.options.length, 4);
    });

    test('ProjectEvaluationModel deserializes correctly with rubrics and scores', () {
      final json = {
        'overall_score': 85,
        'architecture_score': 90,
        'code_quality_score': 80,
        'deployment_score': 85,
        'strengths': ['Clean separation of concerns', 'Comprehensive test suite'],
        'suggestions': ['Add Docker compose configuration'],
        'feedback': 'Impressive production-readiness demonstration.',
      };

      final eval = ProjectEvaluationModel.fromJson(json);
      expect(eval.overallScore, 85);
      expect(eval.architectureScore, 90);
      expect(eval.codeQualityScore, 80);
      expect(eval.deploymentScore, 85);
      expect(eval.strengths.length, 2);
      expect(eval.suggestions.first, contains('Docker'));
      expect(eval.feedback, contains('production-readiness'));
    });

    test('ActiveRoadmapState computes currentPhaseNumber and retrieves phases', () {
      final active = ActiveRoadmapState(
        roadmapId: 'road-test',
        targetRole: 'Cyber Security Engineer',
        level: 'Intermediate',
        weeklyHours: 15,
        currentFocus: 'Phase 3: Network Penetration & Threat Modeling',
        todayGoal: 'Simulate ARP spoofing in isolated lab',
        progressPercent: 0.45,
        phases: [
          RoadmapPhaseDetailModel(
            phaseNumber: 1,
            title: 'Foundations',
            weeks: 2,
            description: 'Core Linux and networking',
          ),
          RoadmapPhaseDetailModel(
            phaseNumber: 3,
            title: 'Penetration Testing',
            weeks: 4,
            description: 'Exploitation frameworks',
          ),
        ],
      );

      expect(active.currentPhaseNumber, 3);
      expect(active.phases.length, 2);
      expect(active.phases[1].title, 'Penetration Testing');
    });
  });

  group('JourneyMapWidget Tests', () {
    testWidgets('Renders Journey Map with phases and version history chip', (tester) async {
      final activeRoadmap = ActiveRoadmapState(
        roadmapId: 'road-abc',
        targetRole: 'Full Stack Engineer',
        level: 'Intermediate',
        weeklyHours: 12,
        currentFocus: 'Phase 1: Foundations',
        todayGoal: 'Complete unit test',
        progressPercent: 0.35,
        version: 2,
        quizScores: {
          'phase_1': {'passed': true, 'score': 90},
        },
      );

      final phases = [
        {
          'num': 1,
          'title': 'Foundations & Architecture',
          'weeks': 'Weeks 1-3',
          'skills': ['Syntax', 'Git Flow'],
        },
        {
          'num': 2,
          'title': 'Core Backend & Storage',
          'weeks': 'Weeks 4-7',
          'skills': ['PostgreSQL', 'Prisma'],
        },
      ];

      bool tappedChanges = false;
      int? tappedPhase;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JourneyMapWidget(
              activeRoadmap: activeRoadmap,
              phases: phases,
              onPhaseTap: (p) => tappedPhase = p,
              onViewChanges: () => tappedChanges = true,
            ),
          ),
        ),
      );

      // Verify Header and Chip
      expect(find.text('Curriculum Journey Map'), findsOneWidget);
      expect(find.text('v2 Changes'), findsOneWidget);

      // Verify Phase 1 is marked Mastered
      expect(find.text('Mastered'), findsOneWidget);
      expect(find.text('Foundations & Architecture'), findsOneWidget);

      // Verify Phase 2 is marked In Progress
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Core Backend & Storage'), findsOneWidget);

      // Tap v2 Changes chip
      await tester.tap(find.text('v2 Changes'));
      expect(tappedChanges, true);

      // Tap Phase 2 card
      await tester.tap(find.text('Core Backend & Storage'));
      expect(tappedPhase, 2);
    });
  });
}
