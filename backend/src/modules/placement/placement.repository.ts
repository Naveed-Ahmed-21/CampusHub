import { prisma } from '../../config/database';
import { ApplicationStatus, DriveStatus } from '@prisma/client';
import {
  CreateDriveDto,
  ApplyDriveDto,
  UpdateApplicationStatusDto,
  ScheduleInterviewDto,
  RespondOfferDto,
  DriveQueryDto,
} from './placement.types';

export class PlacementRepository {
  // Placement Officer Dashboard & Metrics
  async getOfficerDashboardStats(collegeId: string) {
    const [totalDrives, activeDrives, totalApplications, offeredCount, acceptedOffers] = await Promise.all([
      prisma.placementDrive.count({ where: { college_id: collegeId } }),
      prisma.placementDrive.count({ where: { college_id: collegeId, status: DriveStatus.ONGOING } }),
      prisma.placementApplication.count({ where: { drive: { college_id: collegeId } } }),
      prisma.placementApplication.count({
        where: { drive: { college_id: collegeId }, status: ApplicationStatus.OFFERED },
      }),
      prisma.placementApplication.count({
        where: { drive: { college_id: collegeId }, offer_status: 'ACCEPTED' },
      }),
    ]);

    return {
      totalDrives,
      activeDrives,
      totalApplications,
      offeredCount,
      acceptedOffers,
    };
  }

  // Student Dashboard & Applications Tracking
  async getStudentDashboardStats(userId: string) {
    const [myApplications, myOffers, upcomingInterviews] = await Promise.all([
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
    ]);

    return {
      myApplications,
      myOffers,
      upcomingInterviews,
    };
  }

  // Drives
  async createDrive(collegeId: string, dto: CreateDriveDto) {
    return prisma.placementDrive.create({
      data: {
        college_id: collegeId,
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
      },
      include: {
        _count: { select: { applications: true } },
      },
    });
  }

  async findDrives(collegeId: string, query: DriveQueryDto) {
    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const where: Record<string, unknown> = { college_id: collegeId };
    if (query.status) where.status = query.status;
    if (query.search) {
      where.OR = [
        { company_name: { contains: query.search, mode: 'insensitive' } },
        { role_title: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    const [total, drives] = await Promise.all([
      prisma.placementDrive.count({ where: where as never }),
      prisma.placementDrive.findMany({
        where: where as never,
        skip,
        take: limit,
        orderBy: { created_at: 'desc' },
        include: {
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
        applications: {
          include: {
            student: {
              select: {
                id: true,
                first_name: true,
                last_name: true,
                email: true,
                avatar_url: true,
                department: { select: { id: true, code: true, name: true } },
              },
            },
            interviews: true,
          },
        },
        _count: { select: { applications: true } },
      },
    });
  }

  // Applications
  async createApplication(studentId: string, dto: ApplyDriveDto) {
    return prisma.placementApplication.create({
      data: {
        drive_id: dto.drive_id,
        student_id: studentId,
        resume_url: dto.resume_url,
      },
      include: {
        drive: true,
      },
    });
  }

  async findApplication(studentId: string, driveId: string) {
    return prisma.placementApplication.findUnique({
      where: { drive_id_student_id: { drive_id: driveId, student_id: studentId } },
    });
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

  // Interviews & Offers
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

  async respondToOffer(applicationId: string, studentId: string, dto: RespondOfferDto) {
    return prisma.placementApplication.update({
      where: { id: applicationId, student_id: studentId, status: ApplicationStatus.OFFERED },
      data: {
        offer_status: dto.offer_status,
      },
      include: { drive: true },
    });
  }
}
