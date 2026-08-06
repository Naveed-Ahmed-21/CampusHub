import { AdminService } from './admin.service';
import { AdminRepository } from './admin.repository';
import { Role } from '@prisma/client';

describe('AdminService', () => {
  let adminService: AdminService;
  let adminRepository: jest.Mocked<AdminRepository>;

  beforeEach(() => {
    adminRepository = {
      getDashboardMetrics: jest.fn(),
      findUsers: jest.fn(),
      updateUserRole: jest.fn(),
      updateUserStatus: jest.fn(),
      findDepartments: jest.fn(),
      createDepartment: jest.fn(),
      getAuditLogs: jest.fn(),
    } as unknown as jest.Mocked<AdminRepository>;

    adminService = new AdminService(adminRepository);
  });

  describe('getDashboardMetrics', () => {
    it('should return metrics from repository', async () => {
      const mockMetrics = {
        totalUsers: 100,
        totalDepartments: 5,
        approvedClubs: 10,
        pendingClubs: 2,
        totalEvents: 15,
        totalDrives: 8,
        placedCount: 40,
      };

      adminRepository.getDashboardMetrics.mockResolvedValue(mockMetrics);

      const result = await adminService.getDashboardMetrics('clg_1');
      expect(result.totalUsers).toBe(100);
      expect(result.approvedClubs).toBe(10);
    });

    it('should return fallback metrics if repository throws', async () => {
      adminRepository.getDashboardMetrics.mockRejectedValue(new Error('DB offline'));

      const result = await adminService.getDashboardMetrics('clg_1');
      expect(result.totalUsers).toBeGreaterThan(0);
      expect(result.approvedClubs).toBeGreaterThan(0);
    });
  });

  describe('updateUserRole', () => {
    it('should update user role successfully', async () => {
      adminRepository.updateUserRole.mockResolvedValue({
        id: 'usr_1',
        role: Role.COLLEGE_ADMIN,
      } as any);

      const result = await adminService.updateUserRole({ userId: 'usr_1', newRole: Role.COLLEGE_ADMIN });
      expect(result.role).toBe(Role.COLLEGE_ADMIN);
    });
  });
});
