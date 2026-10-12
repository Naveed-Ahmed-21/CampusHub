import { PrismaClient, Role, UserStatus, DriveStatus } from '@prisma/client';
import { prisma } from '../../config/database';
import { ForbiddenError, NotFoundError, BadRequestError, ConflictError } from '../../shared/errors/AppError';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationsRepository } from '../notifications/notifications.repository';

export class DeptAdminService {
  private notificationsService: NotificationsService;

  constructor(notificationsService?: NotificationsService) {
    this.notificationsService = notificationsService ?? new NotificationsService(new NotificationsRepository());
  }

  public resolveDeptId(
    user: { id?: string; role: string; departmentId?: string | null },
    queryDeptId?: string
  ): string {
    if (user.role === Role.DEPT_ADMIN) {
      if (!user.departmentId) {
        throw new ForbiddenError('Department Administrator is not associated with any department');
      }
      if (queryDeptId && queryDeptId !== user.departmentId) {
        throw new ForbiddenError('Department Administrator can only access their own department');
      }
      return user.departmentId;
    }

    if (user.role === Role.ADMIN) {
      if (queryDeptId) return queryDeptId;
      if (user.departmentId) return user.departmentId;
      throw new BadRequestError('Department ID is required for administrative query');
    }

    throw new ForbiddenError('Access restricted to Department Administrators and Administrators');
  }

  private async getEffectiveDeptId(
    collegeId: string,
    user: { id?: string; role: string; departmentId?: string | null },
    queryDeptId?: string
  ): Promise<string> {
    try {
      return this.resolveDeptId(user, queryDeptId);
    } catch (err) {
      // If user is ADMIN without queryDeptId or departmentId, fallback to first department of college
      if (user.role === Role.ADMIN && (!queryDeptId && !user.departmentId)) {
        const firstDept = await prisma.department.findFirst({
          where: collegeId ? { college_id: collegeId } : undefined,
          orderBy: { code: 'asc' },
        });
        if (firstDept) return firstDept.id;
      }
      // If user is DEPT_ADMIN without departmentId on token, fallback to DB
      if (user.role === Role.DEPT_ADMIN && !user.departmentId && user.id) {
        const dbUser = await prisma.user.findUnique({
          where: { id: user.id },
          select: { department_id: true },
        });
        if (dbUser?.department_id) {
          if (queryDeptId && queryDeptId !== dbUser.department_id) {
            throw new ForbiddenError('Department Administrator can only access their own department');
          }
          return dbUser.department_id;
        }
      }
      throw err;
    }
  }

  // 1. DASHBOARD & OVERVIEW
  async getDashboard(collegeId: string, user: { id?: string; role: string; departmentId?: string | null }, queryDeptId?: string) {
    const deptId = await this.getEffectiveDeptId(collegeId, user, queryDeptId);

    const dept = await prisma.department.findUnique({
      where: { id: deptId },
      include: {
        academic_programs: true,
      },
    });

    if (!dept || dept.college_id !== collegeId) {
      throw new NotFoundError('Department not found');
    }

    const activeYear = (await prisma.academicYear.findFirst({
      where: { college_id: collegeId, is_active: true },
    })) || (await prisma.academicYear.findFirst({
      where: { college_id: collegeId },
      orderBy: { start_date: 'desc' },
    }));

    const activeTerm = activeYear
      ? await prisma.academicTerm.findFirst({
          where: { academic_year_id: activeYear.id, status: 'ACTIVE' },
        })
      : null;

    // Counts
    const [totalStudents, totalFaculty, totalClasses, totalSubjects] = await Promise.all([
      prisma.user.count({
        where: { college_id: collegeId, department_id: deptId, role: Role.STUDENT, status: { not: UserStatus.DEACTIVATED } },
      }),
      prisma.user.count({
        where: { college_id: collegeId, department_id: deptId, role: Role.FACULTY, status: { not: UserStatus.DEACTIVATED } },
      }),
      prisma.academicClass.count({
        where: { college_id: collegeId, department_id: deptId },
      }),
      prisma.subject.count({
        where: { college_id: collegeId, department_id: deptId },
      }),
    ]);

    // Active Placement Drives relevant to IT
    const drives = await prisma.placementDrive.findMany({
      where: {
        college_id: collegeId,
        status: { in: [DriveStatus.ONGOING, DriveStatus.UPCOMING] },
      },
      select: {
        id: true,
        allowed_departments: true,
      },
    });

    const relevantDrivesCount = drives.filter((d) => {
      const depts = (d.allowed_departments as string[]) || [];
      return depts.length === 0 || depts.includes(dept.code) || depts.includes(dept.id);
    }).length;

    const isBTech = dept.code.toUpperCase() === 'IT';
    const degreeName = isBTech ? 'B.Tech' : 'B.E.';

    const [
      upcomingAssessmentsCount,
      assignmentsDeadlinesCount,
      recentAnnouncementsCount,
      attTotal,
      attPresent,
      eligibleStudents,
    ] = await Promise.all([
      prisma.subjectAssessment.count({
        where: {
          subject: { college_id: collegeId, department_id: deptId },
          scheduled_at: { gte: new Date() },
        },
      }),
      prisma.subjectAssignment.count({
        where: {
          subject: { college_id: collegeId, department_id: deptId },
          due_at: { gte: new Date() },
        },
      }),
      prisma.subjectAnnouncement.count({
        where: {
          subject: { college_id: collegeId, department_id: deptId },
        },
      }),
      prisma.studentAttendanceRecord.count({
        where: {
          student: { college_id: collegeId, department_id: deptId },
        },
      }),
      prisma.studentAttendanceRecord.count({
        where: {
          student: { college_id: collegeId, department_id: deptId },
          status: 'PRESENT',
        },
      }),
      prisma.user.count({
        where: {
          college_id: collegeId,
          department_id: deptId,
          role: Role.STUDENT,
          portfolio: { cgpa: { gte: 6.0 } },
        },
      }),
    ]);

    const avgAttendance = attTotal > 0 ? Math.round((attPresent / attTotal) * 100) : 0;

    return {
      department: {
        id: dept.id,
        name: dept.name,
        code: dept.code,
        degree: degreeName,
        collegeName: 'Government College of Engineering, Erode',
      },
      academicYear: activeYear?.year_name || '2026-2027',
      semester: activeTerm?.term_type === 'ODD'
          ? 'Odd Semester'
          : (activeTerm?.term_type === 'EVEN'
              ? 'Even Semester'
              : (activeTerm?.name?.toLowerCase().includes('semester 1')
                  ? 'Odd Semester'
                  : (activeTerm?.name || 'Academic Term'))),
      kpis: {
        totalStudents,
        totalFaculty,
        totalClasses,
        totalSubjects,
        avgAttendance,
        activePlacementDrives: relevantDrivesCount,
        eligibleStudents,
      },
      alerts: {
        lowAttendanceCount: 0,
        activeDrivesCount: relevantDrivesCount,
        upcomingAssessmentsCount,
        assignmentsDeadlinesCount,
        recentAnnouncementsCount,
      },
    };
  }

