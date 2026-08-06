import { Role, ClubStatus, ApplicationStatus } from '@prisma/client';

export interface QueryAdminUsersDto {
  role?: Role;
  departmentId?: string;
  search?: string;
  page?: number;
  limit?: number;
}

export interface UpdateUserRoleDto {
  userId: string;
  newRole: Role;
}

export interface UpdateUserStatusDto {
  userId: string;
  isActive: boolean;
}

export interface CreateDepartmentDto {
  name: string;
  code: string;
  hodName?: string;
}

export interface SystemAnalyticsDto {
  totalUsers: number;
  activeStudents: number;
  facultyCount: number;
  totalDepartments: number;
  approvedClubs: number;
  pendingClubs: number;
  totalEvents: number;
  totalPlacementDrives: number;
  totalPlacementsCount: number;
  averagePackageLpa: number;
}

export interface SystemReportItem {
  id: string;
  timestamp: Date;
  actorName: string;
  action: string;
  category: string;
  details: string;
  ipAddress?: string;
}
