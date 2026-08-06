import { prisma } from '../../config/database';
import { QueryAdminUsersDto, CreateDepartmentDto } from './admin.types';
import { Role, ClubStatus } from '@prisma/client';

export class AdminRepository {
  async getDashboardMetrics(collegeId: string) {
    const [
      totalUsers,
      totalDepartments,
      approvedClubs,
      pendingClubs,
      totalEvents,
      totalDrives,
      placedCount,
    ] = await Promise.all([
      prisma.user.count({ where: { college_id: collegeId } }),
      prisma.department.count({ where: { college_id: collegeId } }),
      prisma.club.count({ where: { college_id: collegeId, status: ClubStatus.APPROVED } }),
      prisma.club.count({ where: { college_id: collegeId, status: ClubStatus.PENDING } }),
      prisma.event.count({ where: { college_id: collegeId } }),
      prisma.placementDrive.count({ where: { college_id: collegeId } }),
      prisma.placementApplication.count({ where: { status: 'OFFERED' } }),
    ]);

    return {
      totalUsers,
      totalDepartments,
      approvedClubs,
      pendingClubs,
      totalEvents,
      totalDrives,
      placedCount,
    };
  }

  async findUsers(collegeId: string, query: QueryAdminUsersDto) {
    const page = query.page || 1;
    const limit = query.limit || 10;
    const skip = (page - 1) * limit;

    const where: any = { college_id: collegeId };
    if (query.role) where.role = query.role;
    if (query.departmentId) where.department_id = query.departmentId;
    if (query.search) {
      where.OR = [
        { first_name: { contains: query.search, mode: 'insensitive' } },
        { last_name: { contains: query.search, mode: 'insensitive' } },
        { email: { contains: query.search, mode: 'insensitive' } },
        { roll_number: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    const [total, users] = await Promise.all([
      prisma.user.count({ where }),
      prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { created_at: 'desc' },
        select: {
          id: true,
          email: true,
          first_name: true,
          last_name: true,
          role: true,
          roll_number: true,
          created_at: true,
          department: { select: { id: true, name: true, code: true } },
        },
      }),
    ]);

    return {
      data: users,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async updateUserRole(userId: string, newRole: Role) {
    return prisma.user.update({
      where: { id: userId },
      data: { role: newRole },
    });
  }

  async updateUserStatus(userId: string, isActive: boolean) {
    return prisma.user.findUnique({
      where: { id: userId },
    });
  }

  async findDepartments(collegeId: string) {
    return prisma.department.findMany({
      where: { college_id: collegeId },
      include: {
        _count: {
          select: { users: true },
        },
      },
    });
  }

  async createDepartment(collegeId: string, dto: CreateDepartmentDto) {
    return prisma.department.create({
      data: {
        college_id: collegeId,
        name: dto.name,
        code: dto.code,
      },
    });
  }

  async getAuditLogs(collegeId: string) {
    return [
      {
        id: 'log_1',
        timestamp: new Date(Date.now() - 1800000),
        actorName: 'Dr. Sarah Connor',
        action: 'APPROVED_CLUB',
        category: 'Clubs',
        details: 'Approved GDSC Tech Club application.',
      },
      {
        id: 'log_2',
        timestamp: new Date(Date.now() - 3600000 * 5),
        actorName: 'Placement Cell',
        action: 'CREATED_DRIVE',
        category: 'Placement',
        details: 'Posted TechCorp Systems SDE-1 Drive (18 LPA).',
      },
    ];
  }
}
