import { CareerAIOrchestrator } from './ai/career.agents';
import { CareerAIService } from './career.ai.service';
import { BuiltCareerContext } from './ai/career.context-builder';

describe('Career Hub AI Adaptive Intelligence Suite', () => {
  let orchestrator: CareerAIOrchestrator;
  let aiService: CareerAIService;

  const mockContext: BuiltCareerContext = {
    student: {
      userId: 'test-user',
      department: 'Computer Science & Engineering',
      knownSkills: ['Programming Fundamentals', 'Git'],
      weakSkills: ['System Design'],
      experienceLevel: 'Beginner',
      targetRole: 'Flutter Mobile Architect',
      dailyHours: 2,
      preferredLanguage: 'English',
      projectSubmissions: [],
    },
    roadmap: undefined,
    recentTurns: [],
    summaryString: 'Student in CS department with foundations in Programming Fundamentals and Git.',
  };

  beforeEach(() => {
    orchestrator = new CareerAIOrchestrator();
    aiService = new CareerAIService();
  });

  describe('Dynamic Questioning & Distinct Exploration Paths', () => {
    it('Student A (Mobile / Flutter): Calibrates specifically for Flutter Mobile Architect', async () => {
      const turn0 = await orchestrator.processPathfinderMessage(
        'I want to build mobile apps with Flutter and Dart',
        [],
        undefined,
        mockContext
      );
      expect(turn0.state).toBe('COLLECTING_CONTEXT');
      expect(turn0.message).toContain('Flutter Mobile Architect');
      expect(turn0.message).toContain('Have you written code or built projects');

      const turn1 = await orchestrator.processPathfinderMessage(
        'I built a small calculator app in Dart, know basic syntax',
        [{ sender: 'USER', content: 'Flutter apps' }, { sender: 'EVA', content: turn0.message }],
        undefined,
        mockContext
      );
      expect(turn1.state).toBe('COLLECTING_CONTEXT');
      expect(turn1.message).toContain('How many hours per day');

      const turn2 = await orchestrator.processPathfinderMessage(
        '2 hours per day, English, placement in 4 months, I love hands-on building',
        [
          { sender: 'USER', content: 'Flutter apps' },
          { sender: 'EVA', content: turn0.message },
          { sender: 'USER', content: 'built a small calculator app' },
          { sender: 'EVA', content: turn1.message },
        ],
        undefined,
        mockContext
      );

      expect(turn2.state).toBe('AWAITING_CONFIRMATION');
      expect(turn2.confirmedProfile?.targetRole).toBe('Flutter Mobile Architect');
      expect(turn2.careerMatches?.[0].role).toBe('Flutter Mobile Architect');
      expect(turn2.careerMatches?.[0].matchScore).toBeGreaterThanOrEqual(90);
      expect(turn2.message).toContain('Practical Hands-on Builder');
    });

    it('Student B (Backend & Systems): Calibrates for Backend & Distributed Systems Architect', async () => {
      const turn0 = await orchestrator.processPathfinderMessage(
        'I am passionate about backend APIs, databases, PostgreSQL and microservices',
        [],
        undefined,
        mockContext
      );
      expect(turn0.state).toBe('COLLECTING_CONTEXT');
      expect(turn0.message).toContain('Backend & Distributed Systems Architect');

      const turn2 = await orchestrator.processPathfinderMessage(
        '3 hours per day, English, internship, comfortable builder with Express and SQL',
        [{ sender: 'USER', content: 'backend' }, { sender: 'EVA', content: turn0.message }],
        undefined,
        mockContext
      );
      expect(turn2.state).toBe('AWAITING_CONFIRMATION');
      expect(turn2.careerMatches?.[0].role).toBe('Backend & Distributed Systems Architect');
      expect(turn2.careerMatches?.[0].gaps).toContain('Redis distributed locks');
    });

    it('Student C (Cybersecurity & DevSecOps): Calibrates for Cyber Security & DevSecOps Engineer', async () => {
      const turn0 = await orchestrator.processPathfinderMessage(
        'I am interested in cybersecurity, ethical hacking, network defense, and OWASP',
        [],
        undefined,
        mockContext
      );
      expect(turn0.state).toBe('COLLECTING_CONTEXT');
      expect(turn0.message).toContain('Cyber Security & DevSecOps Engineer');

      const turn2 = await orchestrator.processPathfinderMessage(
        '2 hours per day, placement in 4 months, structured theory first',
        [{ sender: 'USER', content: 'cyber security' }, { sender: 'EVA', content: turn0.message }],
        undefined,
        mockContext
      );
      expect(turn2.state).toBe('AWAITING_CONFIRMATION');
      expect(turn2.careerMatches?.[0].role).toBe('Cyber Security & DevSecOps Engineer');
      expect(turn2.careerMatches?.[0].gaps).toContain('OWASP Top 10 API Security');
      expect(turn2.message).toContain('Structured Conceptual Deep-Dive');
    });

    it('Student D (Unsure / Confused): Guides exploratory breakdown before deciding', async () => {
      const turn0 = await orchestrator.processPathfinderMessage(
        "I'm confused and don't know what to learn in computer science",
        [],
        undefined,
        mockContext
      );
      expect(turn0.state).toBe('COLLECTING_CONTEXT');
      expect(turn0.message).toContain('Discovering what genuinely excites you is the best first step');
      expect(turn0.suggestedPills).toContain('Flutter & Mobile Apps');
      expect(turn0.suggestedPills).toContain('Backend APIs & Cloud');
      expect(turn0.suggestedPills).toContain('Cybersecurity & DevSecOps');
    });

    it('Contradiction Detection: Reconciles claims of expert level with zero coding background', async () => {
      const turn0 = await orchestrator.processPathfinderMessage(
        'I am an expert but I have never coded and starting from scratch with Flutter',
        [],
        undefined,
        mockContext
      );
      expect(turn0.message).toContain('Note on calibration');
      expect(turn0.message).toContain('starting from scratch');
    });
  });

  describe('Adaptive Quiz Generator & Question Bank Coverage', () => {
    it('Generates 8-question adaptive quiz for Flutter Mobile Architect', () => {
      const quiz = aiService.generateAdaptiveQuiz({
        role: 'Flutter Mobile Architect',
        phaseNumber: 1,
        difficulty: 'Intermediate',
        numQuestions: 8,
      });

      expect(quiz.questions.length).toBe(8);
      expect(quiz.role).toBe('Flutter Mobile Architect');

      const types = quiz.questions.map((q) => q.type);
      expect(types).toContain('MCQ');
      expect(types).toContain('SCENARIO');
      expect(types).toContain('DEBUGGING');
      expect(types).toContain('CODE_UNDERSTANDING');
      expect(types).toContain('EDGE_CASE');
      expect(types).toContain('PERFORMANCE');
      expect(types).toContain('SECURITY');
      expect(types).toContain('ARCHITECTURE_TRADEOFF');

      // Verify each question has 4 options and a valid explanation
      for (const q of quiz.questions) {
        expect(q.options.length).toBe(4);
        expect(q.correct_index).toBeGreaterThanOrEqual(0);
        expect(q.correct_index).toBeLessThanOrEqual(3);
        expect(q.explanation.length).toBeGreaterThan(10);
      }
    });

    it('Generates targeted adaptive quiz for Backend & Distributed Systems Architect', () => {
      const quiz = aiService.generateAdaptiveQuiz({
        role: 'Backend & Distributed Systems Architect',
        phaseNumber: 2,
        difficulty: 'Intermediate',
        numQuestions: 8,
      });

      expect(quiz.questions.length).toBe(8);
      const concepts = quiz.questions.map((q) => q.tested_concept);
      expect(concepts.some((c) => c.includes('PostgreSQL') || c.includes('ACID') || c.includes('Race'))).toBe(true);
    });

    it('Prioritizes questions matching user weak skills', () => {
      const quiz = aiService.generateAdaptiveQuiz({
        role: 'Flutter Mobile Architect',
        phaseNumber: 1,
        userWeaknesses: ['Riverpod'],
        numQuestions: 3,
      });

      expect(quiz.questions.length).toBe(3);
      // The Riverpod debugging question should be prioritized at the top
      expect(quiz.questions[0].tested_concept.toLowerCase()).toContain('riverpod');
    });
  });
});
