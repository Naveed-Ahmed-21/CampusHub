import { prisma } from '../../config/database';
import { ApplicationStatus, DriveStatus, Prisma, Role } from '@prisma/client';
import {
  CreateDriveDto,
  UpdateDriveDto,
  ApplyDriveDto,
  UpdateApplicationStatusDto,
  ScheduleInterviewDto,
  RespondOfferDto,
  DriveQueryDto,
  CreateCompanyDto,
  UpdateCompanyDto,
  CreateResourceDto,
  ResourceQueryDto,
  StudentPlacementQueryDto,
  ApplicationQueryDto,
  InterviewQueryDto,
} from './placement.types';

export class PlacementRepository {
  // ==========================================
  // DASHBOARD & ANALYTICS
  // ==========================================

  async getOfficerDashboardStats(collegeId: string) {
    const [
      totalDrives,
      activeDrives,
      totalApplications,
      offeredCount,
      acceptedOffers,
      totalStudents,
      recentDrives,
      upcomingInterviews,
      departments,
    ] = await Promise.all([
      prisma.placementDrive.count({ where: { college_id: collegeId } }),
      prisma.placementDrive.count({ where: { college_id: collegeId, status: DriveStatus.ONGOING } }),
      prisma.placementApplication.count({ where: { drive: { college_id: collegeId } } }),
      prisma.placementApplication.count({
        where: { drive: { college_id: collegeId }, status: ApplicationStatus.OFFERED },
      }),
      prisma.placementApplication.count({
        where: { drive: { college_id: collegeId }, offer_status: 'ACCEPTED' },
      }),
      prisma.user.count({
        where: { college_id: collegeId, role: Role.STUDENT, status: 'ACTIVE' },
      }),
      prisma.placementDrive.findMany({
        where: { college_id: collegeId },
        take: 5,
        orderBy: { created_at: 'desc' },
        include: { _count: { select: { applications: true } } },
      }),
      prisma.placementInterview.findMany({
        where: {
          application: { drive: { college_id: collegeId } },
          scheduled_at: { gte: new Date() },
        },
        take: 5,
        orderBy: { scheduled_at: 'asc' },
        include: {
          application: {
            include: {
              student: { select: { id: true, first_name: true, last_name: true, email: true, avatar_url: true } },
              drive: { select: { id: true, company_name: true, role_title: true } },
            },
          },
        },
      }),
      prisma.department.findMany({
        where: { college_id: collegeId },
        select: { id: true, name: true, code: true },
      }),
    ]);

    // Department-wise breakdown for analytics chart
    const departmentStats = await Promise.all(
      departments.map(async (dept) => {
        const [deptStudents, deptPlaced] = await Promise.all([
          prisma.user.count({
            where: { college_id: collegeId, department_id: dept.id, role: Role.STUDENT },
          }),
          prisma.placementApplication.count({
            where: {
              offer_status: 'ACCEPTED',
              student: { department_id: dept.id },
            },
          }),
        ]);
        const rate = deptStudents > 0 ? Math.round((deptPlaced / deptStudents) * 100) : 0;
        return {
          id: dept.id,
          name: dept.name,
          code: dept.code,
          totalStudents: deptStudents,
          placedStudents: deptPlaced,
          placementRate: rate,
        };
      })
    );

    const placementRate = totalStudents > 0 ? Math.round((acceptedOffers / totalStudents) * 100) : 0;

    // Real CTC statistics from college drives
    const drivesWithPackages = await prisma.placementDrive.findMany({
      where: { college_id: collegeId, package_ctc: { not: null } },
      select: { package_ctc: true },
    });
    const ctcValues = drivesWithPackages
      .map((d) => parseFloat((d.package_ctc || '').replace(/[^0-9.]/g, '') || '0'))
      .filter((v) => v > 0);
    const highestCtcVal = ctcValues.length > 0 ? Math.max(...ctcValues) : 0;
    const avgCtcVal = ctcValues.length > 0 ? (ctcValues.reduce((a, b) => a + b, 0) / ctcValues.length) : 0;
    const highestCtc = highestCtcVal > 0 ? `₹${highestCtcVal.toFixed(1)} LPA` : 'N/A';
    const averageCtc = avgCtcVal > 0 ? `₹${avgCtcVal.toFixed(1)} LPA` : 'N/A';

    return {
      totalDrives,
      activeDrives,
      totalApplications,
      offeredCount,
      acceptedOffers,
      totalStudents,
      placementRate,
      highestCtc,
      averageCtc,
      departmentsCount: departments.length,
      recentDrives,
      upcomingInterviews,
      departmentStats,
    };
  }

