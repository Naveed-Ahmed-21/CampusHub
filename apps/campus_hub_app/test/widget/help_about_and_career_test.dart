import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:campus_hub_app/features/settings/presentation/views/help_support_view.dart';
import 'package:campus_hub_app/features/settings/presentation/views/about_view.dart';
import 'package:campus_hub_app/features/career/domain/career_models.dart';
import 'package:campus_hub_app/features/career/presentation/widgets/eva_ai_avatar.dart';
import 'package:campus_hub_app/features/career/presentation/widgets/phase_challenge_dialog.dart';

void main() {
  group('Career Domain Models Serialization Tests', () {
    test('CareerRecommendationModel deserializes accurately', () {
      final json = {
        'id': 'rec_fullstack',
        'title': 'Full-Stack Web Engineering',
        'slug': 'full-stack-web',
        'category': 'Web & Cloud',
        'match_percentage': 94,
        'difficulty': 'Intermediate',
        'reasoning': 'Matches hands-on interest in web architectures.',
        'weekly_commitment': '12 hours/week',
        'key_skills': ['React', 'Node.js', 'PostgreSQL'],
        'suggested_projects': ['Campus Marketplace', 'Real-Time Collaboration Board'],
      };

      final model = CareerRecommendationModel.fromJson(json);
      expect(model.id, 'rec_fullstack');
      expect(model.title, 'Full-Stack Web Engineering');
      expect(model.matchPercentage, 94);
      expect(model.difficulty, 'Intermediate');
      expect(model.keySkills.length, 3);
      expect(model.suggestedProjects.length, 2);
    });

    test('CareerDecisionResult parses correctly', () {
      final json = {
        'verdict': 'Backend & Distributed Systems Architecture',
        'summary': 'You enjoy deep logical thinking and query optimization.',
        'recommendationId': 'rec_backend',
        'pros': ['Timeless software engineering fundamentals', 'High compensation'],
        'cons': ['Less immediate visual feedback'],
      };

      final decision = CareerDecisionResult.fromJson(json);
      expect(decision.verdict, 'Backend & Distributed Systems Architecture');
      expect(decision.pros.length, 2);
      expect(decision.cons.length, 1);
    });

    test('PhaseQuizResult evaluates score and feedback', () {
      final json = {
        'phaseNumber': 1,
        'score': 3,
        'totalQuestions': 3,
        'percentage': 100,
        'passed': true,
        'feedback': [
          {
            'question': 'What is async execution?',
            'isCorrect': true,
            'selected': 1,
            'correct': 1,
            'explanation': 'Non-blocking I/O event loop.',
          }
        ],
      };

      final quiz = PhaseQuizResult.fromJson(json);
      expect(quiz.phaseNumber, 1);
      expect(quiz.score, 3);
      expect(quiz.passed, true);
      expect(quiz.feedback.first.isCorrect, true);
    });

    test('ActiveRoadmapState handles progress and quiz scores', () {
      final json = {
        'roadmapId': 'rdm_fullstack_2026',
        'targetRole': 'Full-Stack Engineering',
        'level': 'Beginner',
        'weeklyHours': 10,
        'currentFocus': 'Phase 1: Foundations',
        'todayGoal': 'Build 1 responsive layout',
        'progressPercent': 0.4,
        'completedNodeIds': ['node_1', 'node_2'],
        'quizScores': {
          'phase_1': {'score': 3, 'totalQuestions': 3, 'passed': true},
        },
      };

      final state = ActiveRoadmapState.fromJson(json);
      expect(state.roadmapId, 'rdm_fullstack_2026');
      expect(state.progressPercent, 0.4);
      expect(state.completedNodeIds.length, 2);
      expect(state.quizScores?['phase_1']?['passed'], true);
    });

    test('DuplicateCheckResultModel handles existing roadmap validation', () {
      final duplicateJson = {
        'exists': true,
        'message': 'You already have an active roadmap for Full-Stack Developer.',
        'existingRoadmap': {
          'id': 'rdm_123',
          'target_role': 'Full-Stack Developer',
          'version': 1,
        },
      };

      final duplicateResult = DuplicateCheckResultModel.fromJson(duplicateJson);
      expect(duplicateResult.exists, true);
      expect(duplicateResult.hasExisting, true);
      expect(duplicateResult.existingRoadmap?['target_role'], 'Full-Stack Developer');

      final freshJson = {
        'exists': false,
        'message': 'No existing roadmap found for Cloud Engineer.',
        'existingRoadmap': null,
      };

      final freshResult = DuplicateCheckResultModel.fromJson(freshJson);
      expect(freshResult.exists, false);
      expect(freshResult.hasExisting, false);
      expect(freshResult.existingRoadmap, isNull);
    });

    test('SkillGapAnalysisModel formats skills that need improvement correctly', () {
      final json = {
        'target_role': 'Flutter Architect',
        'strong_skills': ['State Management', 'Dart OOP'],
        'needs_work_skills': ['Custom RenderObjects'],
        'missing_skills': ['Platform Channels C++'],
        'recommended_next_step': 'Complete Phase 3 platform channels exercise.',
      };

      final model = SkillGapAnalysisModel.fromJson(json);
      expect(model.targetRole, 'Flutter Architect');
      expect(model.strongSkills.length, 2);
      expect(model.needsWorkSkills.length, 1);
      expect(model.missingSkills.length, 1);

      final improvementList = model.skillsThatNeedImprovement;
      expect(improvementList.length, 4);

      final needsWork = improvementList.firstWhere((item) => item['status'] == 'Needs Work');
      expect(needsWork['skill'], 'Custom RenderObjects');

      final missing = improvementList.firstWhere((item) => item['status'] == 'Missing');
      expect(missing['skill'], 'Platform Channels C++');

      final strong = improvementList.firstWhere((item) => item['status'] == 'Strong');
      expect(strong['skill'], 'State Management');
    });

    test('JobReadinessModel computes readiness levels correctly', () {
      final readyJson = {
        'overallPercent': 82,
        'technicalPercent': 85,
        'projectsPercent': 80,
        'problemSolvingPercent': 78,
        'interviewPercent': 85,
        'portfolioPercent': 80,
        'nextPriority': 'Complete mock interviews.',
      };
      final readyModel = JobReadinessModel.fromJson(readyJson);
      expect(readyModel.readinessPercentage, 82);
      expect(readyModel.readinessLevel, 'Placement Ready');

      final intermediateJson = {
        'overallPercent': 55,
        'technicalPercent': 60,
        'projectsPercent': 50,
        'problemSolvingPercent': 55,
        'interviewPercent': 40,
        'portfolioPercent': 45,
        'nextPriority': 'Build phase 2 project.',
      };
      final intermediateModel = JobReadinessModel.fromJson(intermediateJson);
      expect(intermediateModel.readinessLevel, 'Intermediate Builder');

      final earlyJson = {
        'overallPercent': 25,
        'technicalPercent': 30,
        'projectsPercent': 15,
        'problemSolvingPercent': 20,
        'interviewPercent': 10,
        'portfolioPercent': 10,
        'nextPriority': 'Complete foundations.',
      };
      final earlyModel = JobReadinessModel.fromJson(earlyJson);
      expect(earlyModel.readinessLevel, 'Early Foundations');
    });

    test('DailyLearningPlanModel parses microGoal and task items accurately', () {
      final json = {
        'today_goal': 'Implement JWT Refresh Rotation in Node.js',
        'estimated_minutes': 75,
        'priority': 'HIGH',
        'phase_number': 2,
        'phase_title': 'Backend Auth & Security',
        'tasks': [
          {
            'id': 'task_jwt',
            'title': 'Build Refresh Token endpoint',
            'estimatedMinutes': 45,
            'category': 'PRACTICE',
          },
        ],
      };

      final plan = DailyLearningPlanModel.fromJson(json);
      expect(plan.microGoal, 'Implement JWT Refresh Rotation in Node.js');
      expect(plan.estimatedMinutes, 75);
      expect(plan.priority, 'HIGH');
      expect(plan.phaseNumber, 2);
      expect(plan.tasks.length, 1);
      expect(plan.tasks.first.title, 'Build Refresh Token endpoint');
      expect(plan.tasks.first.category, 'PRACTICE');
    });
  });

  group('HelpSupportView Widget Tests', () {
    testWidgets('Renders Help & Support view with search, report action and FAQs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HelpSupportView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('How can we help you today?'), findsOneWidget);
      expect(find.text('Report an Issue or Send Feedback'), findsOneWidget);
      expect(find.text('Frequently Asked Questions'), findsOneWidget);
      expect(find.text('Campus IT & Admin Desk'), findsOneWidget);
      expect(find.text('Account & Security'), findsOneWidget);
    });

    testWidgets('Filtering FAQs dynamically updates category list', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HelpSupportView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'password');
      await tester.pumpAndSettle();

      expect(find.text('Account & Security'), findsOneWidget);
    });
  });

  group('AboutView Widget Tests', () {
    testWidgets('Renders AboutView with branding, pillars and academic branches', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AboutView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('About CampusHub'), findsOneWidget);
      expect(find.text('CampusHub'), findsOneWidget);
      expect(find.text('Version 1.0.0 (Build 2026.08)'), findsOneWidget);
      expect(find.text('Our Mission'), findsOneWidget);
      expect(find.text('Core Ecosystem Pillars'), findsOneWidget);
      expect(find.text('Academic Collaboration'), findsOneWidget);
      expect(find.text('AI Career Pathfinder'), findsOneWidget);
      expect(find.text('Supported Academic Branches'), findsOneWidget);
      expect(find.text('Open Source Licenses & Attribution'), findsOneWidget);
    });
  });

  group('AI Roadmap Feature Widget Tests', () {
    testWidgets('EvaAiAvatar renders pulsing glowing avatar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: EvaAiAvatar(size: 72, isPulsing: true),
            ),
          ),
        ),
      );

      expect(find.byType(EvaAiAvatar), findsOneWidget);
    });

    testWidgets('PhaseProjectDialog displays tech stack and enables portfolio export', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PhaseProjectDialog(
                roadmapId: 'rdm_fullstack_2026',
                projectTitle: 'Real-Time Chat & Collab Server',
                description: 'Build a production-grade WebSockets backend with Redis Pub/Sub.',
                techStack: ['Node.js', 'Redis', 'WebSockets', 'PostgreSQL'],
                requirements: [
                  'Sub-50ms message latency across rooms',
                  'Persistent message store with PostgreSQL',
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Real-Time Chat & Collab Server'), findsOneWidget);
      expect(find.text('Node.js'), findsOneWidget);
      expect(find.text('Redis'), findsOneWidget);
      expect(find.text('Sub-50ms message latency across rooms'), findsOneWidget);
      expect(find.text('Add to CampusHub Portfolio'), findsOneWidget);

      // Tap to show export fields
      await tester.tap(find.text('Add to CampusHub Portfolio'));
      await tester.pumpAndSettle();

      expect(find.text('Export to Portfolio'), findsOneWidget);
      expect(find.text('Confirm & Add to Portfolio'), findsOneWidget);
    });
  });
}

