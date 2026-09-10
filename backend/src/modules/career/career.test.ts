import { CareerService } from './career.service';
import { CareerRepository } from './career.repository';
import { NotFoundError } from '../../shared/errors/AppError';

describe('CareerService', () => {
  let careerRepository: jest.Mocked<CareerRepository>;
  let careerService: CareerService;

  const mockUserId = 'user-123';
  const mockRoadmapId = 'roadmap-123';

  beforeEach(() => {
    careerRepository = {
      getRoadmaps: jest.fn(),
      getUserRoadmaps: jest.fn(),
      getRoadmapById: jest.fn(),
      findExistingRoadmapForRole: jest.fn(),
      createCustomRoadmap: jest.fn(),
      saveDailyPlan: jest.fn(),
      updateRoadmap: jest.fn(),
      deleteRoadmap: jest.fn(),
      setActiveRoadmap: jest.fn(),
      getUserRoadmapProgress: jest.fn(),
      getUserRoadmapProgressByRoadmap: jest.fn(),
      getActiveUserRoadmap: jest.fn(),
      getUserCompletedNodes: jest.fn(),
      toggleNodeProgress: jest.fn(),
      updateDailyTask: jest.fn(),
      logAIInteraction: jest.fn(),
      createMentorShare: jest.fn(),
      getMenteeRoadmaps: jest.fn(),
      getWeeklyGoals: jest.fn(),
      createWeeklyGoal: jest.fn(),
      toggleWeeklyGoal: jest.fn(),
      getResumeTips: jest.fn(),
      getPlacementPrepModules: jest.fn(),
      getMiniProjects: jest.fn(),
      getUserSubmissions: jest.fn(),
      submitMiniProject: jest.fn(),
    } as unknown as jest.Mocked<CareerRepository>;

    careerService = new CareerService(careerRepository);
  });

  describe('getRoadmaps', () => {
    it('should return career roadmaps', async () => {
      careerRepository.getRoadmaps.mockResolvedValue([
        { id: mockRoadmapId, title: 'Software Engineer' } as never,
      ]);

      const result = await careerService.getRoadmaps({});
      expect(careerRepository.getRoadmaps).toHaveBeenCalledWith(undefined, undefined, undefined);
      expect(result.length).toBe(1);
    });
  });

  describe('getRoadmapDetails', () => {
    it('should throw NotFoundError if roadmap does not exist', async () => {
      careerRepository.getRoadmapById.mockResolvedValue(null);
      await expect(careerService.getRoadmapDetails('non-existent')).rejects.toThrow(NotFoundError);
    });

    it('should return roadmap when found', async () => {
      const mockData = { id: mockRoadmapId, title: 'Flutter Developer' };
      careerRepository.getRoadmapById.mockResolvedValue(mockData as never);
      const result = await careerService.getRoadmapDetails(mockRoadmapId);
      expect(result.title).toBe('Flutter Developer');
    });
  });

  describe('checkDuplicate', () => {
    it('should report exists true when a roadmap already exists for role', async () => {
      careerRepository.findExistingRoadmapForRole.mockResolvedValue({
        id: mockRoadmapId,
        title: 'Flutter Developer',
        target_role: 'Flutter Developer',
        version: 1,
        level: 'Intermediate',
        status: 'ACTIVE',
        created_at: new Date(),
      } as never);

      const result = await careerService.checkDuplicate(mockUserId, 'Flutter Developer');
      expect(result.exists).toBe(true);
      expect(result.existingRoadmap?.version).toBe(1);
    });

    it('should report exists false when no roadmap exists for role', async () => {
      careerRepository.findExistingRoadmapForRole.mockResolvedValue(null);
      const result = await careerService.checkDuplicate(mockUserId, 'DevOps Engineer');
      expect(result.exists).toBe(false);
    });
  });

  describe('generateOrActivateRoadmap', () => {
    it('should prevent accidental duplicates if create_new_version is not set', async () => {
      careerRepository.findExistingRoadmapForRole.mockResolvedValue({
        id: mockRoadmapId,
        title: 'Flutter Developer',
        version: 1,
      } as never);

      const result = await careerService.generateOrActivateRoadmap(mockUserId, {
        role: 'Flutter Developer',
        level: 'Beginner',
        weekly_hours: 10,
        create_new_version: false,
      });

      expect(result.isDuplicate).toBe(true);
      expect(careerRepository.createCustomRoadmap).not.toHaveBeenCalled();
    });

    it('should create new version when create_new_version is true', async () => {
      careerRepository.findExistingRoadmapForRole.mockResolvedValue({
        id: mockRoadmapId,
        title: 'Flutter Developer',
        version: 1,
      } as never);

      careerRepository.createCustomRoadmap.mockResolvedValue({
        roadmap: { id: 'rm-v2', title: 'Flutter Developer (v2)', version: 2 } as never,
        progress: { id: 'prog-2', is_active: true } as never,
      });

      const result = await careerService.generateOrActivateRoadmap(mockUserId, {
        role: 'Flutter Developer',
        level: 'Intermediate',
        weekly_hours: 15,
        create_new_version: true,
      });

      expect(result.isDuplicate).toBe(false);
      expect(result.version).toBe(2);
      expect(careerRepository.createCustomRoadmap).toHaveBeenCalled();
    });
  });

  describe('getUserProgress', () => {
    it('should calculate user progress across roadmaps and nodes', async () => {
      careerRepository.getUserRoadmapProgress.mockResolvedValue([
        { roadmap_id: mockRoadmapId, progress_percent: 50.0 } as never,
      ]);

      careerRepository.getUserCompletedNodes.mockResolvedValue([
        { node_id: 'node-1', completed_at: new Date() },
      ]);

      const result = await careerService.getUserProgress(mockUserId);
      expect(result.activeRoadmaps.length).toBe(1);
      expect(result.totalNodesCompleted).toBe(1);
      expect(result.completedNodeIds).toContain('node-1');
    });
  });

  describe('askAiAboutRoadmap', () => {
    it('should generate contextual AI answer tailored to student roadmap', async () => {
      careerRepository.getRoadmapById.mockResolvedValue({
        id: mockRoadmapId,
        title: 'Flutter Developer',
        target_role: 'Flutter Developer',
        skill_gaps_json: { needs_work_skills: ['Riverpod State Management'] },
      } as never);

      const result = await careerService.askAiAboutRoadmap(mockUserId, {
        roadmap_id: mockRoadmapId,
        prompt: 'I only have one hour today, what should I study?',
      });

      expect(result.answer).toContain('limited time');
      expect(careerRepository.logAIInteraction).toHaveBeenCalled();
    });
  });

  describe('helpMeDecide', () => {
    it('should recommend mobile for visual and fast feedback', async () => {
      const result = await careerService.helpMeDecide({
        visual_vs_logic: 'VISUAL',
        fast_vs_deep: 'FAST_FEEDBACK',
        startup_vs_enterprise: 'AGILE_STARTUP',
      });

      expect(result.recommendationId).toBe('rec_mobile');
      expect(result.verdict).toContain('Mobile');
    });
  });
});
