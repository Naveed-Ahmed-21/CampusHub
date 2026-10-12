import { PlacementService } from './placement.service';
import { PlacementRepository } from './placement.repository';
import { ApplicationStatus, Role } from '@prisma/client';
import { ForbiddenError, BadRequestError } from '../../shared/errors/AppError';

describe('PlacementService', () => {
  let placementRepository: jest.Mocked<PlacementRepository>;
  let placementService: PlacementService;

  const mockCollegeId = 'college-123';
  const mockUserId = 'user-123';

  beforeEach(() => {
    placementRepository = {
      getOfficerDashboardStats: jest.fn(),
      getDepartmentPlacementStats: jest.fn(),
      getStudentDashboardStats: jest.fn(),
      createDrive: jest.fn(),
      findDrives: jest.fn(),
      findDriveById: jest.fn(),
      createApplication: jest.fn(),
      findApplication: jest.fn(),
      updateApplicationStatus: jest.fn(),
      bulkUpdateApplicationStatus: jest.fn(),
      scheduleInterview: jest.fn(),
      respondToOffer: jest.fn(),
      createResource: jest.fn(),
      findResources: jest.fn(),
    } as unknown as jest.Mocked<PlacementRepository>;

    placementService = new PlacementService(placementRepository);
  });

  describe('getOfficerDashboard', () => {
    it('should throw ForbiddenError if user is STUDENT', async () => {
      await expect(
        placementService.getOfficerDashboard(mockCollegeId, Role.STUDENT)
      ).rejects.toThrow(ForbiddenError);
    });

    it('should return officer stats for PLACEMENT', async () => {
      placementRepository.getOfficerDashboardStats.mockResolvedValue({
        totalDrives: 5,
        activeDrives: 2,
        totalApplications: 40,
        offeredCount: 8,
        acceptedOffers: 5,
        totalStudents: 100,
        placementRate: 5,
        recentDrives: [],
        upcomingInterviews: [],
        departmentStats: [],
      });

      const result = await placementService.getOfficerDashboard(mockCollegeId, Role.PLACEMENT);
      expect(result.totalDrives).toBe(5);
    });
  });

  describe('getDepartmentPlacementStats', () => {
    it('should throw ForbiddenError if DEPT_ADMIN queries a different department', async () => {
      await expect(
        placementService.getDepartmentPlacementStats(
          mockCollegeId,
          'dept-cse',
          'dept-ece',
          Role.DEPT_ADMIN
        )
      ).rejects.toThrow(ForbiddenError);
    });

    it('should allow DEPT_ADMIN to view their own department stats', async () => {
      placementRepository.getDepartmentPlacementStats.mockResolvedValue({
        totalStudents: 60,
        eligibleStudents: 45,
        appliedStudents: 30,
        placedStudents: 15,
        placementRate: 25,
        activeDrives: [],
      });

      const result = await placementService.getDepartmentPlacementStats(
        mockCollegeId,
        'dept-cse',
        'dept-cse',
        Role.DEPT_ADMIN
      );
      expect(result.placedStudents).toBe(15);
      expect(result.placementRate).toBe(25);
    });
  });

  describe('createDrive', () => {
    it('should throw BadRequestError if deadline is in the past', async () => {
      await expect(
        placementService.createDrive(mockCollegeId, Role.PLACEMENT, {
          company_name: 'Tech Corp',
          role_title: 'Software Engineer',
          deadline: '2020-01-01T00:00:00Z',
        })
      ).rejects.toThrow(BadRequestError);
    });

    it('should throw ForbiddenError if non-officer attempts to create a drive', async () => {
      await expect(
        placementService.createDrive(mockCollegeId, Role.STUDENT, {
          company_name: 'Tech Corp',
          role_title: 'Software Engineer',
          deadline: '2030-01-01T00:00:00Z',
        })
      ).rejects.toThrow(ForbiddenError);
    });
  });

  describe('bulkUpdateApplicationStatus', () => {
    it('should throw ForbiddenError if user is not a placement officer', async () => {
      await expect(
        placementService.bulkUpdateApplicationStatus(Role.STUDENT, {
          application_ids: ['app-1', 'app-2'],
          status: ApplicationStatus.SHORTLISTED,
        })
      ).rejects.toThrow(ForbiddenError);
    });

    it('should call repository bulkUpdateApplicationStatus when called by PLACEMENT', async () => {
      placementRepository.bulkUpdateApplicationStatus.mockResolvedValue({ count: 2 });

      const result = await placementService.bulkUpdateApplicationStatus(Role.PLACEMENT, {
        application_ids: ['app-1', 'app-2'],
        status: ApplicationStatus.SHORTLISTED,
      });

      expect(placementRepository.bulkUpdateApplicationStatus).toHaveBeenCalledWith(
        ['app-1', 'app-2'],
        ApplicationStatus.SHORTLISTED,
        undefined
      );
      expect(result).toEqual({ count: 2 });
    });
  });

  describe('createResource', () => {
    it('should reject resource creation by STUDENT', async () => {
      await expect(
        placementService.createResource(mockCollegeId, mockUserId, Role.STUDENT, {
          title: 'DSA Cheat Sheet',
          category: 'TECHNICAL',
          resource_type: 'PDF',
        })
      ).rejects.toThrow(ForbiddenError);
    });
  });
});