  async getDepartmentPlacementStats(collegeId: string, departmentId: string) {
    const [totalStudents, eligibleStudents, deptApplications, placedStudents, activeDrives] = await Promise.all([
      prisma.user.count({
        where: { college_id: collegeId, department_id: departmentId, role: Role.STUDENT, status: 'ACTIVE' },
      }),
      prisma.user.count({
        where: {
          college_id: collegeId,
          department_id: departmentId,
          role: Role.STUDENT,
          status: 'ACTIVE',
          portfolio: { cgpa: { gte: 6.0 } },
        },
      }),
      prisma.placementApplication.count({
        where: { student: { department_id: departmentId } },
      }),
      prisma.placementApplication.count({
        where: { student: { department_id: departmentId }, offer_status: 'ACCEPTED' },
      }),
      prisma.placementDrive.findMany({
        where: {
          college_id: collegeId,
          status: DriveStatus.ONGOING,
        },
        take: 5,
        orderBy: { created_at: 'desc' },
      }),
    ]);

    const placementRate = totalStudents > 0 ? Math.round((placedStudents / totalStudents) * 100) : 0;

    return {
      totalStudents,
      eligibleStudents,
      appliedStudents: deptApplications,
      placedStudents,
      placementRate,
      activeDrives,
    };
  }

  async getStudentDashboardStats(userId: string) {
    const [myApplications, myOffers, upcomingInterviews, user] = await Promise.all([
      prisma.placementApplication.findMany({
        where: { student_id: userId },
        include: {
          drive: true,
          interviews: { orderBy: { scheduled_at: 'asc' } },
        },
        orderBy: { applied_at: 'desc' },
      }),
      prisma.placementApplication.findMany({
        where: { student_id: userId, status: ApplicationStatus.OFFERED },
        include: { drive: true },
      }),
      prisma.placementInterview.findMany({
        where: { application: { student_id: userId }, scheduled_at: { gte: new Date() } },
        include: { application: { include: { drive: true } } },
        orderBy: { scheduled_at: 'asc' },
      }),
      prisma.user.findUnique({
        where: { id: userId },
        include: { portfolio: true, academic_profile: true, department: true },
      }),
    ]);

    const collegeId = user?.college_id;
    let eligibleDrivesCount = 0;
    if (collegeId) {
      const studentCgpa = user?.portfolio?.cgpa || 0.0;
      eligibleDrivesCount = await prisma.placementDrive.count({
        where: {
          college_id: collegeId,
          status: { in: [DriveStatus.UPCOMING, DriveStatus.ONGOING] },
          min_cgpa: { lte: studentCgpa },
        },
      });
    }

    return {
      myApplications,
      myOffers,
      upcomingInterviews,
      eligibleDrivesCount,
      activeDrivesCount: myApplications.length,
      studentProfile: {
        cgpa: user?.portfolio?.cgpa || 0.0,
        resumeUrl: user?.portfolio?.resume_url,
        department: user?.department?.name,
        rollNumber: user?.roll_number,
      },
    };
  }

  // ==========================================
  // DRIVES
  // ==========================================

