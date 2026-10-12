import { PlacementRepository } from './placement.repository';
import {
  CreateDriveDto,
  UpdateDriveDto,
  ApplyDriveDto,
  UpdateApplicationStatusDto,
  BulkUpdateStatusDto,
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
import { NotFoundError, BadRequestError, ConflictError, ForbiddenError } from '../../shared/errors/AppError';
import { prisma } from '../../config/database';
import { ApplicationStatus, ChatRoomType, PostType, Role } from '@prisma/client';
import { NotificationsRepository } from '../notifications/notifications.repository';
import { NotificationsService } from '../notifications/notifications.service';
import { PostsRepository } from '../posts/posts.repository';

function isPlacementOfficer(role: Role): boolean {
  return (
    role === Role.PLACEMENT ||
    (role as string) === 'PLACEMENT_OFFICER' ||
    role === Role.ADMIN
  );
}

export class PlacementService {
  private readonly notificationsService: NotificationsService;
  private readonly postsRepository: PostsRepository;

  constructor(
    private readonly placementRepository: PlacementRepository,
    notificationsService?: NotificationsService,
    postsRepository?: PostsRepository,
  ) {
    this.notificationsService = notificationsService ?? new NotificationsService(new NotificationsRepository());
    this.postsRepository = postsRepository ?? new PostsRepository();
  }

  // ==========================================
  // DASHBOARDS & ANALYTICS
  // ==========================================

  async getOfficerDashboard(collegeId: string, role: Role) {
    if (!isPlacementOfficer(role)) {
      throw new ForbiddenError('Only placement officers and admins can access this dashboard');
    }
    return this.placementRepository.getOfficerDashboardStats(collegeId);
  }

  async getDepartmentPlacementStats(collegeId: string, userDepartmentId: string | null | undefined, queryDepartmentId: string, role: Role) {
    if (role === Role.DEPT_ADMIN) {
      if (!userDepartmentId || userDepartmentId !== queryDepartmentId) {
        throw new ForbiddenError('Department admins can only view their own department placement statistics');
      }
    } else if (!isPlacementOfficer(role)) {
      throw new ForbiddenError('Access denied to department placement statistics');
    }

    return this.placementRepository.getDepartmentPlacementStats(collegeId, queryDepartmentId);
  }

  async getStudentDashboard(userId: string) {
    return this.placementRepository.getStudentDashboardStats(userId);
  }

  // ==========================================
  // DRIVES
  // ==========================================

  async createDrive(
    collegeId: string,
    userIdOrRole: string | Role,
    roleOrDto: Role | CreateDriveDto,
    maybeDto?: CreateDriveDto,
  ) {
    let userId: string = 'system';
    let role: Role;
    let dto: CreateDriveDto;

    if (maybeDto !== undefined) {
      userId = userIdOrRole as string;
      role = roleOrDto as Role;
      dto = maybeDto;
    } else {
      role = userIdOrRole as Role;
      dto = roleOrDto as CreateDriveDto;
    }

    if (!isPlacementOfficer(role)) {
      throw new ForbiddenError('Only placement officers and admins can post placement drives');
    }
    if (new Date(dto.deadline) <= new Date()) {
      throw new BadRequestError('Application deadline must be in the future');
    }

    // Auto-link or create company if not provided
    let companyId = dto.company_id;
    if (!companyId && dto.company_name) {
      companyId = await this.placementRepository.findOrCreateCompanyByName(collegeId, dto.company_name);
    }

    const driveData: CreateDriveDto = {
      ...dto,
      company_id: companyId,
    };

    const drive = await this.placementRepository.createDrive(collegeId, driveData);

    // 1. Create Dedicated Drive Chat Room
    try {
      const chatRoom = await prisma.chatRoom.create({
        data: {
          college_id: collegeId,
          name: `${drive.company_name} - ${drive.role_title}`,
          description: `Official placement drive room for ${drive.company_name}`,
          type: ChatRoomType.GROUP,
          is_private: false,
          created_by_id: userId,
          participants: {
            create: [
              {
                user_id: userId,
                role: 'ADMIN',
                status: 'ACTIVE',
              },
            ],
          },
        },
      });

      await this.placementRepository.setDriveChatRoom(drive.id, chatRoom.id);
      drive.chat_room_id = chatRoom.id;
    } catch (err) {
      // Non-fatal if chat room creation logs error
      console.error('Failed to create drive chat room:', err);
    }

    // 2. Feed announcement post: Disabled automatic feed posting as per requirements.

    // 3. Resolve Target Students & Send Notifications
    try {
      const studentWhere: any = {
        college_id: collegeId,
        role: Role.STUDENT,
        status: 'ACTIVE',
      };

      if (dto.allowed_departments && dto.allowed_departments.length > 0) {
        studentWhere.OR = [
          { department: { code: { in: dto.allowed_departments } } },
          { department_id: { in: dto.allowed_departments } },
        ];
      }

      if (dto.target_year) {
        studentWhere.academic_profile = { current_year: dto.target_year };
      }

      const targetStudents = await prisma.user.findMany({
        where: studentWhere,
        select: { id: true },
        take: 300,
      });

      for (const st of targetStudents) {
        this.notificationsService.sendNotification({
          user_id: st.id,
          title: `New Placement Drive: ${drive.company_name}`,
          body: `${drive.role_title} • CTC: ${drive.package_ctc || 'Competitive'}. Apply before ${new Date(drive.deadline).toLocaleDateString()}`,
          type: 'PLACEMENT_UPDATE',
          category: 'Placement',
          deep_link: `/placement`,
        }).catch(() => {});
      }
    } catch (err) {
      console.error('Failed to dispatch placement notifications:', err);
    }

    return drive;
  }

  async updateDrive(driveId: string, collegeId: string, role: Role, dto: UpdateDriveDto) {
    if (!isPlacementOfficer(role)) {
      throw new ForbiddenError('Only placement officers and admins can update placement drives');
    }
    const existing = await this.placementRepository.findDriveById(driveId);
    if (!existing || existing.college_id !== collegeId) {
      throw new NotFoundError('Placement drive not found');
    }
    return this.placementRepository.updateDrive(driveId, collegeId, dto);
  }

  async getDrives(collegeId: string, query: DriveQueryDto) {
    return this.placementRepository.findDrives(collegeId, query);
  }

  async getDriveDetails(driveId: string) {
    const drive = await this.placementRepository.findDriveById(driveId);
    if (!drive) {
      throw new NotFoundError('Placement drive not found');
    }
    return drive;
  }

  // ==========================================
  // APPLICATIONS
  // ==========================================

  async applyForDrive(studentId: string, collegeId: string, dto: ApplyDriveDto) {
    const drive = await this.placementRepository.findDriveById(dto.drive_id);
    if (!drive || drive.college_id !== collegeId) {
      throw new NotFoundError('Placement drive not found');
    }

    if (new Date() > drive.deadline) {
      throw new BadRequestError('Application deadline for this drive has passed');
    }

    const existing = await this.placementRepository.findApplication(studentId, dto.drive_id);
    if (existing) {
      throw new ConflictError('You have already applied for this placement drive');
    }

    // Evaluate student eligibility
    const student = await prisma.user.findUnique({
      where: { id: studentId },
      include: { department: true, portfolio: true, academic_profile: true },
    });

    if (!student) {
      throw new NotFoundError('Student profile not found');
    }

    // 1. CGPA check
    if (drive.min_cgpa && drive.min_cgpa > 0) {
      const studentCgpa = student.portfolio?.cgpa || 0.0;
      if (studentCgpa < drive.min_cgpa) {
        throw new BadRequestError(`Ineligible: Minimum CGPA required is ${drive.min_cgpa} (Your CGPA: ${studentCgpa})`);
      }
    }

    // 2. Department check
    const allowedDepts = (drive.allowed_departments as string[]) || [];
    if (allowedDepts.length > 0) {
      const deptCode = student.department?.code;
      const deptId = student.department_id;
      const isAllowed =
        (deptCode && allowedDepts.includes(deptCode)) ||
        (deptId && allowedDepts.includes(deptId));
      if (!isAllowed) {
        throw new BadRequestError(`Ineligible: Drive is open to [${allowedDepts.join(', ')}] branches only.`);
      }
    }

    // 3. Year check
    if (drive.target_year && student.academic_profile?.current_year) {
      if (student.academic_profile.current_year !== drive.target_year) {
        throw new BadRequestError(`Ineligible: Drive is open to year ${drive.target_year} students only.`);
      }
    }

    const app = await this.placementRepository.createApplication(studentId, dto);

    // Cross-role Chat integration: Add student to drive's official ChatRoom
    if (drive.chat_room_id) {
      try {
        const participantExists = await prisma.chatParticipant.findUnique({
          where: {
            room_id_user_id: {
              room_id: drive.chat_room_id,
              user_id: studentId,
            },
          },
        });
        if (!participantExists) {
          await prisma.chatParticipant.create({
            data: {
              room_id: drive.chat_room_id,
              user_id: studentId,
              role: 'MEMBER',
              status: 'ACTIVE',
            },
          });
        }
      } catch (err) {
        console.error('Failed to add student to drive chat room:', err);
      }
    }

    // Notification
    try {
      await this.notificationsService.sendNotification({
        user_id: studentId,
        title: `Applied: ${drive.company_name}`,
        body: `Your application for ${drive.role_title} has been submitted successfully.`,
        type: 'PLACEMENT_UPDATE',
        category: 'Placement',
        deep_link: `/placement`,
      });
    } catch (_) {}

    return app;
  }

  async getApplications(collegeId: string, role: Role, query: ApplicationQueryDto) {
    if (!isPlacementOfficer(role)) {
      throw new ForbiddenError('Only placement officers and admins can view candidate applications');
    }
    return this.placementRepository.findApplications(collegeId, query);
  }

  async getApplicationById(applicationId: string, userId: string, role: Role) {
    const app = await this.placementRepository.findApplicationById(applicationId);
    if (!app) {
      throw new NotFoundError('Application not found');
    }
    if (!isPlacementOfficer(role) && app.student_id !== userId) {
      throw new ForbiddenError('Access denied to this application');
    }
    return app;
  }

  async updateApplicationStatus(applicationId: string, role: Role, dto: UpdateApplicationStatusDto) {
    if (!isPlacementOfficer(role)) {
      throw new ForbiddenError('Only placement officers can update application statuses');
    }
    const updated = await this.placementRepository.updateApplicationStatus(applicationId, dto);
    try {
      const app = await prisma.placementApplication.findUnique({
        where: { id: applicationId },
        include: { drive: true },
      });
      if (app) {
        await this.notificationsService.sendNotification({
          user_id: app.student_id,
          title: `Placement Update: ${app.drive.company_name}`,
          body: `Your application status for ${app.drive.role_title} is now: ${dto.status}`,
          type: 'PLACEMENT_UPDATE',
          category: 'Placement',
          deep_link: `/placement`,
        });
      }
    } catch (_) {}
    return updated;
  }

  async bulkUpdateApplicationStatus(role: Role, dto: BulkUpdateStatusDto) {
    if (!isPlacementOfficer(role)) {
      throw new ForbiddenError('Only placement officers can perform bulk status updates');
    }

    const result = await this.placementRepository.bulkUpdateApplicationStatus(
      dto.application_ids,
      dto.status,
      dto.offer_ctc
    );

    // Notify all affected students in background
    try {
      const applications = await prisma.placementApplication.findMany({
        where: { id: { in: dto.application_ids } },
        include: { drive: true },
      });

      for (const app of applications) {
        this.notificationsService.sendNotification({
          user_id: app.student_id,
          title: `Placement Status Update: ${app.drive.company_name}`,
          body: `Your application for ${app.drive.role_title} is now: ${dto.status}`,
          type: 'PLACEMENT_UPDATE',
          category: 'Placement',
          deep_link: `/placement`,
        }).catch(() => {});
      }
    } catch (_) {}

    return result;
  }

  // ==========================================
  // INTERVIEWS & OFFERS
  // ==========================================

  async scheduleInterview(role: Role, dto: ScheduleInterviewDto) {
    if (!isPlacementOfficer(role)) {
      throw new ForbiddenError('Only placement officers can schedule interviews');
    }
    const interview = await this.placementRepository.scheduleInterview(dto);
    try {
      const app = await prisma.placementApplication.findUnique({
        where: { id: dto.application_id },
        include: { drive: true },
      });
      if (app) {
        await this.notificationsService.sendNotification({
          user_id: app.student_id,
          title: `Interview Scheduled: ${app.drive.company_name}`,
          body: `Round: ${dto.round_name}. Time: ${new Date(dto.scheduled_at).toLocaleString()}`,
          type: 'PLACEMENT_UPDATE',
          category: 'Placement',
          deep_link: `/placement`,
        });
      }
    } catch (_) {}
    return interview;
  }

  async getInterviews(collegeId: string, query: InterviewQueryDto) {
    return this.placementRepository.findInterviews(collegeId, query);
  }

  async respondToOffer(applicationId: string, studentId: string, dto: RespondOfferDto) {
    return this.placementRepository.respondToOffer(applicationId, studentId, dto);
  }

  // ==========================================
  // COMPANIES
  // ==========================================

  async createCompany(collegeId: string, role: Role, dto: CreateCompanyDto) {
    if (!isPlacementOfficer(role)) {
      throw new ForbiddenError('Only placement officers and admins can create company profiles');
    }
    return this.placementRepository.createCompany(collegeId, dto);
  }

  async updateCompany(companyId: string, collegeId: string, role: Role, dto: UpdateCompanyDto) {
    if (!isPlacementOfficer(role)) {
      throw new ForbiddenError('Only placement officers and admins can update company profiles');
    }
    return this.placementRepository.updateCompany(companyId, collegeId, dto);
  }

  async getCompanies(collegeId: string, search?: string) {
    return this.placementRepository.findCompanies(collegeId, search);
  }

  async getCompanyDetails(companyId: string, collegeId: string) {
    const company = await this.placementRepository.findCompanyById(companyId, collegeId);
    if (!company) {
      throw new NotFoundError('Company not found');
    }
    return company;
  }

  async lookupCompany(query: string) {
    if (!query || !query.trim()) return [];
    return prisma.company.findMany({
      where: {
        name: { contains: query.trim(), mode: 'insensitive' },
      },
      take: 10,
    });
  }

  // ==========================================
  // PREPARATION RESOURCES
  // ==========================================

  async createResource(collegeId: string, creatorId: string, role: Role, dto: CreateResourceDto) {
    if (!isPlacementOfficer(role) && role !== Role.FACULTY) {
      throw new ForbiddenError('Only placement officers, faculty, and admins can upload preparation resources');
    }
    return this.placementRepository.createResource(collegeId, creatorId, dto);
  }

  async getResources(collegeId: string, query: ResourceQueryDto) {
    return this.placementRepository.findResources(collegeId, query);
  }

  async getResourceDetails(resourceId: string, collegeId: string) {
    const resource = await this.placementRepository.findResourceById(resourceId, collegeId);
    if (!resource) {
      throw new NotFoundError('Placement resource not found');
    }
    // Increment view asynchronously
    this.placementRepository.incrementResourceViews(resourceId).catch(() => {});
    return resource;
  }

  async deleteResource(resourceId: string, collegeId: string, role: Role) {
    if (!isPlacementOfficer(role)) {
      throw new ForbiddenError('Only placement officers and admins can delete preparation resources');
    }
    return this.placementRepository.deleteResource(resourceId, collegeId);
  }

  // ==========================================
  // STUDENTS DIRECTORY FOR PLACEMENT
  // ==========================================

  async getStudentsForPlacement(collegeId: string, role: Role, query: StudentPlacementQueryDto) {
    if (!isPlacementOfficer(role) && role !== Role.DEPT_ADMIN && role !== Role.FACULTY) {
      throw new ForbiddenError('Access denied to student placement directory');
    }
    return this.placementRepository.findStudentsForPlacement(collegeId, query);
  }

  async getStudentPlacementProfile(userId: string, currentRole: Role, currentUserId: string) {
    if (!isPlacementOfficer(currentRole) && currentRole !== Role.DEPT_ADMIN && currentRole !== Role.FACULTY && currentUserId !== userId) {
      throw new ForbiddenError('Access denied to student placement profile');
    }
    const profile = await this.placementRepository.getStudentPlacementProfile(userId);
    if (!profile) {
      throw new NotFoundError('Student placement profile not found');
    }
    return profile;
  }
}
