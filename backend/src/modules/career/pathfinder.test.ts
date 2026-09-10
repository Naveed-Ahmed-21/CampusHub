import { z } from 'zod';
import { FreeLLMAPIProvider } from '../../shared/ai/ai.provider';
import { CareerAIOrchestrator } from './ai/career.agents';
import { BuiltCareerContext } from './ai/career.context-builder';
import { CareerService } from './career.service';
import { CareerRepository } from './career.repository';
import { prisma } from '../../config/database';
import { ForbiddenError, NotFoundError } from '../../shared/errors/AppError';

// Mock prisma for database calls
jest.mock('../../config/database', () => ({
  prisma: {
    aIConversation: {
      findFirst: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    aIMessage: {
      create: jest.fn(),
    },
    careerJourney: {
      create: jest.fn(),
      findFirst: jest.fn(),
    },
    careerRoadmap: {
      update: jest.fn(),
    },
    user: {
      findUnique: jest.fn(),
    },
    studentSkill: {
      findMany: jest.fn(),
    },
    userRoadmapProgress: {
      findFirst: jest.fn(),
      findUnique: jest.fn(),
    },
    userMiniProjectSubmission: {
      findMany: jest.fn(),
    },
  },
}));

describe('AI Career Intelligence Foundation & AI Pathfinder', () => {
  describe('FreeLLMAPIProvider Abstraction', () => {
    it('should default to freellmapi provider with 127.0.0.1:3001 and auto model', () => {
      const provider = new FreeLLMAPIProvider();
      expect(provider.provider).toBe('freellmapi');
      expect(provider.baseUrl).toBeDefined();
      expect(provider.model).toBe('auto');
      expect(provider.timeoutMs).toBe(35000);
      expect(provider.maxRetries).toBe(1);
    });

    it('should support custom endpoint, model, and mock provider', () => {
      const provider = new FreeLLMAPIProvider({
        provider: 'mock',
        model: 'custom-model',
        baseUrl: 'http://custom-host:8080/v1/',
      });
      expect(provider.provider).toBe('mock');
      expect(provider.baseUrl).toBe('http://custom-host:8080/v1');
      expect(provider.model).toBe('custom-model');
    });

    it('should provide intelligent contextual fallback without throwing errors', async () => {
      const provider = new FreeLLMAPIProvider({ provider: 'mock' });
      const text = await provider.generateText('What is Riverpod and why is it better than Bloc for beginners?');
      expect(text).toContain('Riverpod vs Bloc');
      expect(text).toContain('compile-time safety');
    });

    it('should parse structured output using Zod schema safely', async () => {
      const provider = new FreeLLMAPIProvider({ provider: 'mock' });
      // Mock generateText to return a JSON string
      jest.spyOn(provider, 'generateText').mockResolvedValue(
        JSON.stringify({ role: 'Flutter Mobile Architect', matchScore: 95 })
      );

      const schema = z.object({
        role: z.string(),
        matchScore: z.number(),
      });

      const result = await provider.generateStructured('Test prompt', schema);
      expect(result.role).toBe('Flutter Mobile Architect');
      expect(result.matchScore).toBe(95);
    });
  });

  describe('CareerAIOrchestrator Pathfinder Engine', () => {
    let orchestrator: CareerAIOrchestrator;
    const mockContext: BuiltCareerContext = {
      student: {
        userId: 'student-1',
        department: 'Computer Science & Engineering',
        experienceLevel: 'Beginner',
        knownSkills: ['Dart', 'Basic Python'],
        weakSkills: ['State Management'],
        preferredLanguage: 'English',
        dailyHours: 2,
        projectSubmissions: ['Campus Attendance App'],
      },
      recentTurns: [],
      summaryString: 'STUDENT CONTEXT',
    };

    beforeEach(() => {
      orchestrator = new CareerAIOrchestrator();
    });

    it('should enrich initial greeting with student department and database skills', () => {
      const greeting = orchestrator.generateInitialGreeting(mockContext);
      expect(greeting.state).toBe('STARTED');
      expect(greeting.message).toContain('Computer Science & Engineering');
      expect(greeting.message).toContain('Dart');
      expect(greeting.suggestedPills.length).toBeGreaterThanOrEqual(4);
    });

    it('should prompt for hands-on experience and projects on turn 0', async () => {
      const response = await orchestrator.processPathfinderMessage(
        'I am interested in Flutter & Mobile Apps',
        [],
        undefined,
        mockContext
      );

      expect(response.state).toBe('COLLECTING_CONTEXT');
      expect(response.isConfirmed).toBe(false);
      expect(response.message).toContain('Flutter Mobile Architect');
      expect(response.message).toContain('Have you written code or built projects');
    });

    it('should prompt for hours and preferred tutorial language on turn 1', async () => {
      const history = [
        { sender: 'USER', content: 'Flutter & Mobile Apps' },
        { sender: 'EVA', content: 'Have you built anything before?' },
      ];

      const response = await orchestrator.processPathfinderMessage(
        'I built a small calculator app in Dart, know basic syntax',
        history,
        undefined,
        mockContext
      );

      expect(response.state).toBe('COLLECTING_CONTEXT');
      expect(response.message).toContain('How many hours per day');
    });

    it('should synthesize responses and calculate 3 career matches on turn 2', async () => {
      const history = [
        { sender: 'USER', content: 'Flutter & Mobile Apps' },
        { sender: 'EVA', content: 'Have you built anything before?' },
        { sender: 'USER', content: 'Built 1-2 small projects in Dart' },
        { sender: 'EVA', content: 'How many hours per day?' },
      ];

      const response = await orchestrator.processPathfinderMessage(
        '2 hours per day, English, placement in 4 months',
        history,
        undefined,
        mockContext
      );

      expect(response.state).toBe('AWAITING_CONFIRMATION');
      expect(response.confirmedProfile).toBeDefined();
      expect(response.confirmedProfile?.targetRole).toBe('Flutter Mobile Architect');
      expect(response.careerMatches?.length).toBe(3);

      const topMatch = response.careerMatches![0];
      expect(topMatch.role).toBe('Flutter Mobile Architect');
      expect(topMatch.matchScore).toBeGreaterThanOrEqual(90);
      expect(topMatch.gaps.length).toBeGreaterThanOrEqual(2);
      expect(topMatch.nextSteps?.length).toBeGreaterThanOrEqual(2);

      // Verify no hallucinated skills: known skills should come from DB + student
      expect(response.confirmedProfile?.knownSkills).toContain('Dart');
    });

    it('should detect confirmation intent and transition to CONFIRMED', async () => {
      const existingProfile = {
        targetRole: 'Flutter Mobile Architect',
        experienceLevel: 'Intermediate',
        dailyHours: 2,
        preferredLanguage: 'English',
        goal: 'Tier-1 Campus Placement',
      };

      const response = await orchestrator.processPathfinderMessage(
        'Yes, confirm & build my journey',
        [{ sender: 'USER', content: 'Looks great!' }],
        existingProfile,
        mockContext
      );

      expect(response.state).toBe('CONFIRMED');
      expect(response.isConfirmed).toBe(true);
      expect(response.isComplete).toBe(true);
      expect(response.message).toContain('confirmed');
    });
  });

  describe('CareerService Pathfinder Session Management', () => {
    let careerService: CareerService;
    let mockRepo: jest.Mocked<CareerRepository>;
    const userId = 'user-uuid-123';
    const sessionId = 'session-uuid-456';

    beforeEach(() => {
      mockRepo = {
        createCustomRoadmap: jest.fn(),
        findExistingRoadmapForRole: jest.fn(),
      } as unknown as jest.Mocked<CareerRepository>;
      careerService = new CareerService(mockRepo);
      jest.clearAllMocks();
    });

    it('should start a new pathfinder session with enriched student greeting', async () => {
      (prisma.aIConversation.findFirst as jest.Mock).mockResolvedValue(null);
      (prisma.user.findUnique as jest.Mock).mockResolvedValue({
        id: userId,
        department: { name: 'Information Technology' },
      });
      (prisma.studentSkill.findMany as jest.Mock).mockResolvedValue([
        { skill_name: 'Python', confidence_score: 75, proficiency_level: 'Intermediate' },
      ]);
      (prisma.userMiniProjectSubmission.findMany as jest.Mock).mockResolvedValue([]);
      (prisma.aIConversation.create as jest.Mock).mockResolvedValue({
        id: sessionId,
        user_id: userId,
        type: 'PATHFINDER',
        created_at: new Date(),
        updated_at: new Date(),
      });
      (prisma.aIMessage.create as jest.Mock).mockResolvedValue({ id: 'msg-1' });

      const session = await careerService.startPathfinderSession(userId, true);
      expect(session.session_id).toBe(sessionId);
      expect(session.state).toBe('STARTED');
      expect(session.message).toContain('Information Technology');
      expect(prisma.aIConversation.create).toHaveBeenCalled();
    });

    it('should resume an active unconfirmed pathfinder session if present', async () => {
      (prisma.aIConversation.findFirst as jest.Mock).mockResolvedValue({
        id: sessionId,
        user_id: userId,
        type: 'PATHFINDER',
        is_confirmed: false,
        created_at: new Date(),
        updated_at: new Date(),
        confirmed_profile: {
          state: 'COLLECTING_CONTEXT',
          targetRole: 'Flutter Mobile Architect',
        },
        messages: [
          { sender: 'EVA', content: 'What is your current coding background?' },
        ],
      });

      const session = await careerService.startPathfinderSession(userId, true);
      expect(session.session_id).toBe(sessionId);
      expect(session.state).toBe('COLLECTING_CONTEXT');
      expect(session.message).toContain('What is your current coding background?');
      expect(prisma.aIConversation.create).not.toHaveBeenCalled();
    });

    it('should throw ForbiddenError when user accesses another student session', async () => {
      (prisma.aIConversation.findUnique as jest.Mock).mockResolvedValue({
        id: sessionId,
        user_id: 'other-user-uuid',
      });

      await expect(
        careerService.getPathfinderSession(userId, sessionId)
      ).rejects.toThrow(ForbiddenError);
    });

    it('should confirm pathfinder session and allow track selection override', async () => {
      (prisma.aIConversation.findUnique as jest.Mock).mockResolvedValue({
        id: sessionId,
        user_id: userId,
        confirmed_profile: {
          targetRole: 'Flutter Mobile Architect',
          dailyHours: 2,
        },
      });
      (prisma.aIConversation.update as jest.Mock).mockResolvedValue({});

      const result = await careerService.confirmPathfinderSession(userId, sessionId, {
        selected_direction: 'Backend & Distributed Systems Architect',
        overrides: { dailyHours: 3 },
      });

      expect(result.state).toBe('CONFIRMED');
      expect(result.confirmed_profile.targetRole).toBe('Backend & Distributed Systems Architect');
      expect(result.confirmed_profile.dailyHours).toBe(3);
      expect(prisma.aIConversation.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: sessionId },
          data: expect.objectContaining({ is_confirmed: true }),
        })
      );
    });
  });
});
