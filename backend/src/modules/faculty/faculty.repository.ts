import { prisma } from '../../config/database';
import {
  CreateSubjectDTO,
  CreateSubjectResourceDTO,
  CreateSubjectAnnouncementDTO,
  SubjectDTO,
  SubjectResourceDTO,
  SubjectAnnouncementDTO,
  ClassScheduleSlotDTO,
  MenteeStudentDTO,
  FacultyProfileDTO,
  UpdateFacultyProfileDTO,
} from './faculty.types';

export class FacultyRepository {
  async getFacultyUserInfo(facultyId: string) {
    try {
      const user = await prisma.user.findUnique({
        where: { id: facultyId },
        include: {
          department: true,
          faculty_profile: true,
        },
      });
      if (user) {
        return {
          id: user.id,
          name: `${user.first_name} ${user.last_name}`.trim(),
          email: user.email,
          designation: user.faculty_profile?.designation || 'Associate Professor',
          department: user.department?.name || user.faculty_profile?.department_name || 'Department of Computer Science',
          avatarUrl: user.avatar_url,
          officeRoom: user.faculty_profile?.office_room || 'Room 304, Tech Block',
          officeHours: user.faculty_profile?.office_hours || 'Mon - Thu: 2:00 PM - 4:00 PM',
          specialization: user.faculty_profile?.specialization || 'Distributed Systems & Cloud Computing',
        };
      }
    } catch (_) {}
    return null;
  }

  async findSubjectsByFaculty(facultyId: string, collegeId?: string): Promise<SubjectDTO[]> {
    try {
      const where: any = {};
      if (facultyId && collegeId && collegeId.length > 10) {
        where.OR = [{ faculty_id: facultyId }, { college_id: collegeId }];
      } else if (facultyId && facultyId.length > 10) {
        where.faculty_id = facultyId;
      } else if (collegeId && collegeId.length > 10) {
        where.college_id = collegeId;
      }

      const subjects = await prisma.subject.findMany({
        where,
        include: {
          department: true,
          _count: {
            select: {
              resources: true,
              announcements: true,
              enrollments: true,
            },
          },
        },
        orderBy: { created_at: 'desc' },
      });

      return subjects.map((s) => ({
        id: s.id,
        code: s.code,
        name: s.name,
        department: s.department?.name || 'Computer Science & Engineering',
        semester: s.semester,
        section: s.section,
        credits: s.credits,
        description: s.description || undefined,
        academicYear: s.academic_year || '2024-2025',
        resourcesCount: s._count.resources,
        announcementsCount: s._count.announcements,
        studentsCount: s._count.enrollments,
        createdAt: s.created_at,
      }));
    } catch (_) {
      return [];
    }
  }

