import { z } from 'zod';
import {
  RoadmapPhase,
  SkillGapAnalysis,
  SkillMapNode,
  DailyLearningPlan,
  InterviewQuestion,
  AdaptiveQuizQuestion,
  AdaptiveQuizResponse,
  QuizQuestionType,
} from './career.types';
import { logger } from '../../infrastructure/logger/logger';

// Strict Zod schema for validated AI roadmap phase
const roadmapTaskSchema = z.object({
  id: z.string(),
  title: z.string(),
  type: z.enum(['LEARN', 'PRACTICE', 'CHALLENGE']),
  duration_mins: z.number().min(5).max(180),
  is_completed: z.boolean().default(false),
  resource_ref: z.string().optional(),
});

const roadmapQuizQuestionSchema = z.object({
  question: z.string().min(5),
  options: z.array(z.string()).min(2).max(5),
  correct_index: z.number().min(0).max(4),
  explanation: z.string().min(5),
});

const roadmapPhaseSchema = z.object({
  phase_number: z.number().min(1),
  title: z.string().min(3),
  weeks: z.number().min(1),
  description: z.string(),
  objectives: z.array(z.string()),
  skills: z.array(z.string()),
  tasks: z.array(roadmapTaskSchema),
  practical_challenge: z
    .object({
      title: z.string(),
      description: z.string(),
      requirements: z.array(z.string()),
      difficulty: z.enum(['Beginner', 'Intermediate', 'Advanced']),
    })
    .optional(),
  project: z
    .object({
      title: z.string(),
      description: z.string(),
      difficulty: z.enum(['Beginner', 'Intermediate', 'Advanced']),
      tech_stack: z.array(z.string()),
      milestones: z.array(z.string()),
    })
    .optional(),
  quiz: z
    .object({
      title: z.string(),
      questions: z.array(roadmapQuizQuestionSchema),
    })
    .optional(),
  completion_criteria: z.string(),
});

export class CareerAIService {
  /**
   * Generates a fully structured, multi-phase AI roadmap.
   * Validated against strict Zod schemas with domain curricula.
   */
  public generateRoadmapStructure(params: {
    role: string;
    level: string;
    weeklyHours: number;
    goal?: string;
    deadlineDays?: number;
    isPlacementFocused?: boolean;
    assessmentData?: Record<string, unknown>;
  }): {
    phases: RoadmapPhase[];
    skillMap: SkillMapNode[];
    skillGaps: SkillGapAnalysis;
    estimatedMonths: number;
  } {
    const roleNormalized = params.role.trim().toLowerCase();
    const isCpp = roleNormalized.includes('c++') || roleNormalized.includes('cpp') || roleNormalized.includes('competitive');
    const isFlutter = roleNormalized.includes('flutter') || roleNormalized.includes('mobile');
    const isBackend = roleNormalized.includes('backend') || roleNormalized.includes('system') || roleNormalized.includes('distributed');
    const isAi = roleNormalized.includes('ai') || roleNormalized.includes('machine') || roleNormalized.includes('data');
    const isCyber = roleNormalized.includes('cyber') || roleNormalized.includes('security');

    let phases: RoadmapPhase[];
    let skillMap: SkillMapNode[];

    if (isCpp) {
      phases = this.getCppCurriculum(params.level, params.isPlacementFocused);
      skillMap = this.getCppSkillMap();
    } else if (isFlutter) {
      phases = this.getFlutterCurriculum(params.level, params.isPlacementFocused);
      skillMap = this.getFlutterSkillMap();
    } else if (isBackend) {
      phases = this.getBackendCurriculum(params.level, params.isPlacementFocused);
      skillMap = this.getBackendSkillMap();
    } else if (isAi) {
      phases = this.getAiCurriculum(params.level, params.isPlacementFocused);
      skillMap = this.getAiSkillMap();
    } else if (isCyber) {
      phases = this.getCyberCurriculum(params.level, params.isPlacementFocused);
      skillMap = this.getCyberSkillMap();
    } else {
      phases = this.getFullStackCurriculum(params.level, params.isPlacementFocused);
      skillMap = this.getFullStackSkillMap();
    }

    // Validate all phases against strict Zod schema
    const validatedPhases: RoadmapPhase[] = [];
    for (const phase of phases) {
      const parsed = roadmapPhaseSchema.safeParse(phase);
      if (parsed.success) {
        validatedPhases.push(parsed.data as RoadmapPhase);
      } else {
        logger.warn({ error: parsed.error }, 'Roadmap phase validation warning, falling back to raw');
        validatedPhases.push(phase);
      }
    }

    // Skill Gap initial analysis
    const initialGaps: SkillGapAnalysis = {
      target_role: params.role,
      strong_skills: params.level === 'Expert' ? [phases[0].skills[0], phases[0].skills[1]] : [],
      needs_work_skills: [phases[0].skills[0], phases[0].skills[1] || 'Fundamentals'],
      missing_skills: phases.slice(1).flatMap((p) => p.skills.slice(0, 2)),
      recommended_next_step: `Start with ${phases[0].title}: complete the core syntax and interactive challenge.`,
    };

    const totalWeeks = validatedPhases.reduce((acc, p) => acc + p.weeks, 0);
    const estimatedMonths = Math.max(2, Math.round(totalWeeks / 4));

    return {
      phases: validatedPhases,
      skillMap,
      skillGaps: initialGaps,
      estimatedMonths,
    };
  }

  /**
   * Generates a context-aware daily learning plan
   */
  public generateDailyPlan(
    roadmap: { target_role?: string; phases_json?: unknown },
    activeProgress: { current_focus?: string; progress_percent?: number; quiz_scores?: unknown; completed_node_count?: number }
  ): DailyLearningPlan {
    const rawPhases = (roadmap.phases_json as RoadmapPhase[]) || [];
    const activePhase = rawPhases[0] || {
      phase_number: 1,
      title: 'Phase 1: Foundations',
      tasks: [],
    };

    const unfinishedTasks = activePhase.tasks?.filter((t) => !t.is_completed) || [];
    const todayTasks = unfinishedTasks.slice(0, 3);

    if (todayTasks.length === 0) {
      todayTasks.push(
        { id: 'dt_1', title: 'Deep dive into core architecture patterns', type: 'LEARN', duration_mins: 25, is_completed: false },
        { id: 'dt_2', title: 'Solve 2 practical scenario implementation exercises', type: 'PRACTICE', duration_mins: 20, is_completed: false },
        { id: 'dt_3', title: 'Code practical mini challenge for milestone review', type: 'CHALLENGE', duration_mins: 15, is_completed: false }
      );
    }

    const estimatedTotalMinutes = todayTasks.reduce((acc, t) => acc + t.duration_mins, 0);

    return {
      today_goal: activeProgress.current_focus || `Master ${activePhase.title}`,
      estimated_minutes: estimatedTotalMinutes || 60,
      priority: (activeProgress.progress_percent || 0) < 30 ? 'HIGH' : 'NORMAL',
      phase_number: activePhase.phase_number || 1,
      phase_title: activePhase.title || 'Foundations',
      tasks: todayTasks,
    };
  }

  /**
   * Evaluates skill gaps based on roadmap requirements and real performance evidence
   */
  public evaluateSkillGaps(
    targetRole: string,
    phases: RoadmapPhase[],
    quizScores: Record<string, { score: number; total: number; percentage: number; passed?: boolean }> = {},
    completedNodeIds: string[] = []
  ): SkillGapAnalysis {
    const strongSkills: string[] = [];
    const needsWorkSkills: string[] = [];
    const missingSkills: string[] = [];

    phases.forEach((phase, idx) => {
      const quizKey = `phase_${phase.phase_number}`;
      const scoreData = quizScores[quizKey];

      if (scoreData && scoreData.percentage >= 75) {
        strongSkills.push(...phase.skills.slice(0, 3));
      } else if (scoreData && scoreData.percentage < 75) {
        needsWorkSkills.push(...phase.skills.slice(0, 2));
      } else if (idx === 0) {
        needsWorkSkills.push(...phase.skills.slice(0, 2));
      } else {
        missingSkills.push(...phase.skills.slice(0, 2));
      }
    });

    const topNeedsWork = Array.from(new Set(needsWorkSkills)).slice(0, 4);
    const topStrong = Array.from(new Set(strongSkills)).slice(0, 4);
    const topMissing = Array.from(new Set(missingSkills)).slice(0, 4);

    let nextStep = `Focus on ${topNeedsWork[0] || 'Foundations'}: complete the phase quiz and practical challenge.`;
    if (topNeedsWork.length > 0) {
      nextStep = `Reinforce ${topNeedsWork[0]} with targeted practice before moving forward.`;
    }

    return {
      target_role: targetRole,
      strong_skills: topStrong,
      needs_work_skills: topNeedsWork,
      missing_skills: topMissing,
      recommended_next_step: nextStep,
    };
  }

  /**
   * Adapts the roadmap based on student activity (quiz scores, performance, time changes)
   */
  public adaptRoadmap(params: {
    targetRole: string;
    phases: RoadmapPhase[];
    quizScores: Record<string, { score: number; total: number; percentage: number }>;
    feedbackNote?: string;
  }): {
    adaptedPhases: RoadmapPhase[];
    adaptationSummary: string;
    skillGaps: SkillGapAnalysis;
  } {
    const updatedPhases = [...params.phases];
    let adaptationSummary = 'Roadmap is on track. Continuing with scheduled phases.';

    // Check if any quiz showed weak performance
    for (const [phaseKey, score] of Object.entries(params.quizScores)) {
      const phaseNum = parseInt(phaseKey.replace('phase_', ''), 10);
      const phaseIndex = updatedPhases.findIndex((p) => p.phase_number === phaseNum);

      if (phaseIndex !== -1 && score.percentage < 60) {
        const targetPhase = updatedPhases[phaseIndex];
        adaptationSummary = `Adaptive AI detected reinforcement needed for ${targetPhase.title} (${score.percentage}% quiz score). Added targeted remediation practice exercises.`;

        // Add reinforcement task if not already present
        const hasReinforcement = targetPhase.tasks.some((t) => t.title.includes('Reinforcement'));
        if (!hasReinforcement) {
          targetPhase.tasks.unshift({
            id: `reinf_${Date.now()}`,
            title: `Reinforcement: Core review of ${targetPhase.skills[0] || 'concepts'}`,
            type: 'PRACTICE',
            duration_mins: 30,
            is_completed: false,
          });
        }
      }
    }

    const gaps = this.evaluateSkillGaps(params.targetRole, updatedPhases, params.quizScores as any);

    return {
      adaptedPhases: updatedPhases,
      adaptationSummary,
      skillGaps: gaps,
    };
  }

