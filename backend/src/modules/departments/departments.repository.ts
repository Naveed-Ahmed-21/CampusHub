import { PrismaClient } from '@prisma/client';

export class DepartmentsRepository {
  constructor(private prisma: PrismaClient) {}

  async findDepartmentById(id: string) {
    return this.prisma.department.findUnique({
      where: { id },
    });
  }

  async findDepartmentsByCollege(collegeId: string) {
    return this.prisma.department.findMany({
      where: { college_id: collegeId },
      orderBy: { name: 'asc' },
    });
  }

  async findDepartmentsByCodes(collegeId: string, codes: string[]) {
    return this.prisma.department.findMany({
      where: {
        college_id: collegeId,
        code: { in: codes, mode: 'insensitive' },
      },
      orderBy: { name: 'asc' },
    });
  }
}