  async findSubjectById(
    subjectId: string
  ): Promise<
    | (SubjectDTO & {
        facultyId: string;
        facultyName: string;
        facultyEmail: string;
        facultyAvatarUrl?: string | null;
        facultyDesignation?: string;
        facultyOfficeRoom?: string;
        facultyOfficeHours?: string;
        resources: SubjectResourceDTO[];
        announcements: SubjectAnnouncementDTO[];
      })
    | null
  > {
    const subject = await prisma.subject.findUnique({
      where: { id: subjectId },
      include: {
        department: true,
        faculty: {
          include: {
            faculty_profile: true,
          },
        },
        resources: {
          include: { uploaded_by: true },
          orderBy: [{ unit: 'asc' }, { created_at: 'desc' }],
        },
        announcements: {
          include: { faculty: true },
          orderBy: { created_at: 'desc' },
        },
        _count: {
          select: { enrollments: true },
        },
      },
    });

    if (!subject) return null;

    return {
      id: subject.id,
      facultyId: subject.faculty_id,
      facultyName: `${subject.faculty.first_name} ${subject.faculty.last_name}`.trim(),
      facultyEmail: subject.faculty.email,
      facultyAvatarUrl: subject.faculty.avatar_url,
      facultyDesignation: subject.faculty.faculty_profile?.designation || 'Associate Professor',
      facultyOfficeRoom: subject.faculty.faculty_profile?.office_room || 'Room 304, Block B',
      facultyOfficeHours: subject.faculty.faculty_profile?.office_hours || 'Mon - Thu: 2:00 PM - 4:00 PM',
      code: subject.code,
      name: subject.name,
      department: subject.department?.name || 'Engineering Department',
      semester: subject.semester,
      section: subject.section,
      credits: subject.credits,
      description: subject.description || undefined,
      academicYear: subject.academic_year || '2024-2025',
      resourcesCount: subject.resources.length,
      announcementsCount: subject.announcements.length,
      studentsCount: subject._count.enrollments,
      createdAt: subject.created_at,
      resources: subject.resources.map((r) => ({
        id: r.id,
        subjectId: r.subject_id,
        title: r.title,
        description: r.description || undefined,
        fileUrl: r.file_url,
        fileType: r.file_type,
        unit: r.unit,
        topic: r.topic,
        resourceType: r.resource_type || 'NOTES',
        visibility: r.visibility || 'PUBLIC',
        thumbnailUrl: r.thumbnail_url,
        academicYear: r.academic_year || '2024-2025',
        downloadCount: r.download_count || 0,
        viewCount: r.view_count || 0,
        uploadedById: r.uploaded_by_id,
        uploadedByName: `${r.uploaded_by.first_name} ${r.uploaded_by.last_name}`.trim(),
        createdAt: r.created_at,
        updatedAt: r.updated_at,
      })),
      announcements: subject.announcements.map((a) => ({
        id: a.id,
        subjectId: a.subject_id,
        title: a.title,
        content: a.content,
        authorId: a.faculty_id,
        authorName: `${a.faculty.first_name} ${a.faculty.last_name}`.trim(),
        createdAt: a.created_at,
      })),
    };
  }

  async createSubject(facultyId: string, collegeId: string, dto: CreateSubjectDTO): Promise<SubjectDTO> {
    const subject = await prisma.subject.create({
      data: {
        college_id: collegeId,
        faculty_id: facultyId,
        department_id: dto.departmentId || null,
        code: dto.code.toUpperCase().trim(),
        name: dto.name.trim(),
        semester: dto.semester.trim(),
        section: (dto.section || 'A').toUpperCase().trim(),
        credits: dto.credits || 3,
        description: dto.description?.trim() || null,
        academic_year: dto.academicYear || '2024-2025',
      },
      include: { department: true },
    });

    // Also record faculty subject assignment
    await prisma.facultySubject.upsert({
      where: {
        faculty_id_subject_id: {
          faculty_id: facultyId,
          subject_id: subject.id,
        },
      },
      update: {},
      create: {
        faculty_id: facultyId,
        subject_id: subject.id,
        role: 'PRIMARY',
      },
    });

    return {
      id: subject.id,
      code: subject.code,
      name: subject.name,
      department: subject.department?.name || dto.departmentName || 'Computer Science & Engineering',
      semester: subject.semester,
      section: subject.section,
      credits: subject.credits,
      description: subject.description || undefined,
      academicYear: subject.academic_year || '2024-2025',
      resourcesCount: 0,
      announcementsCount: 0,
      studentsCount: 0,
      createdAt: subject.created_at,
    };
  }

  async createSubjectResource(
    facultyId: string,
    subjectId: string,
    dto: CreateSubjectResourceDTO
  ): Promise<SubjectResourceDTO> {
    const resource = await prisma.subjectResource.create({
      data: {
        subject_id: subjectId,
        uploaded_by_id: facultyId,
        title: dto.title.trim(),
        description: dto.description?.trim() || null,
        file_url: dto.fileUrl.trim(),
        file_type: dto.fileType.toUpperCase().trim(),
        unit: dto.unit?.trim() || null,
        topic: dto.topic?.trim() || null,
        resource_type: (dto.resourceType || 'NOTES').toUpperCase().trim(),
        visibility: (dto.visibility || 'PUBLIC').toUpperCase().trim(),
        thumbnail_url: dto.thumbnailUrl?.trim() || null,
        academic_year: dto.academicYear || '2024-2025',
      },
      include: { uploaded_by: true },
    });

    return {
      id: resource.id,
      subjectId: resource.subject_id,
      title: resource.title,
      description: resource.description || undefined,
      fileUrl: resource.file_url,
      fileType: resource.file_type,
      unit: resource.unit,
      topic: resource.topic,
      resourceType: resource.resource_type,
      visibility: resource.visibility,
      thumbnailUrl: resource.thumbnail_url,
      academicYear: resource.academic_year,
      downloadCount: resource.download_count,
      viewCount: resource.view_count,
      uploadedById: resource.uploaded_by_id,
      uploadedByName: `${resource.uploaded_by.first_name} ${resource.uploaded_by.last_name}`.trim(),
      createdAt: resource.created_at,
      updatedAt: resource.updated_at,
    };
  }