  /**
   * Answers contextual questions regarding the student's active roadmap.
   */
  public answerRoadmapQuery(params: {
    prompt: string;
    role: string;
    currentPhase: string;
    progressPercent: number;
    weakSkills: string[];
  }): { answer: string; suggestedActions: string[] } {
    const query = params.prompt.toLowerCase();

    if (query.includes('hour') || query.includes('time') || query.includes('short on time')) {
      return {
        answer: `If you only have limited time today, focus strictly on one micro-task in **${params.currentPhase}**. Complete 25 minutes of hands-on practice on **${params.weakSkills[0] || 'core concepts'}** rather than reading theory. Consistency compounds!`,
        suggestedActions: ['Open Today\'s Learning Plan', 'Take 5-min Quick Quiz'],
      };
    }

    if (query.includes('project') || query.includes('portfolio') || query.includes('build')) {
      return {
        answer: `For your **${params.role}** path, focus on building a real-world project that demonstrates **${params.weakSkills[0] || 'state management and APIs'}**. When finished, you can export it with one tap to your CampusHub Student Portfolio for campus recruitment visibility.`,
        suggestedActions: ['View Phase Project Specs', 'Export to CampusHub Portfolio'],
      };
    }

    if (query.includes('stuck') || query.includes('mentor') || query.includes('help')) {
      return {
        answer: `If you are stuck on **${params.currentPhase}**, don't worry! Try breaking the problem into isolated unit tests. If you still need guidance, use the **Ask Faculty Mentor** option below to share your current roadmap milestone with your assigned professor.`,
        suggestedActions: ['Ask Faculty Mentor', 'Review Concept Explanations'],
      };
    }

    if (query.includes('interview') || query.includes('placement')) {
      return {
        answer: `Campus recruiters evaluating **${params.role}** candidates focus heavily on how you handle architecture trade-offs and edge cases. Make sure to prepare STAR-method explanations for your roadmap projects and review system design fundamentals.`,
        suggestedActions: ['Open Interview Preparation', 'Take Checkpoint Quiz'],
      };
    }

    return {
      answer: `Based on your **${params.role}** roadmap (currently at ${params.progressPercent}% in ${params.currentPhase}): your primary learning objective is mastering **${params.weakSkills[0] || 'the active milestone'}**. Keep following the daily micro-goals and complete the checkpoint quiz when ready.`,
      suggestedActions: ['Continue Active Phase', 'Check Skill Dependency Map'],
    };
  }

  /**
   * Generates contextual interview questions
   */
  public generateInterviewPrep(role: string, completedSkills: string[]): InterviewQuestion[] {
    const isFlutter = role.toLowerCase().includes('flutter') || role.toLowerCase().includes('mobile');

    if (isFlutter) {
      return [
        {
          id: 'int_1',
          type: 'TECHNICAL',
          question: 'How does Riverpod 2.0 differ from Provider and StateNotifier in terms of compile-time safety and auto-disposal?',
          context: 'Assesses state management architecture and memory leak awareness.',
          tips: ['Mention compile-time safety without BuildContext', 'Discuss ref.watch vs ref.read', 'Highlight autoDispose and family modifiers'],
        },
        {
          id: 'int_2',
          type: 'PROJECT',
          question: 'In your Flutter application, describe how you designed the network caching layer and handled token refresh when access tokens expire.',
          context: 'Focuses on Dio interceptors and offline persistence.',
          tips: ['Explain QueuedInterceptor lock/unlock mechanism', 'Mention secure storage for refresh tokens', 'Discuss cache-first fallback with Hive/SQLite'],
        },
        {
          id: 'int_3',
          type: 'SYSTEM_DESIGN',
          question: 'Design a real-time collaborative chat module in Flutter with offline synchronization and message delivery receipts.',
          context: 'Tests WebSocket integration, optimistic UI updates, and local database sync.',
          tips: ['Describe optimistic UI message insertion', 'Detail WebSocket reconnection strategy', 'Explain read receipt acknowledgment packets'],
        },
        {
          id: 'int_4',
          type: 'BEHAVIORAL',
          question: 'Tell me about a difficult performance jank or memory leak issue you encountered in your mobile project and how you profiled it.',
          context: 'STAR method evaluation of debugging rigor.',
          tips: ['Use Flutter DevTools performance overlay', 'Mention RepaintBoundary and build method minimization', 'Quantify frame time improvements'],
        },
      ];
    }

    return [
      {
        id: 'int_1',
        type: 'TECHNICAL',
        question: 'Explain how Node.js event loop handles I/O polling, timers, and microtasks (Promise.then vs process.nextTick).',
        context: 'Core runtime concurrency understanding.',
        tips: ['Explain Libuv thread pool vs event loop', 'Detail microtask queue execution order', 'Discuss non-blocking asynchronous patterns'],
      },
      {
        id: 'int_2',
        type: 'PROJECT',
        question: 'How did you structure the relational database schema in PostgreSQL to prevent N+1 query problems and ensure data consistency?',
        context: 'Prisma ORM optimization and database normalization.',
        tips: ['Explain SQL JOINs vs separate queries', 'Discuss B-Tree indexing on foreign keys', 'Explain database transactions with ACID guarantees'],
      },
      {
        id: 'int_3',
        type: 'SYSTEM_DESIGN',
        question: 'How would you design a distributed rate-limiter for a public campus API handling 50,000 requests per minute?',
        context: 'Distributed caching and system resilience.',
        tips: ['Compare Sliding Window Counter vs Token Bucket in Redis', 'Explain rate limit response headers (429 Too Many Requests)', 'Discuss Redis cluster fallback'],
      },
      {
        id: 'int_4',
        type: 'BEHAVIORAL',
        question: 'Describe a situation where a major API broke in production or during an integration test. How did you diagnose and remediate it?',
        context: 'Problem solving under pressure.',
        tips: ['Use STAR framework (Situation, Task, Action, Result)', 'Mention structured logging (Pino/Winston)', 'Discuss post-mortem and automated test regression prevention'],
      },
    ];
  }

  // ==========================================
  // CURRICULUM TEMPLATES
  // ==========================================

  private getFlutterCurriculum(level: string, isPlacement?: boolean): RoadmapPhase[] {
    return [
      {
        phase_number: 1,
        title: 'Phase 1: Dart 3 Foundations & Object-Oriented Mastery',
        weeks: 2,
        description: 'Deep dive into Dart 3 language features, records, pattern matching, type safety, null safety, futures, and streams.',
        objectives: [
          'Master Dart 3 records, switch expressions, and exhaustive pattern matching',
          'Understand asynchronous concurrency with Futures, Streams, and async*',
          'Implement clean object-oriented architecture using interfaces and mixins',
        ],
        skills: ['Dart 3 Core', 'OOP Principles', 'Async / Await', 'Streams & Reactive'],
        tasks: [
          { id: 't_f1_1', title: 'Dart 3 Pattern Matching & Records Syntax', type: 'LEARN', duration_mins: 30, is_completed: false },
          { id: 't_f1_2', title: 'Implement generic Repository interface with Futures', type: 'PRACTICE', duration_mins: 25, is_completed: false },
          { id: 't_f1_3', title: 'Write StreamController reactive data pipeline test', type: 'CHALLENGE', duration_mins: 20, is_completed: false },
        ],
        practical_challenge: {
          title: 'Reactive Async Stream Transformer',
          description: 'Build a Dart library module that debounces and throttles user search keystrokes without external packages.',
          requirements: ['Use StreamController<String>', 'Debounce search events by 300ms', 'Handle cancellation cleanly'],
          difficulty: 'Intermediate',
        },
        quiz: {
          title: 'Dart 3 & Asynchronous Concurrency Checkpoint',
          questions: [
            {
              question: 'In Dart 3, what is the main advantage of using Records over custom tuple classes?',
              options: [
                'Records are mutable and dynamically typed',
                'Records are immutable, aggregate anonymous composite values with compile-time type safety',
                'Records replace all abstract classes in Flutter',
                'Records can only store primitive integers',
              ],
              correct_index: 1,
              explanation: 'Records are first-class anonymous composite values that are deeply immutable and type-safe.',
            },
            {
              question: 'What happens when an unhandled exception occurs inside a Dart Future?',
              options: [
                'The app crashes immediately with a kernel panic',
                'The Future completes with an error state that can be caught via .catchError or try/catch with await',
                'The event loop resets all running timers',
                'The error is ignored silently by Dart runtime',
              ],
              correct_index: 1,
              explanation: 'Futures model errors as completions with an error object, caught using try/catch on awaited futures.',
            },
            {
              question: 'Why is it essential to close StreamControllers when a widget or service is disposed?',
              options: [
                'To free up operating system file handles and prevent memory leaks',
                'To automatically restart the Flutter engine',
                'To trigger garbage collection on all widgets immediately',
                'Dart automatically closes all streams so closing is optional',
              ],
              correct_index: 0,
              explanation: 'Unclosed StreamControllers retain subscriptions and listener closures, causing memory leaks.',
            },
          ],
        },
        completion_criteria: 'Score at least 67% on the Dart checkpoint quiz and complete the Reactive Async Stream challenge.',
      },
      {
        phase_number: 2,
        title: 'Phase 2: Flutter UI Architecture, Layouts & Theming',
        weeks: 3,
        description: 'Understand the three widget trees (Widget, Element, RenderObject), Material 3 design system, and responsive layouts.',
        objectives: [
          'Understand the widget build pipeline and jank prevention',
          'Build adaptive responsive layouts using LayoutBuilder and MediaQuery',
          'Implement full Material 3 light/dark theming and custom extensions',
        ],
        skills: ['Widget Tree', 'RenderObjects', 'Material 3', 'Responsive Layouts'],
        tasks: [
          { id: 't_f2_1', title: 'Widget vs Element vs RenderObject mechanics', type: 'LEARN', duration_mins: 30, is_completed: false },
          { id: 't_f2_2', title: 'Build custom ThemeExtension for campus branding', type: 'PRACTICE', duration_mins: 25, is_completed: false },
          { id: 't_f2_3', title: 'Construct responsive tablet/mobile grid layout', type: 'CHALLENGE', duration_mins: 20, is_completed: false },
        ],
        practical_challenge: {
          title: 'Adaptive Campus Dashboard Card UI',
          description: 'Build an interactive dashboard widget that adapts between mobile phone view and widescreen tablet view without overflow.',
          requirements: ['Support Material 3 dynamic color', 'Zero layout overflow errors on small screens', 'Smooth subtle animations on press'],
          difficulty: 'Intermediate',
        },
        quiz: {
          title: 'Flutter Widget Architecture Checkpoint',
          questions: [
            {
              question: 'Which component in Flutter is actually responsible for layout, painting, and hit testing?',
              options: ['The Widget', 'The RenderObject', 'The BuildContext', 'The StateNotifier'],
              correct_index: 1,
              explanation: 'Widgets are lightweight immutable configurations; RenderObjects perform actual layout sizing and painting.',
            },
            {
              question: 'Why should expensive computations never be placed directly inside a widget\'s build() method?',
              options: [
                'Flutter does not allow CPU operations in build()',
                'build() can be called every frame (60–120 FPS), causing severe UI jank if it contains heavy work',
                'It causes compile-time syntax errors',
                'build() methods can only return Text widgets',
              ],
              correct_index: 1,
              explanation: 'Flutter re-evaluates build() frequently. Heavy computations must be offloaded to providers or background isolates.',
            },
          ],
        },
        completion_criteria: 'Complete the Adaptive Card challenge and pass the Widget Architecture quiz.',
      },
      {
        phase_number: 3,
        title: 'Phase 3: Production State Management with Riverpod 2.0',
        weeks: 3,
        description: 'Master Riverpod 2.0 Notifiers, AsyncNotifier, family providers, autoDispose, and clean state mutation patterns.',
        objectives: [
          'Architect scalable state flows using AsyncNotifier and family providers',
          'Implement optimistic UI updates with automatic error rollback',
          'Organize code using Feature-First and Layer-First clean architecture',
        ],
        skills: ['Riverpod 2.0', 'AsyncNotifier', 'Clean Architecture', 'State Modeling'],
        tasks: [
          { id: 't_f3_1', title: 'AsyncNotifier with AsyncValue.guard pattern', type: 'LEARN', duration_mins: 35, is_completed: false },
          { id: 't_f3_2', title: 'Implement optimistic state toggle with rollback', type: 'PRACTICE', duration_mins: 30, is_completed: false },
          { id: 't_f3_3', title: 'Unit test Riverpod providers using ProviderContainer', type: 'CHALLENGE', duration_mins: 25, is_completed: false },
        ],
        practical_challenge: {
          title: 'Optimistic Bookmark & Like System',
          description: 'Build a Riverpod state controller for post liking that immediately toggles UI state and rolls back if API throws 500.',
          requirements: ['Use AsyncNotifier<List<Post>>', 'Optimistic UI update', 'Display toast and rollback on failure'],
          difficulty: 'Intermediate',
        },
        project: {
          title: 'Campus Task & Study Planner App',
          description: 'A complete Riverpod-powered application managing study sessions, task filtering, and persistent state.',
          difficulty: 'Intermediate',
          tech_stack: ['Flutter', 'Riverpod 2.0', 'GoRouter', 'Hive'],
          milestones: [
            'Setup ProviderContainer and clean folder structure',
            'Implement task creation with AsyncNotifier',
            'Add filtering by category and due dates',
            'Write provider unit tests with 80%+ coverage',
          ],
        },
        completion_criteria: 'Submit the Campus Study Planner app and score >= 70% on State Management quiz.',
      },
      {
        phase_number: 4,
        title: 'Phase 4: Networking, Offline Caching & WebSockets',
        weeks: 4,
        description: 'Professional networking with Dio, JWT interceptors, automatic refresh tokens, Socket.IO client, and offline caching.',
        objectives: [
          'Implement secure Dio interceptors with automatic token refresh',
          'Build real-time bi-directional messaging with Socket.IO client',
          'Design offline-first persistence with Hive or SQLite',
        ],
        skills: ['Dio Networking', 'JWT Refresh Token', 'Socket.IO', 'Offline SQLite/Hive'],
        tasks: [
          { id: 't_f4_1', title: 'Dio QueuedInterceptor token refresh pipeline', type: 'LEARN', duration_mins: 30, is_completed: false },
          { id: 't_f4_2', title: 'Implement Socket.IO connection manager with reconnection', type: 'PRACTICE', duration_mins: 30, is_completed: false },
          { id: 't_f4_3', title: 'Offline cache-aside with Hive box storage', type: 'CHALLENGE', duration_mins: 25, is_completed: false },
        ],
        project: {
          title: 'Real-Time Campus Study Squad Messenger',
          description: 'End-to-end messaging client featuring optimistic message sending, image attachments, read receipts, and offline draft storage.',
          difficulty: 'Advanced',
          tech_stack: ['Flutter', 'Riverpod', 'Dio', 'Socket.IO Client', 'SecureStorage'],
          milestones: [
            'Connect authenticated Socket.IO client with JWT handshake',
            'Implement room channels and live message streams',
            'Add typing indicators and read receipt acknowledgments',
            'Persist messages locally for offline viewing',
          ],
        },
        completion_criteria: 'Complete the Real-Time Messenger project with live socket events and offline persistence.',
      },
      {
        phase_number: 5,
        title: 'Phase 5: Production Polish, Performance Profiling & Placement',
        weeks: 3,
        description: 'Eliminate UI jank using Flutter DevTools, write widget tests, prepare for mobile system design, and mock interviews.',
        objectives: [
          'Profile GPU/UI thread jank and memory leaks using Flutter DevTools',
          'Write integration and Golden UI tests for core flows',
          'Master mobile system design (Offline sync, Image caching, Push notifications)',
        ],
        skills: ['Performance Profiling', 'DevTools', 'Widget Testing', 'Mobile System Design'],
        tasks: [
          { id: 't_f5_1', title: 'Flutter DevTools memory leak & jank profiling', type: 'LEARN', duration_mins: 30, is_completed: false },
          { id: 't_f5_2', title: 'Write widget test verifying Riverpod consumer rebuilding', type: 'PRACTICE', duration_mins: 25, is_completed: false },
          { id: 't_f5_3', title: 'Mobile system design: architect offline image caching system', type: 'CHALLENGE', duration_mins: 30, is_completed: false },
        ],
        completion_criteria: 'Pass the mobile system design evaluation and complete the final portfolio capstone project.',
      },
    ];
  }