  // 2. STUDENTS (Scoped to Department)
  async getStudents(
    collegeId: string,
    user: { id?: string; role: string; departmentId?: string | null },
    query: {
      year?: string | number;
      batchId?: string;
      section?: string;
      search?: string;
      placementStatus?: string;
      page?: number;
      limit?: number;
    }
  ) {
    const deptId = await this.getEffectiveDeptId(collegeId, user);
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.max(1, Math.min(100, Number(query.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {
      college_id: collegeId,
      department_id: deptId,
      role: Role.STUDENT,
      status: { not: UserStatus.DEACTIVATED },
    };

    if (query.search && query.search.trim()) {
      const term = query.search.trim();
      where.OR = [
        { first_name: { contains: term, mode: 'insensitive' } },
        { last_name: { contains: term, mode: 'insensitive' } },
        { roll_number: { contains: term, mode: 'insensitive' } },
        { email: { contains: term, mode: 'insensitive' } },
      ];
    }

    if (query.year && query.year !== 'All') {
      const y = parseInt(query.year.toString(), 10);
      if (!isNaN(y)) {
        where.academic_profile = {
          current_year: y,
        };
      }
    }

    if (query.batchId) {
      where.academic_profile = {
        ...(where.academic_profile || {}),
        batch_id: query.batchId,
      };
    }

    if (query.section) {
      where.academic_profile = {
        ...(where.academic_profile || {}),
        section: query.section,
      };
    }

    const [total, students] = await Promise.all([
      prisma.user.count({ where }),
      prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { roll_number: 'asc' },
        include: {
          student_profile: true,
          academic_profile: {
            include: { batch: true, program: true },
          },
          portfolio: true,
        },
      }),
    ]);

    const mapped = await Promise.all(
      students.map(async (s) => {
        const ap = s.academic_profile;
        const port = s.portfolio;
        const calculatedYear = ap?.current_year || 1;

        // Query real attendance
        const [attTotal, attPresent] = await Promise.all([
          prisma.studentAttendanceRecord.count({ where: { student_id: s.id } }),
          prisma.studentAttendanceRecord.count({ where: { student_id: s.id, status: 'PRESENT' } }),
        ]);
        const attendance = attTotal > 0 ? Math.round((attPresent / attTotal) * 100) : 0;

        // Query real placement status
        const app = await prisma.placementApplication.findFirst({
          where: { student_id: s.id },
          orderBy: { applied_at: 'desc' },
        });
        let placementStatus = 'ELIGIBLE';
        if (app) {
          if (app.status === 'OFFERED') placementStatus = 'PLACED';
          else if (app.status === 'SHORTLISTED') placementStatus = 'SHORTLISTED';
          else placementStatus = 'APPLIED';
        } else if (port?.cgpa && Number(port.cgpa) < 6.0) {
          placementStatus = 'NOT_ELIGIBLE';
        }

        return {
          id: s.id,
          name: `${s.first_name} ${s.last_name}`.trim(),
          rollNumber: s.roll_number || s.student_profile?.registration_number || 'N/A',
          regNumber: s.student_profile?.registration_number || s.roll_number || 'N/A',
          email: s.email,
          avatarUrl: s.avatar_url,
          year: calculatedYear,
          yearLabel: `${calculatedYear}th Year`,
          batch: ap?.batch_name || ap?.batch?.name || 'Batch 2027',
          section: ap?.section ? `IT-${ap.section}` : 'IT-A',
          cgpa: port?.cgpa != null ? Number(port.cgpa) : 0.0,
          attendance,
          placementStatus,
        };
      })
    );

    return {
      total,
      page,
      limit,
      students: mapped,
    };
  }

  // 3. STUDENT DETAIL (Scoped with strict 403 enforcement)
  async getStudentById(collegeId: string, user: { id?: string; role: string; departmentId?: string | null }, studentId: string) {
    const deptId = await this.getEffectiveDeptId(collegeId, user);

    const student = await prisma.user.findUnique({
      where: { id: studentId },
      include: {
        department: true,
        student_profile: true,
        academic_profile: {
          include: { batch: true, program: true },
        },
        portfolio: {
          include: { skills: true, projects: true, certificates: true },
        },
        applications: {
          include: { drive: true },
          orderBy: { applied_at: 'desc' },
        },
      },
    });

    if (!student || student.college_id !== collegeId) {
      throw new NotFoundError('Student not found');
    }

    if (student.department_id !== deptId) {
      throw new ForbiddenError('Department administrators can only view students in their own department');
    }

    const rawStudent = student as any;
    const ap = rawStudent.academic_profile;
    const sp = rawStudent.student_profile;
    const port = rawStudent.portfolio;

    const [attTotal, attPresent] = await Promise.all([
      prisma.studentAttendanceRecord.count({ where: { student_id: studentId } }),
      prisma.studentAttendanceRecord.count({ where: { student_id: studentId, status: 'PRESENT' } }),
    ]);
    const attendance = attTotal > 0 ? Math.round((attPresent / attTotal) * 100) : 0;

    const recentActivity = (rawStudent.applications || []).slice(0, 5).map((app: any) => ({
      title: `Applied for ${app.drive?.company_name || 'Placement Drive'} - ${app.drive?.role_title || ''}`.trim(),
      date: new Date(app.applied_at || Date.now()).toLocaleDateString(),
      type: app.status,
    }));

    const enrollments = await prisma.subjectEnrollment.findMany({
      where: { student_id: studentId },
      include: { subject: true },
    });
    const courses = enrollments.map((en) => ({
      code: en.subject?.code || 'SUB',
      name: en.subject?.name || 'Subject',
      attendance: `${attendance}%`,
      internal: 'N/A',
    }));

    return {
      id: rawStudent.id,
      name: `${rawStudent.first_name} ${rawStudent.last_name}`.trim(),
      email: rawStudent.email,
      phone: rawStudent.phone || sp?.emergency_contact_phone || 'Not provided',
      avatarUrl: rawStudent.avatar_url,
      regNumber: sp?.registration_number || rawStudent.roll_number || 'N/A',
      rollNumber: rawStudent.roll_number || 'N/A',
      department: rawStudent.department?.name || '',
      degree: rawStudent.department?.code === 'IT' ? 'B.Tech' : 'B.E.',
      year: ap?.current_year || 1,
      batch: ap?.batch_name || ap?.batch?.name || 'N/A',
      section: ap?.section ? `${rawStudent.department?.code || ''}-${ap.section}` : '',
      cgpa: port?.cgpa != null ? Number(port.cgpa) : 0.0,
      attendance,
      backlogs: 0,
      placementStatus: rawStudent.applications?.some((a: any) => a.status === 'OFFERED') ? 'PLACED' : 'ELIGIBLE',
      skills: (port?.skills || []).map((sk: any) => sk.skill_name),
      projectsCount: port?.projects?.length || 0,
      certificationsCount: port?.certificates?.length || 0,
      applicationsCount: rawStudent.applications?.length || 0,
      offersCount: rawStudent.applications?.filter((a: any) => a.status === 'OFFERED').length || 0,
      courses,
      recentActivity,
    };
  }

  // 4. FACULTY (Scoped to Department)
  async getFaculty(
    collegeId: string,
    user: { id?: string; role: string; departmentId?: string | null },
    query: { search?: string; designation?: string; page?: number; limit?: number }
  ) {
    const deptId = await this.getEffectiveDeptId(collegeId, user);
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.max(1, Math.min(100, Number(query.limit) || 20));
    const skip = (page - 1) * limit;

    const where: any = {
      college_id: collegeId,
      department_id: deptId,
      role: Role.FACULTY,
      status: { not: UserStatus.DEACTIVATED },
    };

    if (query.search && query.search.trim()) {
      const term = query.search.trim();
      where.OR = [
        { first_name: { contains: term, mode: 'insensitive' } },
        { last_name: { contains: term, mode: 'insensitive' } },
        { email: { contains: term, mode: 'insensitive' } },
      ];
    }

    const [total, facultyList] = await Promise.all([
      prisma.user.count({ where }),
      prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { first_name: 'asc' },
        include: {
          faculty_profile: true,
          faculty_subjects: { select: { code: true, name: true } },
          faculty_assignments: {
            include: { subject: { select: { code: true, name: true } } },
          },
          faculty_schedules: {
            select: { section: true, room_or_venue: true },
          },
        },
      }),
    ]);

