import { PortfolioService } from './portfolio.service';
import { PortfolioRepository } from './portfolio.repository';
import { NotFoundError } from '../../shared/errors/AppError';

describe('PortfolioService', () => {
  let portfolioRepository: jest.Mocked<PortfolioRepository>;
  let portfolioService: PortfolioService;

  const mockUserId = 'user-123';

  beforeEach(() => {
    portfolioRepository = {
      findPortfolioByUserId: jest.fn(),
      findPublicPortfolio: jest.fn(),
      updatePortfolio: jest.fn(),
      addProject: jest.fn(),
      deleteProject: jest.fn(),
      addSkill: jest.fn(),
      deleteSkill: jest.fn(),
      addCertificate: jest.fn(),
      deleteCertificate: jest.fn(),
      addAchievement: jest.fn(),
      deleteAchievement: jest.fn(),
    } as unknown as jest.Mocked<PortfolioRepository>;

    portfolioService = new PortfolioService(portfolioRepository);
  });

  describe('getPublicPortfolio', () => {
    it('should throw NotFoundError if public portfolio does not exist', async () => {
      portfolioRepository.findPublicPortfolio.mockResolvedValue(null);
      await expect(portfolioService.getPublicPortfolio('non-existent')).rejects.toThrow(NotFoundError);
    });

    it('should return public portfolio profile', async () => {
      portfolioRepository.findPublicPortfolio.mockResolvedValue({
        id: 'port-123',
        user_id: mockUserId,
        bio: 'Full Stack Engineer',
        projects: [],
        skills: [],
      } as never);

      const result = await portfolioService.getPublicPortfolio(mockUserId);
      expect(result.bio).toBe('Full Stack Engineer');
    });
  });

  describe('addProject', () => {
    it('should add project to portfolio', async () => {
      portfolioRepository.addProject.mockResolvedValue({
        id: 'proj-1',
        title: 'CampusHub App',
      } as never);

      const result = await portfolioService.addProject(mockUserId, {
        title: 'CampusHub App',
        tech_stack: ['Flutter', 'Node.js'],
      });

      expect(result.title).toBe('CampusHub App');
    });
  });
});