  private getFullStackCurriculum(level: string, isPlacement?: boolean): RoadmapPhase[] {
    return [
      {
        phase_number: 1,
        title: 'Phase 1: Modern TypeScript & Asynchronous Architecture',
        weeks: 3,
        description: 'Core TypeScript type system, generics, utility types, event loops, Promises, and modern Node.js runtime.',
        objectives: ['Master TypeScript generics, unions, and intersection types', 'Understand Node.js asynchronous non-blocking event loop', 'Write clean modular ES modules with automated unit testing'],
        skills: ['TypeScript', 'Node.js', 'Async / Promises', 'Jest Testing'],
        tasks: [
          { id: 't_fs1_1', title: 'TypeScript Generics & Conditional Types', type: 'LEARN', duration_mins: 30, is_completed: false },
          { id: 't_fs1_2', title: 'Build custom Promise-based concurrency limiter', type: 'PRACTICE', duration_mins: 25, is_completed: false },
          { id: 't_fs1_3', title: 'Write automated Jest unit tests for async service', type: 'CHALLENGE', duration_mins: 20, is_completed: false },
        ],
        completion_criteria: 'Complete the concurrency limiter challenge and pass TypeScript fundamentals quiz.',
      },
      {
        phase_number: 2,
        title: 'Phase 2: Express Backend Architecture & Relational PostgreSQL',
        weeks: 4,
        description: 'Layered backend architecture, Express middleware, Prisma ORM, PostgreSQL indexes, transactions, and JWT authentication.',
        objectives: ['Build robust REST APIs using layered controller-service-repository pattern', 'Design normalized relational schemas with PostgreSQL and Prisma', 'Implement JWT access & refresh token rotation with security headers'],
        skills: ['Express.js', 'PostgreSQL', 'Prisma ORM', 'JWT Auth', 'REST API'],
        tasks: [
          { id: 't_fs2_1', title: 'Layered architecture: Controller, Service, Repository', type: 'LEARN', duration_mins: 30, is_completed: false },
          { id: 't_fs2_2', title: 'Prisma multi-table transactions with rollback', type: 'PRACTICE', duration_mins: 30, is_completed: false },
          { id: 't_fs2_3', title: 'Build secure authentication middleware with Zod validation', type: 'CHALLENGE', duration_mins: 25, is_completed: false },
        ],
        project: {
          title: 'Campus Course & Club Marketplace API',
          description: 'Scalable RESTful API supporting user roles (Student, Faculty, Admin), relational club memberships, and transaction-safe registrations.',
          difficulty: 'Intermediate',
          tech_stack: ['TypeScript', 'Express', 'PostgreSQL', 'Prisma', 'Zod', 'Argon2'],
          milestones: ['Schema design and migrations', 'Authentication and RBAC middleware', 'Club management CRUD with Prisma', 'Integration testing with Supertest'],
        },
        completion_criteria: 'Ship the Course & Club Marketplace API with passing Supertest suites.',
      },
      {
        phase_number: 3,
        title: 'Phase 3: Modern React Frontend & State Management',
        weeks: 4,
        description: 'React 18/19 hooks, component composition, server state management, and responsive styling.',
        objectives: ['Master React hooks (useEffect, useCallback, useMemo, custom hooks)', 'Implement server state caching and optimistic mutations', 'Construct clean design systems with Tailwind CSS'],
        skills: ['React', 'React Hooks', 'Tailwind CSS', 'State Management'],
        tasks: [
          { id: 't_fs3_1', title: 'Custom React hooks for data fetching & caching', type: 'LEARN', duration_mins: 30, is_completed: false },
          { id: 't_fs3_2', title: 'Implement optimistic UI comment submission', type: 'PRACTICE', duration_mins: 25, is_completed: false },
          { id: 't_fs3_3', title: 'Build accessible modal and dropdown keyboard navigation', type: 'CHALLENGE', duration_mins: 20, is_completed: false },
        ],
        completion_criteria: 'Complete the Frontend state management checkpoint.',
      },
      {
        phase_number: 4,
        title: 'Phase 4: Docker Containerization, Redis Caching & CI/CD',
        weeks: 3,
        description: 'Docker multi-stage builds, in-memory caching with Redis, rate-limiting, and GitHub Actions automated deployment.',
        objectives: ['Containerize full-stack apps with multi-stage Dockerfiles', 'Implement cache-aside architecture with Redis to cut latency', 'Configure automated CI/CD testing pipelines with GitHub Actions'],
        skills: ['Docker', 'Redis', 'CI/CD Pipelines', 'API Security'],
        tasks: [
          { id: 't_fs4_1', title: 'Docker multi-stage build optimization', type: 'LEARN', duration_mins: 30, is_completed: false },
          { id: 't_fs4_2', title: 'Redis cache-aside with TTL invalidation', type: 'PRACTICE', duration_mins: 25, is_completed: false },
          { id: 't_fs4_3', title: 'GitHub Actions workflow running lint and tests on PR', type: 'CHALLENGE', duration_mins: 25, is_completed: false },
        ],
        completion_criteria: 'Deploy full-stack Dockerized app with Redis cache layer.',
      },
      {
        phase_number: 5,
        title: 'Phase 5: System Design, Distributed Scaling & Placement Prep',
        weeks: 4,
        description: 'Design systems for 1M+ DAU: load balancers, database sharding, caching strategies, DSA coding patterns, and mock interviews.',
        objectives: ['Master high-level architecture: CDN, Load Balancers, Sharding, Message Queues', 'Solve top LeetCode patterns (Two Pointers, Sliding Window, Graphs, Trees)', 'Excel in technical STAR-method behavioral and system design interviews'],
        skills: ['System Design', 'Scalability', 'DSA Top Patterns', 'Technical Interviews'],
        tasks: [
          { id: 't_fs5_1', title: 'System design: Design TinyURL / Link Shortener with Analytics', type: 'LEARN', duration_mins: 35, is_completed: false },
          { id: 't_fs5_2', title: 'Solve 3 graph traversal BFS/DFS problems', type: 'PRACTICE', duration_mins: 30, is_completed: false },
          { id: 't_fs5_3', title: 'Mock interview: explain database index B-Tree trade-offs', type: 'CHALLENGE', duration_mins: 25, is_completed: false },
        ],
        completion_criteria: 'Complete the high-level system design capstone and placement assessment.',
      },
    ];
  }

