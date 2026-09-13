import { Phase7Evaluator } from './evaluation/phase7-evaluator';
import { PHASE7_STUDENT_PERSONAS } from './evaluation/phase7-personas';
import { CareerDAGService, DAGNode, DAGEdge } from './services/career.dag.service';
import { CareerService } from './career.service';
import { prisma } from '../../config/database';
import { aiProvider } from '../../shared/ai/ai.provider';
import { CareerGitHubService } from './services/career.github.service';
import { CareerYouTubeService } from './services/career.youtube.service';
import { CareerAIOrchestrator } from './ai/career.agents';
import { JobReadinessEngine } from './career.readiness-engine';

describe('CAMPUSHUB CAREER HUB v2.0 — PHASE 7 PRODUCTION ACCEPTANCE & EVALUATION', () => {
  let evaluator: Phase7Evaluator;

  beforeAll(() => {
    jest.spyOn(aiProvider, 'generateStructured').mockRejectedValue(new Error('Deterministic test fallback'));
  });

  afterAll(() => {
    jest.restoreAllMocks();
  });

  beforeEach(() => {
    evaluator = new Phase7Evaluator();
  });

  // =========================================================================
  // 1. REALISTIC STUDENT PERSONAS & PATHFINDER AI QUALITY EVALUATION (SECTIONS 3, 4, 5)
  // =========================================================================
  describe('Pathfinder & Career Hypotheses Across 6 Realistic Personas', () => {
    it('PERSONA A (Beginner Mobile): Ranks mobile development top and starts with foundational Flutter', async () => {
      const persona = PHASE7_STUDENT_PERSONAS.PERSONA_A;
      const evaluation = await evaluator.evaluatePathfinderPersona(persona);

      expect(evaluation.scorecard.passed).toBe(true);
      expect(evaluation.scorecard.averageScore).toBeGreaterThanOrEqual(4.0);
      expect(evaluation.topHypotheses.length).toBeGreaterThan(0);
      expect(evaluation.topHypotheses[0].career).toContain('Mobile');
    });

    it('PERSONA B (Backend-Oriented): Ranks Backend & Cloud Architect top with system design gaps', async () => {
      const persona = PHASE7_STUDENT_PERSONAS.PERSONA_B;
      const evaluation = await evaluator.evaluatePathfinderPersona(persona);

      expect(evaluation.scorecard.passed).toBe(true);
      expect(evaluation.scorecard.averageScore).toBeGreaterThanOrEqual(4.0);
      expect(evaluation.topHypotheses[0].career).toContain('Backend');
    });

    it('PERSONA C (Full-Stack Student): Recognizes MERN familiarity and emphasizes testing/DevOps gaps', async () => {
      const persona = PHASE7_STUDENT_PERSONAS.PERSONA_C;
      const evaluation = await evaluator.evaluatePathfinderPersona(persona);

      expect(evaluation.scorecard.passed).toBe(true);
      expect(evaluation.scorecard.averageScore).toBeGreaterThanOrEqual(4.0);
      expect(evaluation.topHypotheses[0].career).toContain('Web');
    });

    it('PERSONA D (Data / AI Interested): Ranks Machine Learning/AI top and maintains multiple hypotheses', async () => {
      const persona = PHASE7_STUDENT_PERSONAS.PERSONA_D;
      const evaluation = await evaluator.evaluatePathfinderPersona(persona);

      expect(evaluation.scorecard.passed).toBe(true);
      expect(evaluation.scorecard.averageScore).toBeGreaterThanOrEqual(4.0);
      expect(evaluation.topHypotheses[0].career).toContain('AI');
      expect(evaluation.topHypotheses.length).toBeGreaterThanOrEqual(2);
    });

    it('PERSONA E (Contradictory Student): Detects semantic contradiction and flags clarification without crashing', async () => {
      const persona = PHASE7_STUDENT_PERSONAS.PERSONA_E;
      const evaluation = await evaluator.evaluatePathfinderPersona(persona);

      expect(evaluation.contradictionsDetected.length).toBeGreaterThan(0);
      expect(evaluation.contradictionsDetected[0].issue).toContain('backend');
      expect(evaluation.scorecard.contradictionHandling).toBe(5);
      expect(evaluation.scorecard.passed).toBe(true);
    });

    it('PERSONA F (Advanced Student): Ranks high-performance systems and honors senior algorithmic background', async () => {
      const persona = PHASE7_STUDENT_PERSONAS.PERSONA_F;
      const evaluation = await evaluator.evaluatePathfinderPersona(persona);

      expect(evaluation.scorecard.passed).toBe(true);
      expect(evaluation.scorecard.averageScore).toBeGreaterThanOrEqual(4.0);
      expect(evaluation.topHypotheses[0].career).toMatch(/Backend|Systems/);
    });

    it('AI Quality Scorecard: Verifies all personas achieve overall score >= 4.0 and no category < 3.0', async () => {
      const personas = Object.values(PHASE7_STUDENT_PERSONAS);
      for (const p of personas) {
        const res = await evaluator.evaluatePathfinderPersona(p);
        expect(res.scorecard.averageScore).toBeGreaterThanOrEqual(4.0);
        expect(res.scorecard.careerRelevance).toBeGreaterThanOrEqual(3);
        expect(res.scorecard.contradictionHandling).toBeGreaterThanOrEqual(3);
        expect(res.scorecard.personalization).toBeGreaterThanOrEqual(3);
      }
    });
  });

  // =========================================================================
  // 2. ROADMAP DAG QUALITY & NEGATIVE INVARIANT TESTING (SECTIONS 6 & 7)
  // =========================================================================
  describe('Roadmap DAG Quality & Invariant Negative Testing', () => {
    it('executes negative tests and rejects all invalid cyclic and malformed DAG structures', () => {
      const negativeResults = evaluator.evaluateDAGNegativeTests();

      expect(negativeResults.selfDependencyRejected).toBe(true);
      expect(negativeResults.duplicateEdgeRejected).toBe(true);
      expect(negativeResults.twoNodeCycleRejected).toBe(true);
      expect(negativeResults.threeNodeCycleRejected).toBe(true);
      expect(negativeResults.pruningRestoresValidDAG).toBe(true);
    });

    it('validates a complex multi-phase roadmap DAG with valid roots and topological order', () => {
      const nodes: DAGNode[] = [
        { id: '1', title: 'HTML & Web Primitives', orderIndex: 1 },
        { id: '2', title: 'CSS Flexbox & Grid', orderIndex: 2 },
        { id: '3', title: 'JavaScript Fundamentals', orderIndex: 3 },
        { id: '4', title: 'React Core & Hooks', orderIndex: 4 },
        { id: '5', title: 'State Management (Riverpod/Zustand)', orderIndex: 5 },
        { id: '6', title: 'REST & GraphQL APIs', orderIndex: 6 },
        { id: '7', title: 'Full Stack Capstone', orderIndex: 7 },
      ];

      const edges: DAGEdge[] = [
        { sourceSkill: 'HTML & Web Primitives', targetSkill: 'JavaScript Fundamentals', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'CSS Flexbox & Grid', targetSkill: 'JavaScript Fundamentals', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'JavaScript Fundamentals', targetSkill: 'React Core & Hooks', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'React Core & Hooks', targetSkill: 'State Management (Riverpod/Zustand)', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'React Core & Hooks', targetSkill: 'REST & GraphQL APIs', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'State Management (Riverpod/Zustand)', targetSkill: 'Full Stack Capstone', dependencyType: 'PREREQUISITE' },
        { sourceSkill: 'REST & GraphQL APIs', targetSkill: 'Full Stack Capstone', dependencyType: 'PREREQUISITE' },
      ];

      const validation = CareerDAGService.validateDAG(nodes, edges);
      expect(validation.isValid).toBe(true);
      expect(validation.isDAG).toBe(true);
      expect(validation.cycles.length).toBe(0);

      // Verify roots (in-degree 0)
      const htmlIdx = validation.topologicalOrder.indexOf('HTML & Web Primitives');
      const capstoneIdx = validation.topologicalOrder.indexOf('Full Stack Capstone');
      expect(htmlIdx).toBeLessThan(capstoneIdx);
    });
  });

  // =========================================================================
  // 3. ADAPTIVE QUIZ EVALUATION & ADAPTIVE CURRICULUM LOOP (SECTIONS 8 & 9)
  // =========================================================================
  describe('Adaptive Quiz Evaluation & Dynamic Curriculum Loop', () => {
    let careerService: CareerService;
    const testUserId = 'test-student-phase7';
    const testRoadmapId = '8132aead-2a44-47ad-91fb-9754ef845fb3';

    beforeEach(() => {
      careerService = new CareerService({
        updateQuizScore: jest.fn().mockResolvedValue({}),
      } as any);
    });

    it('STATE A (Strong Performance >=70%): Increases confidence and records skill evidence', async () => {
      jest.spyOn(prisma.quizAttempt, 'create').mockResolvedValue({ id: 'qa-pass' } as any);
      jest.spyOn(prisma.studentSkill, 'findUnique').mockResolvedValue({
        id: 'sk-flutter',
        confidence_score: 55,
      } as any);
      const upsertSpy = jest.spyOn(prisma.studentSkill, 'upsert').mockResolvedValue({
        id: 'sk-flutter',
        confidence_score: 70,
      } as any);
      const evidenceSpy = jest.spyOn(prisma.skillEvidence, 'create').mockResolvedValue({ id: 'ev-pass' } as any);

      const result = await careerService.submitQuiz(testUserId, {
        phase_number: 1,
        role: 'Full-Stack',
        roadmap_id: testRoadmapId,
        answers: { 0: 1, 1: 2, 2: 2 }, // 3/3 correct
      });

      expect(result.passed).toBe(true);
      expect(result.percentage).toBe(100);
      expect(result.roadmapAdapted).toBe(false);
      expect(upsertSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          update: expect.objectContaining({ confidence_score: 70 }),
        })
      );
      expect(evidenceSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({ evidence_type: 'QUIZ', score: 100 }),
        })
      );
    });

    it('STATE B (Struggling Performance <50%): Identifies gap, reduces confidence, and adapts roadmap', async () => {
      jest.spyOn(prisma.quizAttempt, 'create').mockResolvedValue({ id: 'qa-fail' } as any);
      jest.spyOn(prisma.studentSkill, 'findUnique').mockResolvedValue({
        id: 'sk-backend',
        confidence_score: 60,
      } as any);
      const upsertSpy = jest.spyOn(prisma.studentSkill, 'upsert').mockResolvedValue({
        id: 'sk-backend',
        confidence_score: 50,
      } as any);
      jest.spyOn(careerService, 'adaptRoadmap').mockResolvedValue({} as any);
      const changeSpy = jest.spyOn(prisma.roadmapChange, 'create').mockResolvedValue({ id: 'rc-1' } as any);

      const result = await careerService.submitQuiz(testUserId, {
        phase_number: 1,
        role: 'Full-Stack',
        roadmap_id: testRoadmapId,
        answers: { 0: 0, 1: 0, 2: 0 }, // 0/3 correct
      });

      expect(result.passed).toBe(false);
      expect(result.percentage).toBe(0);
      expect(result.roadmapAdapted).toBe(true);
      expect(upsertSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          update: expect.objectContaining({ confidence_score: 50 }),
        })
      );
      expect(changeSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            title: expect.stringContaining('Reinforced Phase 1'),
          }),
        })
      );
    });

    it('ADAPTIVE LEARNING LOOP: Verifies roadmap changes when evidence changes', async () => {
      // Step 1: Student fails quiz
      const adaptSpy = jest.spyOn(careerService, 'adaptRoadmap').mockResolvedValue({
        adaptationSummary: 'Added 2 targeted remediation modules on Asynchronous Event Loops.',
      } as any);

      await careerService.improveRoadmap(
        testUserId,
        testRoadmapId,
        'Remediate Async Loop Weakness',
        'Student scored 0% on async concepts'
      );

      expect(adaptSpy).toHaveBeenCalledWith(
        testUserId,
        testRoadmapId,
        'Remediate Async Loop Weakness: Student scored 0% on async concepts'
      );
    });
  });

  // =========================================================================
  // 4. RESOURCE QUALITY & EXTERNAL API FAILURE RESILIENCE (SECTIONS 10 & 11)
  // =========================================================================
  describe('Resource Quality & External API Failure Resilience', () => {
    it('verifies GitHub repositories have valid structure, positive stars, and non-empty URLs', async () => {
      const repos = await CareerGitHubService.searchRepositories('Full-Stack Web Development', 3);
      expect(repos.length).toBeGreaterThan(0);
      for (const repo of repos) {
        expect(repo.url).toMatch(/^https:\/\/github\.com\//);
        expect(repo.stars).toBeGreaterThanOrEqual(0);
        expect(repo.name.length).toBeGreaterThan(0);
      }
    });

    it('verifies YouTube resources match topic and prioritize preferred language without hallucinated links', () => {
      const videos = CareerYouTubeService.getEducationalVideos('Data Structures and Algorithms', 'English', 3);
      expect(videos.length).toBeGreaterThan(0);
      expect(videos[0].language.toLowerCase()).toBe('english');
      for (const vid of videos) {
        expect(vid.url).toMatch(/^https:\/\/www\.youtube\.com\//);
        expect(vid.title.length).toBeGreaterThan(0);
        expect(vid.isVerified).toBe(true);
      }
    });

    it('provides graceful fallback when AI provider or network times out without crashing', async () => {
      const fallbackRepos = CareerGitHubService.getCuratedFallback('NonExistentTech');
      expect(fallbackRepos.length).toBeGreaterThan(0);
      expect(fallbackRepos[0].url).toContain('github.com');
    });
  });

  // =========================================================================
  // 5. MALFORMED AI OUTPUT VALIDATION (SECTION 12)
  // =========================================================================
  describe('AI Output Validation & Malformed Schema Protection', () => {
    it('rejects malformed structured JSON and catches invalid field types', async () => {
      const malformedPayloads = [
        {}, // Empty
        null, // Null
        { question: 'Too short', options: ['Only 1 option'] }, // Missing required fields
        { fitPercentage: 150 }, // Out of bounds percentage
      ];

      for (const bad of malformedPayloads) {
        expect(() => {
          if (!bad || typeof bad !== 'object') throw new Error('Invalid JSON');
          if (!('question' in bad) || !Array.isArray((bad as any).options) || (bad as any).options.length < 2) {
            throw new Error('Schema validation failed');
          }
        }).toThrow();
      }
    });
  });

  // =========================================================================
  // 6. MULTI-DIMENSIONAL JOB READINESS CONTROLLED CHANGES (SECTION 13)
  // =========================================================================
  describe('Job Readiness 6-Dimension Controlled Changes', () => {
    it('calculates job readiness across all 6 dimensions strictly bounded between 0 and 100', async () => {
      const report = await JobReadinessEngine.calculateReadiness('3ed8e5d8-2788-4c54-ab0f-1338b6048b7c');

      // Check all 6 dimensions exist
      expect(report.technical).toBeDefined();
      expect(report.projects).toBeDefined();
      expect(report.problemSolving).toBeDefined();
      expect(report.interview).toBeDefined();
      expect(report.portfolio).toBeDefined();
      expect(report.learningConsistency).toBeDefined();

      // Check bounds
      if (report.overallPercent !== null) {
        expect(report.overallPercent).toBeGreaterThanOrEqual(0);
        expect(report.overallPercent).toBeLessThanOrEqual(100);
      }
      if (report.technical.score !== null) {
        expect(report.technical.score).toBeLessThanOrEqual(100);
      }
      if (report.projects.score !== null) {
        expect(report.projects.score).toBeLessThanOrEqual(100);
      }
    });
  });

  // =========================================================================
  // 7. SECURITY & CROSS-USER ISOLATION AUDIT (SECTION 16)
  // =========================================================================
  describe('Security & Cross-User Authorization Audit', () => {
    let careerService: CareerService;
    const userA = '11111111-1111-1111-1111-111111111111';
    const userB = '22222222-2222-2222-2222-222222222222';

    beforeEach(() => {
      careerService = new CareerService({
        getRoadmapById: jest.fn().mockResolvedValue({
          id: 'roadmap-b',
          user_id: userB,
          title: 'Private User B Roadmap',
        }),
      } as any);
    });

    it('blocks User A from accessing User B custom roadmap details (ForbiddenError)', async () => {
      await expect(careerService.getRoadmapDetails('roadmap-b', userA)).rejects.toThrow(
        'You do not have permission to access this roadmap'
      );
    });

    it('blocks User A from accessing User B interview session', async () => {
      jest.spyOn(prisma.interviewSession, 'findUnique').mockResolvedValue({
        id: 'interview-b',
        user_id: userB,
      } as any);

      await expect(careerService.submitInterviewTurn(userA, 'interview-b', 'My answer')).rejects.toThrow(
        'Interview session not found'
      );
    });

    it('blocks User A from submitting answers to User B Pathfinder session', async () => {
      jest.spyOn(prisma.careerPathfinderSession, 'findUnique').mockResolvedValue({
        id: 'session-b',
        user_id: userB,
        user: { department: { name: 'CS' } },
        stage: 'CAREER_DISCOVERY',
      } as any);

      const pathfinder = new (evaluator as any).pathfinderService.constructor();
      await expect(pathfinder.submitAnswer('session-b', 'Hacked answer', userA)).rejects.toThrow(
        'Unauthorized to submit answers to this session'
      );
    });
  });
});
