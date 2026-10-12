import { prisma } from '../../config/database';
import { NotFoundError, BadRequestError } from '../../shared/errors/AppError';
import {
  QueryAdminUsersDto,
  CreateDepartmentDto,
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
  QueryAuditLogsDto,
  UpdateCollegeDto,
} from './admin.types';
import { Role, ClubStatus, UserStatus, NotificationType } from '@prisma/client';

export class AdminRepository {
  async getDashboardMetrics(collegeId: string) {
    const [
      totalUsers,
      totalStudents,
      totalFaculty,
      totalDepartments,
      totalClasses,
      approvedClubs,
      pendingClubs,
      totalEvents,
      totalDrives,
      placedCount,
    ] = await Promise.all([
      prisma.user.count({ where: { college_id: collegeId } }),
      prisma.user.count({ where: { college_id: collegeId, role: Role.STUDENT } }),
      prisma.user.count({ where: { college_id: collegeId, role: Role.FACULTY } }),
      prisma.department.count({ where: { college_id: collegeId } }),
      prisma.academicClass.count({ where: { college_id: collegeId } }),
      prisma.club.count({ where: { college_id: collegeId, status: ClubStatus.APPROVED } }),
      prisma.club.count({ where: { college_id: collegeId, status: ClubStatus.PENDING } }),
      prisma.event.count({ where: { college_id: collegeId } }),
      prisma.placementDrive.count({ where: { college_id: collegeId } }),
      prisma.placementApplication.count({ where: { status: 'OFFERED' } }),
    ]);

    return {
      totalUsers,
      totalStudents,
      totalFaculty,
      totalDepartments,
      totalClasses,
      approvedClubs,
      pendingClubs,
      totalEvents,
      totalDrives,
      placedCount,
    };
  }