  private getBackendCurriculum(level: string, isPlacement?: boolean): RoadmapPhase[] {
    return [
      {
        phase_number: 1,
        title: 'Phase 1: Backend Protocols, Concurrency & Clean Architecture',
        weeks: 3,
        description: 'TCP/IP, HTTP/1.1 vs HTTP/2 vs gRPC, event loop concurrency, and layered service repository patterns.',
        objectives: ['Understand network socket specs and protocols', 'Implement clean hexagonal/layered architecture', 'Master asynchronous event loops and thread pooling'],
        skills: ['HTTP Protocols', 'Concurrency', 'Node.js/Go', 'Clean Architecture'],
        tasks: [
          { id: 't_b1_1', title: 'HTTP/2 multiplexing vs HTTP/1.1 keep-alive', type: 'LEARN', duration_mins: 30, is_completed: false },
          { id: 't_b1_2', title: 'Build custom rate limiter with Sliding Window algorithm', type: 'PRACTICE', duration_mins: 30, is_completed: false },
        ],
        completion_criteria: 'Pass network protocol checkpoint and complete sliding window limiter.',
      },
      {
        phase_number: 2,
        title: 'Phase 2: Database Internals & Query Tuning (PostgreSQL)',
        weeks: 4,
        description: 'B-Tree vs Hash indexes, EXPLAIN ANALYZE query planning, ACID isolation levels, and zero-downtime migrations.',
        objectives: ['Analyze SQL query execution plans with EXPLAIN ANALYZE', 'Optimize slow queries with composite and partial indexes', 'Handle race conditions using pessimistic and optimistic locks'],
        skills: ['PostgreSQL Internals', 'Query Tuning', 'ACID Transactions', 'Indexing Strategies'],
        tasks: [
          { id: 't_b2_1', title: 'PostgreSQL EXPLAIN ANALYZE & Buffer Read analysis', type: 'LEARN', duration_mins: 30, is_completed: false },
          { id: 't_b2_2', title: 'Prevent double-spending bug using SELECT FOR UPDATE', type: 'PRACTICE', duration_mins: 25, is_completed: false },
        ],
        completion_criteria: 'Pass database optimization practical challenge.',
      },
      {
        phase_number: 3,
        title: 'Phase 3: In-Memory Caching & Message Queues (Redis, RabbitMQ)',
        weeks: 4,
        description: 'Redis caching patterns (Cache-Aside, Write-Through), message queues with RabbitMQ/Kafka, and event-driven architecture.',
        objectives: ['Implement distributed cache invalidation strategies', 'Build asynchronous background workers using message queues', 'Handle dead letter queues and retry policies'],
        skills: ['Redis Caching', 'Message Brokers', 'Event-Driven Systems', 'Pub/Sub'],
        tasks: [
          { id: 't_b3_1', title: 'Redis cache stampede prevention using distributed locks', type: 'LEARN', duration_mins: 35, is_completed: false },
          { id: 't_b3_2', title: 'Construct RabbitMQ background task consumer with retries', type: 'PRACTICE', duration_mins: 30, is_completed: false },
        ],
        completion_criteria: 'Deploy an event-driven worker pipeline with dead letter queues.',
      },
      {
        phase_number: 4,
        title: 'Phase 4: Microservices, Observability & Cloud Security',
        weeks: 3,
        description: 'Structured logging, distributed tracing with OpenTelemetry, Prometheus metrics, and OWASP API security.',
        objectives: ['Implement structured JSON logging with correlation IDs', 'Set up Prometheus metrics and Grafana dashboards', 'Harden APIs against OWASP Top 10 vulnerabilities'],
        skills: ['OpenTelemetry', 'Prometheus', 'OWASP API Security', 'Docker'],
        tasks: [
          { id: 't_b4_1', title: 'Distributed tracing across microservices with trace headers', type: 'LEARN', duration_mins: 30, is_completed: false },
          { id: 't_b4_2', title: 'Audit and patch SQL injection and IDOR vulnerabilities', type: 'PRACTICE', duration_mins: 25, is_completed: false },
        ],
        completion_criteria: 'Complete security audit and monitoring setup.',
      },
      {
        phase_number: 5,
        title: 'Phase 5: High-Scale Distributed System Design & Interview Mastery',
        weeks: 4,
        description: 'CAP Theorem, consistent hashing, distributed consensus (Raft), database sharding, and mock system design rounds.',
        objectives: ['Design fault-tolerant distributed systems handling 100k+ RPS', 'Master consistent hashing and partitioned storage', 'Crack product company technical interview loops'],
        skills: ['Distributed Systems', 'CAP Theorem', 'Consistent Hashing', 'Tech Interviews'],
        tasks: [
          { id: 't_b5_1', title: 'Design distributed key-value store with consistent hashing', type: 'LEARN', duration_mins: 40, is_completed: false },
          { id: 't_b5_2', title: 'System design mock: design a high-volume notification engine', type: 'PRACTICE', duration_mins: 30, is_completed: false },
        ],
        completion_criteria: 'Complete final system design interview simulation.',
      },
    ];
  }

  private getAiCurriculum(level: string, isPlacement?: boolean): RoadmapPhase[] {
    return [
      {
        phase_number: 1,
        title: 'Phase 1: Python for Data Science & Numerical Computing',
        weeks: 3,
        description: 'Vectorized operations with NumPy, Pandas data wrangling, data visualization, and applied linear algebra.',
        objectives: ['Master NumPy array broadcasting and matrix manipulation', 'Clean and transform tabular datasets with Pandas', 'Apply linear algebra concepts (eigenvalues, dot products, tensors)'],
        skills: ['Python 3', 'NumPy', 'Pandas', 'Linear Algebra'],
        tasks: [
          { id: 't_ai1_1', title: 'NumPy broadcasting and vectorized calculations', type: 'LEARN', duration_mins: 30, is_completed: false },
          { id: 't_ai1_2', title: 'Clean real-world missing data pipeline with Pandas', type: 'PRACTICE', duration_mins: 25, is_completed: false },
        ],
        completion_criteria: 'Complete the numerical data pipeline challenge.',
      },
      {
        phase_number: 2,
        title: 'Phase 2: Classical Machine Learning & Scikit-Learn',
        weeks: 4,
        description: 'Supervised vs unsupervised learning, regression, decision trees, cross-validation, and feature engineering.',
        objectives: ['Train regression and classification models with Scikit-Learn', 'Evaluate models using ROC-AUC, F1-Score, and cross-validation', 'Prevent data leakage during preprocessing and feature scaling'],
        skills: ['Scikit-Learn', 'Feature Engineering', 'Model Validation', 'Regression/Classification'],
        tasks: [
          { id: 't_ai2_1', title: 'Cross-validation and hyperparameter tuning with GridSearchCV', type: 'LEARN', duration_mins: 30, is_completed: false },
          { id: 't_ai2_2', title: 'Build customer churn classification model with 85%+ F1', type: 'PRACTICE', duration_mins: 30, is_completed: false },
        ],
        completion_criteria: 'Pass ML evaluation checkpoint and submit churn model.',
      },
      {
        phase_number: 3,
        title: 'Phase 3: Deep Learning with PyTorch',
        weeks: 4,
        description: 'Tensors, autograd, feedforward neural nets, convolutional networks (CNNs), and loss functions.',
        objectives: ['Build and train neural networks using PyTorch from scratch', 'Understand backpropagation, learning rate schedulers, and optimizers', 'Implement image classification with convolutional architectures'],
        skills: ['PyTorch', 'Neural Networks', 'CNNs', 'Backpropagation'],
        tasks: [
          { id: 't_ai3_1', title: 'PyTorch Autograd & manual gradient descent step', type: 'LEARN', duration_mins: 35, is_completed: false },
          { id: 't_ai3_2', title: 'Train CNN on handwritten digits with early stopping', type: 'PRACTICE', duration_mins: 30, is_completed: false },
        ],
        completion_criteria: 'Deploy trained PyTorch model with valid validation loss.',
      },
      {
        phase_number: 4,
        title: 'Phase 4: LLMs, Embeddings & RAG Architectures',
        weeks: 3,
        description: 'Vector databases (Chroma, Pinecone), retrieval-augmented generation (RAG), embedding similarity, and AI agents.',
        objectives: ['Build semantic vector search with embeddings', 'Implement production RAG pipeline for document querying', 'Construct autonomous agents using function calling and tools'],
        skills: ['RAG Architectures', 'Vector Databases', 'Embeddings', 'AI Agents'],
        tasks: [
          { id: 't_ai4_1', title: 'Chunking strategies and cosine similarity vector search', type: 'LEARN', duration_mins: 30, is_completed: false },
          { id: 't_ai4_2', title: 'Build campus document Q&A assistant with citations', type: 'PRACTICE', duration_mins: 35, is_completed: false },
        ],
        completion_criteria: 'Deploy a working RAG document intelligence pipeline.',
      },
      {
        phase_number: 5,
        title: 'Phase 5: AI Production Deployment & Interview Readiness',
        weeks: 3,
        description: 'Serving models with FastAPI, ONNX runtime optimization, Docker, monitoring model drift, and interview coding rounds.',
        objectives: ['Deploy low-latency AI inference endpoints using FastAPI', 'Optimize inference speed with ONNX and quantisation', 'Prepare for applied AI engineering technical interviews'],
        skills: ['FastAPI Serving', 'Model Optimization', 'Docker', 'AI Interviews'],
        tasks: [
          { id: 't_ai5_1', title: 'Asynchronous FastAPI model serving with batching', type: 'LEARN', duration_mins: 30, is_completed: false },
          { id: 't_ai5_2', title: 'AI system design: Design recommendation feed ranking', type: 'PRACTICE', duration_mins: 30, is_completed: false },
        ],
        completion_criteria: 'Complete final AI system design mock review.',
      },
    ];
  }

  private getCyberCurriculum(level: string, isPlacement?: boolean): RoadmapPhase[] {
    return [
      {
        phase_number: 1,
        title: 'Phase 1: Computer Networking & Linux Fundamentals',
        weeks: 3,
        description: 'OSI model, packet analysis with Wireshark, Linux permissions, Bash scripting, and firewall configurations.',
        objectives: ['Inspect network packets and protocols with Wireshark', 'Master Linux server administration and permissions', 'Configure iptables and network firewalls'],
        skills: ['Wireshark', 'TCP/IP', 'Linux Administration', 'Firewalls'],
        tasks: [{ id: 't_c1_1', title: 'Packet analysis: TCP 3-way handshake in Wireshark', type: 'LEARN', duration_mins: 30, is_completed: false }],
        completion_criteria: 'Complete packet capture analysis lab.',
      },
      {
        phase_number: 2,
        title: 'Phase 2: Web Application Security & OWASP Top 10',
        weeks: 4,
        description: 'SQL injection, XSS, CSRF, SSRF, broken authentication, and security auditing tools like Burp Suite.',
        objectives: ['Identify and remediate OWASP Top 10 vulnerabilities', 'Use Burp Suite for automated and manual vulnerability assessment', 'Implement secure session management and CSP policies'],
        skills: ['OWASP Top 10', 'Burp Suite', 'XSS & SQLi Defense', 'Web Security'],
        tasks: [{ id: 't_c2_1', title: 'Burp Suite proxy and request intercepting lab', type: 'LEARN', duration_mins: 30, is_completed: false }],
        completion_criteria: 'Pass the Web Application Penetration Testing lab.',
      },
      {
        phase_number: 3,
        title: 'Phase 3: Cryptography & Public Key Infrastructure (PKI)',
        weeks: 3,
        description: 'Symmetric vs asymmetric encryption, RSA, AES, hashing (SHA-256), digital certificates, and TLS/SSL.',
        objectives: ['Implement secure AES-256 and RSA encryption flows', 'Understand digital certificates and SSL/TLS handshakes', 'Prevent cryptographic misuse and weak key storage'],
        skills: ['Cryptography', 'AES / RSA', 'TLS / SSL', 'PKI Certificates'],
        tasks: [{ id: 't_c3_1', title: 'AES-256-GCM authenticated encryption implementation', type: 'LEARN', duration_mins: 30, is_completed: false }],
        completion_criteria: 'Pass Cryptography checkpoint.',
      },
      {
        phase_number: 4,
        title: 'Phase 4: Cloud Security & DevSecOps Pipelines',
        weeks: 3,
        description: 'IAM least privilege, container vulnerability scanning, secrets management with Vault, and compliance.',
        objectives: ['Audit cloud IAM policies and reduce excessive permissions', 'Integrate automated vulnerability scanning in CI/CD pipelines', 'Secure secrets and environment variables with Vault'],
        skills: ['Cloud Security', 'IAM Hardening', 'DevSecOps', 'Vulnerability Scanning'],
        tasks: [{ id: 't_c4_1', title: 'Container image vulnerability scanning with Trivy', type: 'LEARN', duration_mins: 30, is_completed: false }],
        completion_criteria: 'Complete DevSecOps CI/CD security gating pipeline.',
      },
    ];
  }