  async createDrive(collegeId: string, dto: CreateDriveDto) {
    let bannerUrl = dto.banner_url;
    if (!bannerUrl && dto.company_id) {
      const comp = await prisma.company.findUnique({ where: { id: dto.company_id } });
      bannerUrl = comp?.cover_image_url || undefined;
    }
    return prisma.placementDrive.create({
      data: {
        college_id: collegeId,
        company_id: dto.company_id,
        company_name: dto.company_name,
        role_title: dto.role_title,
        package_ctc: dto.package_ctc,
        location: dto.location,
        eligibility: dto.eligibility,
        min_cgpa: dto.min_cgpa || 0.0,
        allowed_departments: dto.allowed_departments || [],
        max_backlogs: dto.max_backlogs || 0,
        job_description: dto.job_description,
        deadline: new Date(dto.deadline),
        status: dto.status || DriveStatus.UPCOMING,
        target_year: dto.target_year,
        target_batch: dto.target_batch,
        employment_type: dto.employment_type || 'FULL_TIME',
        work_mode: dto.work_mode || 'ON_SITE',
        required_skills: dto.required_skills || [],
        drive_date: dto.drive_date && dto.drive_date.trim() ? new Date(dto.drive_date) : undefined,
        test_date: dto.test_date && dto.test_date.trim() ? new Date(dto.test_date) : undefined,
        interview_date: dto.interview_date && dto.interview_date.trim() ? new Date(dto.interview_date) : undefined,
        venue_or_link: dto.venue_or_link,
        banner_url: bannerUrl,
      },
      include: {
        _count: { select: { applications: true } },
        company: true,
      },
    });
  }

  async updateDrive(driveId: string, collegeId: string, dto: UpdateDriveDto) {
    const data: Prisma.PlacementDriveUpdateInput = {};
    if (dto.company_name !== undefined) data.company_name = dto.company_name;
    if (dto.company_id !== undefined) data.company = dto.company_id ? { connect: { id: dto.company_id } } : { disconnect: true };
    if (dto.role_title !== undefined) data.role_title = dto.role_title;
    if (dto.package_ctc !== undefined) data.package_ctc = dto.package_ctc;
    if (dto.location !== undefined) data.location = dto.location;
    if (dto.eligibility !== undefined) data.eligibility = dto.eligibility;
    if (dto.min_cgpa !== undefined) data.min_cgpa = dto.min_cgpa;
    if (dto.allowed_departments !== undefined) data.allowed_departments = dto.allowed_departments;
    if (dto.max_backlogs !== undefined) data.max_backlogs = dto.max_backlogs;
    if (dto.job_description !== undefined) data.job_description = dto.job_description;
    if (dto.deadline !== undefined) data.deadline = dto.deadline && dto.deadline.trim() ? new Date(dto.deadline) : undefined;
    if (dto.status !== undefined) data.status = dto.status;
    if (dto.target_year !== undefined) data.target_year = dto.target_year;
    if (dto.target_batch !== undefined) data.target_batch = dto.target_batch;
    if (dto.employment_type !== undefined) data.employment_type = dto.employment_type;
    if (dto.work_mode !== undefined) data.work_mode = dto.work_mode;
    if (dto.required_skills !== undefined) data.required_skills = dto.required_skills;
    if (dto.drive_date !== undefined) data.drive_date = dto.drive_date && dto.drive_date.trim() ? new Date(dto.drive_date) : null;
    if (dto.test_date !== undefined) data.test_date = dto.test_date && dto.test_date.trim() ? new Date(dto.test_date) : null;
    if (dto.interview_date !== undefined) data.interview_date = dto.interview_date && dto.interview_date.trim() ? new Date(dto.interview_date) : null;
    if (dto.venue_or_link !== undefined) data.venue_or_link = dto.venue_or_link;
    if (dto.banner_url !== undefined) data.banner_url = dto.banner_url;

    return prisma.placementDrive.update({
      where: { id: driveId, college_id: collegeId },
      data,
      include: {
        _count: { select: { applications: true } },
        company: true,
      },
    });
  }

  async setDriveChatRoom(driveId: string, chatRoomId: string) {
    return prisma.placementDrive.update({
      where: { id: driveId },
      data: { chat_room_id: chatRoomId },
    });
  }