  async updateSubjectResource(
    resourceId: string,
    dto: Partial<CreateSubjectResourceDTO>
  ): Promise<SubjectResourceDTO | null> {
    const data: any = {};
    if (dto.title !== undefined) data.title = dto.title.trim();
    if (dto.description !== undefined) data.description = dto.description?.trim() || null;
    if (dto.fileUrl !== undefined) data.file_url = dto.fileUrl.trim();
    if (dto.fileType !== undefined) data.file_type = dto.fileType.toUpperCase().trim();
    if (dto.unit !== undefined) data.unit = dto.unit?.trim() || null;
    if (dto.topic !== undefined) data.topic = dto.topic?.trim() || null;
    if (dto.resourceType !== undefined) data.resource_type = dto.resourceType.toUpperCase().trim();
    if (dto.visibility !== undefined) data.visibility = dto.visibility.toUpperCase().trim();
    if (dto.thumbnailUrl !== undefined) data.thumbnail_url = dto.thumbnailUrl?.trim() || null;

    const resource = await prisma.subjectResource.update({
      where: { id: resourceId },
      data,
      include: { uploaded_by: true },
    });

    return {
      id: resource.id,
      subjectId: resource.subject_id,
      title: resource.title,
      description: resource.description || undefined,
      fileUrl: resource.file_url,
      fileType: resource.file_type,
      unit: resource.unit,
      topic: resource.topic,
      resourceType: resource.resource_type,
      visibility: resource.visibility,
      thumbnailUrl: resource.thumbnail_url,
      academicYear: resource.academic_year,
      downloadCount: resource.download_count,
      viewCount: resource.view_count,
      uploadedById: resource.uploaded_by_id,
      uploadedByName: `${resource.uploaded_by.first_name} ${resource.uploaded_by.last_name}`.trim(),
      createdAt: resource.created_at,
      updatedAt: resource.updated_at,
    };
  }

  async deleteSubjectResource(resourceId: string): Promise<boolean> {
    await prisma.subjectResource.delete({
      where: { id: resourceId },
    });
    return true;
  }

  async createSubjectAnnouncement(
    facultyId: string,
    subjectId: string,
    dto: CreateSubjectAnnouncementDTO
  ): Promise<SubjectAnnouncementDTO> {
    const announcement = await prisma.subjectAnnouncement.create({
      data: {
        subject_id: subjectId,
        faculty_id: facultyId,
        title: dto.title.trim(),
        content: dto.content.trim(),
      },
      include: {
        subject: true,
        faculty: true,
      },
    });

    return {
      id: announcement.id,
      subjectId: announcement.subject_id,
      subjectName: announcement.subject.name,
      title: announcement.title,
      content: announcement.content,
      authorId: announcement.faculty_id,
      authorName: `${announcement.faculty.first_name} ${announcement.faculty.last_name}`.trim(),
      createdAt: announcement.created_at,
    };
  }