  // ==========================================
  // SKILL DEPENDENCY MAPS
  // ==========================================

  private getFlutterSkillMap(): SkillMapNode[] {
    return [
      { id: 'sk_dart', name: 'Dart 3 Core', category: 'Language', status: 'IN_PROGRESS', depends_on: [] },
      { id: 'sk_widgets', name: 'Widget Architecture', category: 'UI', status: 'LOCKED', depends_on: ['sk_dart'] },
      { id: 'sk_riverpod', name: 'Riverpod 2.0 State', category: 'Architecture', status: 'LOCKED', depends_on: ['sk_widgets'] },
      { id: 'sk_networking', name: 'Dio & JWT Auth', category: 'Networking', status: 'LOCKED', depends_on: ['sk_riverpod'] },
      { id: 'sk_sockets', name: 'Socket.IO Real-Time', category: 'Networking', status: 'LOCKED', depends_on: ['sk_networking'] },
      { id: 'sk_persistence', name: 'Offline Hive / SQLite', category: 'Storage', status: 'LOCKED', depends_on: ['sk_riverpod'] },
      { id: 'sk_profiling', name: 'Performance Profiling', category: 'Production', status: 'LOCKED', depends_on: ['sk_widgets', 'sk_riverpod'] },
      { id: 'sk_system_design', name: 'Mobile System Design', category: 'Placement', status: 'LOCKED', depends_on: ['sk_sockets', 'sk_persistence'] },
    ];
  }

  private getFullStackSkillMap(): SkillMapNode[] {
    return [
      { id: 'sk_ts', name: 'TypeScript Core', category: 'Language', status: 'IN_PROGRESS', depends_on: [] },
      { id: 'sk_node', name: 'Node.js & Express', category: 'Backend', status: 'LOCKED', depends_on: ['sk_ts'] },
      { id: 'sk_postgres', name: 'PostgreSQL & Prisma', category: 'Database', status: 'LOCKED', depends_on: ['sk_node'] },
      { id: 'sk_react', name: 'React 18 & Hooks', category: 'Frontend', status: 'LOCKED', depends_on: ['sk_ts'] },
      { id: 'sk_docker', name: 'Docker & Containerization', category: 'DevOps', status: 'LOCKED', depends_on: ['sk_node'] },
      { id: 'sk_redis', name: 'Redis Caching', category: 'Performance', status: 'LOCKED', depends_on: ['sk_postgres'] },
      { id: 'sk_sys_design', name: 'Scalable System Design', category: 'Placement', status: 'LOCKED', depends_on: ['sk_docker', 'sk_redis'] },
    ];
  }

  private getBackendSkillMap(): SkillMapNode[] {
    return [
      { id: 'sk_proto', name: 'HTTP/2 & TCP Protocols', category: 'Networking', status: 'IN_PROGRESS', depends_on: [] },
      { id: 'sk_clean_arch', name: 'Clean Architecture', category: 'Architecture', status: 'LOCKED', depends_on: ['sk_proto'] },
      { id: 'sk_pg_tuning', name: 'PostgreSQL Tuning', category: 'Database', status: 'LOCKED', depends_on: ['sk_clean_arch'] },
      { id: 'sk_redis_cache', name: 'Redis Cache-Aside', category: 'Performance', status: 'LOCKED', depends_on: ['sk_pg_tuning'] },
      { id: 'sk_queues', name: 'Message Brokers (RabbitMQ)', category: 'Distributed', status: 'LOCKED', depends_on: ['sk_redis_cache'] },
      { id: 'sk_dist_sys', name: 'Distributed Systems', category: 'Placement', status: 'LOCKED', depends_on: ['sk_queues'] },
    ];
  }

  private getAiSkillMap(): SkillMapNode[] {
    return [
      { id: 'sk_py', name: 'Python for AI', category: 'Language', status: 'IN_PROGRESS', depends_on: [] },
      { id: 'sk_numpy', name: 'NumPy & Linear Algebra', category: 'Math', status: 'LOCKED', depends_on: ['sk_py'] },
      { id: 'sk_ml', name: 'Classical Scikit-Learn', category: 'ML', status: 'LOCKED', depends_on: ['sk_numpy'] },
      { id: 'sk_pytorch', name: 'PyTorch Deep Learning', category: 'DL', status: 'LOCKED', depends_on: ['sk_ml'] },
      { id: 'sk_rag', name: 'Vector DB & RAG', category: 'GenAI', status: 'LOCKED', depends_on: ['sk_pytorch'] },
      { id: 'sk_serving', name: 'FastAPI Production Serving', category: 'Production', status: 'LOCKED', depends_on: ['sk_rag'] },
    ];
  }

  private getCyberSkillMap(): SkillMapNode[] {
    return [
      { id: 'sk_net', name: 'Computer Networking', category: 'Fundamentals', status: 'IN_PROGRESS', depends_on: [] },
      { id: 'sk_linux', name: 'Linux Hardening', category: 'OS', status: 'LOCKED', depends_on: ['sk_net'] },
      { id: 'sk_owasp', name: 'OWASP Web Security', category: 'Security', status: 'LOCKED', depends_on: ['sk_linux'] },
      { id: 'sk_crypto', name: 'Applied Cryptography', category: 'Security', status: 'LOCKED', depends_on: ['sk_owasp'] },
      { id: 'sk_devsec', name: 'DevSecOps & Vault', category: 'Cloud', status: 'LOCKED', depends_on: ['sk_crypto'] },
    ];
  }

  private getCppCurriculum(level: string, isPlacement?: boolean): RoadmapPhase[] {
    return [
      {
        phase_number: 1,
        title: 'Phase 1: Modern C++20 Fundamentals & Memory Model',
        weeks: 3,
        description: 'Pointers, references, value categories, memory allocation, RAII, and modern C++ smart pointers.',
        objectives: [
          'Master pointer arithmetic, stack vs heap allocation, and memory leak prevention',
          'Understand RAII and modern smart pointers (std::unique_ptr, std::shared_ptr)',
          'Implement custom resource managing classes with copy/move constructors',
        ],
        skills: ['C++20 Core', 'Pointers & References', 'RAII', 'Smart Pointers'],
        tasks: [
          { id: 't_c1_1', title: 'Pointers, References & Value Categories Guide', type: 'LEARN', duration_mins: 30, is_completed: false },
          { id: 't_c1_2', title: 'Implement Custom Dynamic Array with RAII', type: 'PRACTICE', duration_mins: 35, is_completed: false },
          { id: 't_c1_3', title: 'Smart Pointer Ownership & Valgrind Memory Audit', type: 'CHALLENGE', duration_mins: 25, is_completed: false },
        ],
        completion_criteria: 'Implement a zero-leak RAII dynamic vector and score >= 80% on the memory model quiz.',
        project: {
          title: 'Memory-Safe Dynamic Vector & Arena Allocator',
          description: 'Build a custom heap memory allocator and dynamic vector adhering strictly to C++ RAII semantics.',
          difficulty: 'Intermediate',
          milestones: ['Custom allocator implementation', 'Unit tests with zero memory leaks', 'Benchmark comparison with std::vector'],
          tech_stack: ['C++20', 'GDB / LLDB', 'CMake', 'Valgrind'],
        },
      },
      {
        phase_number: 2,
        title: 'Phase 2: Standard Template Library (STL) & Complexity Analysis',
        weeks: 3,
        description: 'Comprehensive mastery of STL sequence containers, associative containers, iterators, and lambdas.',
        objectives: [
          'Internal mechanics of std::vector, std::deque, std::map (Red-Black trees), and std::unordered_map',
          'Mastering STL algorithms: std::sort, std::lower_bound, std::binary_search',
          'Amortized Big-O analysis and space complexity trade-offs',
        ],
        skills: ['STL Containers', 'Iterators', 'STL Algorithms', 'Big-O Complexity'],
        tasks: [
          { id: 't_c2_1', title: 'STL Internal Data Structures & Complexity Deep-Dive', type: 'LEARN', duration_mins: 30, is_completed: false },
          { id: 't_c2_2', title: 'Implement Priority Queue & Frequency Tracker', type: 'PRACTICE', duration_mins: 30, is_completed: false },
          { id: 't_c2_3', title: 'Two Pointers & Sliding Window Problem Set', type: 'CHALLENGE', duration_mins: 30, is_completed: false },
        ],
        completion_criteria: 'Solve all sliding window problem sets and complete the order matching book simulator.',
        project: {
          title: 'High-Throughput Fast I/O Order Book Simulator',
          description: 'Simulate a financial order matching book using std::priority_queue and std::unordered_map.',
          difficulty: 'Intermediate',
          milestones: ['Order book matching engine', 'Benchmarking 100,000 orders/sec', 'Documentation'],
          tech_stack: ['C++20', 'STL', 'Chrono Profiler'],
        },
      },
      {
        phase_number: 3,
        title: 'Phase 3: Core DSA Patterns for Placement Screening',
        weeks: 4,
        description: 'Graph algorithms, Trees, Dynamic Programming, and Placement Online Assessment patterns.',
        objectives: [
          'Tree and Graph traversals (BFS, DFS, Dijkstra, Topological Sort)',
          '1D and 2D Dynamic Programming (Knapsack, LCS, Matrix Chain)',
          'Placement OA timed mock tests with fast I/O optimization',
        ],
        skills: ['Trees & Graphs', 'Dynamic Programming', 'Competitive Programming', 'Placement OA'],
        tasks: [
          { id: 't_c3_1', title: 'Graph Traversal & Shortest Path Implementations', type: 'LEARN', duration_mins: 35, is_completed: false },
          { id: 't_c3_2', title: 'Dynamic Programming Top-Down vs Bottom-Up Drill', type: 'PRACTICE', duration_mins: 40, is_completed: false },
          { id: 't_c3_3', title: 'Timed 3-Question Placement OA Mock Challenge', type: 'CHALLENGE', duration_mins: 60, is_completed: false },
        ],
        completion_criteria: 'Solve 3 medium/hard OA problems within 60 minutes and score >= 85% on the algorithms checkpoint.',
        project: {
          title: 'Campus Navigation & Shortest Route Optimizer',
          description: 'Graph-based route pathfinder using Dijkstra and A* search algorithms with weighted path visualization.',
          difficulty: 'Advanced',
          milestones: ['Graph traversal library', 'Route finding benchmark', 'Interactive terminal visualizer'],
          tech_stack: ['C++20', 'Graph Algorithms', 'A* Search'],
        },
      },
      {
        phase_number: 4,
        title: 'Phase 4: Concurrency & High-Performance Capstone Project',
        weeks: 4,
        description: 'Multithreading, std::thread, mutexes, condition variables, and placement interview readiness.',
        objectives: [
          'Master multithreading, race condition elimination, and atomic operations',
          'Design an in-memory key-value store with concurrent read/write locks',
          'Final technical mock interviews and placement preparation',
        ],
        skills: ['Multithreading', 'std::thread', 'Concurrency', 'System Performance'],
        tasks: [
          { id: 't_c4_1', title: 'C++ Threading, Mutexes & Condition Variables', type: 'LEARN', duration_mins: 30, is_completed: false },
          { id: 't_c4_2', title: 'Thread-Safe Concurrent Queue Implementation', type: 'PRACTICE', duration_mins: 40, is_completed: false },
          { id: 't_c4_3', title: 'EVA AI 1-on-1 Placement Interview Simulation', type: 'CHALLENGE', duration_mins: 45, is_completed: false },
        ],
        completion_criteria: 'Deploy a functional multithreaded key-value store with clean concurrent benchmarks.',
        project: {
          title: 'Thread-Safe In-Memory Key-Value Database in C++',
          description: 'A concurrent Redis-like key-value store with read-write mutexes, TTL expiration, and persistence.',
          difficulty: 'Advanced',
          milestones: ['Multithreaded server engine', 'Benchmark performance metrics', 'Clean Git repository'],
          tech_stack: ['C++20', 'POSIX Sockets', 'std::thread', 'CMake'],
        },
      },
    ];
  }

