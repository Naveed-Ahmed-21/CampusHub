import argon2 from 'argon2';
import crypto from 'crypto';
import { AdminRepository } from './admin.repository';
import {
  QueryAdminUsersDto,
  UpdateUserRoleDto,
  UpdateUserStatusDto,
  CreateDepartmentDto,
  UpdateDepartmentDto,
  CreateUserDto,
  UpdateUserDto,
  CreateAcademicYearDto,
  UpdateAcademicYearDto,
  CreateAcademicTermDto,
  UpdateAcademicTermDto,
  CreateAcademicProgramDto,
  UpdateAcademicProgramDto,
  CreateBatchDto,
  UpdateBatchDto,
  CreateSubjectDto,
  UpdateSubjectDto,
  CreateCurriculumSubjectDto,
  CreateAcademicClassDto,
  UpdateAcademicClassDto,
  CreateRoomDto,
  UpdateRoomDto,
  CreateFacultyAssignmentDto,
  CreateScheduleDto,
  UpdateScheduleDto,
  QueryAcademicMonitoringDto,
  SendBroadcastNotificationDto,
  QueryAuditLogsDto,
  UpdateCollegeDto,
} from './admin.types';
import { Role, UserStatus, NotificationType } from '@prisma/client';
import { prisma } from '../../config/database';
import { BadRequestError, ForbiddenError, NotFoundError, ConflictError } from '../../shared/errors/AppError';
import { emailService } from '../../infrastructure/email/email.service';
import { logger } from '../../infrastructure/logger/logger.service';
import { termResolutionService } from '../academics/term-resolution.service';

export interface ActorContext {
  actorUserId?: string;
  actorRole?: Role;
  actorDeptId?: string | null;
}

export class AdminService {
  constructor(private readonly adminRepository: AdminRepository) {}

  async getDashboardMetrics(collegeId: string) {
    return await this.adminRepository.getDashboardMetrics(collegeId);
  }

  async getUsers(collegeId: string, query: QueryAdminUsersDto, actor?: ActorContext) {
    if (actor?.actorRole === Role.DEPT_ADMIN && actor.actorDeptId) {
      query.departmentId = actor.actorDeptId;
    }
    return await this.adminRepository.findUsers(collegeId, query, actor?.actorUserId);
  }

  async getUserById(userId: string, actor?: ActorContext) {
    const user = await this.adminRepository.findUserById(userId);
    if (!user) {
      throw new NotFoundError('User not found');
    }
    if (actor?.actorRole === Role.DEPT_ADMIN && user.department_id && actor.actorDeptId && user.department_id !== actor.actorDeptId) {
      throw new ForbiddenError('Department administrators can only view users in their own department');
    }
    return user;
  }