  async findUsers(collegeId: string, query: QueryAdminUsersDto, excludeUserId?: string) {
    const page = query.page || 1;
    const limit = query.limit || 10;
    const skip = (page - 1) * limit;

    const where: any = { college_id: collegeId, deleted_at: null };
    if (excludeUserId) {
      where.id = { not: excludeUserId };
    }
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

  async findDeletedUsers(collegeId: string, query: QueryAdminUsersDto) {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const where: any = { college_id: collegeId, deleted_at: { not: null } };
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
        orderBy: { deleted_at: 'desc' },
        select: {
          id: true,
          email: true,
          first_name: true,
          last_name: true,
          role: true,
          roll_number: true,
          status: true,
          created_at: true,
          deleted_at: true,
          department: { select: { id: true, name: true, code: true } },
          student_profile: { select: { registration_number: true } },
          academic_profile: { select: { batch_name: true, current_year: true } },
        },
      }),
    ]);

    const now = Date.now();
    const enriched = users.map((u) => {
      const deletedTime = u.deleted_at ? new Date(u.deleted_at).getTime() : now;
      const elapsedDays = Math.floor((now - deletedTime) / (1000 * 60 * 60 * 24));
      const daysLeft = Math.max(0, 30 - elapsedDays);
      return {
        ...u,
        days_left: daysLeft,
      };
    });

    return {
      data: enriched,
      meta: { total, page, limit, totalPages: Math.ceil(total / limit) },
    };
  }

  async updateUserRole(userId: string, newRole: Role) {
    return prisma.user.update({
      where: { id: userId },
      data: { role: newRole },
    });
  }

  async updateUserStatus(userId: string, status: UserStatus) {
    return prisma.user.update({
      where: { id: userId },
      data: { status },
    });
  }

  async findDepartments(collegeId: string) {
    const departments = await prisma.department.findMany({
      where: { college_id: collegeId },
      include: {
        _count: {
          select: { users: true, subjects: true, academic_programs: true },
        },
      },
      orderBy: { name: 'asc' },
    });

    const counts = await prisma.user.groupBy({
      by: ['department_id', 'role'],
      where: {
        college_id: collegeId,
        department_id: { in: departments.map((d) => d.id) },
        status: { not: UserStatus.DEACTIVATED },
      },
      _count: { id: true },
    });

    const studentMap: Record<string, number> = {};
    const facultyMap: Record<string, number> = {};

    for (const item of counts) {
      if (!item.department_id) continue;
      if (item.role === Role.STUDENT) {
        studentMap[item.department_id] = (studentMap[item.department_id] || 0) + item._count.id;
      } else if (item.role === Role.FACULTY) {
        facultyMap[item.department_id] = (facultyMap[item.department_id] || 0) + item._count.id;
      }
    }

    return departments.map((dept) => ({
      ...dept,
      total_students: studentMap[dept.id] || 0,
      total_faculty: facultyMap[dept.id] || 0,
    }));
  }

  async findDepartmentById(id: string) {
    const dept = await prisma.department.findUnique({
      where: { id },
      include: {
        _count: {
          select: { users: true, subjects: true, academic_programs: true },
        },
      },
    });
    if (!dept) return null;

    const [totalStudents, totalFaculty] = await Promise.all([
      prisma.user.count({
        where: { department_id: id, role: Role.STUDENT, status: { not: UserStatus.DEACTIVATED } },
      }),
      prisma.user.count({
        where: { department_id: id, role: Role.FACULTY, status: { not: UserStatus.DEACTIVATED } },
      }),
    ]);

    return {
      ...dept,
      total_students: totalStudents,
      total_faculty: totalFaculty,
    };
  }

  async findDepartmentOverview(collegeId: string, departmentId: string) {
    const dept = await prisma.department.findUnique({
      where: { id: departmentId },
      include: {
        _count: {
          select: { users: true, subjects: true, academic_programs: true },
        },
      },
    });
    if (!dept || dept.college_id !== collegeId) {
      return null;
    }

    const activeYear = (await prisma.academicYear.findFirst({
      where: { college_id: collegeId, is_active: true },
    })) || (await prisma.academicYear.findFirst({
      where: { college_id: collegeId },
      orderBy: { start_date: 'desc' },
    }));

    const ayMatch = activeYear?.year_name.match(/^(\d{4})/);
    const ayStartYear = ayMatch ? parseInt(ayMatch[1], 10) : (activeYear ? new Date(activeYear.start_date).getFullYear() : new Date().getFullYear());

    const totalFaculty = await prisma.user.count({
      where: {
        college_id: collegeId,
        department_id: departmentId,
        role: Role.FACULTY,
        status: { not: UserStatus.DEACTIVATED },
      },
    });

    const students = await prisma.user.findMany({
      where: {
        college_id: collegeId,
        department_id: departmentId,
        role: Role.STUDENT,
        status: { not: UserStatus.DEACTIVATED },
      },
      select: {
        id: true,
        academic_profile: {
          select: {
            admission_year: true,
            current_status: true,
            current_year: true,
          },
        },
      },
    });

    let firstYear = 0;
    let secondYear = 0;
    let thirdYear = 0;
    let fourthYear = 0;
    let graduated = 0;

    for (const s of students) {
      const ap = s.academic_profile;
      if (ap?.current_status === 'GRADUATED' || (ap?.current_year && ap.current_year > 4)) {
        graduated++;
        continue;
      }
      const admYear = ap?.admission_year || (ayStartYear - 3);
      const calculatedYear = ap?.current_year || Math.max(1, ayStartYear - admYear + 1);

      if (calculatedYear <= 1) firstYear++;
      else if (calculatedYear === 2) secondYear++;
      else if (calculatedYear === 3) thirdYear++;
      else if (calculatedYear === 4) fourthYear++;
      else graduated++;
    }

    return {
      department: dept,
      totalStudents: students.length,
      totalFaculty,
      studentsByYear: {
        firstYear,
        secondYear,
        thirdYear,
        fourthYear,
        graduated,
      },
    };
  }

  async findDepartmentStudents(
    collegeId: string,
    departmentId: string,
    query: { year?: string | number; page?: number; limit?: number; search?: string }
  ) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.max(1, Math.min(100, Number(query.limit) || 20));
    const skip = (page - 1) * limit;

    const activeYear = (await prisma.academicYear.findFirst({
      where: { college_id: collegeId, is_active: true },
    })) || (await prisma.academicYear.findFirst({
      where: { college_id: collegeId },
      orderBy: { start_date: 'desc' },
    }));

    const ayMatch = activeYear?.year_name.match(/^(\d{4})/);
    const ayStartYear = ayMatch ? parseInt(ayMatch[1], 10) : (activeYear ? new Date(activeYear.start_date).getFullYear() : new Date().getFullYear());

    const where: any = {
      college_id: collegeId,
      department_id: departmentId,
      role: Role.STUDENT,
      status: { not: UserStatus.DEACTIVATED },
    };

    if (query.search) {
      where.OR = [
        { first_name: { contains: query.search, mode: 'insensitive' } },
        { last_name: { contains: query.search, mode: 'insensitive' } },
        { email: { contains: query.search, mode: 'insensitive' } },
        { roll_number: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    const targetYear = query.year
      ? query.year.toString().toLowerCase().includes('grad')
        ? 5
        : parseInt(query.year.toString(), 10)
      : undefined;

    const allStudents = await prisma.user.findMany({
      where,
      include: {
        department: { select: { id: true, name: true, code: true } },
        student_profile: { select: { registration_number: true } },
        academic_profile: {
          select: {
            admission_year: true,
            batch_name: true,
            current_status: true,
            current_year: true,
          },
        },
      },
      orderBy: [{ first_name: 'asc' }, { last_name: 'asc' }],
    });

    const formattedStudents = allStudents.map((s) => {
      const ap = s.academic_profile;
      const isGrad = ap?.current_status === 'GRADUATED' || (ap?.current_year && ap.current_year > 4);
      const admYear = ap?.admission_year || (ayStartYear - 3);
      const calcYear = ap?.current_year || (isGrad ? 5 : Math.max(1, ayStartYear - admYear + 1));
      const yearLabel = isGrad || calcYear > 4
        ? 'Graduated'
        : calcYear === 1
          ? '1st Year'
          : calcYear === 2
            ? '2nd Year'
            : calcYear === 3
              ? '3rd Year'
              : '4th Year';

      return {
        id: s.id,
        email: s.email,
        firstName: s.first_name,
        lastName: s.last_name,
        fullName: `${s.first_name} ${s.last_name}`.trim(),
        role: s.role,
        avatarUrl: s.avatar_url,
        rollNumber: s.roll_number || 'N/A',
        registrationNumber: s.student_profile?.registration_number || s.roll_number || 'N/A',
        batch: ap?.batch_name || `${admYear}-${admYear + 4}`,
        currentYear: yearLabel,
        yearNumber: calcYear > 4 ? 5 : calcYear,
        status: s.status,
        department: s.department,
      };
    });

    const filtered = targetYear !== undefined
      ? formattedStudents.filter((s) => s.yearNumber === targetYear)
      : formattedStudents;

    const total = filtered.length;
    const paginated = filtered.slice(skip, skip + limit);

    return {
      data: paginated,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async findDepartmentFaculty(
    collegeId: string,
    departmentId: string,
    query: { page?: number; limit?: number; search?: string }
  ) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.max(1, Math.min(100, Number(query.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {
      college_id: collegeId,
      department_id: departmentId,
      role: Role.FACULTY,
      status: { not: UserStatus.DEACTIVATED },
    };

    if (query.search) {
      where.OR = [
        { first_name: { contains: query.search, mode: 'insensitive' } },
        { last_name: { contains: query.search, mode: 'insensitive' } },
        { email: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    const [total, facultyMembers] = await Promise.all([
      prisma.user.count({ where }),
      prisma.user.findMany({
        where,
        skip,
        take: limit,
        include: {
          department: { select: { id: true, name: true, code: true } },
          faculty_profile: true,
          faculty_assignments: {
            include: { subject: { select: { id: true, name: true, code: true } } },
          },
        },
        orderBy: [{ first_name: 'asc' }, { last_name: 'asc' }],
      }),
    ]);

    const data = facultyMembers.map((f) => ({
      id: f.id,
      email: f.email,
      firstName: f.first_name,
      lastName: f.last_name,
      fullName: `${f.first_name} ${f.last_name}`.trim(),
      role: f.role,
      avatarUrl: f.avatar_url,
      phone: f.phone,
      department: f.department,
      designation: f.faculty_profile?.designation || 'Faculty Member',
      officeRoom: f.faculty_profile?.office_room || 'Academic Block',
      assignedSubjects: f.faculty_assignments?.map((a) => a.subject?.name).filter(Boolean) || [],
      status: f.status,
    }));

    return {
      data,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async findDepartmentByCode(collegeId: string, code: string) {
    return prisma.department.findFirst({
      where: { college_id: collegeId, code: { equals: code, mode: 'insensitive' } },
    });
  }

  async createDepartment(collegeId: string, dto: CreateDepartmentDto) {
    return prisma.department.create({
      data: {
        college_id: collegeId,
        name: dto.name,
        code: dto.code.toUpperCase(),
        description: dto.description || null,
      },
      include: {
        _count: {
          select: { users: true },
        },
      },
    });
  }

  async updateDepartment(id: string, data: { name?: string; code?: string; description?: string; isActive?: boolean; is_active?: boolean }) {
    const active = data.isActive !== undefined ? data.isActive : data.is_active;
    return prisma.department.update({
      where: { id },
      data: {
        ...(data.name && { name: data.name }),
        ...(data.code && { code: data.code.toUpperCase() }),
        ...(data.description !== undefined && { description: data.description }),
        ...(active !== undefined && { is_active: active }),
      },
      include: {
        _count: {
          select: { users: true },
        },
      },
    });
  }

  async deleteDepartment(id: string) {
    return prisma.$transaction(async (tx) => {
      // 1. Unlink users from this department
      await tx.user.updateMany({
        where: { department_id: id },
        data: { department_id: null },
      });
      // 2. Unlink events and posts
      await tx.event.updateMany({
        where: { department_id: id },
        data: { department_id: null },
      });
      await tx.post.updateMany({
        where: { department_id: id },
        data: { department_id: null },
      });
      // 3. Delete department
      return tx.department.delete({
        where: { id },
      });
    });
  }

  async deleteUser(userId: string) {
    return prisma.$transaction(async (tx) => {
      // 1. Delete dependent profiles & tokens
      await tx.studentProfile.deleteMany({ where: { user_id: userId } });
      await tx.studentAcademicProfile.deleteMany({ where: { student_id: userId } });
      await tx.facultyProfile.deleteMany({ where: { user_id: userId } });
      await tx.profileChangeRequest.deleteMany({
        where: { OR: [{ student_id: userId }, { reviewed_by: userId }] },
      });
      await tx.notification.deleteMany({ where: { user_id: userId } });
      await tx.notificationToken.deleteMany({ where: { user_id: userId } });
      await tx.refreshToken.deleteMany({ where: { user_id: userId } });
      await tx.passwordResetToken.deleteMany({ where: { user_id: userId } });
      await tx.portfolio.deleteMany({ where: { user_id: userId } });
      await tx.clubMember.deleteMany({ where: { user_id: userId } });
      await tx.userFollow.deleteMany({
        where: { OR: [{ follower_id: userId }, { following_id: userId }] },
      });
      await tx.auditLog.deleteMany({ where: { actor_user_id: userId } });
      await tx.chatMessage.deleteMany({ where: { sender_id: userId } });
      await tx.chatParticipant.deleteMany({ where: { user_id: userId } });
      await tx.chatBlock.deleteMany({
        where: { OR: [{ blocker_id: userId }, { blocked_id: userId }] },
      });
      await tx.chatRequest.deleteMany({
        where: { OR: [{ sender_id: userId }, { recipient_id: userId }] },
      });
      await tx.studentChatSettings.deleteMany({ where: { student_id: userId } });
      await tx.eventRegistration.deleteMany({ where: { user_id: userId } });
      await tx.placementApplication.deleteMany({ where: { student_id: userId } });

      // 2. Delete the user record
      return tx.user.delete({
        where: { id: userId },
      });
    });
  }

  async softDeleteUser(userId: string) {
    return prisma.$transaction(async (tx) => {
      await tx.refreshToken.deleteMany({ where: { user_id: userId } });
      await tx.passwordResetToken.deleteMany({ where: { user_id: userId } });
      return tx.user.update({
        where: { id: userId },
        data: {
          deleted_at: new Date(),
          status: UserStatus.DEACTIVATED,
        },
      });
    });
  }

  async restoreUser(userId: string) {
    return prisma.user.update({
      where: { id: userId },
      data: {
        deleted_at: null,
        status: UserStatus.ACTIVE,
      },
    });
  }

  async permanentlyDeleteUser(userId: string) {
    return this.deleteUser(userId);
  }

  async purgeExpiredDeletedUsers(collegeId: string, maxDays: number = 30) {
    const cutoff = maxDays === 0
      ? new Date()
      : new Date(Date.now() - maxDays * 24 * 60 * 60 * 1000);

    const expiredUsers = await prisma.user.findMany({
      where: {
        college_id: collegeId,
        deleted_at: {
          not: null,
          lte: cutoff,
        },
      },
      select: { id: true },
    });

    let purgedCount = 0;
    for (const u of expiredUsers) {
      await this.deleteUser(u.id);
      purgedCount++;
    }
    return { purgedCount };
  }

  async findUserById(userId: string) {
    return prisma.user.findUnique({
      where: { id: userId },
      include: {
        department: { select: { id: true, name: true, code: true } },
        academic_profile: true,
        faculty_profile: true,
      },
    });
  }

  async createUser(data: {
    college_id: string;
    email: string;
    password_hash: string;
    first_name: string;
    last_name: string;
    role: Role;
    department_id?: string;
    roll_number?: string;
    registration_number?: string;
    phone?: string;
    admission_year?: number;
    batch_name?: string;
    batch_id?: string;
    current_year?: number;
    section?: string;
    program_id?: string;
    designation?: string;
    office_room?: string;
    status?: UserStatus;
    is_password_configured?: boolean;
    is_profile_completed?: boolean;
    first_login_completed?: boolean;
  }) {
    return prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          college_id: data.college_id,
          email: data.email,
          password_hash: data.password_hash,
          first_name: data.first_name,
          last_name: data.last_name,
          role: data.role,
          department_id: data.department_id,
          roll_number: data.roll_number,
          phone: data.phone,
          status: data.status || UserStatus.ACTIVE,
          is_password_configured: data.is_password_configured !== undefined ? data.is_password_configured : true,
          is_profile_completed: data.is_profile_completed !== undefined ? data.is_profile_completed : true,
          first_login_completed: data.first_login_completed !== undefined ? data.first_login_completed : true,
        },
      });

      if (data.role === Role.STUDENT) {
        await tx.studentAcademicProfile.create({
          data: {
            student_id: user.id,
            program_id: data.program_id,
            batch_id: data.batch_id,
            admission_year: data.admission_year || new Date().getFullYear(),
            batch_name: data.batch_name || `Batch of ${data.admission_year || new Date().getFullYear()}`,
            current_year: data.current_year,
            section: data.section || 'A',
            current_status: 'ACTIVE',
          },
        });

        await tx.studentProfile.create({
          data: {
            user_id: user.id,
            registration_number: data.registration_number || data.roll_number || null,
          },
        });
      } else if (data.role === Role.FACULTY) {
        await tx.facultyProfile.create({
          data: {
            user_id: user.id,
            designation: data.designation || 'Assistant Professor',
            office_room: data.office_room || 'Main Block',
          },
        });
      }

      return tx.user.findUnique({
        where: { id: user.id },
        include: {
          department: { select: { id: true, name: true, code: true } },
          academic_profile: true,
          faculty_profile: true,
          student_profile: true,
        },
      });
    });
  }

  async updateUser(userId: string, data: {
    first_name?: string;
    last_name?: string;
    email?: string;
    phone?: string;
    department_id?: string | null;
    roll_number?: string;
    registration_number?: string;
    role?: Role;
    status?: UserStatus;
    admission_year?: number;
    batch_name?: string;
    batch_id?: string;
    current_year?: number;
    section?: string;
    designation?: string;
    office_room?: string;
    password_hash?: string;
    is_password_configured?: boolean;
  }) {
    return prisma.$transaction(async (tx) => {
      const updatePayload: any = {};
      if (data.first_name !== undefined) updatePayload.first_name = data.first_name;
      if (data.last_name !== undefined) updatePayload.last_name = data.last_name;
      if (data.email !== undefined) updatePayload.email = data.email;
      if (data.phone !== undefined) updatePayload.phone = data.phone;
      if (data.department_id !== undefined) updatePayload.department_id = data.department_id;
      if (data.roll_number !== undefined) updatePayload.roll_number = data.roll_number;
      if (data.role !== undefined) updatePayload.role = data.role;
      if (data.status !== undefined) updatePayload.status = data.status;
      if (data.password_hash !== undefined) updatePayload.password_hash = data.password_hash;
      if (data.is_password_configured !== undefined) updatePayload.is_password_configured = data.is_password_configured;

      const user = await tx.user.update({
        where: { id: userId },
        data: updatePayload,
      });

      if (data.registration_number !== undefined) {
        await tx.studentProfile.upsert({
          where: { user_id: userId },
          update: { registration_number: data.registration_number },
          create: {
            user_id: userId,
            registration_number: data.registration_number,
          },
        });
      }

      if (
        data.admission_year !== undefined ||
        data.batch_name !== undefined ||
        data.batch_id !== undefined ||
        data.current_year !== undefined ||
        data.section !== undefined
      ) {
        await tx.studentAcademicProfile.upsert({
          where: { student_id: userId },
          update: {
            ...(data.admission_year !== undefined && { admission_year: data.admission_year }),
            ...(data.batch_name !== undefined && { batch_name: data.batch_name }),
            ...(data.batch_id !== undefined && { batch_id: data.batch_id }),
            ...(data.current_year !== undefined && { current_year: data.current_year }),
            ...(data.section !== undefined && { section: data.section }),
          },
          create: {
            student_id: userId,
            admission_year: data.admission_year || new Date().getFullYear(),
            batch_name: data.batch_name || `Batch of ${new Date().getFullYear()}`,
            batch_id: data.batch_id,
            current_year: data.current_year,
            section: data.section || 'A',
          },
        });
      }

      if (data.designation !== undefined || data.office_room !== undefined) {
        await tx.facultyProfile.upsert({
          where: { user_id: userId },
          update: {
            ...(data.designation !== undefined && { designation: data.designation }),
            ...(data.office_room !== undefined && { office_room: data.office_room }),
          },
          create: {
            user_id: userId,
            designation: data.designation || 'Faculty Member',
            office_room: data.office_room || 'Main Block',
          },
        });
      }

      return tx.user.findUnique({
        where: { id: userId },
        include: {
          department: { select: { id: true, name: true, code: true } },
          academic_profile: true,
          faculty_profile: true,
          student_profile: true,
        },
      });
    });
  }

  async createAuditLog(data: {
    college_id: string;
    actor_user_id?: string;
    action: string;
    entity_type: string;
    entity_id?: string;
    category?: string;
    description: string;
    metadata?: any;
    ip_address?: string;
    user_agent?: string;
  }) {
    return prisma.auditLog.create({
      data: {
        college_id: data.college_id,
        actor_user_id: data.actor_user_id,
        action: data.action,
        entity_type: data.entity_type,
        entity_id: data.entity_id,
        category: data.category || 'ADMIN',
        description: data.description,
        metadata: data.metadata || {},
        ip_address: data.ip_address,
        user_agent: data.user_agent,
      },
    });
  }

  async getAuditLogs(collegeId: string, queryOrLimit?: QueryAuditLogsDto | number) {
    const query: QueryAuditLogsDto =
      typeof queryOrLimit === 'number' ? { limit: queryOrLimit } : queryOrLimit || {};
    const limit = query.limit || 50;

    const where: any = {
      college_id: collegeId,
      ...(query.action && { action: { contains: query.action, mode: 'insensitive' } }),
      ...(query.category && { category: query.category }),
      ...(query.entityType && { entity_type: query.entityType }),
      ...(query.actorUserId && { actor_user_id: query.actorUserId }),
      ...((query.startDate || query.endDate) && {
        created_at: {
          ...(query.startDate && { gte: new Date(query.startDate) }),
          ...(query.endDate && { lte: new Date(query.endDate) }),
        },
      }),
    };

    const logs = await prisma.auditLog.findMany({
      where,
      orderBy: { created_at: 'desc' },
      take: limit,
      include: {
        actor: {
          select: {
            id: true,
            first_name: true,
            last_name: true,
            email: true,
            role: true,
          },
        },
      },
    });

    return logs.map((log) => ({
      id: log.id,
      timestamp: log.created_at,
      actorName: log.actor ? `${log.actor.first_name} ${log.actor.last_name}`.trim() : 'System Admin',
      actorEmail: log.actor?.email,
      actorRole: log.actor?.role,
      action: log.action,
      entityType: log.entity_type,
      entityId: log.entity_id,
      category: log.category,
      details: log.description,
      metadata: log.metadata,
      ipAddress: log.ip_address,
      userAgent: log.user_agent,
    }));
  }

  // ==========================================
  // INSTITUTIONAL SETTINGS & COLLEGE PROFILE
  // ==========================================
  async findCollegeById(collegeId: string) {
    return prisma.college.findUnique({
      where: { id: collegeId },
      include: {
        _count: {
          select: {
            departments: true,
            users: true,
            clubs: true,
            events: true,
            drives: true,
            academic_programs: true,
            academic_classes: true,
            rooms: true,
          },
        },
      },
    });
  }

  async updateCollege(collegeId: string, dto: UpdateCollegeDto) {
    return prisma.college.update({
      where: { id: collegeId },
      data: {
        ...(dto.name && { name: dto.name }),
        ...(dto.domain && { domain: dto.domain.toLowerCase() }),
        ...(dto.logoUrl !== undefined && { logo_url: dto.logoUrl }),
        ...(dto.address !== undefined && { address: dto.address }),
      },
    });
  }

  // ==========================================
  // ACADEMIC YEARS
  // ==========================================
  async findAcademicYears(collegeId: string) {
    return prisma.academicYear.findMany({
      where: { college_id: collegeId },
      include: {
        _count: { select: { terms: true } },
      },
      orderBy: { start_date: 'desc' },
    });
  }

  async findAcademicYearById(id: string) {
    return prisma.academicYear.findUnique({
      where: { id },
      include: {
        terms: { orderBy: { semester_number: 'asc' } },
      },
    });
  }

  async findAcademicYearByName(collegeId: string, yearName: string) {
    return prisma.academicYear.findFirst({
      where: { college_id: collegeId, year_name: { equals: yearName, mode: 'insensitive' } },
    });
  }

  async createAcademicYear(collegeId: string, dto: CreateAcademicYearDto) {
    return prisma.academicYear.create({
      data: {
        college_id: collegeId,
        year_name: dto.yearName,
        start_date: new Date(dto.startDate),
        end_date: new Date(dto.endDate),
        is_active: dto.isActive ?? false,
      },
      include: {
        _count: { select: { terms: true } },
      },
    });
  }

  async updateAcademicYear(id: string, dto: UpdateAcademicYearDto) {
    return prisma.academicYear.update({
      where: { id },
      data: {
        ...(dto.yearName && { year_name: dto.yearName }),
        ...(dto.startDate && { start_date: new Date(dto.startDate) }),
        ...(dto.endDate && { end_date: new Date(dto.endDate) }),
        ...(dto.isActive !== undefined && { is_active: dto.isActive }),
      },
      include: {
        _count: { select: { terms: true } },
      },
    });
  }

  async setActiveAcademicYear(collegeId: string, id: string) {
    return prisma.$transaction(async (tx) => {
      await tx.academicYear.updateMany({
        where: { college_id: collegeId },
        data: { is_active: false },
      });
      return tx.academicYear.update({
        where: { id },
        data: { is_active: true },
        include: { _count: { select: { terms: true } } },
      });
    });
  }

  // ==========================================
  // ACADEMIC TERMS
  // ==========================================
  async findAcademicTerms(academicYearId?: string, collegeId?: string) {
    return prisma.academicTerm.findMany({
      where: {
        ...(academicYearId && { academic_year_id: academicYearId }),
        ...(collegeId && { academic_year: { college_id: collegeId } }),
      },
      include: {
        academic_year: { select: { id: true, year_name: true, is_active: true } },
        _count: { select: { subjects: true, enrollments: true } },
      },
      orderBy: { semester_number: 'asc' },
    });
  }

  async findAcademicTermById(id: string) {
    return prisma.academicTerm.findUnique({
      where: { id },
      include: { academic_year: true },
    });
  }

  async createAcademicTerm(dto: CreateAcademicTermDto) {
    return prisma.academicTerm.create({
      data: {
        academic_year_id: dto.academicYearId,
        name: dto.name,
        term_type: dto.termType || 'ODD',
        semester_number: dto.semesterNumber,
        start_date: new Date(dto.startDate),
        end_date: new Date(dto.endDate),
        status: dto.status || 'UPCOMING',
      },
      include: {
        academic_year: { select: { id: true, year_name: true } },
      },
    });
  }

  async updateAcademicTerm(id: string, dto: UpdateAcademicTermDto) {
    return prisma.academicTerm.update({
      where: { id },
      data: {
        ...(dto.name && { name: dto.name }),
        ...(dto.termType && { term_type: dto.termType }),
        ...(dto.semesterNumber !== undefined && { semester_number: dto.semesterNumber }),
        ...(dto.startDate && { start_date: new Date(dto.startDate) }),
        ...(dto.endDate && { end_date: new Date(dto.endDate) }),
        ...(dto.status && { status: dto.status }),
      },
      include: {
        academic_year: { select: { id: true, year_name: true } },
      },
    });
  }

  // ==========================================
  // ACADEMIC PROGRAMS
  // ==========================================
  async findAcademicPrograms(collegeId: string, departmentId?: string) {
    return prisma.academicProgram.findMany({
      where: {
        college_id: collegeId,
        ...(departmentId && { department_id: departmentId }),
      },
      include: {
        department: { select: { id: true, name: true, code: true } },
        _count: { select: { student_profiles: true, curriculum_subjects: true, batches: true } },
      },
      orderBy: { name: 'asc' },
    });
  }

  async findAcademicProgramById(id: string) {
    return prisma.academicProgram.findUnique({
      where: { id },
      include: {
        department: true,
        batches: true,
      },
    });
  }

  async findAcademicProgramByCode(collegeId: string, code: string) {
    return prisma.academicProgram.findFirst({
      where: { college_id: collegeId, code: { equals: code, mode: 'insensitive' } },
    });
  }

  async createAcademicProgram(collegeId: string, dto: CreateAcademicProgramDto) {
    return prisma.academicProgram.create({
      data: {
        college_id: collegeId,
        department_id: dto.departmentId,
        name: dto.name,
        code: dto.code.toUpperCase(),
        degree_type: dto.degreeType || 'UNDERGRADUATE',
        total_semesters: dto.totalSemesters || 8,
        is_active: dto.isActive ?? true,
      },
      include: {
        department: { select: { id: true, name: true, code: true } },
      },
    });
  }

  async updateAcademicProgram(id: string, dto: UpdateAcademicProgramDto) {
    return prisma.academicProgram.update({
      where: { id },
      data: {
        ...(dto.departmentId && { department_id: dto.departmentId }),
        ...(dto.name && { name: dto.name }),
        ...(dto.code && { code: dto.code.toUpperCase() }),
        ...(dto.degreeType && { degree_type: dto.degreeType }),
        ...(dto.totalSemesters !== undefined && { total_semesters: dto.totalSemesters }),
        ...(dto.isActive !== undefined && { is_active: dto.isActive }),
      },
      include: {
        department: { select: { id: true, name: true, code: true } },
      },
    });
  }

  // ==========================================
  // BATCHES
  // ==========================================
  async ensureCommonBatches(collegeId: string) {
    const commonBatchDefs = [
      { name: '2026-2030', admissionYear: 2026, graduationYear: 2030 },
      { name: '2025-2029', admissionYear: 2025, graduationYear: 2029 },
      { name: '2024-2028', admissionYear: 2024, graduationYear: 2028 },
      { name: '2023-2027', admissionYear: 2023, graduationYear: 2027 },
      { name: '2022-2026', admissionYear: 2022, graduationYear: 2026 },
      { name: '2021-2025', admissionYear: 2021, graduationYear: 2025 },
      { name: '2020-2024', admissionYear: 2020, graduationYear: 2024 },
    ];

    for (const def of commonBatchDefs) {
      const existing = await prisma.batch.findFirst({
        where: {
          college_id: collegeId,
          name: def.name,
        },
      });
      if (!existing) {
        await prisma.batch.create({
          data: {
            college_id: collegeId,
            name: def.name,
            admission_year: def.admissionYear,
            graduation_year: def.graduationYear,
            status: 'ACTIVE',
            department_id: null, // Common to all departments
          },
        });
      }
    }
  }

  async findBatches(collegeId: string, programId?: string, departmentId?: string) {
    await this.ensureCommonBatches(collegeId);
    return prisma.batch.findMany({
      where: {
        college_id: collegeId,
        ...(programId && { program_id: programId }),
        ...(departmentId ? { OR: [{ department_id: departmentId }, { department_id: null }] } : {}),
      },
      include: {
        program: { select: { id: true, name: true, code: true } },
        department: { select: { id: true, name: true, code: true } },
      },
      orderBy: { admission_year: 'desc' },
    });
  }

  async findBatchById(id: string) {
    return prisma.batch.findUnique({
      where: { id },
      include: {
        program: true,
        department: true,
      },
    });
  }

  async findBatchByName(collegeId: string, programId: string | undefined, name: string) {
    return prisma.batch.findFirst({
      where: {
        college_id: collegeId,
        ...(programId && { program_id: programId }),
        name: { equals: name, mode: 'insensitive' },
      },
    });
  }

  async createBatch(collegeId: string, dto: CreateBatchDto) {
    return prisma.batch.create({
      data: {
        college_id: collegeId,
        department_id: dto.departmentId,
        program_id: dto.programId,
        name: dto.name,
        admission_year: dto.admissionYear,
        graduation_year: dto.graduationYear,
        status: dto.status || 'ACTIVE',
      },
      include: {
        program: { select: { id: true, name: true, code: true } },
        department: { select: { id: true, name: true, code: true } },
      },
    });
  }

  async updateBatch(id: string, dto: UpdateBatchDto) {
    return prisma.batch.update({
      where: { id },
      data: {
        ...(dto.departmentId !== undefined && { department_id: dto.departmentId }),
        ...(dto.programId !== undefined && { program_id: dto.programId }),
        ...(dto.name && { name: dto.name }),
        ...(dto.admissionYear !== undefined && { admission_year: dto.admissionYear }),
        ...(dto.graduationYear !== undefined && { graduation_year: dto.graduationYear }),
        ...(dto.status && { status: dto.status }),
      },
      include: {
        program: { select: { id: true, name: true, code: true } },
        department: { select: { id: true, name: true, code: true } },
      },
    });
  }

  // ==========================================
  // SUBJECTS & COURSES
  // ==========================================
  async findSubjects(collegeId: string, departmentId?: string, semester?: string, academicTermId?: string) {
    return prisma.subject.findMany({
      where: {
        college_id: collegeId,
        ...(departmentId && { department_id: departmentId }),
        ...(semester && { semester }),
        ...(academicTermId && { academic_term_id: academicTermId }),
      },
      include: {
        department: { select: { id: true, name: true, code: true } },
        faculty: { select: { id: true, first_name: true, last_name: true, email: true } },
        academic_term: { select: { id: true, name: true } },
        _count: { select: { enrollments: true, resources: true } },
      },
      orderBy: { code: 'asc' },
    });
  }

  async findSubjectById(id: string) {
    return prisma.subject.findUnique({
      where: { id },
      include: {
        department: true,
        faculty: { select: { id: true, first_name: true, last_name: true, email: true } },
        academic_term: true,
        curriculum_subjects: { include: { program: true } },
        _count: { select: { enrollments: true, resources: true } },
      },
    });
  }

  async findSubjectByCodeAndSection(collegeId: string, code: string, semester: string, section: string) {
    return prisma.subject.findFirst({
      where: {
        college_id: collegeId,
        code: { equals: code, mode: 'insensitive' },
        semester,
        section,
      },
    });
  }

  async createSubject(collegeId: string, dto: CreateSubjectDto) {
    return prisma.subject.create({
      data: {
        college_id: collegeId,
        department_id: dto.departmentId,
        faculty_id: dto.facultyId,
        code: dto.code.toUpperCase(),
        name: dto.name,
        semester: dto.semester,
        section: dto.section || 'A',
        credits: dto.credits ?? 3,
        description: dto.description || null,
        subject_type: dto.subjectType || 'CORE',
        hours_per_week: dto.hoursPerWeek ?? 4,
        academic_year: dto.academicYear || null,
        academic_term_id: dto.academicTermId || null,
      },
      include: {
        department: { select: { id: true, name: true, code: true } },
        faculty: { select: { id: true, first_name: true, last_name: true, email: true } },
      },
    });
  }

  async updateSubject(id: string, dto: UpdateSubjectDto) {
    return prisma.subject.update({
      where: { id },
      data: {
        ...(dto.departmentId !== undefined && { department_id: dto.departmentId }),
        ...(dto.facultyId && { faculty_id: dto.facultyId }),
        ...(dto.code && { code: dto.code.toUpperCase() }),
        ...(dto.name && { name: dto.name }),
        ...(dto.semester && { semester: dto.semester }),
        ...(dto.section && { section: dto.section }),
        ...(dto.credits !== undefined && { credits: dto.credits }),
        ...(dto.description !== undefined && { description: dto.description }),
        ...(dto.subjectType && { subject_type: dto.subjectType }),
        ...(dto.hoursPerWeek !== undefined && { hours_per_week: dto.hoursPerWeek }),
        ...(dto.academicYear !== undefined && { academic_year: dto.academicYear }),
        ...(dto.academicTermId !== undefined && { academic_term_id: dto.academicTermId }),
      },
      include: {
        department: { select: { id: true, name: true, code: true } },
        faculty: { select: { id: true, first_name: true, last_name: true, email: true } },
      },
    });
  }

  // ==========================================
  // CURRICULUM SUBJECTS
  // ==========================================
  async findCurriculumSubjects(programId?: string, batchYear?: number, semesterNumber?: number) {
    return prisma.curriculumSubject.findMany({
      where: {
        ...(programId && { program_id: programId }),
        ...(batchYear && { batch_year: batchYear }),
        ...(semesterNumber && { semester_number: semesterNumber }),
      },
      include: {
        program: { select: { id: true, name: true, code: true } },
        subject: { select: { id: true, name: true, code: true, credits: true, subject_type: true } },
      },
      orderBy: [{ semester_number: 'asc' }, { created_at: 'asc' }],
    });
  }

  async createCurriculumSubject(dto: CreateCurriculumSubjectDto) {
    return prisma.curriculumSubject.create({
      data: {
        program_id: dto.programId,
        subject_id: dto.subjectId,
        batch_year: dto.batchYear,
        semester_number: dto.semesterNumber,
        subject_type: dto.subjectType || 'CORE',
        credits: dto.credits ?? 3,
        hours_per_week: dto.hoursPerWeek ?? 4,
        version: dto.version || 'v1',
      },
      include: {
        program: { select: { id: true, name: true, code: true } },
        subject: { select: { id: true, name: true, code: true } },
      },
    });
  }

  async deleteCurriculumSubject(id: string) {
    return prisma.curriculumSubject.delete({ where: { id } });
  }

  // ==========================================
  // ACADEMIC CLASSES
  // ==========================================
  async findAcademicClasses(collegeId: string, departmentId?: string, yearOfStudy?: number, semester?: number) {
    return prisma.academicClass.findMany({
      where: {
        college_id: collegeId,
        ...(departmentId && { department_id: departmentId }),
        ...(yearOfStudy && { year_of_study: yearOfStudy }),
        ...(semester && { semester }),
      },
      include: {
        department: { select: { id: true, name: true, code: true } },
        program: { select: { id: true, name: true, code: true } },
        class_advisor: { select: { id: true, first_name: true, last_name: true, email: true } },
        room: { select: { id: true, code: true, name: true, building: true } },
        _count: { select: { schedules: true } },
      },
      orderBy: [{ year_of_study: 'asc' }, { section: 'asc' }],
    });
  }

  async findAcademicClassById(id: string) {
    return prisma.academicClass.findUnique({
      where: { id },
      include: {
        department: true,
        program: true,
        class_advisor: { select: { id: true, first_name: true, last_name: true, email: true } },
        room: true,
      },
    });
  }

  async createAcademicClass(collegeId: string, dto: CreateAcademicClassDto) {
    return prisma.academicClass.create({
      data: {
        college_id: collegeId,
        department_id: dto.departmentId,
        program_id: dto.programId || null,
        name: dto.name,
        year_of_study: dto.yearOfStudy,
        semester: dto.semester,
        section: dto.section || 'A',
        class_advisor_id: dto.classAdvisorId || null,
        room_id: dto.roomId || null,
      },
      include: {
        department: { select: { id: true, name: true, code: true } },
        program: { select: { id: true, name: true, code: true } },
        class_advisor: { select: { id: true, first_name: true, last_name: true, email: true } },
        room: true,
      },
    });
  }

  async updateAcademicClass(id: string, dto: UpdateAcademicClassDto) {
    return prisma.academicClass.update({
      where: { id },
      data: {
        ...(dto.departmentId && { department_id: dto.departmentId }),
        ...(dto.programId !== undefined && { program_id: dto.programId }),
        ...(dto.name && { name: dto.name }),
        ...(dto.yearOfStudy !== undefined && { year_of_study: dto.yearOfStudy }),
        ...(dto.semester !== undefined && { semester: dto.semester }),
        ...(dto.section && { section: dto.section }),
        ...(dto.classAdvisorId !== undefined && { class_advisor_id: dto.classAdvisorId }),
        ...(dto.roomId !== undefined && { room_id: dto.roomId }),
      },
      include: {
        department: { select: { id: true, name: true, code: true } },
        program: { select: { id: true, name: true, code: true } },
        class_advisor: { select: { id: true, first_name: true, last_name: true, email: true } },
        room: true,
      },
    });
  }

  // ==========================================
  // ROOMS
  // ==========================================
  async findRooms(collegeId: string, filters?: { roomType?: string; isActive?: boolean }) {
    return prisma.room.findMany({
      where: {
        college_id: collegeId,
        ...(filters?.roomType && { room_type: filters.roomType }),
        ...(filters?.isActive !== undefined && { is_active: filters.isActive }),
      },
      include: {
        _count: { select: { schedules: true, classes: true } },
      },
      orderBy: { code: 'asc' },
    });
  }

  async findRoomById(id: string) {
    return prisma.room.findUnique({
      where: { id },
      include: {
        _count: { select: { schedules: true, classes: true } },
      },
    });
  }

  async findRoomByCode(collegeId: string, code: string) {
    return prisma.room.findUnique({
      where: {
        college_id_code: { college_id: collegeId, code },
      },
    });
  }

  async createRoom(collegeId: string, dto: CreateRoomDto) {
    return prisma.room.create({
      data: {
        college_id: collegeId,
        code: dto.code,
        name: dto.name,
        building: dto.building || null,
        floor: dto.floor ?? 1,
        capacity: dto.capacity ?? 60,
        room_type: dto.roomType || 'LECTURE_HALL',
      },
    });
  }

  async updateRoom(id: string, dto: UpdateRoomDto) {
    return prisma.room.update({
      where: { id },
      data: {
        ...(dto.code && { code: dto.code }),
        ...(dto.name && { name: dto.name }),
        ...(dto.building !== undefined && { building: dto.building }),
        ...(dto.floor !== undefined && { floor: dto.floor }),
        ...(dto.capacity !== undefined && { capacity: dto.capacity }),
        ...(dto.roomType && { room_type: dto.roomType }),
        ...(dto.isActive !== undefined && { is_active: dto.isActive }),
      },
    });
  }

  // ==========================================
  // FACULTY SUBJECT ASSIGNMENTS
  // ==========================================
  async findFacultyAssignments(params: {
    collegeId?: string;
    facultyId?: string;
    subjectId?: string;
    academicTermId?: string;
  }) {
    return prisma.facultySubjectAssignment.findMany({
      where: {
        ...(params.facultyId && { faculty_id: params.facultyId }),
        ...(params.subjectId && { subject_id: params.subjectId }),
        ...(params.academicTermId && { academic_term_id: params.academicTermId }),
        ...(params.collegeId && {
          faculty: { college_id: params.collegeId },
        }),
      },
      include: {
        faculty: { select: { id: true, first_name: true, last_name: true, email: true } },
        subject: { select: { id: true, name: true, code: true, semester: true } },
        term: { select: { id: true, name: true } },
      },
      orderBy: { created_at: 'desc' },
    });
  }

  async findFacultyAssignmentById(id: string) {
    return prisma.facultySubjectAssignment.findUnique({
      where: { id },
    });
  }

  async findFacultyAssignmentUnique(facultyId: string, subjectId: string, academicTermId: string, section: string) {
    return prisma.facultySubjectAssignment.findUnique({
      where: {
        faculty_id_subject_id_academic_term_id_section: {
          faculty_id: facultyId,
          subject_id: subjectId,
          academic_term_id: academicTermId,
          section,
        },
      },
    });
  }

  async createFacultyAssignment(dto: CreateFacultyAssignmentDto) {
    return prisma.facultySubjectAssignment.create({
      data: {
        faculty_id: dto.facultyId,
        subject_id: dto.subjectId,
        academic_term_id: dto.academicTermId,
        section: dto.section || 'A',
        role: dto.role || 'PRIMARY_INSTRUCTOR',
        is_primary: dto.isPrimary ?? true,
      },
      include: {
        faculty: { select: { id: true, first_name: true, last_name: true, email: true } },
        subject: { select: { id: true, name: true, code: true, semester: true } },
        term: { select: { id: true, name: true } },
      },
    });
  }

  async deleteFacultyAssignment(id: string) {
    return prisma.facultySubjectAssignment.delete({
      where: { id },
    });
  }

  // ==========================================
  // FACULTY SCHEDULES / TIMETABLE
  // ==========================================
  async findSchedules(params: {
    collegeId?: string;
    facultyId?: string;
    classId?: string;
    roomId?: string;
    dayOfWeek?: string;
    academicTermId?: string;
  }) {
    return prisma.facultySchedule.findMany({
      where: {
        status: { not: 'CANCELLED' },
        ...(params.facultyId && { faculty_id: params.facultyId }),
        ...(params.classId && { class_id: params.classId }),
        ...(params.roomId && { room_id: params.roomId }),
        ...(params.dayOfWeek && { day_of_week: params.dayOfWeek }),
        ...(params.academicTermId && { academic_term_id: params.academicTermId }),
        ...(params.collegeId && {
          faculty: { college_id: params.collegeId },
        }),
      },
      include: {
        faculty: { select: { id: true, first_name: true, last_name: true, email: true } },
        subject: { select: { id: true, code: true, name: true } },
        class: { select: { id: true, name: true, section: true } },
        room: { select: { id: true, code: true, name: true, building: true } },
        academic_term: { select: { id: true, name: true } },
      },
      orderBy: [{ day_of_week: 'asc' }, { start_time: 'asc' }],
    });
  }

  async findScheduleById(id: string) {
    return prisma.facultySchedule.findUnique({
      where: { id },
      include: {
        faculty: true,
        subject: true,
        class: true,
        room: true,
        academic_term: true,
      },
    });
  }

  async findPotentialConflicts(params: {
    dayOfWeek: string;
    roomId?: string;
    facultyId?: string;
    classId?: string;
    excludeScheduleId?: string;
  }) {
    const conditions: any[] = [];
    if (params.roomId) conditions.push({ room_id: params.roomId });
    if (params.facultyId) conditions.push({ faculty_id: params.facultyId });
    if (params.classId) conditions.push({ class_id: params.classId });

    if (conditions.length === 0) return [];

    return prisma.facultySchedule.findMany({
      where: {
        status: { not: 'CANCELLED' },
        day_of_week: params.dayOfWeek,
        ...(params.excludeScheduleId && { id: { not: params.excludeScheduleId } }),
        OR: conditions,
      },
      include: {
        faculty: { select: { id: true, first_name: true, last_name: true } },
        room: { select: { id: true, code: true, name: true } },
        class: { select: { id: true, name: true, section: true } },
      },
    });
  }

  async createSchedule(data: {
    facultyId: string;
    subjectId?: string;
    academicTermId?: string;
    classId?: string;
    roomId?: string;
    dayOfWeek: string;
    startTime: string;
    endTime: string;
    semester?: string;
    section?: string;
    topic?: string;
    sessionType?: string;
    status?: string;
    batchGroup?: string;
    subjectCode?: string;
    subjectName?: string;
    effectiveFrom?: Date;
    effectiveUntil?: Date;
  }) {
    return prisma.facultySchedule.create({
      data: {
        faculty_id: data.facultyId,
        subject_id: data.subjectId || null,
        academic_term_id: data.academicTermId || null,
        class_id: data.classId || null,
        room_id: data.roomId || null,
        day_of_week: data.dayOfWeek,
        start_time: data.startTime,
        end_time: data.endTime,
        semester: data.semester || null,
        section: data.section || 'A',
        topic: data.topic || null,
        session_type: data.sessionType || 'THEORY',
        status: data.status || 'SCHEDULED',
        batch_group: data.batchGroup || null,
        subject_code: data.subjectCode || null,
        subject_name: data.subjectName || null,
        effective_from: data.effectiveFrom || null,
        effective_until: data.effectiveUntil || null,
      },
      include: {
        faculty: { select: { id: true, first_name: true, last_name: true, email: true } },
        subject: { select: { id: true, code: true, name: true } },
        class: { select: { id: true, name: true, section: true } },
        room: { select: { id: true, code: true, name: true, building: true } },
        academic_term: { select: { id: true, name: true } },
      },
    });
  }

  async updateSchedule(
    id: string,
    data: {
      facultyId?: string;
      subjectId?: string;
      academicTermId?: string;
      classId?: string;
      roomId?: string;
      dayOfWeek?: string;
      startTime?: string;
      endTime?: string;
      semester?: string;
      section?: string;
      topic?: string;
      sessionType?: string;
      status?: string;
      batchGroup?: string;
      subjectCode?: string;
      subjectName?: string;
      effectiveFrom?: Date;
      effectiveUntil?: Date;
    }
  ) {
    return prisma.facultySchedule.update({
      where: { id },
      data: {
        ...(data.facultyId && { faculty_id: data.facultyId }),
        ...(data.subjectId !== undefined && { subject_id: data.subjectId }),
        ...(data.academicTermId !== undefined && { academic_term_id: data.academicTermId }),
        ...(data.classId !== undefined && { class_id: data.classId }),
        ...(data.roomId !== undefined && { room_id: data.roomId }),
        ...(data.dayOfWeek && { day_of_week: data.dayOfWeek }),
        ...(data.startTime && { start_time: data.startTime }),
        ...(data.endTime && { end_time: data.endTime }),
        ...(data.semester !== undefined && { semester: data.semester }),
        ...(data.section && { section: data.section }),
        ...(data.topic !== undefined && { topic: data.topic }),
        ...(data.sessionType && { session_type: data.sessionType }),
        ...(data.status && { status: data.status }),
        ...(data.batchGroup !== undefined && { batch_group: data.batchGroup }),
        ...(data.subjectCode !== undefined && { subject_code: data.subjectCode }),
        ...(data.subjectName !== undefined && { subject_name: data.subjectName }),
        ...(data.effectiveFrom !== undefined && { effective_from: data.effectiveFrom }),
        ...(data.effectiveUntil !== undefined && { effective_until: data.effectiveUntil }),
      },
      include: {
        faculty: { select: { id: true, first_name: true, last_name: true, email: true } },
        subject: { select: { id: true, code: true, name: true } },
        class: { select: { id: true, name: true, section: true } },
        room: { select: { id: true, code: true, name: true, building: true } },
        academic_term: { select: { id: true, name: true } },
      },
    });
  }

  async deleteSchedule(id: string) {
    return prisma.facultySchedule.delete({
      where: { id },
    });
  }

  // ==========================================
  // ACADEMIC MONITORING (PHASE 6)
  // ==========================================
  async getMonitoringMetrics(collegeId: string, departmentId?: string) {
    const subjectFilter = {
      college_id: collegeId,
      ...(departmentId && { department_id: departmentId }),
    };

    const [
      totalAttendanceSessions,
      attendanceAgg,
      totalAssignments,
      totalSubmissions,
      totalAssessments,
      scoreAgg,
    ] = await Promise.all([
      prisma.subjectAttendanceSession.count({
        where: { subject: subjectFilter },
      }),
      prisma.subjectAttendanceSession.aggregate({
        where: { subject: subjectFilter },
        _sum: {
          total_students: true,
          present_count: true,
        },
      }),
      prisma.subjectAssignment.count({
        where: { subject: subjectFilter },
      }),
      prisma.assignmentSubmission.count({
        where: { assignment: { subject: subjectFilter } },
      }),
      prisma.subjectAssessment.count({
        where: { subject: subjectFilter },
      }),
      prisma.studentAssessmentResult.aggregate({
        where: {
          marks_obtained: { not: null },
          subject: subjectFilter,
        },
        _avg: { marks_obtained: true },
      }),
    ]);

    const totalStudents = attendanceAgg._sum.total_students || 0;
    const totalPresent = attendanceAgg._sum.present_count || 0;
    const averageAttendanceRate = totalStudents > 0 ? Number(((totalPresent / totalStudents) * 100).toFixed(1)) : 0;
    const averageAssessmentScore = scoreAgg._avg.marks_obtained ? Number(scoreAgg._avg.marks_obtained.toFixed(1)) : 0;

    return {
      totalAttendanceSessions,
      averageAttendanceRate,
      totalAssignments,
      totalSubmissions,
      totalAssessments,
      averageAssessmentScore,
    };
  }

  async findAttendanceSessions(params: {
    collegeId: string;
    departmentId?: string;
    subjectId?: string;
    academicTermId?: string;
    facultyId?: string;
  }) {
    return prisma.subjectAttendanceSession.findMany({
      where: {
        subject: {
          college_id: params.collegeId,
          ...(params.departmentId && { department_id: params.departmentId }),
        },
        ...(params.subjectId && { subject_id: params.subjectId }),
        ...(params.academicTermId && { academic_term_id: params.academicTermId }),
        ...(params.facultyId && { faculty_id: params.facultyId }),
      },
      include: {
        subject: { select: { id: true, code: true, name: true, semester: true } },
        faculty: { select: { id: true, first_name: true, last_name: true, email: true } },
        academic_term: { select: { id: true, name: true } },
        _count: { select: { records: true } },
      },
      orderBy: { session_date: 'desc' },
      take: 100,
    });
  }

  async findAttendanceSessionById(id: string) {
    return prisma.subjectAttendanceSession.findUnique({
      where: { id },
      include: {
        subject: true,
        faculty: { select: { id: true, first_name: true, last_name: true, email: true } },
        records: {
          include: {
            student: { select: { id: true, first_name: true, last_name: true, email: true } },
          },
          orderBy: { student: { last_name: 'asc' } },
        },
      },
    });
  }

  async findSubjectAssignments(params: {
    collegeId: string;
    departmentId?: string;
    subjectId?: string;
    academicTermId?: string;
    facultyId?: string;
  }) {
    return prisma.subjectAssignment.findMany({
      where: {
        subject: {
          college_id: params.collegeId,
          ...(params.departmentId && { department_id: params.departmentId }),
        },
        ...(params.subjectId && { subject_id: params.subjectId }),
        ...(params.academicTermId && { academic_term_id: params.academicTermId }),
        ...(params.facultyId && { faculty_id: params.facultyId }),
      },
      include: {
        subject: { select: { id: true, code: true, name: true, semester: true } },
        faculty: { select: { id: true, first_name: true, last_name: true, email: true } },
        academic_term: { select: { id: true, name: true } },
        _count: { select: { submissions: true } },
      },
      orderBy: { created_at: 'desc' },
      take: 100,
    });
  }

  async findSubjectAssignmentById(id: string) {
    return prisma.subjectAssignment.findUnique({
      where: { id },
      include: {
        subject: true,
        faculty: { select: { id: true, first_name: true, last_name: true, email: true } },
        submissions: {
          include: {
            student: { select: { id: true, first_name: true, last_name: true, email: true } },
          },
          orderBy: { submitted_at: 'desc' },
        },
      },
    });
  }

  async findSubjectAssessments(params: {
    collegeId: string;
    departmentId?: string;
    subjectId?: string;
    academicTermId?: string;
    facultyId?: string;
  }) {
    return prisma.subjectAssessment.findMany({
      where: {
        subject: {
          college_id: params.collegeId,
          ...(params.departmentId && { department_id: params.departmentId }),
        },
        ...(params.subjectId && { subject_id: params.subjectId }),
        ...(params.academicTermId && { academic_term_id: params.academicTermId }),
        ...(params.facultyId && { faculty_id: params.facultyId }),
      },
      include: {
        subject: { select: { id: true, code: true, name: true, semester: true } },
        faculty: { select: { id: true, first_name: true, last_name: true, email: true } },
        academic_term: { select: { id: true, name: true } },
        _count: { select: { results: true } },
      },
      orderBy: { created_at: 'desc' },
      take: 100,
    });
  }

  async findSubjectAssessmentById(id: string) {
    return prisma.subjectAssessment.findUnique({
      where: { id },
      include: {
        subject: true,
        faculty: { select: { id: true, first_name: true, last_name: true, email: true } },
        results: {
          include: {
            student: { select: { id: true, first_name: true, last_name: true, email: true } },
          },
          orderBy: { marks_obtained: 'desc' },
        },
      },
    });
  }

  // ==========================================
  // PHASE 7: BROADCAST NOTIFICATIONS & MODERATION
  // ==========================================
  async findTargetUserIds(params: {
    collegeId: string;
    targetAudience: 'ALL' | 'STUDENTS' | 'FACULTY' | 'DEPARTMENT';
    departmentId?: string;
  }) {
    return prisma.user.findMany({
      where: {
        college_id: params.collegeId,
        status: UserStatus.ACTIVE,
        deleted_at: null,
        ...(params.targetAudience === 'STUDENTS' && { role: Role.STUDENT }),
        ...(params.targetAudience === 'FACULTY' && { role: Role.FACULTY }),
        ...(params.targetAudience === 'DEPARTMENT' && params.departmentId && { department_id: params.departmentId }),
      },
      select: { id: true },
    });
  }

  async createBroadcastNotifications(
    notifications: {
      user_id: string;
      title: string;
      body: string;
      type: NotificationType;
      category?: string;
    }[]
  ) {
    if (notifications.length === 0) return { count: 0 };
    return prisma.notification.createMany({
      data: notifications,
    });
  }

  async findModerationEvents(params: {
    collegeId: string;
    departmentId?: string;
    scope?: string;
  }) {
    return prisma.event.findMany({
      where: {
        college_id: params.collegeId,
        ...(params.departmentId && { department_id: params.departmentId }),
        ...(params.scope && { scope: params.scope }),
      },
      include: {
        organizer: { select: { id: true, first_name: true, last_name: true, email: true } },
        department: { select: { id: true, name: true, code: true } },
        club: { select: { id: true, name: true } },
        _count: { select: { registrations: true } },
      },
      orderBy: { created_at: 'desc' },
      take: 100,
    });
  }

  async findModerationEventById(id: string) {
    return prisma.event.findUnique({
      where: { id },
      include: {
        organizer: { select: { id: true, first_name: true, last_name: true, email: true } },
        department: { select: { id: true, name: true, code: true } },
        club: { select: { id: true, name: true } },
      },
    });
  }

  async deleteModerationEvent(id: string) {
    return prisma.event.delete({
      where: { id },
    });
  }

  async findModerationPosts(params: {
    collegeId: string;
    departmentId?: string;
    clubId?: string;
  }) {
    return prisma.post.findMany({
      where: {
        college_id: params.collegeId,
        ...(params.departmentId && { department_id: params.departmentId }),
        ...(params.clubId && { club_id: params.clubId }),
      },
      include: {
        author: { select: { id: true, first_name: true, last_name: true, email: true, role: true } },
        department: { select: { id: true, name: true, code: true } },
        club: { select: { id: true, name: true } },
        _count: { select: { comments: true, likes: true } },
      },
      orderBy: { created_at: 'desc' },
      take: 100,
    });
  }

  async findModerationPostById(id: string) {
    return prisma.post.findUnique({
      where: { id },
      include: {
        author: { select: { id: true, first_name: true, last_name: true, email: true, role: true } },
        department: { select: { id: true, name: true, code: true } },
        club: { select: { id: true, name: true } },
      },
    });
  }

  async deleteModerationPost(id: string) {
    return prisma.post.delete({
      where: { id },
    });
  }

  async getChangeRequests(collegeId: string, options: {
    status?: string;
    departmentId?: string;
    category?: string;
    page?: number;
    limit?: number;
  }) {
    const page = options.page || 1;
    const limit = options.limit || 20;
    const skip = (page - 1) * limit;

    let categoryFilter: any = undefined;
    let fieldFilter: any = undefined;

    if (options.category) {
      const cat = options.category.toUpperCase().trim();
      if (cat === 'PERSONAL' || cat === 'PERSONAL_CHANGE') {
        categoryFilter = 'PERSONAL_CHANGE';
      } else if (cat === 'ACADEMIC' || cat === 'ACADEMIC_IDENTITY_CHANGE') {
        categoryFilter = 'ACADEMIC_IDENTITY_CHANGE';
      } else if (cat === 'CAREER' || cat === 'CAREER_PROFILE_CHANGE') {
        categoryFilter = 'CAREER_PROFILE_CHANGE';
      } else if (cat === 'CONTACT') {
        categoryFilter = 'PERSONAL_CHANGE';
        fieldFilter = { in: ['phone', 'father_phone', 'mother_phone', 'guardian_phone', 'emergency_contact_phone', 'permanent_address', 'current_address', 'permanent_city', 'current_city'] };
      } else if (cat === 'EMERGENCY') {
        categoryFilter = 'PERSONAL_CHANGE';
        fieldFilter = { in: ['emergency_contact_name', 'emergency_contact_phone', 'emergency_contact_relation'] };
      } else if (['PERSONAL_CHANGE', 'ACADEMIC_IDENTITY_CHANGE', 'CAREER_PROFILE_CHANGE'].includes(cat)) {
        categoryFilter = cat;
      }
    }

    let statusFilter: any = undefined;
    if (options.status) {
      const st = options.status.toUpperCase().trim();
      if (['PENDING', 'APPROVED', 'REJECTED', 'CANCELLED'].includes(st)) {
        statusFilter = st;
      }
    }

    const where: any = {
      college_id: collegeId,
      ...(statusFilter && { status: statusFilter }),
      ...(categoryFilter && { category: categoryFilter }),
      ...(fieldFilter && { field: fieldFilter }),
      ...(options.departmentId && {
        student: { department_id: options.departmentId },
      }),
    };

    const [total, items] = await Promise.all([
      prisma.profileChangeRequest.count({ where }),
      prisma.profileChangeRequest.findMany({
        where,
        skip,
        take: limit,
        orderBy: { submitted_at: 'desc' },
        include: {
          student: {
            select: {
              id: true,
              first_name: true,
              last_name: true,
              email: true,
              roll_number: true,
              department: {
                select: { id: true, name: true, code: true },
              },
            },
          },
          reviewer: {
            select: {
              id: true,
              first_name: true,
              last_name: true,
              email: true,
            },
          },
        },
      }),
    ]);

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  async getChangeRequestById(requestId: string, collegeId: string) {
    return prisma.profileChangeRequest.findFirst({
      where: { id: requestId, college_id: collegeId },
      include: {
        student: {
          select: {
            id: true,
            first_name: true,
            last_name: true,
            email: true,
            phone: true,
            roll_number: true,
            department: {
              select: { id: true, name: true, code: true },
            },
          },
        },
        reviewer: {
          select: {
            id: true,
            first_name: true,
            last_name: true,
            email: true,
          },
        },
      },
    });
  }

  async approveChangeRequest(requestId: string, reviewerId: string, reviewComment?: string) {
    return prisma.$transaction(async (tx) => {
      const request = await tx.profileChangeRequest.findUnique({
        where: { id: requestId },
        include: { student: true },
      });

      if (!request) {
        throw new NotFoundError('Change request not found');
      }

      if (request.status !== 'PENDING') {
        throw new BadRequestError(`Cannot approve change request with status ${request.status}`);
      }

      const studentId = request.student_id;
      const field = request.field;
      const value = request.requested_value;
      const normField = field.toLowerCase().replace(/_/g, '');

      if (normField === 'firstname') {
        await tx.user.update({ where: { id: studentId }, data: { first_name: value } });
      } else if (normField === 'lastname') {
        await tx.user.update({ where: { id: studentId }, data: { last_name: value } });
      } else if (normField === 'phone') {
        await tx.user.update({ where: { id: studentId }, data: { phone: value } });
      } else if (normField === 'rollnumber') {
        await tx.user.update({ where: { id: studentId }, data: { roll_number: value } });
      } else if (normField === 'batchname') {
        await tx.studentAcademicProfile.updateMany({
          where: { student_id: studentId },
          data: { batch_name: value },
        });
      } else if (normField === 'section') {
        await tx.studentAcademicProfile.updateMany({
          where: { student_id: studentId },
          data: { section: value },
        });
      } else {
        const spData: any = {};
        if (normField === 'dob') spData.dob = new Date(value);
        else if (normField === 'fathername') spData.father_name = value;
        else if (normField === 'fatherphone') spData.father_phone = value;
        else if (normField === 'mothername') spData.mother_name = value;
        else if (normField === 'motherphone') spData.mother_phone = value;
        else if (normField === 'guardianname') spData.guardian_name = value;
        else if (normField === 'guardianphone') spData.guardian_phone = value;
        else if (normField === 'bloodgroup') spData.blood_group = value;
        else if (normField === 'emergencycontactname') spData.emergency_contact_name = value;
        else if (normField === 'emergencycontactrelation') spData.emergency_contact_relation = value;
        else if (normField === 'emergencycontactphone') spData.emergency_contact_phone = value;
        else if (normField === 'permanentaddress') spData.permanent_address = value;
        else if (normField === 'permanentcity') spData.permanent_city = value;
        else if (normField === 'permanentstate') spData.permanent_state = value;
        else if (normField === 'permanentpincode') spData.permanent_pincode = value;
        else if (normField === 'currentaddress') spData.current_address = value;
        else if (normField === 'currentcity') spData.current_city = value;
        else if (normField === 'currentstate') spData.current_state = value;
        else if (normField === 'currentpincode') spData.current_pincode = value;
        else if (normField === 'tenthpercentage') spData.tenth_percentage = parseFloat(value.replace('%', ''));
        else if (normField === 'twelfthpercentage') spData.twelfth_percentage = parseFloat(value.replace('%', ''));
        else if (normField === 'registrationnumber') spData.registration_number = value;

        if (Object.keys(spData).length > 0) {
          await tx.studentProfile.upsert({
            where: { user_id: studentId },
            create: { user_id: studentId, ...spData },
            update: spData,
          });
        }
      }

      const updated = await tx.profileChangeRequest.update({
        where: { id: requestId },
        data: {
          status: 'APPROVED',
          reviewed_at: new Date(),
          reviewed_by: reviewerId,
          review_comment: reviewComment,
        },
      });

      return { request: updated, student: request.student };
    });
  }

  async rejectChangeRequest(requestId: string, reviewerId: string, rejectionReason: string) {
    const request = await prisma.profileChangeRequest.findUnique({
      where: { id: requestId },
      include: { student: true },
    });

    if (!request) {
      throw new NotFoundError('Change request not found');
    }

    if (request.status !== 'PENDING') {
      throw new BadRequestError(`Cannot reject change request with status ${request.status}`);
    }

    const updated = await prisma.profileChangeRequest.update({
      where: { id: requestId },
      data: {
        status: 'REJECTED',
        reviewed_at: new Date(),
        reviewed_by: reviewerId,
        review_comment: rejectionReason,
      },
    });

    return { request: updated, student: request.student };
  }
}