  private getCppSkillMap(): SkillMapNode[] {
    return [
      { id: 'sk_cpp_core', name: 'C++20 Core & Pointers', category: 'Language', status: 'IN_PROGRESS', depends_on: [] },
      { id: 'sk_cpp_raii', name: 'RAII & Smart Pointers', category: 'Memory', status: 'LOCKED', depends_on: ['sk_cpp_core'] },
      { id: 'sk_cpp_stl', name: 'STL Containers & Algorithms', category: 'Standard Library', status: 'LOCKED', depends_on: ['sk_cpp_raii'] },
      { id: 'sk_cpp_dsa', name: 'Placement DSA & DP Patterns', category: 'Algorithms', status: 'LOCKED', depends_on: ['sk_cpp_stl'] },
      { id: 'sk_cpp_threads', name: 'Multithreading & Concurrency', category: 'Systems', status: 'LOCKED', depends_on: ['sk_cpp_dsa'] },
      { id: 'sk_cpp_project', name: 'Concurrent KV Store Engine', category: 'Capstone', status: 'LOCKED', depends_on: ['sk_cpp_threads'] },
    ];
  }

  public generateAdaptiveQuiz(params: {
    role?: string;
    phaseNumber?: number;
    topic?: string;
    difficulty?: 'Beginner' | 'Intermediate' | 'Advanced';
    userWeaknesses?: string[];
    numQuestions?: number;
  }): AdaptiveQuizResponse {
    const role = params.role || 'Modern Full-Stack & Cloud Engineer';
    const phaseNumber = params.phaseNumber || 1;
    const difficulty = params.difficulty || 'Beginner';
    const count = Math.min(Math.max(params.numQuestions || 5, 1), 15);
    const weaknesses = (params.userWeaknesses || []).map((w) => w.toLowerCase());

    const bank = this.getAdaptiveQuestionBank(role);

    // Prioritize questions matching user's recorded weak skills or topic
    const prioritized: AdaptiveQuizQuestion[] = [];
    const others: AdaptiveQuizQuestion[] = [];
    const topicLower = (params.topic || '').toLowerCase();

    for (const q of bank) {
      const matchesWeakness = weaknesses.some(
        (w) => q.tested_concept.toLowerCase().includes(w) || q.question.toLowerCase().includes(w)
      );
      const matchesTopic = topicLower
        ? q.tested_concept.toLowerCase().includes(topicLower) || q.question.toLowerCase().includes(topicLower)
        : false;

      if (matchesWeakness || matchesTopic) {
        prioritized.push(q);
      } else {
        others.push(q);
      }
    }

    const combined = [...prioritized, ...others];
    const selected = combined.slice(0, count);

    return {
      quiz_id: `quiz_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      topic: params.topic || `${role} - Phase ${phaseNumber} Adaptive Assessment`,
      phase_number: phaseNumber,
      role,
      difficulty,
      questions: selected,
      total_questions: selected.length,
    };
  }

  private getAdaptiveQuestionBank(role: string): AdaptiveQuizQuestion[] {
    const r = role.toLowerCase();

    if (r.includes('flutter') || r.includes('mobile')) {
      return [
        {
          id: 'fl_q1_mcq',
          type: 'MCQ',
          question: 'In Flutter, which lifecycle method of a State object is called immediately after dependencies change (such as InheritedWidget updates)?',
          options: ['initState()', 'didChangeDependencies()', 'build()', 'didUpdateWidget()'],
          correct_index: 1,
          explanation: 'didChangeDependencies() is invoked immediately after initState() on first load and whenever an InheritedWidget that this State object relies on is updated.',
          difficulty: 'Beginner',
          tested_concept: 'State Lifecycle & InheritedWidget',
        },
        {
          id: 'fl_q2_scenario',
          type: 'SCENARIO',
          scenario: 'A student is building a chat feed displaying 5,000 real-time campus messages. When scrolling fast on lower-end Android devices, the UI drops frames below 30 FPS.',
          question: 'What is the most effective Flutter architectural fix to ensure a smooth 60 FPS scroll rate?',
          options: [
            'Use Column inside SingleChildScrollView so all items render at once.',
            'Use ListView.builder with itemExtent and extract message items into const/memoized widgets.',
            'Wrap the entire Screen in a RepaintBoundary.',
            'Call setState every time a message is added to rebuild the entire widget tree.',
          ],
          correct_index: 1,
          explanation: 'ListView.builder lazily creates only visible viewports on-screen. Setting itemExtent avoids costly intrinsic layout recalculations, eliminating frame drops.',
          difficulty: 'Intermediate',
          tested_concept: 'Lazy List Rendering & Viewport Optimization',
        },
        {
          id: 'fl_q3_debug',
          type: 'DEBUGGING',
          code_snippet: 'ElevatedButton(\n  onPressed: () {\n    final user = ref.watch(userProfileProvider);\n    sendNotification(user.id);\n  },\n  child: Text("Notify"),\n)',
          question: 'What critical Riverpod anti-pattern / bug is present in the code snippet above?',
          options: [
            'ref.watch is invoked inside an event handler; it should use ref.read to obtain one-off state on user action.',
            'ElevatedButton cannot interact with Riverpod providers directly.',
            'sendNotification must be called inside initState.',
            'userProfileProvider cannot contain an id field.',
          ],
          correct_index: 0,
          explanation: 'ref.watch subscribes a widget to updates and causes rebuilds. Calling ref.watch inside callbacks like onPressed throws an assertion error or causes unexpected rebuild behaviors; ref.read must be used for one-off reads.',
          difficulty: 'Intermediate',
          tested_concept: 'Riverpod State Watch vs Read Semantics',
        },
        {
          id: 'fl_q4_code',
          type: 'CODE_UNDERSTANDING',
          code_snippet: 'String formatResponse(AsyncValue<List<String>> state) {\n  return state.when(\n    data: (items) => items.isEmpty ? "No items" : items.first,\n    loading: () => "Loading...",\n    error: (err, stack) => "Error",\n  );\n}',
          question: 'What will formatResponse return when state is AsyncValue.data([])?',
          options: ['"Loading..."', '"No items"', '"Error"', 'Throws NoSuchMethodError'],
          correct_index: 1,
          explanation: 'The data branch is executed because the state holds data. The ternary check items.isEmpty evaluates to true, returning "No items".',
          difficulty: 'Beginner',
          tested_concept: 'AsyncValue Pattern Matching',
        },
        {
          id: 'fl_q5_edge',
          type: 'EDGE_CASE',
          question: 'When implementing offline persistence with Hive/Isar in Flutter, what happens if the mobile app process is killed by the OS while writing to disk without transaction flushing?',
          options: [
            'The box file will automatically repair itself without any lock file.',
            'The write may leave corrupted uncommitted binary data unless wrapped in a transactional atomic batch and compact operation.',
            'Hive writes directly to SQLite WAL so transactions are always ACID compliant.',
            'Flutter crashes the entire phone filesystem.',
          ],
          correct_index: 1,
          explanation: 'File-based NoSQL engines can suffer corruption on sudden process termination if writes are not batched atomically or properly closed.',
          difficulty: 'Advanced',
          tested_concept: 'Offline Storage Durability & Corruption Defense',
        },
        {
          id: 'fl_q6_perf',
          type: 'PERFORMANCE',
          question: 'Why does Flutter DevTools Performance view recommend avoiding Opacity widgets inside animated transitions?',
          options: [
            'Opacity widgets force Flutter to render the subtree into an offscreen buffer layer before compositing, which is GPU-intensive.',
            'Opacity widgets are deprecated in Flutter 3.',
            'Opacity widgets do not support child widgets.',
            'Opacity prevents touch events from working.',
          ],
          correct_index: 0,
          explanation: 'Opacity pushes a layer to saveLayer, causing offscreen GPU rendering. AnimatedOpacity or Color.withOpacity should be preferred.',
          difficulty: 'Advanced',
          tested_concept: 'GPU Layer Compositing & Offscreen Buffering',
        },
        {
          id: 'fl_q7_sec',
          type: 'SECURITY',
          question: 'Where should sensitive JWT refresh tokens and cryptographic secrets be persisted on a mobile device in Flutter?',
          options: [
            'SharedPreferences (XML file on Android, plist on iOS)',
            'flutter_secure_storage (Keychain on iOS and EncryptedSharedPreferences on Android)',
            'In a plain text JSON file in getApplicationDocumentsDirectory()',
            'Hardcoded as a static string constant in main.dart',
          ],
          correct_index: 1,
          explanation: 'SharedPreferences stores data in plaintext. flutter_secure_storage leverages hardware-backed Android KeyStore / EncryptedSharedPreferences and iOS Keychain for encryption at rest.',
          difficulty: 'Intermediate',
          tested_concept: 'Mobile Secure Storage & Key Management',
        },
        {
          id: 'fl_q8_tradeoff',
          type: 'ARCHITECTURE_TRADEOFF',
          question: 'What is the primary architectural tradeoff between using standard setState vs Riverpod AsyncNotifier in an enterprise Flutter application?',
          options: [
            'setState requires zero boilerplate and works great for localized widget ephemera, but fails to share asynchronous state across screens without prop-drilling or breaking separation of concerns.',
            'setState is faster in release mode than Riverpod in every scenario.',
            'Riverpod requires Flutter runtime changes and cannot run on iOS.',
            'There is no architectural difference between them.',
          ],
          correct_index: 0,
          explanation: 'setState is ideal for ephemeral UI state (e.g. checkbox, tab index) within a single widget, while Riverpod decouples business logic, API calls, and caching from the presentation layer.',
          difficulty: 'Intermediate',
          tested_concept: 'State Management Architecture Tradeoffs',
        },
      ];
    }

    if (r.includes('backend') || r.includes('system') || r.includes('distributed')) {
      return [
        {
          id: 'be_q1_mcq',
          type: 'MCQ',
          question: 'In PostgreSQL, what is the key difference between a B-Tree index and a GIN index?',
          options: [
            'B-Tree is optimized for equality and range comparisons (e.g. <, <=, =, >=), whereas GIN is optimized for indexing composite values, arrays, and JSONB keys.',
            'B-Tree can only store text, while GIN only stores integers.',
            'GIN indexes do not require disk space.',
            'B-Tree indexes cannot be used for primary keys.',
          ],
          correct_index: 0,
          explanation: 'B-Tree maintains sorted nodes for O(log N) scalar searches and ranges. GIN (Generalized Inverted Index) maps elements within composite items (like JSONB or full text) to rows.',
          difficulty: 'Intermediate',
          tested_concept: 'PostgreSQL Index Selection (B-Tree vs GIN)',
        },
        {
          id: 'be_q2_scenario',
          type: 'SCENARIO',
          scenario: 'During college course registration, 5,000 students submit their seat reservations at exactly 10:00:00 AM. Only 60 seats are available in CS101.',
          question: 'Which backend concurrency control mechanism prevents overselling seats while maintaining high API throughput?',
          options: [
            'Read the seat count with a normal SELECT, check if count > 0 in JavaScript, and execute an UPDATE.',
            'Use PostgreSQL SELECT FOR UPDATE or an atomic UPDATE with WHERE seats_available > 0 and check affected row count.',
            'Disable indexes on the registration table.',
            'Store the seat count in an in-memory global JavaScript variable.',
          ],
          correct_index: 1,
          explanation: 'A plain read-then-write creates a classic Time-of-Check to Time-of-Use (TOCTOU) race condition. An atomic conditional update (UPDATE courses SET seats_available = seats_available - 1 WHERE id = $1 AND seats_available > 0) guarantees database-level isolation.',
          difficulty: 'Intermediate',
          tested_concept: 'Race Conditions & Pessimistic/Optimistic Concurrency Control',
        },
        {
          id: 'be_q3_debug',
          type: 'DEBUGGING',
          code_snippet: 'app.post("/transfer", async (req, res) => {\n  const { fromId, toId, amount } = req.body;\n  await prisma.account.update({ where: { id: fromId }, data: { balance: { decrement: amount } } });\n  await prisma.account.update({ where: { id: toId }, data: { balance: { increment: amount } } });\n  res.json({ success: true });\n});',
          question: 'What critical bug will cause data inconsistency if the server crashes or encounters an error on the second database operation?',
          options: [
            'prisma.account does not support decrement operations.',
            'The two updates are not wrapped in an ACID transaction (prisma.$transaction), meaning money will be deducted from sender without reaching recipient.',
            'The status code must be 201 instead of 200.',
            'fromId and toId must be numbers, not strings.',
          ],
          correct_index: 1,
          explanation: 'Financial transfers require Atomicity: either both operations succeed, or both roll back. Without prisma.$transaction([...]), any failure between the statements leaves the database in an inconsistent state.',
          difficulty: 'Intermediate',
          tested_concept: 'ACID Transactions & Database Consistency',
        },
        {
          id: 'be_q4_code',
          type: 'CODE_UNDERSTANDING',
          code_snippet: 'const rateLimit = (req, res, next) => {\n  const ip = req.ip;\n  const count = cache.get(ip) || 0;\n  if (count >= 100) return res.status(429).json({ error: "Too Many Requests" });\n  cache.set(ip, count + 1, 60);\n  next();\n};',
          question: 'If two concurrent requests from the same IP arrive simultaneously at a multi-process Node.js cluster, what is the flaw with using local in-memory cache for rate limiting?',
          options: [
            'Node.js cannot send HTTP 429 status codes.',
            'In a multi-process cluster, each worker process has its own isolated memory, allowing the client to bypass the limit by hitting different workers.',
            'cache.set requires asynchronous promises.',
            'The client IP address cannot be retrieved in Express.',
          ],
          correct_index: 1,
          explanation: 'In-memory process cache is not shared across cluster workers or multiple server replicas. A shared distributed store like Redis is necessary for consistent cluster rate-limiting.',
          difficulty: 'Intermediate',
          tested_concept: 'Distributed State & In-Memory Cluster Limitations',
        },
        {
          id: 'be_q5_edge',
          type: 'EDGE_CASE',
          question: 'In a distributed caching architecture with Redis, what is "Cache Stampede" (or the Thundering Herd problem), and how do you protect against it?',
          options: [
            'When Redis runs out of memory and crashes.',
            'When a hot cached key expires, causing hundreds of concurrent requests to all miss the cache simultaneously and overwhelm the source database.',
            'When network cables between servers are severed.',
            'When a database contains duplicate primary keys.',
          ],
          correct_index: 1,
          explanation: 'A Cache Stampede occurs when many clients concurrently request an expired key. Mitigations include mutex locking (probabilistic early expiration) or background cache recomputation.',
          difficulty: 'Advanced',
          tested_concept: 'Cache Stampede Mitigation & High-Throughput Caching',
        },
        {
          id: 'be_q6_perf',
          type: 'PERFORMANCE',
          question: 'You run EXPLAIN ANALYZE on a query: `SELECT * FROM events WHERE college_id = $1 AND start_date > NOW() ORDER BY start_date ASC LIMIT 10;`. It shows "Seq Scan on events". What index will transform this into an efficient Index Scan?',
          options: [
            'CREATE INDEX ON events (start_date);',
            'CREATE INDEX ON events (college_id, start_date);',
            'CREATE INDEX ON events (description);',
            'No index can help queries with LIMIT clauses.',
          ],
          correct_index: 1,
          explanation: 'A composite index on (college_id, start_date) allows PostgreSQL to filter by the equality condition (college_id) and immediately stream sorted rows by start_date without an in-memory sort.',
          difficulty: 'Intermediate',
          tested_concept: 'PostgreSQL EXPLAIN ANALYZE & Composite Indexes',
        },
        {
          id: 'be_q7_sec',
          type: 'SECURITY',
          question: 'Why should password hashes be verified using constant-time comparison algorithms (like crypto.timingSafeEqual or bcrypt.compare) rather than simple string equality (===)?',
          options: [
            'Simple string equality fails if strings contain special characters.',
            'Simple string equality returns early on the first mismatched byte, leaking timing information that attackers can exploit via side-channel timing attacks.',
            'bcrypt hashes are not strings.',
            'crypto.timingSafeEqual runs 10x faster than ===.',
          ],
          correct_index: 1,
          explanation: 'Variable-time comparisons terminate early upon finding the first mismatched byte. An attacker measuring response times down to nanoseconds can deduce byte-by-byte secrets.',
          difficulty: 'Advanced',
          tested_concept: 'Timing Attacks & Constant-Time String Verification',
        },
        {
          id: 'be_q8_tradeoff',
          type: 'ARCHITECTURE_TRADEOFF',
          question: 'In microservices, what is the fundamental tradeoff between REST over HTTP vs Message Queues (e.g. RabbitMQ/Kafka) for inter-service communication?',
          options: [
            'REST is synchronous and easy to inspect, but couples caller availability to callee latency; Message Queues provide asynchronous decoupling and backpressure buffering, but require eventual consistency handling.',
            'Message queues cannot transmit JSON payloads.',
            'REST is always faster than message brokers.',
            'Message queues eliminate all software bugs.',
          ],
          correct_index: 0,
          explanation: 'REST creates synchronous temporal coupling where an outage cascades upstream. Message brokers provide durable asynchronous queues at the cost of eventual consistency and complex compensation workflows (Sagas).',
          difficulty: 'Intermediate',
          tested_concept: 'Synchronous vs Asynchronous Distributed Architecture',
        },
      ];
    }

    if (r.includes('cyber') || r.includes('security') || r.includes('devsecops')) {
      return [
        {
          id: 'cy_q1_mcq',
          type: 'MCQ',
          question: 'Which vulnerability on the OWASP Top 10 API Security list occurs when an API endpoint exposes an object ID (e.g. /api/user/101) without validating that the authenticated user owns that resource?',
          options: [
            'Broken Object Level Authorization (BOLA / IDOR)',
            'Broken Authentication',
            'Server-Side Request Forgery (SSRF)',
            'Security Misconfiguration',
          ],
          correct_index: 0,
          explanation: 'BOLA (formerly IDOR) is the #1 vulnerability on OWASP API Security. It occurs when authorization checks are missing on individual database entity lookups.',
          difficulty: 'Beginner',
          tested_concept: 'OWASP API #1: Broken Object Level Authorization',
        },
        {
          id: 'cy_q2_scenario',
          type: 'SCENARIO',
          scenario: 'A developer adds an image proxy endpoint: `app.get("/proxy-image", (req, res) => { http.get(req.query.url, (stream) => stream.pipe(res)); });`. An attacker calls `/proxy-image?url=http://169.254.169.254/latest/meta-data/`.',
          question: 'What critical security vulnerability is demonstrated here, and what is the attacker attempting to steal?',
          options: [
            'SQL Injection attempting to drop users table.',
            'Server-Side Request Forgery (SSRF) attempting to exfiltrate AWS cloud instance metadata and IAM credentials.',
            'Cross-Site Scripting (XSS) targeting browser cookies.',
            'Distributed Denial of Service (DDoS).',
          ],
          correct_index: 1,
          explanation: '169.254.169.254 is the link-local AWS instance metadata address. SSRF allows attackers to force the server to fetch internal resources that are not accessible from the public internet.',
          difficulty: 'Intermediate',
          tested_concept: 'Server-Side Request Forgery (SSRF) & Cloud Metadata Protection',
        },
        {
          id: 'cy_q3_debug',
          type: 'DEBUGGING',
          code_snippet: 'FROM node:18\nUSER root\nWORKDIR /app\nCOPY . .\nRUN chmod -R 777 /app\nCMD ["npm", "start"]',
          question: 'What major container security violations exist in this Dockerfile?',
          options: [
            'Running as root user and setting world-writable 777 permissions, violating the principle of least privilege.',
            'Node:18 is not supported in Docker.',
            'WORKDIR cannot be named /app.',
            'CMD must use double single quotes.',
          ],
          correct_index: 0,
          explanation: 'Running container workloads as root grants potential container-escape vulnerabilities root host permissions. chmod 777 allows any compromised process to overwrite app code.',
          difficulty: 'Intermediate',
          tested_concept: 'Container Least Privilege & Hardening',
        },
        {
          id: 'cy_q4_sec',
          type: 'SECURITY',
          question: 'How does a Cross-Site Request Forgery (CSRF) attack exploit standard cookie authentication, and what is the modern defense?',
          options: [
            'The attacker steals the cookie via JavaScript and sends it from their terminal.',
            'The browser automatically attaches ambient session cookies to cross-origin requests; modern defense is SameSite=Strict/Lax cookie attribute and CSRF anti-forgery tokens.',
            'CSRF only affects mobile applications.',
            'Using HTTPS completely eliminates CSRF.',
          ],
          correct_index: 1,
          explanation: 'Browsers attach ambient cookies automatically on cross-origin requests unless restricted by SameSite attributes. SameSite=Strict/Lax ensures cookies are omitted on cross-site origin calls.',
          difficulty: 'Intermediate',
          tested_concept: 'Cross-Site Request Forgery & SameSite Cookies',
        },
        {
          id: 'cy_q5_tradeoff',
          type: 'ARCHITECTURE_TRADEOFF',
          question: 'In TLS 1.3 encryption, why is asymmetric cryptography (e.g. ECDHE) used during the handshake while symmetric cryptography (e.g. AES-GCM) is used for data transmission?',
          options: [
            'Asymmetric cryptography solves the key-exchange problem securely over an untrusted channel, but is too computationally slow for gigabytes of stream data; symmetric encryption is orders of magnitude faster with hardware acceleration.',
            'Symmetric cryptography cannot encrypt web pages.',
            'Asymmetric cryptography cannot be decrypted.',
            'TLS 1.3 does not use symmetric cryptography.',
          ],
          correct_index: 0,
          explanation: 'Elliptic curve asymmetric crypto enables secure key agreement without revealing the key, while symmetric AES-GCM provides high-speed, hardware-accelerated authenticated bulk cipher streaming.',
          difficulty: 'Intermediate',
          tested_concept: 'Hybrid Cryptography in Network Protocols',
        },
      ];
    }

    if (r.includes('ai') || r.includes('machine') || r.includes('data')) {
      return [
        {
          id: 'ai_q1_mcq',
          type: 'MCQ',
          question: 'In deep learning training loops using PyTorch, why is `optimizer.zero_grad()` called before `loss.backward()`?',
          options: [
            'To reset the model weights back to zero.',
            'Because PyTorch accumulates gradients in tensors by default; failing to zero them adds gradients across successive batches, causing divergent parameter updates.',
            'To free GPU VRAM allocated by the forward pass.',
            'It is optional and only needed for convolutional networks.',
          ],
          correct_index: 1,
          explanation: 'PyTorch tensors accumulate gradients (grad += new_grad) to allow flexible gradient accumulation across mini-batches. Calling zero_grad() prevents previous batch gradients from contaminating the current step.',
          difficulty: 'Beginner',
          tested_concept: 'PyTorch Gradient Accumulation Mechanics',
        },
        {
          id: 'ai_q2_scenario',
          type: 'SCENARIO',
          scenario: 'A CampusHub AI assistant answers student questions using Retrieval-Augmented Generation (RAG). Students report that EVA AI frequently retrieves irrelevant document paragraphs when they ask questions using domain jargon.',
          question: 'Which retrieval pipeline enhancement most effectively improves retrieval precision and relevance?',
          options: [
            'Increase the LLM temperature to 1.5.',
            'Implement Hybrid Search (combining dense semantic vector embeddings with sparse BM25 keyword search) followed by a Cross-Encoder Re-ranker step.',
            'Reduce the vector embedding dimension from 1536 to 64.',
            'Feed the entire database into the system prompt on every turn.',
          ],
          correct_index: 1,
          explanation: 'Pure vector similarity often fails on exact keyword jargon and acronyms. Hybrid search merges semantic similarity with keyword precision (BM25), and a re-ranker scores top candidates for maximum relevance.',
          difficulty: 'Intermediate',
          tested_concept: 'RAG Retrieval Optimization (Hybrid Search & Re-ranking)',
        },
        {
          id: 'ai_q3_debug',
          type: 'DEBUGGING',
          code_snippet: 'logits = model(inputs)\nprobs = F.softmax(logits, dim=1)\nloss = nn.CrossEntropyLoss()(probs, targets)',
          question: 'What mathematical/algorithmic error is present in the loss calculation snippet above?',
          options: [
            'CrossEntropyLoss expects raw unnormalized logits because it internally applies LogSoftmax followed by NLLLoss; passing probabilities applies softmax twice and degrades gradient flow.',
            'model(inputs) must be called inside torch.no_grad().',
            'CrossEntropyLoss only works with binary labels.',
            'inputs must be transposed before passing to model.',
          ],
          correct_index: 0,
          explanation: 'PyTorch nn.CrossEntropyLoss combines LogSoftmax and NLLLoss in a single numerically stable function. Applying softmax prior to CrossEntropyLoss causes numerical underflow and incorrect gradients.',
          difficulty: 'Intermediate',
          tested_concept: 'Loss Function Formulation & Numerical Stability',
        },
        {
          id: 'ai_q4_code',
          type: 'CODE_UNDERSTANDING',
          code_snippet: 'import numpy as np\na = np.ones((3, 1))\nb = np.ones((1, 4))\nc = a + b\nprint(c.shape)',
          question: 'What shape will be printed by the NumPy broadcasting snippet above?',
          options: ['(3, 1)', '(1, 4)', '(3, 4)', 'ValueError: operands could not be broadcast together'],
          correct_index: 2,
          explanation: 'NumPy broadcasting rules compare dimensions from right to left. Dimension 1 matches dimension 4 (stretching a across columns), and dimension 3 matches 1 (stretching b across rows), producing shape (3, 4).',
          difficulty: 'Beginner',
          tested_concept: 'NumPy Tensor Broadcasting Rules',
        },
        {
          id: 'ai_q5_tradeoff',
          type: 'ARCHITECTURE_TRADEOFF',
          question: 'When deploying Large Language Models (LLMs) in production, what is the main tradeoff of using 4-bit Quantization (e.g. AWQ / GGUF) compared to 16-bit FP16 precision?',
          options: [
            '4-bit quantization dramatically reduces VRAM requirements by ~75% and improves inference speed with negligible loss in reasoning capability for most general tasks.',
            '4-bit quantization produces random output strings.',
            'FP16 uses less GPU memory than 4-bit.',
            'Quantized models cannot run on CUDA hardware.',
          ],
          correct_index: 0,
          explanation: 'Post-training quantization reduces weight bitwidth from 16 bits to 4 bits, allowing a 70B parameter model to fit on a consumer GPU while retaining over 98% of baseline accuracy.',
          difficulty: 'Intermediate',
          tested_concept: 'LLM Model Quantization & Serving Tradeoffs',
        },
      ];
    }

    // Default: Modern Full-Stack & Cloud Engineer
    return [
      {
        id: 'fs_q1_mcq',
        type: 'MCQ',
        question: 'What is the primary architectural purpose of the cleanup function returned from a React `useEffect` hook?',
        options: [
          'To abort pending AbortController network requests, clear timers, and remove event listeners before the component unmounts or re-runs the effect.',
          'To delete the component from the DOM permanently.',
          'To force garbage collection of all React variables.',
          'To reset component props to their initial default values.',
        ],
        correct_index: 0,
        explanation: 'The cleanup function executes before the component unmounts and before re-running the effect on dependency change. This prevents memory leaks from detached listeners and stale callbacks.',
        difficulty: 'Beginner',
        tested_concept: 'React useEffect Lifecycle & Memory Leak Prevention',
      },
      {
        id: 'fs_q2_scenario',
        type: 'SCENARIO',
        scenario: 'A college event portal built with Next.js displays upcoming campus events. The event schedule updates several times a day, but 99% of page visits are read-only and need sub-100ms load times.',
        question: 'Which Next.js rendering strategy achieves instant CDN caching while keeping event listings fresh without rebuilding the whole application?',
        options: [
          'Client-Side Rendering (CSR) with raw fetch in useEffect.',
          'Incremental Static Regeneration (ISR) with revalidate: 60.',
          'Server-Side Rendering (SSR) without any caching headers.',
          'Static Site Generation (SSG) with no revalidation.',
        ],
        correct_index: 1,
        explanation: 'Incremental Static Regeneration generates static HTML at build time that is served directly from edge CDNs, while automatically revalidating in the background when requests arrive after the revalidate interval.',
        difficulty: 'Intermediate',
        tested_concept: 'Next.js Rendering Strategies (ISR vs SSR vs CSR)',
      },
      {
        id: 'fs_q3_debug',
        type: 'DEBUGGING',
        code_snippet: 'const [items, setItems] = useState([]);\nconst addItem = (item) => {\n  items.push(item);\n  setItems(items);\n};',
        question: 'Why does the React component fail to re-render when addItem is triggered in the snippet above?',
        options: [
          'React performs Object.is referential identity checks on state; mutating the array in-place preserves the existing memory reference, so React skips re-rendering.',
          'useState does not support arrays.',
          'setItems cannot be called inside a function.',
          'items.push is an asynchronous function that requires await.',
        ],
        correct_index: 0,
        explanation: 'State immutability is fundamental to React. items.push mutates the existing array reference. React sees oldState === newState and skips the render pass. The fix is setItems([...items, item]).',
        difficulty: 'Beginner',
        tested_concept: 'React State Immutability & Referential Equality',
      },
      {
        id: 'fs_q4_perf',
        type: 'PERFORMANCE',
        question: 'What is the primary benefit of implementing Dynamic Imports (e.g. React.lazy() / Next.js dynamic) for heavy components like rich-text editors or charting libraries?',
        options: [
          'It splits code into separate JavaScript chunks, reducing the initial bundle size downloaded over the network and accelerating First Contentful Paint (FCP).',
          'It translates JavaScript into C++ binary code.',
          'It removes the need for CSS stylesheets.',
          'It encrypts the component source code.',
        ],
        correct_index: 0,
        explanation: 'Route-based and component-level code splitting ensures clients only download the minimal JavaScript required for the current view, drastically improving mobile web performance.',
        difficulty: 'Intermediate',
        tested_concept: 'Code Splitting & Bundle Optimization',
      },
      {
        id: 'fs_q5_tradeoff',
        type: 'ARCHITECTURE_TRADEOFF',
        question: 'When architecting live real-time notifications in a web application, what is the key architectural difference between Server-Sent Events (SSE) and WebSockets?',
        options: [
          'SSE is unidirectional (server-to-client), runs over standard HTTP/2 without protocol upgrades, and includes automatic reconnection; WebSockets are full-duplex bidirectional, but require custom socket protocol management.',
          'WebSockets only work on localhost.',
          'SSE can only transmit binary audio files.',
          'There is no functional or architectural difference between them.',
        ],
        correct_index: 0,
        explanation: 'For notifications where the client only receives events and does not need to stream data back over the same channel, SSE is much simpler, firewall-friendly, and leverages HTTP/2 multiplexing.',
        difficulty: 'Intermediate',
        tested_concept: 'Real-Time Communication Protocols (SSE vs WebSockets)',
      },
    ];
  }
}

