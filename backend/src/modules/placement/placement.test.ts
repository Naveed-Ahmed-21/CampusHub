import { PlacementService } from './placement.service';
import { PlacementRepository } from './placement.repository';
import { Role } from '@prisma/client';
import { ForbiddenError, BadRequestError } from '../../shared/errors/AppError';

describe('PlacementService', () => {
  let placementRepository: jest.Mocked<PlacementRepository>;
  let placementService: PlacementService;

  const mockCollegeId = 'college-123';
  const mockUserId = 'user-123';

  beforeEach(() => {
    placementRepository = {
      getOfficerDashboardStats: jest.fn(),
      getStudentDashboardStats: jest.fn(),
      createDrive: jest.fn(),
      findDrives: jest.fn(),
      findDriveById: jest.fn(),
      createApplication: jest.fn(),
      findApplication: jest.fn(),
      updateApplicationStatus: jest.fn(),
      scheduleInterview: jest.fn(),
      respondToOffer: jest.fn(),
    } as unknown as jest.Mocked<PlacementRepository>;

    placementService = new PlacementService(placementRepository);
  });

  describe('getOfficerDashboard', () => {
    it('should throw ForbiddenError if user is STUDENT', async () => {
      await expect(
        placementService.getOfficerDashboard(mockCollegeId, Role.STUDENT)
      ).rejects.toThrow(ForbiddenError);
    });

    it('should return officer stats for ADMIN', async () => {
      placementRepository.getOfficerDashboardStats.mockResolvedValue({
        totalDrives: 5,
        activeDrives: 2,
        totalApplications: 40,
        offeredCount: 8,
        acceptedOffers: 5,
      });

      const result = await placementService.getOfficerDashboard(mockCollegeId, Role.PLACEMENT_OFFICER);
      expect(result.totalDrives).toBe(5);
    });
  });

  describe('createDrive', () => {
    it('should throw BadRequestError if deadline is in the past', async () => {
      await expect(
        placementService.createDrive(mockCollegeId, Role.PLACEMENT_OFFICER, {
          company_name: 'Tech Corp',
          role_title: 'Software Engineer',
          deadline: '2020-01-01T00:00:00Z',
        })
      ).rejects.toThrow(BadRequestError);
    });
  });
});
