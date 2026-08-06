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
      getRoadmapById: jest.fn(),
      getUserRoadmapProgress: jest.fn(),
      getUserCompletedNodes: jest.fn(),
      toggleNodeProgress: jest.fn(),
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
});
