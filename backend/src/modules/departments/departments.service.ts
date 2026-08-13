import { DepartmentsRepository } from './departments.repository';

export class DepartmentsService {
  constructor(private repo: DepartmentsRepository) {}

  private static CLUSTERS: Record<string, string[]> = {
    IT: ['IT', 'CSE', 'AI_DS', 'CSE_AIDS', 'CS'],
    CSE: ['IT', 'CSE', 'AI_DS', 'CSE_AIDS', 'CS'],
    AI_DS: ['IT', 'CSE', 'AI_DS', 'CSE_AIDS', 'CS'],
    ECE: ['ECE', 'EEE'],
    EEE: ['ECE', 'EEE'],
    MECH: ['MECH', 'AUTO', 'MECHANICAL'],
    AUTO: ['MECH', 'AUTO', 'AUTOMOBILE'],
    CIVIL: ['CIVIL'],
  };

  async getRelatedDepartments(collegeId: string, userDepartmentId?: string | null) {
    if (!userDepartmentId) {
      return this.repo.findDepartmentsByCollege(collegeId);
    }

    const dept = await this.repo.findDepartmentById(userDepartmentId);
    if (!dept) {
      return this.repo.findDepartmentsByCollege(collegeId);
    }

    const codeUpper = dept.code.toUpperCase();
    const clusterCodes = DepartmentsService.CLUSTERS[codeUpper] || [codeUpper];

    const related = await this.repo.findDepartmentsByCodes(collegeId, clusterCodes);
    if (related.length === 0) {
      return [dept];
    }
    return related;
  }
}