  async createUser(collegeId: string, data: CreateUserDto, actor?: ActorContext) {
    const existing = await prisma.user.findUnique({
      where: { email: data.email },
    });
    if (existing) {
      throw new BadRequestError('User with this email already exists');
    }

    if (data.role === Role.ADMIN) {
      throw new BadRequestError('Admin accounts cannot be created through the standard user creation flow');
    }

    const allowedRoles = [Role.DEPT_ADMIN, Role.FACULTY, Role.PLACEMENT, Role.STUDENT];
    if (!allowedRoles.includes(data.role)) {
      throw new BadRequestError(`Invalid role for user creation. Allowed roles: ${allowedRoles.join(', ')}`);
    }

    if (data.role === Role.DEPT_ADMIN) {
      if (!data.departmentId) {
        throw new BadRequestError('Department is required for Department Admin accounts');
      }
    }

    if (data.role === Role.FACULTY) {
      if (!data.departmentId) {
        throw new BadRequestError('Department is required for Faculty accounts');
      }
      if (!data.password || data.password.trim().length < 6) {
        throw new BadRequestError('Password is required (minimum 6 characters) for Faculty accounts');
      }
    }

    if (data.role === Role.PLACEMENT) {
      if (!data.password || data.password.trim().length < 6) {
        throw new BadRequestError('Password is required (minimum 6 characters) for Placement accounts');
      }
    }

    if (actor?.actorRole === Role.DEPT_ADMIN) {
      if (data.departmentId && actor.actorDeptId && data.departmentId !== actor.actorDeptId) {
        throw new ForbiddenError('Department administrators can only create users in their own department');
      }
      data.departmentId = actor.actorDeptId || data.departmentId;
    }

    let currentYearNumber: number | undefined = undefined;
    if (data.currentYear !== undefined && data.currentYear !== null) {
      currentYearNumber = Number(data.currentYear);
    } else if (data.year) {
      const yStr = String(data.year).toLowerCase();
      if (yStr.includes('1st') || yStr === '1') currentYearNumber = 1;
      else if (yStr.includes('2nd') || yStr === '2') currentYearNumber = 2;
      else if (yStr.includes('3rd') || yStr === '3') currentYearNumber = 3;
      else if (yStr.includes('4th') || yStr === '4') currentYearNumber = 4;
      else if (yStr.includes('graduated') || yStr === '5') currentYearNumber = 5;
    }

    let admissionYear = data.admissionYear;
    if (!admissionYear && data.batchName) {
      const match = data.batchName.match(/^(\d{4})/);
      if (match) {
        admissionYear = parseInt(match[1], 10);
      }
    }

    if (data.role === Role.STUDENT) {
      if (admissionYear && currentYearNumber === undefined) {
        currentYearNumber = termResolutionService.calculateYearFromBatch(admissionYear).currentYear;
      } else if (!admissionYear) {
        const activeYear = (await prisma.academicYear.findFirst({
          where: { college_id: collegeId, is_active: true },
        })) || (await prisma.academicYear.findFirst({
          where: { college_id: collegeId },
          orderBy: { start_date: 'desc' },
        }));
        const ayMatch = activeYear?.year_name.match(/^(\d{4})/);
        const currentCalendarYear = ayMatch ? parseInt(ayMatch[1], 10) : (activeYear ? new Date(activeYear.start_date).getFullYear() : new Date().getFullYear());
        if (currentYearNumber && currentYearNumber >= 1 && currentYearNumber <= 4) {
          admissionYear = currentCalendarYear - currentYearNumber + 1;
        } else {
          admissionYear = currentCalendarYear;
        }
      }
    }

    const batchName = data.batchName || (admissionYear ? `${admissionYear}-${admissionYear + 4}` : undefined);

    const emailPrefix = data.email.split('@')[0];
    const derivedFirst = data.firstName || (emailPrefix.charAt(0).toUpperCase() + emailPrefix.slice(1));
    const derivedLast = data.lastName || (data.role === Role.STUDENT ? 'Student' : 'User');

    const isExplicitPassword = Boolean(data.password);
    const tempPassword = data.password || crypto.randomBytes(16).toString('hex');
    const hashedPassword = await argon2.hash(tempPassword);
    const isStaffOrPlacement = data.role === Role.FACULTY || data.role === Role.PLACEMENT || data.role === Role.DEPT_ADMIN;

    const user = await this.adminRepository.createUser({
      college_id: collegeId,
      email: data.email,
      password_hash: hashedPassword,
      first_name: derivedFirst,
      last_name: derivedLast,
      role: data.role,
      department_id: data.departmentId,
      roll_number: data.rollNumber,
      registration_number: data.registrationNumber || data.rollNumber,
      phone: data.phone,
      admission_year: admissionYear,
      batch_name: batchName,
      batch_id: data.batchId,
      current_year: currentYearNumber,
      section: data.section,
      program_id: data.programId,
      designation: data.designation,
      office_room: data.officeRoom,
      status: data.status || UserStatus.ACTIVE,
      is_password_configured: isExplicitPassword || isStaffOrPlacement,
      is_profile_completed: isExplicitPassword || isStaffOrPlacement,
      first_login_completed: isExplicitPassword || isStaffOrPlacement,
    });

    if (!user) {
      throw new BadRequestError('Failed to create user');
    }

    if (this.adminRepository.createAuditLog) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'USER_CREATED',
        entity_type: 'USER',
        entity_id: user.id,
        category: 'USER_MANAGEMENT',
        description: `Created user ${user.first_name} ${user.last_name} (${user.email}) with role ${user.role}`,
        metadata: { role: user.role, departmentId: user.department_id },
      });
    }

    try {
      const wholeCollege = await prisma.chatRoom.findFirst({
        where: { college_id: collegeId, type: 'GROUP', name: 'Whole College', club_id: null, department_id: null },
      });
      if (wholeCollege) {
        await prisma.chatParticipant.upsert({
          where: { room_id_user_id: { room_id: wholeCollege.id, user_id: user.id } },
          update: { status: 'ACTIVE' },
          create: {
            room_id: wholeCollege.id,
            user_id: user.id,
            role: user.role === Role.ADMIN ? 'ADMIN' : 'MEMBER',
            status: 'ACTIVE',
          },
        });
      }
    } catch (_) {}

    const appBaseUrl = process.env.APP_URL || 'http://10.83.3.161:5000';
    const activationLink = `${appBaseUrl}/setup-password?email=${encodeURIComponent(user.email)}`;

    // Notify the user through official email asynchronously (do not block createUser response)
    (async () => {
      try {
        const college = await prisma.college.findUnique({
          where: { id: collegeId },
          select: { name: true },
        });
        await emailService.sendAccountCreatedNotification({
          to: user.email,
          name: `${user.first_name} ${user.last_name}`,
          role: user.role,
          activationLink,
          tempPassword: isExplicitPassword ? data.password : undefined,
          collegeName: college?.name,
        });
      } catch (mailErr) {
        logger.warn({ mailErr, email: user.email }, 'Failed to dispatch account creation notification email');
      }
    })().catch((err) => {
      logger.error({ err, email: user.email }, 'Unhandled error in background account notification dispatch');
    });

    return {
      ...user,
      activationLink,
    };
  }

  async updateUser(collegeId: string, targetUserId: string, dto: UpdateUserDto, actor?: ActorContext) {
    const target = await this.adminRepository.findUserById(targetUserId);
    if (!target) {
      throw new NotFoundError('User not found');
    }

    if (dto.role) {
      if (actor?.actorUserId && actor.actorUserId === targetUserId) {
        throw new ForbiddenError('Users cannot modify their own role');
      }
      if (dto.role === Role.ADMIN && actor?.actorRole && actor.actorRole !== Role.ADMIN) {
        throw new ForbiddenError('Only Admins can assign the Admin role');
      }
    }

    if (actor?.actorRole === Role.DEPT_ADMIN) {
      if (target.role === Role.ADMIN) {
        throw new ForbiddenError('Department administrators cannot modify Admin accounts');
      }
      if (target.department_id && actor.actorDeptId && target.department_id !== actor.actorDeptId) {
        throw new ForbiddenError('Department administrators can only modify users in their own department');
      }
      if (dto.role === Role.ADMIN) {
        throw new ForbiddenError('Department administrators cannot assign Admin role');
      }
      if (dto.departmentId && actor.actorDeptId && dto.departmentId !== actor.actorDeptId) {
        throw new ForbiddenError('Department administrators cannot move users to another department');
      }
    }

    if (dto.email && dto.email !== target.email) {
      const existing = await prisma.user.findUnique({ where: { email: dto.email } });
      if (existing && existing.id !== targetUserId) {
        throw new BadRequestError('Email is already taken by another user');
      }
    }

    let currentYearNumber: number | undefined = undefined;
    if (dto.currentYear !== undefined && dto.currentYear !== null) {
      currentYearNumber = Number(dto.currentYear);
    } else if (dto.year) {
      const yStr = String(dto.year).toLowerCase();
      if (yStr.includes('1st') || yStr === '1') currentYearNumber = 1;
      else if (yStr.includes('2nd') || yStr === '2') currentYearNumber = 2;
      else if (yStr.includes('3rd') || yStr === '3') currentYearNumber = 3;
      else if (yStr.includes('4th') || yStr === '4') currentYearNumber = 4;
      else if (yStr.includes('graduated') || yStr === '5') currentYearNumber = 5;
    }

    let admissionYear = dto.admissionYear;
    if (!admissionYear && dto.batchName) {
      const match = dto.batchName.match(/^(\d{4})/);
      if (match) {
        admissionYear = parseInt(match[1], 10);
      }
    }

    if ((target.role === Role.STUDENT || dto.role === Role.STUDENT) && currentYearNumber === undefined && admissionYear) {
      currentYearNumber = termResolutionService.calculateYearFromBatch(admissionYear).currentYear;
    }

    const batchName = dto.batchName || (admissionYear ? `${admissionYear}-${admissionYear + 4}` : undefined);

    const updated = await this.adminRepository.updateUser(targetUserId, {
      first_name: dto.firstName,
      last_name: dto.lastName,
      email: dto.email,
      phone: dto.phone,
      department_id: dto.departmentId,
      roll_number: dto.rollNumber,
      registration_number: dto.registrationNumber || (dto as any).registration_number,
      role: dto.role,
      status: dto.status,
      admission_year: admissionYear,
      batch_name: batchName,
      batch_id: dto.batchId,
      current_year: currentYearNumber,
      section: dto.section,
      designation: dto.designation,
      office_room: dto.officeRoom,
    });

    if (this.adminRepository.createAuditLog && updated) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'USER_UPDATED',
        entity_type: 'USER',
        entity_id: targetUserId,
        category: 'USER_MANAGEMENT',
        description: `Updated profile for ${updated.first_name} ${updated.last_name} (${updated.email})`,
        metadata: dto,
      });
    }

    return updated;
  }

  async updateUserRole(dto: UpdateUserRoleDto, actor?: ActorContext, collegeId?: string) {
    if (actor?.actorUserId && actor.actorUserId === dto.userId) {
      throw new ForbiddenError('Users cannot modify their own role');
    }
    if (dto.newRole === Role.ADMIN && actor?.actorRole && actor.actorRole !== Role.ADMIN) {
      throw new ForbiddenError('Only Admins can grant the Admin role');
    }

    if (actor?.actorRole === Role.DEPT_ADMIN && dto.newRole === Role.ADMIN) {
      throw new ForbiddenError('Department administrators cannot grant Admin role');
    }

    const user = await this.adminRepository.findUserById(dto.userId);
    if (!user) {
      throw new NotFoundError('User not found');
    }

    if (actor?.actorRole === Role.DEPT_ADMIN) {
      if (user.role === Role.ADMIN) {
        throw new ForbiddenError('Department administrators cannot modify Admin accounts');
      }
      if (user.department_id && actor.actorDeptId && user.department_id !== actor.actorDeptId) {
        throw new ForbiddenError('Department administrators can only modify users in their own department');
      }
    }

    const result = await this.adminRepository.updateUserRole(dto.userId, dto.newRole);

    const targetCollegeId = collegeId || user.college_id;
    if (this.adminRepository.createAuditLog && targetCollegeId) {
      await this.adminRepository.createAuditLog({
        college_id: targetCollegeId,
        actor_user_id: actor?.actorUserId,
        action: 'USER_ROLE_CHANGED',
        entity_type: 'USER',
        entity_id: dto.userId,
        category: 'USER_MANAGEMENT',
        description: `Changed role of user ${user.first_name} ${user.last_name} (${user.email}) to ${dto.newRole}`,
        metadata: { oldRole: user.role, newRole: dto.newRole },
      });
    }

    return result;
  }

  async updateUserStatus(dto: UpdateUserStatusDto, actor?: ActorContext, collegeId?: string) {
    if (actor?.actorUserId && actor.actorUserId === dto.userId && (dto.isActive === false || dto.status === UserStatus.DEACTIVATED)) {
      throw new ForbiddenError('Administrators cannot deactivate their own accounts');
    }

    const user = await this.adminRepository.findUserById(dto.userId);
    if (!user) {
      throw new NotFoundError('User not found');
    }

    if (actor?.actorRole === Role.DEPT_ADMIN) {
      if (user.role === Role.ADMIN) {
        throw new ForbiddenError('Department administrators cannot modify Admin accounts');
      }
      if (user.department_id && actor.actorDeptId && user.department_id !== actor.actorDeptId) {
        throw new ForbiddenError('Department administrators can only modify users in their own department');
      }
    }

    const status: UserStatus = dto.status || (dto.isActive ? UserStatus.ACTIVE : UserStatus.DEACTIVATED);
    const result = await this.adminRepository.updateUserStatus(dto.userId, status);

    const targetCollegeId = collegeId || user.college_id;
    if (this.adminRepository.createAuditLog && targetCollegeId) {
      await this.adminRepository.createAuditLog({
        college_id: targetCollegeId,
        actor_user_id: actor?.actorUserId,
        action: 'USER_STATUS_CHANGED',
        entity_type: 'USER',
        entity_id: dto.userId,
        category: 'USER_MANAGEMENT',
        description: `Changed status of user ${user.first_name} ${user.last_name} (${user.email}) to ${status}`,
        metadata: { oldStatus: user.status, newStatus: status },
      });
    }

    return result;
  }

  async deleteUser(collegeId: string, userId: string, actor?: ActorContext) {
    if (actor?.actorUserId && actor.actorUserId === userId) {
      throw new BadRequestError('You cannot delete your own user account');
    }

    const user = await this.adminRepository.findUserById(userId);
    if (!user) {
      throw new NotFoundError('User not found');
    }
    if (user.college_id !== collegeId) {
      throw new ForbiddenError('User does not belong to this college');
    }

    if (actor?.actorRole === Role.DEPT_ADMIN) {
      if (user.role === Role.ADMIN) {
        throw new ForbiddenError('Department administrators cannot delete Admin accounts');
      }
      if (user.department_id && actor.actorDeptId && user.department_id !== actor.actorDeptId) {
        throw new ForbiddenError('Department administrators can only delete users in their own department');
      }
    }

    const deleted = await this.adminRepository.softDeleteUser(userId);

    if (this.adminRepository.createAuditLog) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'USER_DELETED',
        entity_type: 'USER',
        entity_id: userId,
        category: 'USER_LIFECYCLE',
        description: `Moved user ${user.email} (${user.role}) to recycle bin`,
        metadata: {
          email: user.email,
          role: user.role,
          name: `${user.first_name || ''} ${user.last_name || ''}`.trim(),
        },
      });
    }

    return deleted;
  }

  async getDeletedUsers(collegeId: string, query: QueryAdminUsersDto, actor?: ActorContext) {
    if (actor?.actorRole === Role.DEPT_ADMIN && actor.actorDeptId) {
      query.departmentId = actor.actorDeptId;
    }
    return await this.adminRepository.findDeletedUsers(collegeId, query);
  }

  async restoreUser(collegeId: string, userId: string, actor?: ActorContext) {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user || user.college_id !== collegeId) {
      throw new NotFoundError('User not found in recycle bin');
    }
    if (!user.deleted_at) {
      throw new BadRequestError('User is not in the recycle bin');
    }

    if (actor?.actorRole === Role.DEPT_ADMIN) {
      if (user.role === Role.ADMIN) {
        throw new ForbiddenError('Department administrators cannot restore Admin accounts');
      }
      if (user.department_id && actor.actorDeptId && user.department_id !== actor.actorDeptId) {
        throw new ForbiddenError('Department administrators can only restore users in their own department');
      }
    }

    const restored = await this.adminRepository.restoreUser(userId);

    if (this.adminRepository.createAuditLog) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'USER_RESTORED',
        entity_type: 'USER',
        entity_id: userId,
        category: 'USER_LIFECYCLE',
        description: `Restored user ${user.email} (${user.role}) from recycle bin`,
      });
    }

    return restored;
  }

  async permanentlyDeleteUser(collegeId: string, userId: string, actor?: ActorContext) {
    if (actor?.actorRole && actor.actorRole !== Role.ADMIN) {
      throw new ForbiddenError('Only Institution Administrators can permanently delete users');
    }

    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user || user.college_id !== collegeId) {
      throw new NotFoundError('User not found');
    }

    const result = await this.adminRepository.permanentlyDeleteUser(userId);

    if (this.adminRepository.createAuditLog) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'USER_PERMANENTLY_DELETED',
        entity_type: 'USER',
        entity_id: userId,
        category: 'USER_LIFECYCLE',
        description: `Permanently deleted user ${user.email} (${user.role})`,
      });
    }

    return result;
  }

  async purgeExpiredDeletedUsers(collegeId: string, actor?: ActorContext) {
    if (actor?.actorRole && actor.actorRole !== Role.ADMIN) {
      throw new ForbiddenError('Only Institution Administrators can purge the recycle bin');
    }
    const purgedCount = await this.adminRepository.purgeExpiredDeletedUsers(collegeId, 30);
    return { count: purgedCount };
  }

  async setTemporaryPassword(
    actor: ActorContext | undefined,
    collegeId: string,
    targetUserId: string,
    explicitPassword?: string,
  ): Promise<{ message: string; tempPassword?: string }> {
    const user = await this.adminRepository.findUserById(targetUserId);
    if (!user || user.college_id !== collegeId) {
      throw new NotFoundError('User not found in this institution');
    }

    if (user.role === Role.STUDENT) {
      throw new ForbiddenError('Temporary passwords cannot be set for students. Students must verify via OTP.');
    }

    if (user.role === Role.ADMIN && actor?.actorRole !== Role.ADMIN) {
      throw new ForbiddenError('Only institutional administrators can manage Admin passwords');
    }

    if (actor?.actorRole === Role.DEPT_ADMIN) {
      if (user.department_id && actor.actorDeptId && user.department_id !== actor.actorDeptId) {
        throw new ForbiddenError('Department administrators can only manage users in their own department');
      }
    }

    const tempPassword = explicitPassword && explicitPassword.trim().length >= 8
      ? explicitPassword.trim()
      : `Temp@${crypto.randomInt(100000, 999999)}`;

    const hashedPassword = await argon2.hash(tempPassword);

    await this.adminRepository.updateUser(targetUserId, {
      password_hash: hashedPassword,
      is_password_configured: false,
      status: UserStatus.PASSWORD_SETUP_REQUIRED,
    });

    if (this.adminRepository.createAuditLog) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'SET_TEMPORARY_PASSWORD',
        entity_type: 'USER',
        entity_id: user.id,
        category: 'USER_MANAGEMENT',
        description: `Set temporary password for ${user.first_name} ${user.last_name} (${user.email}) [${user.role}]`,
        metadata: { role: user.role, email: user.email },
      });
    }

    return {
      message: `Temporary password set successfully for ${user.email}. User will be required to change their password on first login.`,
      tempPassword,
    };
  }

  async getDepartments(collegeId: string) {
    return await this.adminRepository.findDepartments(collegeId);
  }

  async getDepartmentById(deptId: string) {
    const dept = await this.adminRepository.findDepartmentById(deptId);
    if (!dept) {
      throw new NotFoundError('Department not found');
    }
    return dept;
  }

  async getDepartmentOverview(collegeId: string, departmentId: string, actor?: ActorContext) {
    if (actor?.actorRole === Role.DEPT_ADMIN && actor.actorDeptId && actor.actorDeptId !== departmentId) {
      throw new ForbiddenError('Department administrators can only view their own department');
    }
    const overview = await this.adminRepository.findDepartmentOverview(collegeId, departmentId);
    if (!overview) {
      throw new NotFoundError('Department not found');
    }
    return overview;
  }

  async getDepartmentStudents(
    collegeId: string,
    departmentId: string,
    query: { year?: string | number; page?: number; limit?: number; search?: string },
    actor?: ActorContext
  ) {
    if (actor?.actorRole === Role.DEPT_ADMIN && actor.actorDeptId && actor.actorDeptId !== departmentId) {
      throw new ForbiddenError('Department administrators can only view students in their own department');
    }
    return await this.adminRepository.findDepartmentStudents(collegeId, departmentId, query);
  }

  async getDepartmentFaculty(
    collegeId: string,
    departmentId: string,
    query: { page?: number; limit?: number; search?: string },
    actor?: ActorContext
  ) {
    if (actor?.actorRole === Role.DEPT_ADMIN && actor.actorDeptId && actor.actorDeptId !== departmentId) {
      throw new ForbiddenError('Department administrators can only view faculty in their own department');
    }
    return await this.adminRepository.findDepartmentFaculty(collegeId, departmentId, query);
  }

  async createDepartment(collegeId: string, dto: CreateDepartmentDto, actor?: ActorContext) {
    const existing = await this.adminRepository.findDepartmentByCode(collegeId, dto.code);
    if (existing) {
      throw new BadRequestError(`Department with code ${dto.code.toUpperCase()} already exists in this college`);
    }

    const dept = await this.adminRepository.createDepartment(collegeId, dto);

    if (this.adminRepository.createAuditLog && dept) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'DEPARTMENT_CREATED',
        entity_type: 'DEPARTMENT',
        entity_id: dept.id,
        category: 'ACADEMIC_SETUP',
        description: `Created department ${dept.name} (${dept.code})`,
        metadata: { code: dept.code, name: dept.name },
      });
    }

    return dept;
  }

  async updateDepartment(collegeId: string, deptId: string, dto: UpdateDepartmentDto, actor?: ActorContext) {
    const dept = await this.adminRepository.findDepartmentById(deptId);
    if (!dept) {
      throw new NotFoundError('Department not found');
    }
    if (dept.college_id !== collegeId) {
      throw new ForbiddenError('Department does not belong to this college');
    }
    if (actor?.actorRole === Role.DEPT_ADMIN && actor.actorDeptId && actor.actorDeptId !== deptId) {
      throw new ForbiddenError('Department administrators can only manage their own department');
    }
    if (dto.code && dto.code.toUpperCase() !== dept.code) {
      const existing = await this.adminRepository.findDepartmentByCode(collegeId, dto.code);
      if (existing && existing.id !== deptId) {
        throw new BadRequestError(`Department with code ${dto.code.toUpperCase()} already exists in this college`);
      }
    }

    const updated = await this.adminRepository.updateDepartment(deptId, dto);

    if (this.adminRepository.createAuditLog && updated) {
      const activeChanged = (dto.isActive !== undefined && dto.isActive !== (dept as any).is_active) ||
                            (dto.is_active !== undefined && dto.is_active !== (dept as any).is_active);
      const isNowActive = dto.isActive !== undefined ? dto.isActive : dto.is_active;
      const action = activeChanged
        ? (isNowActive ? 'DEPARTMENT_ACTIVATED' : 'DEPARTMENT_DEACTIVATED')
        : 'DEPARTMENT_UPDATED';

      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action,
        entity_type: 'DEPARTMENT',
        entity_id: deptId,
        category: 'ACADEMIC_SETUP',
        description: `${action === 'DEPARTMENT_ACTIVATED' ? 'Activated' : action === 'DEPARTMENT_DEACTIVATED' ? 'Deactivated' : 'Updated'} department ${updated.name} (${updated.code})`,
        metadata: dto,
      });
    }

    return updated;
  }

  async deleteDepartment(collegeId: string, departmentId: string, actor?: ActorContext) {
    const dept = await this.adminRepository.findDepartmentById(departmentId);
    if (!dept) {
      throw new NotFoundError('Department not found');
    }
    if (dept.college_id !== collegeId) {
      throw new ForbiddenError('Department does not belong to this college');
    }
    const deleted = await this.adminRepository.deleteDepartment(departmentId);

    if (this.adminRepository.createAuditLog) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'DEPARTMENT_DELETED',
        entity_type: 'DEPARTMENT',
        entity_id: departmentId,
        category: 'ACADEMIC_SETUP',
        description: `Permanently deleted department ${dept.name} (${dept.code})`,
        metadata: { name: dept.name, code: dept.code },
      });
    }

    return deleted;
  }

  async getAnalytics(collegeId: string) {
    const metrics = await this.getDashboardMetrics(collegeId);

    const [totalEligible, placedStudents, drives] = await Promise.all([
      prisma.user.count({ where: { college_id: collegeId, role: Role.STUDENT } }),
      prisma.placementApplication.count({
        where: {
          status: 'OFFERED',
          drive: { college_id: collegeId },
        },
      }),
      prisma.placementDrive.findMany({
        where: { college_id: collegeId },
        select: { package_ctc: true, company_name: true },
      }),
    ]);

    const placementRate = totalEligible > 0 ? Number(((placedStudents / totalEligible) * 100).toFixed(1)) : 0;
    const packages = drives
      .map((d) => parseFloat((d.package_ctc || '').replace(/[^0-9.]/g, '') || '0'))
      .filter((p) => p > 0);
    const highestPackage = packages.length > 0 ? Math.max(...packages) : 0;
    const averagePackage = packages.length > 0 ? Number((packages.reduce((a, b) => a + b, 0) / packages.length).toFixed(1)) : 0;
    const topRecruiters = Array.from(new Set(drives.map((d) => d.company_name))).slice(0, 5);

    const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

    const [activeDailyUsers, monthlyPosts, eventRegistrations] = await Promise.all([
      prisma.user.count({
        where: {
          college_id: collegeId,
          last_seen: { gte: oneDayAgo },
        },
      }),
      prisma.post.count({
        where: {
          college_id: collegeId,
          created_at: { gte: thirtyDaysAgo },
        },
      }),
      prisma.eventRegistration.count({
        where: {
          event: { college_id: collegeId },
        },
      }),
    ]);

    const eventAttendanceRate = metrics.totalEvents > 0 && totalEligible > 0
      ? Number(((eventRegistrations / (metrics.totalEvents * totalEligible)) * 100).toFixed(1))
      : 0;

    return {
      overview: metrics,
      placementStats: {
        totalEligible,
        placedStudents,
        placementRate,
        highestPackage,
        averagePackage,
        topRecruiters,
      },
      engagementStats: {
        activeDailyUsers,
        monthlyPosts,
        eventAttendanceRate,
        clubParticipationRate: 0,
      },
    };
  }

  async getAuditReports(collegeId: string, query?: QueryAuditLogsDto) {
    return await this.adminRepository.getAuditLogs(collegeId, query);
  }

  async getAuditReportsCsv(collegeId: string, query?: QueryAuditLogsDto): Promise<string> {
    const logs = await this.adminRepository.getAuditLogs(collegeId, query);
    const headers = ['ID', 'Timestamp', 'Actor Name', 'Actor Email', 'Actor Role', 'Action', 'Category', 'Entity Type', 'Entity ID', 'Details'];
    const escapeCsv = (str: string | undefined | null) => {
      if (str === undefined || str === null) return '""';
      const escaped = String(str).replace(/"/g, '""');
      return `"${escaped}"`;
    };

    const rows = logs.map((log: any) => [
      escapeCsv(log.id),
      escapeCsv(log.timestamp ? new Date(log.timestamp).toISOString() : ''),
      escapeCsv(log.actorName),
      escapeCsv(log.actorEmail),
      escapeCsv(log.actorRole),
      escapeCsv(log.action),
      escapeCsv(log.category),
      escapeCsv(log.entityType),
      escapeCsv(log.entityId),
      escapeCsv(log.details),
    ].join(','));

    return [headers.join(','), ...rows].join('\n');
  }

  async getCollegeSettings(collegeId: string) {
    const college = await this.adminRepository.findCollegeById(collegeId);
    if (!college) throw new NotFoundError('College profile not found');
    return college;
  }

  async updateCollegeSettings(collegeId: string, dto: UpdateCollegeDto, actor?: ActorContext) {
    const college = await this.adminRepository.findCollegeById(collegeId);
    if (!college) throw new NotFoundError('College profile not found');

    const updated = await this.adminRepository.updateCollege(collegeId, dto);

    if (this.adminRepository.createAuditLog) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'COLLEGE_SETTINGS_UPDATED',
        entity_type: 'College',
        entity_id: collegeId,
        category: 'INSTITUTIONAL_SETTINGS',
        description: `Updated institutional configuration for ${updated.name}`,
        metadata: dto,
      });
    }

    return updated;
  }

  // ==========================================
  // ACADEMIC YEARS
  // ==========================================
  async getAcademicYears(collegeId: string) {
    return await this.adminRepository.findAcademicYears(collegeId);
  }

  async getAcademicYearById(id: string) {
    const year = await this.adminRepository.findAcademicYearById(id);
    if (!year) throw new NotFoundError('Academic year not found');
    return year;
  }

  async createAcademicYear(collegeId: string, dto: CreateAcademicYearDto, actor?: ActorContext) {
    if (new Date(dto.startDate) >= new Date(dto.endDate)) {
      throw new BadRequestError('Academic year start date must be before end date');
    }

    const existing = await this.adminRepository.findAcademicYearByName(collegeId, dto.yearName);
    if (existing) {
      throw new BadRequestError(`Academic year '${dto.yearName}' already exists in this college`);
    }

    const year = await this.adminRepository.createAcademicYear(collegeId, dto);

    if (this.adminRepository.createAuditLog && year) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'ACADEMIC_YEAR_CREATED',
        entity_type: 'ACADEMIC_YEAR',
        entity_id: year.id,
        category: 'ACADEMIC_SETUP',
        description: `Created academic year ${year.year_name}`,
        metadata: { yearName: year.year_name, startDate: year.start_date, endDate: year.end_date },
      });
    }

    return year;
  }

  async updateAcademicYear(collegeId: string, id: string, dto: UpdateAcademicYearDto, actor?: ActorContext) {
    const existing = await this.adminRepository.findAcademicYearById(id);
    if (!existing) throw new NotFoundError('Academic year not found');
    if (existing.college_id !== collegeId) throw new ForbiddenError('Academic year does not belong to your college');

    if (dto.startDate && dto.endDate && new Date(dto.startDate) >= new Date(dto.endDate)) {
      throw new BadRequestError('Academic year start date must be before end date');
    }

    if (dto.yearName && dto.yearName.toLowerCase() !== existing.year_name.toLowerCase()) {
      const duplicate = await this.adminRepository.findAcademicYearByName(collegeId, dto.yearName);
      if (duplicate && duplicate.id !== id) {
        throw new BadRequestError(`Academic year '${dto.yearName}' already exists in this college`);
      }
    }

    const updated = await this.adminRepository.updateAcademicYear(id, dto);

    if (this.adminRepository.createAuditLog && updated) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'ACADEMIC_YEAR_UPDATED',
        entity_type: 'ACADEMIC_YEAR',
        entity_id: id,
        category: 'ACADEMIC_SETUP',
        description: `Updated academic year ${updated.year_name}`,
        metadata: dto,
      });
    }

    return updated;
  }

  async setActiveAcademicYear(collegeId: string, id: string, actor?: ActorContext) {
    const year = await this.adminRepository.findAcademicYearById(id);
    if (!year) throw new NotFoundError('Academic year not found');
    if (year.college_id !== collegeId) throw new ForbiddenError('Academic year does not belong to your college');

    const updated = await this.adminRepository.setActiveAcademicYear(collegeId, id);

    // Automatically trigger idempotent student progression transition
    let transitionResult: any = null;
    try {
      transitionResult = await termResolutionService.processYearTransition(collegeId, id, actor?.actorUserId);
    } catch (transErr) {
      logger.warn({ transErr, yearId: id }, 'Automatic progression on active academic year set failed or was skipped');
    }

    if (this.adminRepository.createAuditLog && updated) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'ACADEMIC_YEAR_ACTIVATED',
        entity_type: 'ACADEMIC_YEAR',
        entity_id: id,
        category: 'ACADEMIC_SETUP',
        description: `Set active academic year to ${updated.year_name}. ${transitionResult ? transitionResult.message : ''}`,
        metadata: { activeYearId: id, yearName: updated.year_name, transitionResult },
      });
    }

    return {
      ...updated,
      transition: transitionResult,
    };
  }

  async processAcademicTransition(collegeId: string, academicYearId: string, actor?: ActorContext) {
    if (actor?.actorRole !== Role.ADMIN) {
      throw new ForbiddenError('Only institutional administrators can run academic year transitions');
    }
    return await termResolutionService.processYearTransition(collegeId, academicYearId, actor?.actorUserId);
  }

  // ==========================================
  // ACADEMIC TERMS
  // ==========================================
  async getAcademicTerms(academicYearId?: string, collegeId?: string) {
    return await this.adminRepository.findAcademicTerms(academicYearId, collegeId);
  }

  async getAcademicTermById(id: string) {
    const term = await this.adminRepository.findAcademicTermById(id);
    if (!term) throw new NotFoundError('Academic term not found');
    return term;
  }

  async createAcademicTerm(collegeId: string, dto: CreateAcademicTermDto, actor?: ActorContext) {
    const year = await this.adminRepository.findAcademicYearById(dto.academicYearId);
    if (!year) throw new NotFoundError('Academic year not found');
    if (year.college_id !== collegeId) throw new ForbiddenError('Academic year does not belong to your college');

    if (new Date(dto.startDate) >= new Date(dto.endDate)) {
      throw new BadRequestError('Term start date must be before end date');
    }

    const duplicateSem = year.terms.find((t) => t.semester_number === dto.semesterNumber);
    if (duplicateSem) {
      throw new BadRequestError(`Semester ${dto.semesterNumber} already exists in academic year ${year.year_name}`);
    }

    const term = await this.adminRepository.createAcademicTerm(dto);

    if (this.adminRepository.createAuditLog && term) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'ACADEMIC_TERM_CREATED',
        entity_type: 'ACADEMIC_TERM',
        entity_id: term.id,
        category: 'ACADEMIC_SETUP',
        description: `Created academic term ${term.name} (Semester ${term.semester_number})`,
        metadata: dto,
      });
    }

    return term;
  }

  async updateAcademicTerm(collegeId: string, id: string, dto: UpdateAcademicTermDto, actor?: ActorContext) {
    const existing = await this.adminRepository.findAcademicTermById(id);
    if (!existing) throw new NotFoundError('Academic term not found');
    if (existing.academic_year.college_id !== collegeId) {
      throw new ForbiddenError('Academic term does not belong to your college');
    }

    const updated = await this.adminRepository.updateAcademicTerm(id, dto);

    if (this.adminRepository.createAuditLog && updated) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'ACADEMIC_TERM_UPDATED',
        entity_type: 'ACADEMIC_TERM',
        entity_id: id,
        category: 'ACADEMIC_SETUP',
        description: `Updated academic term ${updated.name}`,
        metadata: dto,
      });
    }

    return updated;
  }

  // ==========================================
  // ACADEMIC PROGRAMS
  // ==========================================
  async getAcademicPrograms(collegeId: string, departmentId?: string, actor?: ActorContext) {
    let effectiveDeptId = departmentId;
    return await this.adminRepository.findAcademicPrograms(collegeId, effectiveDeptId);
  }

  async getAcademicProgramById(id: string, actor?: ActorContext) {
    const program = await this.adminRepository.findAcademicProgramById(id);
    if (!program) throw new NotFoundError('Academic program not found');
    return program;
  }

  async createAcademicProgram(collegeId: string, dto: CreateAcademicProgramDto, actor?: ActorContext) {

    const existingCode = await this.adminRepository.findAcademicProgramByCode(collegeId, dto.code);
    if (existingCode) {
      throw new BadRequestError(`Academic program with code '${dto.code.toUpperCase()}' already exists in this college`);
    }

    const program = await this.adminRepository.createAcademicProgram(collegeId, dto);

    if (this.adminRepository.createAuditLog && program) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'ACADEMIC_PROGRAM_CREATED',
        entity_type: 'ACADEMIC_PROGRAM',
        entity_id: program.id,
        category: 'ACADEMIC_SETUP',
        description: `Created program ${program.name} (${program.code})`,
        metadata: { code: program.code, name: program.name, departmentId: program.department_id },
      });
    }

    return program;
  }

  async updateAcademicProgram(collegeId: string, id: string, dto: UpdateAcademicProgramDto, actor?: ActorContext) {
    const existing = await this.adminRepository.findAcademicProgramById(id);
    if (!existing) throw new NotFoundError('Academic program not found');
    if (existing.college_id !== collegeId) throw new ForbiddenError('Program does not belong to your college');


    if (dto.code && dto.code.toUpperCase() !== existing.code) {
      const duplicateCode = await this.adminRepository.findAcademicProgramByCode(collegeId, dto.code);
      if (duplicateCode && duplicateCode.id !== id) {
        throw new BadRequestError(`Academic program with code '${dto.code.toUpperCase()}' already exists`);
      }
    }

    const updated = await this.adminRepository.updateAcademicProgram(id, dto);

    if (this.adminRepository.createAuditLog && updated) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'ACADEMIC_PROGRAM_UPDATED',
        entity_type: 'ACADEMIC_PROGRAM',
        entity_id: id,
        category: 'ACADEMIC_SETUP',
        description: `Updated program ${updated.name} (${updated.code})`,
        metadata: dto,
      });
    }

    return updated;
  }

  // ==========================================
  // BATCHES
  // ==========================================
  async getBatches(collegeId: string, programId?: string, departmentId?: string, actor?: ActorContext) {
    let effectiveDeptId = departmentId;
    return await this.adminRepository.findBatches(collegeId, programId, effectiveDeptId);
  }

  async getBatchById(id: string, actor?: ActorContext) {
    const batch = await this.adminRepository.findBatchById(id);
    if (!batch) throw new NotFoundError('Batch not found');
    return batch;
  }

  async createBatch(collegeId: string, dto: CreateBatchDto, actor?: ActorContext) {

    if (dto.admissionYear > dto.graduationYear) {
      throw new BadRequestError('Admission year must be less than or equal to graduation year');
    }

    const existing = await this.adminRepository.findBatchByName(collegeId, dto.programId, dto.name);
    if (existing) {
      throw new BadRequestError(`Batch '${dto.name}' already exists for this program`);
    }

    const batch = await this.adminRepository.createBatch(collegeId, dto);

    if (this.adminRepository.createAuditLog && batch) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'BATCH_CREATED',
        entity_type: 'BATCH',
        entity_id: batch.id,
        category: 'ACADEMIC_SETUP',
        description: `Created batch ${batch.name} (${batch.admission_year}-${batch.graduation_year})`,
        metadata: dto,
      });
    }

    return batch;
  }

  async updateBatch(collegeId: string, id: string, dto: UpdateBatchDto, actor?: ActorContext) {
    const existing = await this.adminRepository.findBatchById(id);
    if (!existing) throw new NotFoundError('Batch not found');
    if (existing.college_id !== collegeId) throw new ForbiddenError('Batch does not belong to your college');


    const updated = await this.adminRepository.updateBatch(id, dto);

    if (this.adminRepository.createAuditLog && updated) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'BATCH_UPDATED',
        entity_type: 'BATCH',
        entity_id: id,
        category: 'ACADEMIC_SETUP',
        description: `Updated batch ${updated.name}`,
        metadata: dto,
      });
    }

    return updated;
  }

  // ==========================================
  // SUBJECTS & COURSES
  // ==========================================
  async getSubjects(collegeId: string, departmentId?: string, semester?: string, academicTermId?: string, actor?: ActorContext) {
    let effectiveDeptId = departmentId;
    return await this.adminRepository.findSubjects(collegeId, effectiveDeptId, semester, academicTermId);
  }

  async getSubjectById(id: string, actor?: ActorContext) {
    const subject = await this.adminRepository.findSubjectById(id);
    if (!subject) throw new NotFoundError('Subject not found');
    return subject;
  }

  async createSubject(collegeId: string, dto: CreateSubjectDto, actor?: ActorContext) {

    const faculty = await this.adminRepository.findUserById(dto.facultyId);
    if (!faculty || faculty.college_id !== collegeId) {
      throw new BadRequestError('Assigned faculty instructor not found or not in this college');
    }

    const existing = await this.adminRepository.findSubjectByCodeAndSection(
      collegeId,
      dto.code,
      dto.semester,
      dto.section || 'A'
    );
    if (existing) {
      throw new BadRequestError(`Subject '${dto.code.toUpperCase()}' for semester ${dto.semester} section ${dto.section || 'A'} already exists`);
    }

    const subject = await this.adminRepository.createSubject(collegeId, dto);

    if (this.adminRepository.createAuditLog && subject) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'SUBJECT_CREATED',
        entity_type: 'SUBJECT',
        entity_id: subject.id,
        category: 'ACADEMIC_SETUP',
        description: `Created subject ${subject.code} - ${subject.name}`,
        metadata: dto,
      });
    }

    return subject;
  }

  async updateSubject(collegeId: string, id: string, dto: UpdateSubjectDto, actor?: ActorContext) {
    const existing = await this.adminRepository.findSubjectById(id);
    if (!existing) throw new NotFoundError('Subject not found');
    if (existing.college_id !== collegeId) throw new ForbiddenError('Subject does not belong to your college');


    if (dto.facultyId) {
      const faculty = await this.adminRepository.findUserById(dto.facultyId);
      if (!faculty || faculty.college_id !== collegeId) {
        throw new BadRequestError('Assigned faculty instructor not found or not in this college');
      }
    }

    const updated = await this.adminRepository.updateSubject(id, dto);

    if (this.adminRepository.createAuditLog && updated) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'SUBJECT_UPDATED',
        entity_type: 'SUBJECT',
        entity_id: id,
        category: 'ACADEMIC_SETUP',
        description: `Updated subject ${updated.code} - ${updated.name}`,
        metadata: dto,
      });
    }

    return updated;
  }

  // ==========================================
  // CURRICULUM SUBJECTS
  // ==========================================
  async getCurriculumSubjects(programId?: string, batchYear?: number, semesterNumber?: number) {
    return await this.adminRepository.findCurriculumSubjects(programId, batchYear, semesterNumber);
  }

  async createCurriculumSubject(collegeId: string, dto: CreateCurriculumSubjectDto, actor?: ActorContext) {
    const program = await this.adminRepository.findAcademicProgramById(dto.programId);
    if (!program) throw new NotFoundError('Academic program not found');
    if (program.college_id !== collegeId) throw new ForbiddenError('Program does not belong to your college');

    const subject = await this.adminRepository.findSubjectById(dto.subjectId);
    if (!subject) throw new NotFoundError('Subject not found');

    const item = await this.adminRepository.createCurriculumSubject(dto);

    if (this.adminRepository.createAuditLog && item) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'CURRICULUM_SUBJECT_ADDED',
        entity_type: 'CURRICULUM_SUBJECT',
        entity_id: item.id,
        category: 'ACADEMIC_SETUP',
        description: `Added ${subject.code} to curriculum for ${program.code} (Sem ${dto.semesterNumber}, Batch ${dto.batchYear})`,
        metadata: dto,
      });
    }

    return item;
  }

  async deleteCurriculumSubject(collegeId: string, id: string, actor?: ActorContext) {
    const deleted = await this.adminRepository.deleteCurriculumSubject(id);

    if (this.adminRepository.createAuditLog && deleted) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'CURRICULUM_SUBJECT_REMOVED',
        entity_type: 'CURRICULUM_SUBJECT',
        entity_id: id,
        category: 'ACADEMIC_SETUP',
        description: `Removed subject from curriculum mapping`,
        metadata: { id },
      });
    }

    return deleted;
  }

  // ==========================================
  // ACADEMIC CLASSES
  // ==========================================
  async getAcademicClasses(collegeId: string, departmentId?: string, yearOfStudy?: number, semester?: number, actor?: ActorContext) {
    let effectiveDeptId = departmentId;
    return await this.adminRepository.findAcademicClasses(collegeId, effectiveDeptId, yearOfStudy, semester);
  }

  async getAcademicClassById(id: string, actor?: ActorContext) {
    const cls = await this.adminRepository.findAcademicClassById(id);
    if (!cls) throw new NotFoundError('Academic class not found');
    return cls;
  }

  async createAcademicClass(collegeId: string, dto: CreateAcademicClassDto, actor?: ActorContext) {

    const cls = await this.adminRepository.createAcademicClass(collegeId, dto);

    if (this.adminRepository.createAuditLog && cls) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'CLASS_CREATED',
        entity_type: 'ACADEMIC_CLASS',
        entity_id: cls.id,
        category: 'ACADEMIC_SETUP',
        description: `Created class section ${cls.name} (Year ${cls.year_of_study}, Sem ${cls.semester}, Sec ${cls.section})`,
        metadata: dto,
      });
    }

    return cls;
  }

  async updateAcademicClass(collegeId: string, id: string, dto: UpdateAcademicClassDto, actor?: ActorContext) {
    const existing = await this.adminRepository.findAcademicClassById(id);
    if (!existing) throw new NotFoundError('Academic class not found');
    if (existing.college_id !== collegeId) throw new ForbiddenError('Class does not belong to your college');


    const updated = await this.adminRepository.updateAcademicClass(id, dto);

    if (this.adminRepository.createAuditLog && updated) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'CLASS_UPDATED',
        entity_type: 'ACADEMIC_CLASS',
        entity_id: id,
        category: 'ACADEMIC_SETUP',
        description: `Updated class section ${updated.name}`,
        metadata: dto,
      });
    }

    return updated;
  }

  // ==========================================
  // ROOMS
  // ==========================================
  async getRooms(collegeId: string, filters?: { roomType?: string; isActive?: boolean }) {
    return this.adminRepository.findRooms(collegeId, filters);
  }

  async getRoomById(collegeId: string, id: string) {
    const room = await this.adminRepository.findRoomById(id);
    if (!room) throw new NotFoundError('Room not found');
    if (room.college_id !== collegeId) throw new ForbiddenError('Room does not belong to your college');
    return room;
  }

  async createRoom(collegeId: string, dto: CreateRoomDto, actor?: ActorContext) {
    const existing = await this.adminRepository.findRoomByCode(collegeId, dto.code);
    if (existing) throw new ConflictError(`Room with code '${dto.code}' already exists`);

    const room = await this.adminRepository.createRoom(collegeId, dto);

    if (this.adminRepository.createAuditLog && room) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'ROOM_CREATED',
        entity_type: 'ROOM',
        entity_id: room.id,
        category: 'FACILITIES',
        description: `Created room ${room.code} (${room.name})`,
        metadata: dto,
      });
    }

    return room;
  }

  async updateRoom(collegeId: string, id: string, dto: UpdateRoomDto, actor?: ActorContext) {
    const existing = await this.adminRepository.findRoomById(id);
    if (!existing) throw new NotFoundError('Room not found');
    if (existing.college_id !== collegeId) throw new ForbiddenError('Room does not belong to your college');

    if (dto.code && dto.code !== existing.code) {
      const codeTaken = await this.adminRepository.findRoomByCode(collegeId, dto.code);
      if (codeTaken) throw new ConflictError(`Room code '${dto.code}' is already in use`);
    }

    const updated = await this.adminRepository.updateRoom(id, dto);

    if (this.adminRepository.createAuditLog && updated) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'ROOM_UPDATED',
        entity_type: 'ROOM',
        entity_id: id,
        category: 'FACILITIES',
        description: `Updated room ${updated.code} (${updated.name})`,
        metadata: dto,
      });
    }

    return updated;
  }

  // ==========================================
  // FACULTY SUBJECT ASSIGNMENTS
  // ==========================================
  async getFacultyAssignments(collegeId: string, params: { facultyId?: string; subjectId?: string; academicTermId?: string }) {
    return this.adminRepository.findFacultyAssignments({ collegeId, ...params });
  }

  async createFacultyAssignment(collegeId: string, dto: CreateFacultyAssignmentDto, actor?: ActorContext) {
    const faculty = await this.adminRepository.findUserById(dto.facultyId);
    if (!faculty || faculty.college_id !== collegeId) {
      throw new NotFoundError('Faculty member not found in your college');
    }

    const subject = await this.adminRepository.findSubjectById(dto.subjectId);
    if (!subject || subject.college_id !== collegeId) {
      throw new NotFoundError('Subject not found in your college');
    }


    const term = await this.adminRepository.findAcademicTermById(dto.academicTermId);
    if (!term || term.academic_year?.college_id !== collegeId) {
      throw new NotFoundError('Academic term not found');
    }

    const existing = await this.adminRepository.findFacultyAssignmentUnique(
      dto.facultyId,
      dto.subjectId,
      dto.academicTermId,
      dto.section || 'A'
    );
    if (existing) {
      throw new ConflictError(`Faculty is already assigned to this subject section in this term`);
    }

    const assignment = await this.adminRepository.createFacultyAssignment(dto);

    if (this.adminRepository.createAuditLog && assignment) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'FACULTY_ASSIGNED',
        entity_type: 'FACULTY_SUBJECT_ASSIGNMENT',
        entity_id: assignment.id,
        category: 'ACADEMIC_SETUP',
        description: `Assigned faculty ${faculty.first_name} ${faculty.last_name} to ${subject.code} (${dto.section || 'A'})`,
        metadata: dto,
      });
    }

    return assignment;
  }

  async deleteFacultyAssignment(collegeId: string, id: string, actor?: ActorContext) {
    const assignment = await this.adminRepository.findFacultyAssignmentById(id);
    if (!assignment) throw new NotFoundError('Faculty assignment not found');

    const subject = await this.adminRepository.findSubjectById(assignment.subject_id);
    if (!subject || subject.college_id !== collegeId) {
      throw new ForbiddenError('Assignment does not belong to your college');
    }


    await this.adminRepository.deleteFacultyAssignment(id);

    if (this.adminRepository.createAuditLog) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'FACULTY_UNASSIGNED',
        entity_type: 'FACULTY_SUBJECT_ASSIGNMENT',
        entity_id: id,
        category: 'ACADEMIC_SETUP',
        description: `Removed faculty assignment for subject ${subject.code}`,
        metadata: { id },
      });
    }

    return { success: true, message: 'Faculty assignment removed successfully' };
  }

  // ==========================================
  // FACULTY SCHEDULES / TIMETABLE
  // ==========================================
  async getSchedules(
    collegeId: string,
    params: {
      facultyId?: string;
      classId?: string;
      roomId?: string;
      dayOfWeek?: string;
      academicTermId?: string;
    }
  ) {
    return this.adminRepository.findSchedules({ collegeId, ...params });
  }

  async getScheduleById(collegeId: string, id: string) {
    const schedule = await this.adminRepository.findScheduleById(id);
    if (!schedule) throw new NotFoundError('Schedule slot not found');
    if (schedule.faculty?.college_id !== collegeId) {
      throw new ForbiddenError('Schedule does not belong to your college');
    }
    return schedule;
  }

  async createSchedule(collegeId: string, dto: CreateScheduleDto, actor?: ActorContext) {
    if (dto.startTime >= dto.endTime) {
      throw new BadRequestError('Start time must precede end time (e.g. 09:00 - 10:00)');
    }

    const faculty = await this.adminRepository.findUserById(dto.facultyId);
    if (!faculty || faculty.college_id !== collegeId) {
      throw new NotFoundError('Faculty member not found in your college');
    }

    let subjectCode: string | undefined;
    let subjectName: string | undefined;

    if (dto.subjectId) {
      const subject = await this.adminRepository.findSubjectById(dto.subjectId);
      if (!subject || subject.college_id !== collegeId) {
        throw new NotFoundError('Subject not found');
      }
      subjectCode = subject.code;
      subjectName = subject.name;

    }

    if (dto.classId) {
      const academicClass = await this.adminRepository.findAcademicClassById(dto.classId);
      if (!academicClass || academicClass.college_id !== collegeId) {
        throw new NotFoundError('Academic class not found');
      }
    }

    if (dto.roomId) {
      const room = await this.adminRepository.findRoomById(dto.roomId);
      if (!room || room.college_id !== collegeId) {
        throw new NotFoundError('Room not found');
      }
    }

    // ==========================================
    // CONFLICT DETECTION
    // ==========================================
    const potentialConflicts = await this.adminRepository.findPotentialConflicts({
      dayOfWeek: dto.dayOfWeek,
      roomId: dto.roomId,
      facultyId: dto.facultyId,
      classId: dto.classId,
    });

    const isOverlap = (s1: string, e1: string, s2: string, e2: string) => s1 < e2 && s2 < e1;

    for (const c of potentialConflicts) {
      if (isOverlap(c.start_time, c.end_time, dto.startTime, dto.endTime)) {
        if (dto.roomId && c.room_id === dto.roomId) {
          throw new ConflictError(
            `Room conflict: Room ${c.room?.code || dto.roomId} is already booked on ${dto.dayOfWeek} from ${c.start_time} to ${c.end_time}`
          );
        }
        if (c.faculty_id === dto.facultyId) {
          throw new ConflictError(
            `Faculty conflict: ${c.faculty?.first_name} ${c.faculty?.last_name} is already scheduled on ${dto.dayOfWeek} from ${c.start_time} to ${c.end_time}`
          );
        }
        if (dto.classId && c.class_id === dto.classId) {
          throw new ConflictError(
            `Class conflict: Class ${c.class?.name || dto.classId} is already scheduled on ${dto.dayOfWeek} from ${c.start_time} to ${c.end_time}`
          );
        }
      }
    }

    const schedule = await this.adminRepository.createSchedule({
      ...dto,
      effectiveFrom: dto.effectiveFrom ? new Date(dto.effectiveFrom) : undefined,
      effectiveUntil: dto.effectiveUntil ? new Date(dto.effectiveUntil) : undefined,
      subjectCode,
      subjectName,
    });

    if (this.adminRepository.createAuditLog && schedule) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'SCHEDULE_CREATED',
        entity_type: 'FACULTY_SCHEDULE',
        entity_id: schedule.id,
        category: 'TIMETABLE',
        description: `Created schedule on ${dto.dayOfWeek} ${dto.startTime}-${dto.endTime} for ${faculty.first_name} ${faculty.last_name}`,
        metadata: dto,
      });
    }

    return schedule;
  }

  async updateSchedule(collegeId: string, id: string, dto: UpdateScheduleDto, actor?: ActorContext) {
    const existing = await this.adminRepository.findScheduleById(id);
    if (!existing) throw new NotFoundError('Schedule slot not found');
    if (existing.faculty?.college_id !== collegeId) {
      throw new ForbiddenError('Schedule does not belong to your college');
    }

    const dayOfWeek = dto.dayOfWeek || existing.day_of_week;
    const startTime = dto.startTime || existing.start_time;
    const endTime = dto.endTime || existing.end_time;
    const facultyId = dto.facultyId || existing.faculty_id;
    const roomId = dto.roomId !== undefined ? dto.roomId : (existing.room_id || undefined);
    const classId = dto.classId !== undefined ? dto.classId : (existing.class_id || undefined);

    if (startTime >= endTime) {
      throw new BadRequestError('Start time must precede end time');
    }

    const potentialConflicts = await this.adminRepository.findPotentialConflicts({
      dayOfWeek,
      roomId,
      facultyId,
      classId,
      excludeScheduleId: id,
    });

    const isOverlap = (s1: string, e1: string, s2: string, e2: string) => s1 < e2 && s2 < e1;

    for (const c of potentialConflicts) {
      if (isOverlap(c.start_time, c.end_time, startTime, endTime)) {
        if (roomId && c.room_id === roomId) {
          throw new ConflictError(
            `Room conflict: Room ${c.room?.code || roomId} is already booked on ${dayOfWeek} from ${c.start_time} to ${c.end_time}`
          );
        }
        if (c.faculty_id === facultyId) {
          throw new ConflictError(
            `Faculty conflict: Faculty is already scheduled on ${dayOfWeek} from ${c.start_time} to ${c.end_time}`
          );
        }
        if (classId && c.class_id === classId) {
          throw new ConflictError(
            `Class conflict: Class is already scheduled on ${dayOfWeek} from ${c.start_time} to ${c.end_time}`
          );
        }
      }
    }

    const updated = await this.adminRepository.updateSchedule(id, {
      ...dto,
      effectiveFrom: dto.effectiveFrom ? new Date(dto.effectiveFrom) : undefined,
      effectiveUntil: dto.effectiveUntil ? new Date(dto.effectiveUntil) : undefined,
    });

    if (this.adminRepository.createAuditLog && updated) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'SCHEDULE_UPDATED',
        entity_type: 'FACULTY_SCHEDULE',
        entity_id: id,
        category: 'TIMETABLE',
        description: `Updated schedule slot on ${dayOfWeek} ${startTime}-${endTime}`,
        metadata: dto,
      });
    }

    return updated;
  }

  async deleteSchedule(collegeId: string, id: string, actor?: ActorContext) {
    const existing = await this.adminRepository.findScheduleById(id);
    if (!existing) throw new NotFoundError('Schedule slot not found');
    if (existing.faculty?.college_id !== collegeId) {
      throw new ForbiddenError('Schedule does not belong to your college');
    }

    await this.adminRepository.deleteSchedule(id);

    if (this.adminRepository.createAuditLog) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'SCHEDULE_DELETED',
        entity_type: 'FACULTY_SCHEDULE',
        entity_id: id,
        category: 'TIMETABLE',
        description: `Deleted timetable slot on ${existing.day_of_week} ${existing.start_time}-${existing.end_time}`,
        metadata: { id },
      });
    }

    return { success: true, message: 'Schedule slot removed successfully' };
  }

  // ==========================================
  // ACADEMIC MONITORING (PHASE 6)
  // ==========================================
  async getMonitoringMetrics(collegeId: string, departmentId?: string, actor?: ActorContext) {
    const effectiveDeptId = departmentId;
    return this.adminRepository.getMonitoringMetrics(collegeId, effectiveDeptId);
  }

  async getAttendanceSessions(collegeId: string, query: QueryAcademicMonitoringDto, actor?: ActorContext) {
    const effectiveQuery = { ...query };
    return this.adminRepository.findAttendanceSessions({ collegeId, ...effectiveQuery });
  }

  async getAttendanceSessionById(collegeId: string, id: string, actor?: ActorContext) {
    const session = await this.adminRepository.findAttendanceSessionById(id);
    if (!session) throw new NotFoundError('Attendance session not found');
    if (session.subject.college_id !== collegeId) {
      throw new ForbiddenError('Session does not belong to your college');
    }
    return session;
  }

  async getSubjectAssignments(collegeId: string, query: QueryAcademicMonitoringDto, actor?: ActorContext) {
    const effectiveQuery = { ...query };
    return this.adminRepository.findSubjectAssignments({ collegeId, ...effectiveQuery });
  }

  async getSubjectAssignmentById(collegeId: string, id: string, actor?: ActorContext) {
    const assignment = await this.adminRepository.findSubjectAssignmentById(id);
    if (!assignment) throw new NotFoundError('Assignment not found');
    if (assignment.subject.college_id !== collegeId) {
      throw new ForbiddenError('Assignment does not belong to your college');
    }
    return assignment;
  }

  async getSubjectAssessments(collegeId: string, query: QueryAcademicMonitoringDto, actor?: ActorContext) {
    const effectiveQuery = { ...query };
    return this.adminRepository.findSubjectAssessments({ collegeId, ...effectiveQuery });
  }

  async getSubjectAssessmentById(collegeId: string, id: string, actor?: ActorContext) {
    const assessment = await this.adminRepository.findSubjectAssessmentById(id);
    if (!assessment) throw new NotFoundError('Assessment not found');
    if (assessment.subject.college_id !== collegeId) {
      throw new ForbiddenError('Assessment does not belong to your college');
    }
    return assessment;
  }

  // ==========================================
  // PHASE 7: BROADCAST NOTIFICATIONS & MODERATION
  // ==========================================
  async sendBroadcastNotification(collegeId: string, dto: SendBroadcastNotificationDto, actor?: ActorContext) {
    if (!dto.title || !dto.title.trim()) {
      throw new BadRequestError('Notification title is required');
    }
    if (!dto.body || !dto.body.trim()) {
      throw new BadRequestError('Notification body is required');
    }

    const validAudiences = ['ALL', 'STUDENTS', 'FACULTY', 'DEPARTMENT'];
    if (!validAudiences.includes(dto.targetAudience)) {
      throw new BadRequestError(`Invalid target audience. Must be one of: ${validAudiences.join(', ')}`);
    }


    const targetUsers = await this.adminRepository.findTargetUserIds({
      collegeId,
      targetAudience: dto.targetAudience,
      departmentId: dto.departmentId,
    });

    if (targetUsers.length === 0) {
      return {
        success: true,
        count: 0,
        message: 'No active recipients found for the selected audience.',
      };
    }

    const notifications = targetUsers.map((u) => ({
      user_id: u.id,
      title: dto.title.trim(),
      body: dto.body.trim(),
      type: NotificationType.ANNOUNCEMENT,
      category: dto.category?.trim() || 'CAMPUS_BROADCAST',
    }));

    await this.adminRepository.createBroadcastNotifications(notifications);

    if (this.adminRepository.createAuditLog) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'BROADCAST_NOTIFICATION_SENT',
        entity_type: 'Notification',
        category: 'COMMUNICATION',
        description: `Broadcast notification "${dto.title}" sent to ${targetUsers.length} users (${dto.targetAudience})`,
        metadata: {
          title: dto.title,
          targetAudience: dto.targetAudience,
          departmentId: dto.departmentId,
          recipientCount: targetUsers.length,
        },
      });
    }

    return {
      success: true,
      count: targetUsers.length,
      message: `Broadcast notification sent successfully to ${targetUsers.length} users.`,
    };
  }

  async getModerationEvents(
    collegeId: string,
    query: { departmentId?: string; scope?: string },
    actor?: ActorContext
  ) {
    const effectiveDeptId =
      query.departmentId;

    return this.adminRepository.findModerationEvents({
      collegeId,
      departmentId: effectiveDeptId,
      scope: query.scope,
    });
  }

  async deleteModerationEvent(collegeId: string, id: string, actor?: ActorContext) {
    const event = await this.adminRepository.findModerationEventById(id);
    if (!event) throw new NotFoundError('Event not found');
    if (event.college_id !== collegeId) {
      throw new ForbiddenError('Event does not belong to your college');
    }


    await this.adminRepository.deleteModerationEvent(id);

    if (this.adminRepository.createAuditLog) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'EVENT_DELETED_BY_ADMIN',
        entity_type: 'Event',
        entity_id: id,
        category: 'MODERATION',
        description: `Moderator deleted event "${event.title}"`,
        metadata: {
          title: event.title,
          organizer_id: event.organizer_id,
          department_id: event.department_id,
        },
      });
    }

    return { success: true, message: 'Event successfully removed by administrator.' };
  }

  async getModerationPosts(
    collegeId: string,
    query: { departmentId?: string; clubId?: string },
    actor?: ActorContext
  ) {
    const effectiveDeptId =
      query.departmentId;

    return this.adminRepository.findModerationPosts({
      collegeId,
      departmentId: effectiveDeptId,
      clubId: query.clubId,
    });
  }

  async deleteModerationPost(collegeId: string, id: string, actor?: ActorContext) {
    const post = await this.adminRepository.findModerationPostById(id);
    if (!post) throw new NotFoundError('Post not found');
    if (post.college_id !== collegeId) {
      throw new ForbiddenError('Post does not belong to your college');
    }


    await this.adminRepository.deleteModerationPost(id);

    if (this.adminRepository.createAuditLog) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'POST_DELETED_BY_ADMIN',
        entity_type: 'Post',
        entity_id: id,
        category: 'MODERATION',
        description: `Moderator deleted post "${post.title}"`,
        metadata: {
          title: post.title,
          author_id: post.author_id,
          department_id: post.department_id,
        },
      });
    }

    return { success: true, message: 'Post successfully removed by administrator.' };
  }

  // ==========================================
  // 17. PROFILE CHANGE REQUEST WORKFLOWS
  // ==========================================

  async getChangeRequests(
    collegeId: string,
    options: {
      status?: string;
      departmentId?: string;
      category?: string;
      page?: number;
      limit?: number;
    },
    actor?: ActorContext,
  ) {
    const filterDept = options.departmentId;

    return this.adminRepository.getChangeRequests(collegeId, {
      ...options,
      departmentId: filterDept,
    });
  }

  async getChangeRequestById(collegeId: string, requestId: string, actor?: ActorContext) {
    const request = await this.adminRepository.getChangeRequestById(requestId, collegeId);
    if (!request) throw new NotFoundError('Change request not found');

    return request;
  }

  async approveChangeRequest(collegeId: string, requestId: string, reviewComment?: string, actor?: ActorContext) {
    const request = await this.adminRepository.getChangeRequestById(requestId, collegeId);
    if (!request) throw new NotFoundError('Change request not found');

    const { request: updated, student } = await this.adminRepository.approveChangeRequest(
      requestId,
      actor?.actorUserId || '',
      reviewComment,
    );

    if (this.adminRepository.createAuditLog) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'PROFILE_CHANGE_APPROVED',
        entity_type: 'ProfileChangeRequest',
        entity_id: requestId,
        category: 'STUDENT_RECORD',
        description: `Approved profile change on field "${request.field}" for student ${student.first_name} ${student.last_name}`,
        metadata: {
          student_id: request.student_id,
          field: request.field,
          old_value: request.current_value,
          new_value: request.requested_value,
          review_comment: reviewComment,
        },
      });
    }

    try {
      const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(request.student_id);
      if (isUuid) {
        await prisma.notification.create({
          data: {
            user_id: request.student_id,
            title: 'Profile Change Approved',
            body: `Your request to change "${request.field}" to "${request.requested_value}" has been approved.`,
            type: 'SYSTEM',
          },
        });
      }
    } catch (_) {}

    return updated;
  }

  async rejectChangeRequest(collegeId: string, requestId: string, rejectionReason: string, actor?: ActorContext) {
    if (!rejectionReason || !rejectionReason.trim()) {
      throw new BadRequestError('Rejection reason is required');
    }

    const request = await this.adminRepository.getChangeRequestById(requestId, collegeId);
    if (!request) throw new NotFoundError('Change request not found');

    const { request: updated, student } = await this.adminRepository.rejectChangeRequest(
      requestId,
      actor?.actorUserId || '',
      rejectionReason,
    );

    if (this.adminRepository.createAuditLog) {
      await this.adminRepository.createAuditLog({
        college_id: collegeId,
        actor_user_id: actor?.actorUserId,
        action: 'PROFILE_CHANGE_REJECTED',
        entity_type: 'ProfileChangeRequest',
        entity_id: requestId,
        category: 'STUDENT_RECORD',
        description: `Rejected profile change on field "${request.field}" for student ${student.first_name} ${student.last_name}`,
        metadata: {
          student_id: request.student_id,
          field: request.field,
          requested_value: request.requested_value,
          rejection_reason: rejectionReason,
        },
      });
    }

    try {
      const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(request.student_id);
      if (isUuid) {
        await prisma.notification.create({
          data: {
            user_id: request.student_id,
            title: 'Profile Change Rejected',
            body: `Your request to change "${request.field}" was rejected. Reason: ${rejectionReason}`,
            type: 'SYSTEM',
          },
        });
      }
    } catch (_) {}



    return updated;
  }
}

