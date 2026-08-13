import { DepartmentsService } from './departments.service';
import { DepartmentsRepository } from './departments.repository';

describe('DepartmentsService', () => {
  let repo: jest.Mocked<DepartmentsRepository>;
  let service: DepartmentsService;

  const mockCollegeId = 'col-1';
  const mockDeptId = 'dept-it';

  beforeEach(() => {
    repo = {
      findDepartmentById: jest.fn(),
      findDepartmentsByCollege: jest.fn(),
      findDepartmentsByCodes: jest.fn(),
    } as unknown as jest.Mocked<DepartmentsRepository>;

    service = new DepartmentsService(repo);
  });

  it('should return all college departments if user has no department assigned', async () => {
    repo.findDepartmentsByCollege.mockResolvedValue([{ id: 'd1', name: 'IT', code: 'IT' }] as never);

    const res = await service.getRelatedDepartments(mockCollegeId, null);

    expect(repo.findDepartmentsByCollege).toHaveBeenCalledWith(mockCollegeId);
    expect(res.length).toBe(1);
  });

  it('should return cluster departments for IT student (IT, CSE, AI_DS)', async () => {
    repo.findDepartmentById.mockResolvedValue({ id: mockDeptId, code: 'IT', name: 'Information Tech' } as never);
    repo.findDepartmentsByCodes.mockResolvedValue([
      { id: 'd1', code: 'IT', name: 'Information Tech' },
      { id: 'd2', code: 'CSE', name: 'Computer Science' },
    ] as never);

    const res = await service.getRelatedDepartments(mockCollegeId, mockDeptId);

    expect(repo.findDepartmentsByCodes).toHaveBeenCalledWith(mockCollegeId, ['IT', 'CSE', 'AI_DS', 'CSE_AIDS', 'CS']);
    expect(res.length).toBe(2);
  });
});