  async getFacultyProfile(facultyId: string): Promise<FacultyProfileDTO | null> {
    const user = await prisma.user.findUnique({
      where: { id: facultyId },
      include: {
        department: true,
        faculty_profile: true,
        _count: {
          select: {
            faculty_subjects: true,
            mentored_students: true,
          },
        },
      },
    });

    if (!user) return null;

    const prof = user.faculty_profile;

    return {
      id: prof?.id || user.id,
      userId: user.id,
      name: `${user.first_name} ${user.last_name}`.trim(),
      email: user.email,
      avatarUrl: user.avatar_url,
      designation: prof?.designation || 'Associate Professor',
      qualification: prof?.qualification || 'Ph.D., M.Tech',
      department: user.department?.name || prof?.department_name || 'Department of Computer Science',
      specialization: prof?.specialization || 'Distributed Systems & Cloud Architecture',
      bio: prof?.bio || '',
      officeRoom: prof?.office_room || 'Room 304, Block B',
      officeHours: prof?.office_hours || 'Mon - Thu: 2:00 PM - 4:00 PM',
      expertise: prof?.expertise || ['Cloud Computing', 'Distributed Systems'],
      publications: (prof?.publications as any[]) || [],
      linkedinUrl: prof?.linkedin_url,
      googleScholar: prof?.google_scholar,
      subjectsCount: user._count.faculty_subjects,
      menteesCount: user._count.mentored_students,
    };
  }

  async updateFacultyProfile(facultyId: string, dto: UpdateFacultyProfileDTO): Promise<FacultyProfileDTO> {
    const data: any = {};
    if (dto.designation !== undefined) data.designation = dto.designation;
    if (dto.qualification !== undefined) data.qualification = dto.qualification;
    if (dto.departmentName !== undefined) data.department_name = dto.departmentName;
    if (dto.specialization !== undefined) data.specialization = dto.specialization;
    if (dto.bio !== undefined) data.bio = dto.bio;
    if (dto.officeRoom !== undefined) data.office_room = dto.officeRoom;
    if (dto.officeHours !== undefined) data.office_hours = dto.officeHours;
    if (dto.expertise !== undefined) data.expertise = dto.expertise;
    if (dto.publications !== undefined) data.publications = dto.publications;
    if (dto.linkedinUrl !== undefined) data.linkedin_url = dto.linkedinUrl;
    if (dto.googleScholar !== undefined) data.google_scholar = dto.googleScholar;

    if (dto.avatarUrl !== undefined) {
      await prisma.user.update({
        where: { id: facultyId },
        data: { avatar_url: dto.avatarUrl },
      });
    }

    await prisma.facultyProfile.upsert({
      where: { user_id: facultyId },
      update: data,
      create: {
        user_id: facultyId,
        ...data,
      },
    });

    const updated = await this.getFacultyProfile(facultyId);
    return updated!;
  }

  async getMentees(facultyId: string, collegeId: string): Promise<MenteeStudentDTO[]> {
    try {
      const mentees = await prisma.studentMentorship.findMany({
        where: { faculty_id: facultyId },
        include: {
          student: {
            include: {
              department: true,
              portfolio: true,
            },
          },
        },
      });

      return mentees.map((m) => ({
        id: m.student.id,
        name: `${m.student.first_name} ${m.student.last_name}`.trim(),
        rollNumber: m.student.roll_number || '21CS001',
        department: m.student.department?.name || 'Computer Science',
        semester: 'Semester 7',
        cgpa: 8.5,
        email: m.student.email,
        avatarUrl: m.student.avatar_url,
        hasPortfolio: Boolean(m.student.portfolio),
      }));
    } catch (_) {
      return [];
    }
  }

  async getRecentAnnouncements(facultyId: string, collegeId: string): Promise<SubjectAnnouncementDTO[]> {
    try {
      const announcements = await prisma.subjectAnnouncement.findMany({
        where: {
          faculty_id: facultyId,
        },
        include: {
          subject: true,
          faculty: true,
        },
        orderBy: { created_at: 'desc' },
        take: 5,
      });

      return announcements.map((a) => ({
        id: a.id,
        subjectId: a.subject_id,
        subjectName: a.subject.name,
        title: a.title,
        content: a.content,
        authorId: a.faculty_id,
        authorName: `${a.faculty.first_name} ${a.faculty.last_name}`.trim(),
        createdAt: a.created_at,
      }));
    } catch (_) {
      return [];
    }
  }
}