    const mapped = (facultyList as any[]).map((f) => {
      const subjects: string[] = [
        ...(f.faculty_subjects || []).map((s: any) => s.code),
        ...(f.faculty_assignments || []).map((a: any) => a.subject?.code).filter(Boolean),
      ];
      const uniqueSubjects = Array.from(new Set(subjects));
      const scheduledClasses = Array.from(
        new Set(
          (f.faculty_schedules || [])
            .map((s: any) => (s.section ? `Section ${s.section}` : s.room_or_venue))
            .filter(Boolean)
        )
      ) as string[];

      return {
        id: f.id,
        name: `${f.first_name} ${f.last_name}`.trim(),
        email: f.email,
        avatarUrl: f.avatar_url,
        designation: f.faculty_profile?.designation || 'Faculty Member',
        assignedSubjects: uniqueSubjects,
        classes: scheduledClasses,
        workloadHours: (f.faculty_schedules || []).length,
        status: f.status,
      };
    });

    return {
      total,
      page,
      limit,
      faculty: mapped,
    };
  }

  // 5. FACULTY DETAIL (Scoped with strict 403 enforcement)
  async getFacultyById(collegeId: string, user: { id?: string; role: string; departmentId?: string | null }, facultyId: string) {
    const deptId = await this.getEffectiveDeptId(collegeId, user);

    const faculty = await prisma.user.findUnique({
      where: { id: facultyId },
      include: {
        department: true,
        faculty_profile: true,
        faculty_subjects: true,
        faculty_assignments: {
          include: { subject: true },
        },
        faculty_schedules: {
          include: { room: true },
        },
      },
    });

    if (!faculty || faculty.college_id !== collegeId) {
      throw new NotFoundError('Faculty member not found');
    }

    if (faculty.department_id !== deptId) {
      throw new ForbiddenError('Department administrators can only view faculty in their own department');
    }

    const rawFaculty = faculty as any;
    const subjects = [
      ...(rawFaculty.faculty_subjects || []).map((s: any) => ({
        id: s.id,
        code: s.code,
        name: s.name,
        credits: s.credits,
      })),
      ...(rawFaculty.faculty_assignments || []).map((a: any) => ({
        id: a.subject?.id,
        code: a.subject?.code,
        name: a.subject?.name,
        credits: a.subject?.credits,
      })).filter((s: any) => s.id),
    ];

    return {
      id: rawFaculty.id,
      name: `${rawFaculty.first_name} ${rawFaculty.last_name}`.trim(),
      email: rawFaculty.email,
      avatarUrl: rawFaculty.avatar_url,
      designation: rawFaculty.faculty_profile?.designation || 'Faculty',
      qualification: rawFaculty.faculty_profile?.qualification || '',
      department: rawFaculty.department?.name || '',
      bio: rawFaculty.faculty_profile?.bio || '',
      officeRoom: rawFaculty.faculty_profile?.office_room || '',
      subjects,
      schedules: (rawFaculty.faculty_schedules || []).map((sc: any) => ({
        id: sc.id,
        day: sc.day_of_week,
        startTime: sc.start_time,
        endTime: sc.end_time,
        subjectCode: sc.subject_code,
        subjectName: sc.subject_name,
        room: sc.room?.name || sc.venue || '',
      })),
    };
  }

  // 6. ACADEMICS OVERVIEW (Batches, Classes, Subjects)
  async getAcademics(collegeId: string, user: { id?: string; role: string; departmentId?: string | null }) {
    const deptId = await this.getEffectiveDeptId(collegeId, user);

    const dept = await prisma.department.findUnique({
      where: { id: deptId },
      include: { academic_programs: true },
    });

    const activeYear = (await prisma.academicYear.findFirst({
      where: { college_id: collegeId, is_active: true },
    })) || (await prisma.academicYear.findFirst({
      where: { college_id: collegeId },
      orderBy: { start_date: 'desc' },
    }));

    const [batches, classes, subjects] = await Promise.all([
      prisma.batch.findMany({
        where: { college_id: collegeId, department_id: deptId },
        orderBy: { admission_year: 'desc' },
      }),
      prisma.academicClass.findMany({
        where: { college_id: collegeId, department_id: deptId },
        orderBy: [{ year_of_study: 'desc' }, { section: 'asc' }],
      }),
      prisma.subject.findMany({
        where: { college_id: collegeId, department_id: deptId },
        include: { faculty: true },
        orderBy: { code: 'asc' },
      }),
    ]);

    return {
      department: {
        id: dept?.id,
        name: dept?.name,
        code: dept?.code,
        degree: dept?.code === 'IT' ? 'B.Tech' : 'B.E.',
      },
      academicYear: activeYear?.year_name || '2026-2027',
      semester: 'Even Semester',
      batches: batches.map((b) => ({
        id: b.id,
        name: b.name,
        yearLabel: `${2027 - b.admission_year}th Year`,
        admissionYear: b.admission_year,
        graduationYear: b.graduation_year,
      })),
      classes: classes.map((c) => ({
        id: c.id,
        name: c.name,
        section: c.section,
        yearOfStudy: c.year_of_study,
        studentCount: c.name.includes('A') ? 62 : c.name.includes('B') ? 60 : 58,
      })),
      subjects: subjects.map((s) => ({
        id: s.id,
        code: s.code,
        name: s.name,
        credits: s.credits,
        facultyName: s.faculty ? `${s.faculty.first_name} ${s.faculty.last_name}`.trim() : 'Unassigned',
        classesCount: 2,
        studentCount: 62,
      })),
    };
  }

  // 7. TIMETABLE
  async getTimetable(
    collegeId: string,
    user: { id?: string; role: string; departmentId?: string | null },
    query: { dayOfWeek?: string; classId?: string }
  ) {
    const deptId = await this.getEffectiveDeptId(collegeId, user);
    const day = query.dayOfWeek ? query.dayOfWeek.toUpperCase() : 'MONDAY';

    const schedules = await prisma.facultySchedule.findMany({
      where: {
        class: { department_id: deptId },
        day_of_week: day,
      },
      include: {
        faculty: true,
        subject: true,
        class: true,
        room: true,
      },
      orderBy: { start_time: 'asc' },
    });

    return schedules.map((sc) => ({
      id: sc.id,
      day: sc.day_of_week,
      startTime: sc.start_time,
      endTime: sc.end_time,
      subjectCode: sc.subject_code || sc.subject?.code || '',
      subjectName: sc.subject_name || sc.subject?.name || '',
      facultyName: sc.faculty ? `${sc.faculty.first_name} ${sc.faculty.last_name}`.trim() : 'Faculty',
      room: sc.room?.name || (sc as any).room_or_venue || '',
      className: sc.class?.name || '',
    }));
  }

  // 8. TIMETABLE CONFLICT CHECK & CREATION
  async createTimetableSlot(
    collegeId: string,
    user: { id?: string; role: string; departmentId?: string | null },
    dto: {
      facultyId: string;
      subjectId: string;
      classId: string;
      roomId?: string;
      dayOfWeek: string;
      startTime: string;
      endTime: string;
    }
  ) {
    const deptId = await this.getEffectiveDeptId(collegeId, user);

    if (!dto.classId || !dto.facultyId || !dto.subjectId || !dto.dayOfWeek || !dto.startTime || !dto.endTime) {
      throw new BadRequestError('classId, facultyId, subjectId, dayOfWeek, startTime, and endTime are required');
    }

    if (dto.startTime >= dto.endTime) {
      throw new BadRequestError('Start time must precede end time');
    }

    const academicClass = await prisma.academicClass.findUnique({
      where: { id: dto.classId },
    });
    if (!academicClass || academicClass.department_id !== deptId) {
      throw new ForbiddenError('Class does not belong to your department');
    }

    const faculty = await prisma.user.findUnique({
      where: { id: dto.facultyId },
    });
    if (!faculty || faculty.department_id !== deptId) {
      throw new ForbiddenError('Faculty does not belong to your department');
    }

    const subject = await prisma.subject.findUnique({
      where: { id: dto.subjectId },
    });
    if (!subject || subject.department_id !== deptId) {
      throw new ForbiddenError('Subject does not belong to your department');
    }

    // Overlap conflict detection
    const conflicts = await prisma.facultySchedule.findMany({
      where: {
        day_of_week: dto.dayOfWeek.toUpperCase(),
        OR: [
          { faculty_id: dto.facultyId },
          { class_id: dto.classId },
          ...(dto.roomId ? [{ room_id: dto.roomId }] : []),
        ],
      },
      include: { faculty: true, class: true, room: true },
    });

    const isOverlap = (s1: string, e1: string, s2: string, e2: string) => s1 < e2 && s2 < e1;

    for (const c of conflicts) {
      if (isOverlap(c.start_time, c.end_time, dto.startTime, dto.endTime)) {
        if (c.faculty_id === dto.facultyId) {
          throw new ConflictError(
            `Timetable Conflict: ${c.faculty?.first_name} ${c.faculty?.last_name} is already assigned on ${dto.dayOfWeek} from ${c.start_time} to ${c.end_time}`
          );
        }
        if (c.class_id === dto.classId) {
          throw new ConflictError(
            `Timetable Conflict: Class ${c.class?.name} is already scheduled on ${dto.dayOfWeek} from ${c.start_time} to ${c.end_time}`
          );
        }
        if (dto.roomId && c.room_id === dto.roomId) {
          throw new ConflictError(
            `Timetable Conflict: Room ${c.room?.name || dto.roomId} is already occupied on ${dto.dayOfWeek} from ${c.start_time} to ${c.end_time}`
          );
        }
      }
    }

    const schedule = await prisma.facultySchedule.create({
      data: {
        faculty_id: dto.facultyId,
        subject_id: dto.subjectId,
        class_id: dto.classId,
        room_id: dto.roomId,
        day_of_week: dto.dayOfWeek.toUpperCase(),
        start_time: dto.startTime,
        end_time: dto.endTime,
        subject_code: subject.code,
        subject_name: subject.name,
      },
    });

    return schedule;
  }

  // 9. ATTENDANCE OVERVIEW
  async getAttendance(collegeId: string, user: { id?: string; role: string; departmentId?: string | null }) {
    const deptId = await this.getEffectiveDeptId(collegeId, user);

    const [attTotal, attPresent, attAbsent, attOnLeave, subjects, students] = await Promise.all([
      prisma.studentAttendanceRecord.count({
        where: { student: { college_id: collegeId, department_id: deptId } },
      }),
      prisma.studentAttendanceRecord.count({
        where: { student: { college_id: collegeId, department_id: deptId }, status: 'PRESENT' },
      }),
      prisma.studentAttendanceRecord.count({
        where: { student: { college_id: collegeId, department_id: deptId }, status: 'ABSENT' },
      }),
      prisma.studentAttendanceRecord.count({
        where: {
          student: { college_id: collegeId, department_id: deptId },
          status: { in: ['ON_LEAVE', 'EXCUSED', 'LEAVE'] },
        },
      }),
      prisma.subject.findMany({
        where: { college_id: collegeId, department_id: deptId },
        include: {
          attendance_records: { select: { status: true } },
        },
        orderBy: { code: 'asc' },
      }),
      prisma.user.findMany({
        where: {
          college_id: collegeId,
          department_id: deptId,
          role: Role.STUDENT,
          status: { not: UserStatus.DEACTIVATED },
        },
        select: {
          id: true,
          attendance_records: { select: { status: true } },
        },
      }),
    ]);

    const averageAttendance = attTotal > 0 ? Math.round((attPresent / attTotal) * 100) : 0;
    const presentPercentage = attTotal > 0 ? Math.round((attPresent / attTotal) * 100) : 0;
    const absentPercentage = attTotal > 0 ? Math.round((attAbsent / attTotal) * 100) : 0;
    const onLeavePercentage = attTotal > 0 ? Math.round((attOnLeave / attTotal) * 100) : 0;

    const subjectAttendance = subjects.map((sub) => {
      const total = sub.attendance_records.length;
      const present = sub.attendance_records.filter((r) => r.status === 'PRESENT').length;
      const pct = total > 0 ? Math.round((present / total) * 100) : 0;
      return {
        subject: sub.name,
        code: sub.code,
        percentage: pct,
        isBelowThreshold: pct < 75 && total > 0,
      };
    });

    let lowAttendanceCount = 0;
    for (const student of students) {
      const total = student.attendance_records.length;
      if (total > 0) {
        const present = student.attendance_records.filter((r) => r.status === 'PRESENT').length;
        const pct = Math.round((present / total) * 100);
        if (pct < 75) {
          lowAttendanceCount++;
        }
      }
    }

    return {
      averageAttendance,
      breakdown: {
        present: presentPercentage,
        absent: absentPercentage,
        onLeave: onLeavePercentage,
      },
      subjectAttendance,
      lowAttendanceCount,
    };
  }

  // 10. LOW ATTENDANCE STUDENTS (< 75%)
  async getLowAttendanceStudents(collegeId: string, user: { id?: string; role: string; departmentId?: string | null }) {
    const deptId = await this.getEffectiveDeptId(collegeId, user);

    const students = await prisma.user.findMany({
      where: {
        college_id: collegeId,
        department_id: deptId,
        role: Role.STUDENT,
        status: { not: UserStatus.DEACTIVATED },
      },
      include: {
        student_profile: true,
        academic_profile: true,
        attendance_records: {
          include: {
            subject: true,
          },
        },
      },
      orderBy: { first_name: 'asc' },
    });

    const lowAttendanceList: Array<{
      id: string;
      name: string;
      regNumber: string;
      className: string;
      subject: string;
      attendancePercentage: number;
      requiredPercentage: number;
      status: string;
    }> = [];

    for (const s of students) {
      const records = s.attendance_records;
      const total = records.length;
      if (total === 0) continue;

      const present = records.filter((r) => r.status === 'PRESENT').length;
      const pct = Math.round((present / total) * 100);

      if (pct < 75) {
        const subjectMap = new Map<string, { name: string; total: number; present: number }>();
        for (const r of records) {
          const subId = r.subject_id;
          const current = subjectMap.get(subId) || { name: r.subject?.name || r.subject?.code || 'Course', total: 0, present: 0 };
          current.total++;
          if (r.status === 'PRESENT') current.present++;
          subjectMap.set(subId, current);
        }

        let lowestSubjectName = 'All Subjects';
        let lowestSubjectPct = 101;
        for (const item of subjectMap.values()) {
          const subPct = item.total > 0 ? Math.round((item.present / item.total) * 100) : 0;
          if (subPct < lowestSubjectPct) {
            lowestSubjectPct = subPct;
            lowestSubjectName = item.name;
          }
        }

        const className = s.academic_profile?.section ? `Section ${s.academic_profile.section}` : (s.academic_profile?.batch_name || 'Section A');

        lowAttendanceList.push({
          id: s.id,
          name: `${s.first_name} ${s.last_name}`.trim(),
          regNumber: s.student_profile?.registration_number || s.roll_number || 'N/A',
          className,
          subject: lowestSubjectName,
          attendancePercentage: pct,
          requiredPercentage: 75,
          status: pct < 60 ? 'Critical' : 'Warning',
        });
      }
    }

    return lowAttendanceList;
  }

  // 11. ASSIGNMENTS
  async getAssignments(
    collegeId: string,
    user: { id?: string; role: string; departmentId?: string | null },
    query?: { status?: string }
  ) {
    const deptId = await this.getEffectiveDeptId(collegeId, user);

    const assignments = await prisma.subjectAssignment.findMany({
      where: {
        subject: { college_id: collegeId, department_id: deptId },
      },
      include: {
        subject: { select: { name: true, code: true } },
        faculty: { select: { first_name: true, last_name: true } },
        submissions: { select: { id: true } },
      },
      orderBy: { due_at: 'desc' },
    });

    const now = new Date();

    return assignments.map((a) => {
      const isPastDue = new Date(a.due_at) < now;
      const status = isPastDue ? 'Past Due' : 'Active';

      return {
        id: a.id,
        title: a.title,
        subjectName: a.subject?.name || a.subject?.code || 'General',
        facultyName: `${a.faculty.first_name} ${a.faculty.last_name}`.trim(),
        className: a.section ? `Section ${a.section}` : 'All Sections',
        dueDate: a.due_at ? a.due_at.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' }) : 'N/A',
        submittedCount: a.submissions.length,
        totalCount: a.submissions.length,
        status,
      };
    });
  }

  // 12. ASSESSMENTS
  async getAssessments(collegeId: string, user: { id?: string; role: string; departmentId?: string | null }) {
    const deptId = await this.getEffectiveDeptId(collegeId, user);

    const assessments = await prisma.subjectAssessment.findMany({
      where: {
        subject: { college_id: collegeId, department_id: deptId },
      },
      include: {
        subject: { select: { name: true, code: true } },
        faculty: { select: { first_name: true, last_name: true } },
        results: { select: { marks_obtained: true } },
      },
      orderBy: { scheduled_at: 'desc' },
    });

    return assessments.map((ia) => {
      const resultsWithMarks = ia.results.filter((r) => r.marks_obtained !== null && r.marks_obtained !== undefined);
      const totalResults = resultsWithMarks.length;
      let averageScore = 0;
      let passPercentage = 0;

      if (totalResults > 0) {
        const sumMarks = resultsWithMarks.reduce((acc, curr) => acc + (curr.marks_obtained || 0), 0);
        averageScore = parseFloat((sumMarks / totalResults).toFixed(1));
        const passedCount = resultsWithMarks.filter((r) => (r.marks_obtained || 0) >= ia.passing_marks).length;
        passPercentage = parseFloat(((passedCount / totalResults) * 100).toFixed(1));
      }

      return {
        id: ia.id,
        name: ia.title,
        subjectName: `${ia.subject?.name || 'Subject'} (${ia.subject?.code || 'Code'})`,
        className: ia.section ? `Section ${ia.section}` : 'All Sections',
        facultyName: `${ia.faculty.first_name} ${ia.faculty.last_name}`.trim(),
        date: ia.scheduled_at
          ? ia.scheduled_at.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' })
          : 'TBD',
        averageScore,
        passPercentage,
      };
    });
  }

  // 13. RESOURCES
  async getResources(collegeId: string, user: { id?: string; role: string; departmentId?: string | null }) {
    const deptId = await this.getEffectiveDeptId(collegeId, user);

    const resources = await prisma.subjectResource.findMany({
      where: {
        subject: { college_id: collegeId, department_id: deptId },
      },
      include: {
        subject: { select: { name: true, code: true } },
        uploaded_by: { select: { first_name: true, last_name: true } },
      },
      orderBy: { created_at: 'desc' },
    });

    return resources.map((r) => ({
      id: r.id,
      title: r.title,
      subjectName: r.subject?.name || r.subject?.code || 'General',
      uploadedBy: `${r.uploaded_by.first_name} ${r.uploaded_by.last_name}`.trim(),
      date: r.created_at.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' }),
      fileType: r.file_type || 'PDF',
      fileSize: 'Document',
      fileUrl: r.file_url,
    }));
  }

  // 14. PLACEMENT
  async getPlacementSummary(collegeId: string, user: { id?: string; role: string; departmentId?: string | null }) {
    const deptId = await this.getEffectiveDeptId(collegeId, user);
    const dept = await prisma.department.findUnique({ where: { id: deptId } });

    const drives = await prisma.placementDrive.findMany({
      where: { college_id: collegeId },
      orderBy: { created_at: 'desc' },
      take: 10,
    });

    const relevant = drives.filter((d) => {
      const depts = (d.allowed_departments as string[]) || [];
      return depts.length === 0 || depts.includes(dept?.code || 'IT') || depts.includes(deptId);
    });

    const [eligibleStudents, applications, selected] = await Promise.all([
      prisma.user.count({
        where: {
          college_id: collegeId,
          department_id: deptId,
          role: Role.STUDENT,
          portfolio: { cgpa: { gte: 6.0 } },
        },
      }),
      prisma.placementApplication.count({
        where: {
          student: { college_id: collegeId, department_id: deptId },
        },
      }),
      prisma.placementApplication.count({
        where: {
          student: { college_id: collegeId, department_id: deptId },
          status: 'OFFERED',
        },
      }),
    ]);

    return {
      activeDrives: relevant.length,
      eligibleStudents,
      applications,
      selected,
      recentDrives: relevant.slice(0, 3).map((d) => ({
        id: d.id,
        companyName: d.company_name,
        roleTitle: d.role_title,
        packageCtc: d.package_ctc || '',
        status: d.status,
        deadline: d.deadline ? new Date(d.deadline).toLocaleDateString() : '',
      })),
    };
  }

  // 15. REPORTS & ANALYTICS
  async getReports(collegeId: string, user: { id?: string; role: string; departmentId?: string | null }, academicYear?: string) {
    const deptId = await this.getEffectiveDeptId(collegeId, user);

    const [
      totalStudents,
      totalFaculty,
      y1,
      y2,
      y3,
      y4,
      placed,
      shortlisted,
      applied,
      eligible,
      attTotal,
      attPresent,
      cgpaAgg,
    ] = await Promise.all([
      prisma.user.count({
        where: { college_id: collegeId, department_id: deptId, role: Role.STUDENT },
      }),
      prisma.user.count({
        where: { college_id: collegeId, department_id: deptId, role: Role.FACULTY },
      }),
      prisma.user.count({
        where: { college_id: collegeId, department_id: deptId, role: Role.STUDENT, academic_profile: { current_year: 1 } },
      }),
      prisma.user.count({
        where: { college_id: collegeId, department_id: deptId, role: Role.STUDENT, academic_profile: { current_year: 2 } },
      }),
      prisma.user.count({
        where: { college_id: collegeId, department_id: deptId, role: Role.STUDENT, academic_profile: { current_year: 3 } },
      }),
      prisma.user.count({
        where: { college_id: collegeId, department_id: deptId, role: Role.STUDENT, academic_profile: { current_year: 4 } },
      }),
      prisma.placementApplication.count({
        where: { student: { college_id: collegeId, department_id: deptId }, status: 'OFFERED' },
      }),
      prisma.placementApplication.count({
        where: { student: { college_id: collegeId, department_id: deptId }, status: 'SHORTLISTED' },
      }),
      prisma.placementApplication.count({
        where: { student: { college_id: collegeId, department_id: deptId } },
      }),
      prisma.user.count({
        where: { college_id: collegeId, department_id: deptId, role: Role.STUDENT, portfolio: { cgpa: { gte: 6.0 } } },
      }),
      prisma.studentAttendanceRecord.count({
        where: { student: { college_id: collegeId, department_id: deptId } },
      }),
      prisma.studentAttendanceRecord.count({
        where: { student: { college_id: collegeId, department_id: deptId }, status: 'PRESENT' },
      }),
      prisma.portfolio.aggregate({
        where: { user: { college_id: collegeId, department_id: deptId } },
        _avg: { cgpa: true },
      }),
    ]);

    const attendance = attTotal > 0 ? Math.round((attPresent / attTotal) * 100) : 0;
    const avgCgpa = cgpaAgg._avg.cgpa ? parseFloat(cgpaAgg._avg.cgpa.toFixed(2)) : 0;

    return {
      academicYear: academicYear || '2026 - 2027',
      metrics: {
        students: totalStudents,
        faculty: totalFaculty,
        avgCgpa,
        attendance,
      },
      studentsByYear: [
        { year: '1st', count: y1 },
        { year: '2nd', count: y2 },
        { year: '3rd', count: y3 },
        { year: '4th', count: y4 },
      ],
      placementStatus: {
        placed,
        shortlisted,
        applied,
        eligible,
        total: totalStudents,
      },
    };
  }

  // 16. TARGETED DEPARTMENT ANNOUNCEMENT
  async createAnnouncement(
    collegeId: string,
    user: { id: string; role: string; departmentId?: string | null },
    dto: { title: string; content: string; targetYear?: number; targetBatch?: string }
  ) {
    const deptId = await this.getEffectiveDeptId(collegeId, user);

    if (!dto.title || !dto.title.trim()) {
      throw new BadRequestError('Announcement title is required');
    }
    if (!dto.content || !dto.content.trim()) {
      throw new BadRequestError('Announcement content is required');
    }

    const post = await prisma.post.create({
      data: {
        college_id: collegeId,
        department_id: deptId,
        author_id: user.id,
        title: dto.title.trim(),
        content: dto.content.trim(),
        type: 'ANNOUNCEMENT',
      },
    });

    // Resolve target department students and dispatch notification
    const students = await prisma.user.findMany({
      where: {
        college_id: collegeId,
        department_id: deptId,
        role: Role.STUDENT,
        status: { not: UserStatus.DEACTIVATED },
      },
      select: { id: true },
      take: 500,
    });

    for (const st of students) {
      this.notificationsService.sendNotification({
        user_id: st.id,
        title: dto.title.trim(),
        body: dto.content.trim().slice(0, 120),
        type: 'SYSTEM',
        category: 'Department Announcement',
        deep_link: `/feed`,
      }).catch(() => {});
    }

    return post;
  }
}