  async findDrives(collegeId: string, query: DriveQueryDto) {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const where: Prisma.PlacementDriveWhereInput = { college_id: collegeId };
    if (query.status) where.status = query.status;
    if (query.target_year) where.target_year = query.target_year;
    if (query.employment_type) where.employment_type = query.employment_type;

    if (query.search) {
      where.OR = [
        { company_name: { contains: query.search, mode: 'insensitive' } },
        { role_title: { contains: query.search, mode: 'insensitive' } },
        { location: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    const [total, drives] = await Promise.all([
      prisma.placementDrive.count({ where }),
      prisma.placementDrive.findMany({
        where,
        skip,
        take: limit,
        orderBy: { created_at: 'desc' },
        include: {
          company: true,
          _count: { select: { applications: true } },
        },
      }),
    ]);

    return { total, page, limit, drives };
  }

  async findDriveById(driveId: string) {
    return prisma.placementDrive.findUnique({
      where: { id: driveId },
      include: {
        company: true,
        chat_room: {
          select: { id: true, name: true, type: true },
        },
        resources: {
          select: {
            id: true,
            title: true,
            category: true,
            resource_type: true,
            file_url: true,
            external_url: true,
          },
        },
        applications: {
          include: {
            student: {
              select: {
                id: true,
                first_name: true,
                last_name: true,
                email: true,
                avatar_url: true,
                roll_number: true,
                department: { select: { id: true, code: true, name: true } },
                portfolio: { select: { cgpa: true, resume_url: true, github_url: true, linkedin_url: true } },
                academic_profile: { select: { current_year: true, batch_name: true, section: true } },
              },
            },
            interviews: true,
          },
          orderBy: { applied_at: 'desc' },
        },
        _count: { select: { applications: true } },
      },
    });
  }

  // ==========================================
  // COMPANIES
  // ==========================================

  async createCompany(collegeId: string, dto: CreateCompanyDto) {
    return prisma.company.create({
      data: {
        college_id: collegeId,
        name: dto.name,
        website: dto.website || null,
        logo_url: dto.logo_url || null,
        cover_image_url: dto.cover_image_url || null,
        industry: dto.industry || null,
        about: dto.about || null,
        linkedin_url: dto.linkedin_url || null,
      },
    });
  }

  async updateCompany(companyId: string, collegeId: string, dto: UpdateCompanyDto) {
    return prisma.company.update({
      where: { id: companyId, college_id: collegeId },
      data: {
        name: dto.name,
        website: dto.website,
        logo_url: dto.logo_url,
        cover_image_url: dto.cover_image_url,
        industry: dto.industry,
        about: dto.about,
        linkedin_url: dto.linkedin_url,
      },
    });
  }

  async findCompanies(collegeId: string, search?: string) {
    const where: Prisma.CompanyWhereInput = { college_id: collegeId };
    if (search) {
      where.name = { contains: search, mode: 'insensitive' };
    }
    return prisma.company.findMany({
      where,
      orderBy: { name: 'asc' },
      include: {
        _count: { select: { drives: true, resources: true } },
      },
    });
  }

  async findCompanyById(companyId: string, collegeId: string) {
    return prisma.company.findUnique({
      where: { id: companyId, college_id: collegeId },
      include: {
        drives: {
          orderBy: { created_at: 'desc' },
          include: { _count: { select: { applications: true } } },
        },
        resources: {
          orderBy: { created_at: 'desc' },
        },
      },
    });
  }

  async findOrCreateCompanyByName(collegeId: string, name: string): Promise<string> {
    const existing = await prisma.company.findFirst({
      where: { college_id: collegeId, name: { equals: name, mode: 'insensitive' } },
    });
    if (existing) {
      return existing.id;
    }

    const created = await prisma.company.create({
      data: {
        college_id: collegeId,
        name,
        website: null,
        logo_url: null,
        cover_image_url: null,
        industry: null,
        about: null,
        linkedin_url: null,
      },
    });
    return created.id;
  }

  // ==========================================
  // PREPARATION RESOURCES
  // ==========================================

  async createResource(collegeId: string, creatorId: string, dto: CreateResourceDto) {
    return prisma.placementResource.create({
      data: {
        college_id: collegeId,
        creator_id: creatorId,
        title: dto.title,
        description: dto.description,
        category: dto.category,
        resource_type: dto.resource_type,
        file_url: dto.file_url,
        external_url: dto.external_url,
        thumbnail_url: dto.thumbnail_url,
        tags: dto.tags || [],
        target_departments: dto.target_departments || [],
        target_year: dto.target_year,
        target_batch: dto.target_batch,
        company_id: dto.company_id,
        drive_id: dto.drive_id,
      },
      include: {
        creator: { select: { id: true, first_name: true, last_name: true } },
        company: { select: { id: true, name: true, logo_url: true } },
        drive: { select: { id: true, company_name: true, role_title: true } },
      },
    });
  }

  async findResources(collegeId: string, query: ResourceQueryDto) {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const where: Prisma.PlacementResourceWhereInput = { college_id: collegeId };
    if (query.category) where.category = query.category;
    if (query.resource_type) where.resource_type = query.resource_type;
    if (query.company_id) where.company_id = query.company_id;
    if (query.drive_id) where.drive_id = query.drive_id;
    if (query.search) {
      where.OR = [
        { title: { contains: query.search, mode: 'insensitive' } },
        { description: { contains: query.search, mode: 'insensitive' } },
        { tags: { has: query.search } },
      ];
    }

    const [total, resources] = await Promise.all([
      prisma.placementResource.count({ where }),
      prisma.placementResource.findMany({
        where,
        skip,
        take: limit,
        orderBy: { created_at: 'desc' },
        include: {
          creator: { select: { id: true, first_name: true, last_name: true } },
          company: { select: { id: true, name: true, logo_url: true } },
          drive: { select: { id: true, company_name: true, role_title: true } },
        },
      }),
    ]);

    return { total, page, limit, resources };
  }

  async findResourceById(resourceId: string, collegeId: string) {
    return prisma.placementResource.findUnique({
      where: { id: resourceId, college_id: collegeId },
      include: {
        creator: { select: { id: true, first_name: true, last_name: true, avatar_url: true } },
        company: true,
        drive: true,
      },
    });
  }

  async incrementResourceViews(resourceId: string) {
    return prisma.placementResource.update({
      where: { id: resourceId },
      data: { views_count: { increment: 1 } },
    });
  }

  async deleteResource(resourceId: string, collegeId: string) {
    return prisma.placementResource.delete({
      where: { id: resourceId, college_id: collegeId },
    });
  }

  // ==========================================
  // APPLICATIONS
  // ==========================================

  async createApplication(studentId: string, dto: ApplyDriveDto) {
    return prisma.placementApplication.create({
      data: {
        drive_id: dto.drive_id,
        student_id: studentId,
        resume_url: dto.resume_url,
      },
      include: {
        drive: true,
        student: {
          select: {
            id: true,
            first_name: true,
            last_name: true,
            email: true,
            department: { select: { name: true, code: true } },
          },
        },
      },
    });
  }

  async findApplication(studentId: string, driveId: string) {
    return prisma.placementApplication.findUnique({
      where: { drive_id_student_id: { drive_id: driveId, student_id: studentId } },
    });
  }

  async findApplicationById(applicationId: string) {
    return prisma.placementApplication.findUnique({
      where: { id: applicationId },
      include: {
        drive: true,
        student: {
          select: {
            id: true,
            first_name: true,
            last_name: true,
            email: true,
            avatar_url: true,
            roll_number: true,
            department: { select: { id: true, code: true, name: true } },
            portfolio: true,
            academic_profile: true,
          },
        },
        interviews: { orderBy: { scheduled_at: 'asc' } },
      },
    });
  }

  async findApplications(collegeId: string, query: ApplicationQueryDto) {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const where: Prisma.PlacementApplicationWhereInput = {
      drive: { college_id: collegeId },
    };
    if (query.drive_id) where.drive_id = query.drive_id;
    if (query.status) where.status = query.status;

    const studentConditions: Prisma.UserWhereInput[] = [];
    if (query.department_id) {
      studentConditions.push({ department_id: query.department_id });
    }
    if (query.search) {
      studentConditions.push({
        OR: [
          { first_name: { contains: query.search, mode: 'insensitive' } },
          { last_name: { contains: query.search, mode: 'insensitive' } },
          { email: { contains: query.search, mode: 'insensitive' } },
          { roll_number: { contains: query.search, mode: 'insensitive' } },
        ],
      });
    }
    if (studentConditions.length > 0) {
      where.student = { AND: studentConditions };
    }

    const [total, applications] = await Promise.all([
      prisma.placementApplication.count({ where }),
      prisma.placementApplication.findMany({
        where,
        skip,
        take: limit,
        orderBy: { applied_at: 'desc' },
        include: {
          drive: { select: { id: true, company_name: true, role_title: true, package_ctc: true } },
          student: {
            select: {
              id: true,
              first_name: true,
              last_name: true,
              email: true,
              avatar_url: true,
              roll_number: true,
              department: { select: { id: true, code: true, name: true } },
              portfolio: { select: { cgpa: true, resume_url: true } },
            },
          },
          interviews: true,
        },
      }),
    ]);

    return { total, page, limit, applications };
  }

  async updateApplicationStatus(applicationId: string, dto: UpdateApplicationStatusDto) {
    return prisma.placementApplication.update({
      where: { id: applicationId },
      data: {
        status: dto.status,
        offer_ctc: dto.offer_ctc,
        offer_status: dto.status === ApplicationStatus.OFFERED ? 'PENDING' : undefined,
      },
      include: {
        drive: true,
        student: { select: { id: true, first_name: true, last_name: true, email: true } },
      },
    });
  }

  async bulkUpdateApplicationStatus(applicationIds: string[], status: ApplicationStatus, offerCtc?: string) {
    return prisma.placementApplication.updateMany({
      where: { id: { in: applicationIds } },
      data: {
        status,
        offer_ctc: offerCtc,
        offer_status: status === ApplicationStatus.OFFERED ? 'PENDING' : undefined,
      },
    });
  }

  // ==========================================
  // INTERVIEWS & OFFERS
  // ==========================================

  async scheduleInterview(dto: ScheduleInterviewDto) {
    const interview = await prisma.placementInterview.create({
      data: {
        application_id: dto.application_id,
        round_name: dto.round_name,
        scheduled_at: new Date(dto.scheduled_at),
        location_or_link: dto.location_or_link,
        notes: dto.notes,
      },
    });

    await prisma.placementApplication.update({
      where: { id: dto.application_id },
      data: { status: ApplicationStatus.INTERVIEW_SCHEDULED },
    });

    return interview;
  }

  async findInterviews(collegeId: string, query: InterviewQueryDto) {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const appWhere: Prisma.PlacementApplicationWhereInput = {
      drive: { college_id: collegeId },
    };
    if (query.drive_id) {
      appWhere.drive_id = query.drive_id;
    }

    const where: Prisma.PlacementInterviewWhereInput = {
      application: appWhere,
    };
    if (query.status) where.status = query.status;

    const [total, interviews] = await Promise.all([
      prisma.placementInterview.count({ where }),
      prisma.placementInterview.findMany({
        where,
        skip,
        take: limit,
        orderBy: { scheduled_at: 'asc' },
        include: {
          application: {
            include: {
              student: {
                select: {
                  id: true,
                  first_name: true,
                  last_name: true,
                  email: true,
                  avatar_url: true,
                  department: { select: { name: true, code: true } },
                },
              },
              drive: { select: { id: true, company_name: true, role_title: true } },
            },
          },
        },
      }),
    ]);

    return { total, page, limit, interviews };
  }

  async respondToOffer(applicationId: string, studentId: string, dto: RespondOfferDto) {
    return prisma.placementApplication.update({
      where: { id: applicationId, student_id: studentId, status: ApplicationStatus.OFFERED },
      data: {
        offer_status: dto.offer_status,
      },
      include: { drive: true },
    });
  }

  // ==========================================
  // STUDENTS DIRECTORY FOR PLACEMENT
  // ==========================================

  async findStudentsForPlacement(collegeId: string, query: StudentPlacementQueryDto) {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const where: Prisma.UserWhereInput = {
      college_id: collegeId,
      role: Role.STUDENT,
      status: 'ACTIVE',
    };
    if (query.department_id) where.department_id = query.department_id;
    if (query.search) {
      where.OR = [
        { first_name: { contains: query.search, mode: 'insensitive' } },
        { last_name: { contains: query.search, mode: 'insensitive' } },
        { roll_number: { contains: query.search, mode: 'insensitive' } },
        { email: { contains: query.search, mode: 'insensitive' } },
      ];
    }
    if (query.min_cgpa) {
      where.portfolio = { cgpa: { gte: query.min_cgpa } };
    }
    if (query.year) {
      where.academic_profile = { current_year: query.year };
    }

    const [total, students] = await Promise.all([
      prisma.user.count({ where }),
      prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { roll_number: 'asc' },
        select: {
          id: true,
          first_name: true,
          last_name: true,
          email: true,
          roll_number: true,
          avatar_url: true,
          department: { select: { id: true, code: true, name: true } },
          portfolio: { select: { cgpa: true, resume_url: true, github_url: true, linkedin_url: true } },
          academic_profile: { select: { current_year: true, batch_name: true, section: true } },
          applications: {
            select: {
              id: true,
              status: true,
              offer_status: true,
              offer_ctc: true,
              drive: { select: { id: true, company_name: true, role_title: true } },
            },
          },
        },
      }),
    ]);

    // Compute placement state for each student
    const enriched = students.map((s) => {
      const hasAcceptedOffer = s.applications.some((a) => a.offer_status === 'ACCEPTED');
      const hasOffered = s.applications.some((a) => a.status === ApplicationStatus.OFFERED);
      const hasInProcess = s.applications.some((a) =>
        ['APPLIED', 'SHORTLISTED', 'TEST_SCHEDULED', 'INTERVIEW_SCHEDULED'].includes(a.status)
      );

      let placementStatus: 'PLACED' | 'OFFERED' | 'IN_PROCESS' | 'ELIGIBLE' = 'ELIGIBLE';
      if (hasAcceptedOffer) placementStatus = 'PLACED';
      else if (hasOffered) placementStatus = 'OFFERED';
      else if (hasInProcess) placementStatus = 'IN_PROCESS';

      return {
        ...s,
        placementStatus,
        applicationsCount: s.applications.length,
        cgpa: s.portfolio?.cgpa || 0.0,
      };
    });

    // Filter by calculated status if requested
    const filtered = query.status && query.status !== 'ALL'
      ? enriched.filter((s) => s.placementStatus === query.status)
      : enriched;

    return { total, page, limit, students: filtered };
  }

  async getStudentPlacementProfile(userId: string) {
    const student = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        first_name: true,
        last_name: true,
        email: true,
        phone: true,
        roll_number: true,
        avatar_url: true,
        department: { select: { id: true, code: true, name: true } },
        portfolio: true,
        academic_profile: {
          select: {
            current_year: true,
            batch_name: true,
            section: true,
            admission_year: true,
            program: { select: { name: true, code: true } },
          },
        },
        applications: {
          include: {
            drive: true,
            interviews: { orderBy: { scheduled_at: 'asc' } },
          },
          orderBy: { applied_at: 'desc' },
        },
      },
    });

    if (!student) return null;

    const acceptedOffer = student.applications.find((a) => a.offer_status === 'ACCEPTED');
    const isPlaced = !!acceptedOffer;

    return {
      ...student,
      isPlaced,
      placedCompany: acceptedOffer?.drive.company_name,
      placedPackage: acceptedOffer?.offer_ctc || acceptedOffer?.drive.package_ctc,
      totalApplied: student.applications.length,
      totalInterviews: student.applications.reduce((acc, a) => acc + a.interviews.length, 0),
    };
  }
}
