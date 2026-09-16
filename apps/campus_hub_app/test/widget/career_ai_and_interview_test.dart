import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_hub_app/features/career/domain/career_models.dart';
import 'package:campus_hub_app/features/career/presentation/widgets/journey_map_widget.dart';
import 'package:campus_hub_app/features/career/presentation/providers/career_provider.dart';
import 'package:campus_hub_app/features/career/presentation/views/learning_workspace_view.dart';
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

    test('ResourceQuery equality and hashCode prevent infinite re-fetch loop', () {
      const q1 = ResourceQuery(topic: 'Flutter State Management', language: 'English', limit: 6);
      const q2 = ResourceQuery(topic: 'Flutter State Management', language: 'English', limit: 6);
      const q3 = ResourceQuery(topic: 'Cybersecurity OWASP', language: 'English', limit: 6);

      expect(q1 == q2, true);
      expect(q1.hashCode, q2.hashCode);
      expect(q1 == q3, false);
    });

    test('NodeContextQuery equality and hashCode work correctly', () {
      const nq1 = NodeContextQuery(roadmapId: 'road-101', nodeId: 'node-201');
      const nq2 = NodeContextQuery(roadmapId: 'road-101', nodeId: 'node-201');
      const nq3 = NodeContextQuery(roadmapId: 'road-101', nodeId: 'node-202');

      expect(nq1 == nq2, true);
      expect(nq1.hashCode, nq2.hashCode);
      expect(nq1 == nq3, false);
    });

    test('RoadmapNodeContextModel deserializes full structured context', () {
      final json = {
        'roadmap': {
          'id': 'road-123',
          'title': 'Full-Stack Web Development',
          'targetRole': 'Modern Full-Stack & Cloud Engineer',
          'category': 'Engineering',
          'level': 'Beginner',
          'preferredLanguage': 'English',
          'totalNodes': 8,
        },
        'careerGoal': 'Modern Full-Stack & Cloud Engineer',
        'phase': {
          'phaseNumber': 1,
          'title': 'Core Web Foundations',
          'description': 'HTTP, semantic HTML, DOM APIs, and CSS Grid/Flexbox.',
          'skills': ['HTML & CSS Architecture'],
        },
        'node': {
          'id': 'node-1',
          'title': 'Node.js Event Loop & Microtasks',
          'description': 'Master libuv event phases, microtasks queue, and async execution.',
          'orderIndex': 1,
          'estimatedHours': 4,
          'isCompleted': false,
        },
        'skill': 'Node.js Event Loop',
        'topic': 'Node.js Event Loop & Microtasks',
        'learningObjective': 'Understand call stack, event loop tick phases, and process.nextTick priority.',
        'prerequisites': ['JavaScript Execution Context', 'Asynchronous Callbacks'],
        'studentLevel': 'Beginner',
        'confidenceScore': 65,
        'evidenceCount': 2,
        'progress': {
          'progressPercent': 0.15,
          'streakDays': 3,
          'isCompleted': false,
        },
        'resources': {
          'videos': [
            {
              'id': 'k_D7p_w-NnU',
              'title': 'Event Loop in 100 Seconds',
              'channel': 'Fireship',
              'duration': '2:30',
              'views': '1.2M views',
              'url': 'https://www.youtube.com/watch?v=k_D7p_w-NnU',
              'thumbnailUrl': 'https://img.youtube.com/vi/k_D7p_w-NnU/hqdefault.jpg',
              'relevanceScore': 95,
            },
          ],
          'playlists': [
            {
              'id': 'PLillGF-RfqbYRPji8t4SxUkbhTxeNOxEY',
              'title': 'Node.js Crash Course & Best Practices',
              'channel': 'Traversy Media',
              'itemCount': 12,
              'url': 'https://www.youtube.com/playlist?list=PLillGF-RfqbYRPji8t4SxUkbhTxeNOxEY',
            },
          ],
          'documentation': [
            {
              'title': 'Official Node.js Event Loop Documentation',
              'domain': 'nodejs.org',
              'url': 'https://nodejs.org/en/docs/guides/event-loop-timers-and-nexttick/',
              'description': 'Official guide to Node.js event loop and timers.',
            },
          ],
          'github': [
            {
              'name': 'nodejs/node',
              'title': 'nodejs/node',
              'stars': 105000,
              'url': 'https://github.com/nodejs/node',
              'description': 'Node.js JavaScript runtime',
            },
          ],
        },
        'practiceTask': {
          'title': 'Event Loop Ordering Verification',
          'description': 'Write a script with setTimeout, setImmediate, and Promise.resolve to log execution order.',
          'expectedOutput': 'Microtasks execute before timer callbacks.',
          'hints': ['Use process.nextTick and Promise.resolve.', 'Verify against event loop tick semantics.'],
          'starterCode': 'console.log("start");\nPromise.resolve().then(() => console.log("promise"));',
          'difficulty': 'Beginner',
        },
        'quizAvailability': {
          'available': true,
          'numQuestions': 10,
          'checkpointTitle': 'Node.js Event Loop Technical Checkpoint',
        },
        'interviewContext': {
          'initialQuestion': 'Explain how the microtask queue interacts with the Macrotask timer queue in Node.js.',
          'expectedConcepts': ['Microtasks', 'Timer Phase', 'libuv'],
        },
      };

      final model = RoadmapNodeContextModel.fromJson(json);
      expect(model.careerGoal, 'Modern Full-Stack & Cloud Engineer');
      expect(model.skill, 'Node.js Event Loop');
      expect(model.topic, 'Node.js Event Loop & Microtasks');
      expect(model.prerequisites.length, 2);
      expect(model.videos.length, 1);
      expect(model.videos.first.id, 'k_D7p_w-NnU');
      expect(model.playlists.length, 1);
      expect(model.playlists.first.itemCount, 12);
      expect(model.practiceTask?.hints.length, 2);
      expect(model.quizAvailability['numQuestions'], 10);
    });

    testWidgets('LearningWorkspaceView renders 4 tabs cleanly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeUserRoadmapProvider.overrideWith((ref) => Future.value(null)),
            youTubeResourcesProvider.overrideWith((ref, query) => Future.value([
              {
                'id': 'k_D7p_w-NnU',
                'title': 'Node.js Event Loop Masterclass',
                'channel': 'Fireship',
                'duration': '12:00',
                'views': '500K views',
                'url': 'https://www.youtube.com/watch?v=k_D7p_w-NnU',
                'thumbnailUrl': 'https://img.youtube.com/vi/k_D7p_w-NnU/hqdefault.jpg',
              }
            ])),
            youTubePlaylistsProvider.overrideWith((ref, query) => Future.value([
              {
                'id': 'PLillGF-RfqbYRPji8t4SxUkbhTxeNOxEY',
                'title': 'Node.js Course Series',
                'channel': 'Traversy Media',
                'itemCount': 10,
                'url': 'https://www.youtube.com/playlist?list=PLillGF-RfqbYRPji8t4SxUkbhTxeNOxEY',
              }
            ])),
            gitHubResourcesProvider.overrideWith((ref, topic) => Future.value([
              {
                'name': 'nodejs/node',
                'stars': 10000,
                'url': 'https://github.com/nodejs/node',
                'description': 'Node.js runtime',
              }
            ])),
          ],
          child: const MaterialApp(
            home: LearningWorkspaceView(
              topic: 'Node.js Event Loop',
              phaseNumber: 1,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify app bar title
      expect(find.text('Node.js Event Loop'), findsWidgets);

      // Verify 4 segmented tabs
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);
      expect(find.text('Quiz'), findsOneWidget);
      expect(find.text('Resources'), findsOneWidget);

      // Default tab is Learn -> verify Learn content
      expect(find.text('Featured Masterclass & Walkthrough'), findsOneWidget);
      expect(find.text('Technical Mastery Checklist'), findsOneWidget);

      // Tap Practice tab
      await tester.tap(find.text('Practice'));
      await tester.pumpAndSettle();
      expect(find.text('Hands-on Implementation Challenge'), findsOneWidget);

      // Tap Quiz tab
      await tester.tap(find.text('Quiz'));
      await tester.pumpAndSettle();
      expect(find.text('Adaptive Knowledge Checkpoint'), findsOneWidget);
      expect(find.text('Start 10-Question Adaptive Quiz'), findsOneWidget);

      // Tap Resources tab
      await tester.tap(find.text('Resources'));
      await tester.pumpAndSettle();
      expect(find.text('Official Documentation'), findsOneWidget);
    });
  });
}
