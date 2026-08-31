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
} from './faculty.types';

export class FacultyRepository {
  async getFacultyUserInfo(facultyId: string) {
    try {
      const user = await prisma.user.findUnique({
        where: { id: facultyId },
        include: { department: true },
      });
      if (user) {
        return {
          id: user.id,
          name: `${user.first_name} ${user.last_name}`.trim(),
          email: user.email,
          designation: 'Associate Professor',
          department: user.department?.name || 'Department of Computer Science',
          avatarUrl: user.avatar_url,
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
        resourcesCount: s._count.resources,
        announcementsCount: s._count.announcements,
        studentsCount: s._count.enrollments,
        createdAt: s.created_at,
      }));
    } catch (_) {
      return [];
    }
  }

  async findSubjectById(subjectId: string): Promise<(SubjectDTO & { facultyId: string; resources: SubjectResourceDTO[]; announcements: SubjectAnnouncementDTO[] }) | null> {
    const subject = await prisma.subject.findUnique({
      where: { id: subjectId },
      include: {
        department: true,
        faculty: true,
        resources: {
          include: { uploaded_by: true },
          orderBy: { created_at: 'desc' },
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
      code: subject.code,
      name: subject.name,
      department: subject.department?.name || 'Engineering Department',
      semester: subject.semester,
      section: subject.section,
      credits: subject.credits,
      description: subject.description || undefined,
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
        uploadedById: r.uploaded_by_id,
        uploadedByName: `${r.uploaded_by.first_name} ${r.uploaded_by.last_name}`.trim(),
        createdAt: r.created_at,
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
      },
      include: { department: true },
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
      resourcesCount: 0,
      announcementsCount: 0,
      studentsCount: 0,
      createdAt: subject.created_at,
    };
  }

  async createSubjectResource(facultyId: string, subjectId: string, dto: CreateSubjectResourceDTO): Promise<SubjectResourceDTO> {
    const resource = await prisma.subjectResource.create({
      data: {
        subject_id: subjectId,
        uploaded_by_id: facultyId,
        title: dto.title.trim(),
        description: dto.description?.trim() || null,
        file_url: dto.fileUrl.trim(),
        file_type: dto.fileType.toUpperCase().trim(),
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
      uploadedById: resource.uploaded_by_id,
      uploadedByName: `${resource.uploaded_by.first_name} ${resource.uploaded_by.last_name}`.trim(),
      createdAt: resource.created_at,
    };
  }

  async deleteSubjectResource(resourceId: string): Promise<boolean> {
    await prisma.subjectResource.delete({
      where: { id: resourceId },
    });
    return true;
  }

  async createSubjectAnnouncement(facultyId: string, subjectId: string, dto: CreateSubjectAnnouncementDTO): Promise<SubjectAnnouncementDTO> {
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
