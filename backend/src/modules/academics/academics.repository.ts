import { prisma } from '../../config/database';
import {
  SubjectSearchFilter,
  AcademicSubjectDTO,
  AcademicSubjectDetailDTO,
  ResourceSearchResultDTO,
  AcademicFacultyDTO,
} from './academics.types';
import { SubjectResourceDTO } from '../faculty/faculty.types';

export class AcademicsRepository {
  private normalizeCode(raw: string): string {
    return raw.replace(/[\s\-_]+/g, '').toUpperCase().trim();
  }

  async findSubjects(
    filter: SubjectSearchFilter,
    userId?: string,
    collegeId?: string
  ): Promise<AcademicSubjectDTO[]> {
    const where: any = {};

    if (collegeId && collegeId.length > 10) {
      where.college_id = collegeId;
    }

    if (filter.departmentId) {
      where.department_id = filter.departmentId;
    }

    if (filter.semester) {
      where.semester = { contains: filter.semester, mode: 'insensitive' };
    }

    if (filter.academicYear) {
      where.academic_year = filter.academicYear;
    }

    if (filter.search && filter.search.trim().length > 0) {
      const q = filter.search.trim();
      const normalizedQ = this.normalizeCode(q);

      where.OR = [
        { code: { contains: q, mode: 'insensitive' } },
        { code: { contains: normalizedQ, mode: 'insensitive' } },
        { name: { contains: q, mode: 'insensitive' } },
        { description: { contains: q, mode: 'insensitive' } },
        {
          resources: {
            some: {
              OR: [
                { title: { contains: q, mode: 'insensitive' } },
                { topic: { contains: q, mode: 'insensitive' } },
                { unit: { contains: q, mode: 'insensitive' } },
              ],
            },
          },
        },
        {
          faculty: {
            OR: [
              { first_name: { contains: q, mode: 'insensitive' } },
              { last_name: { contains: q, mode: 'insensitive' } },
              { email: { contains: q, mode: 'insensitive' } },
            ],
          },
        },
      ];
    }

    const subjects = await prisma.subject.findMany({
      where,
      include: {
        department: true,
        faculty: {
          include: {
            faculty_profile: true,
          },
        },
        resources: {
          select: {
            unit: true,
          },
        },
        enrollments: userId
          ? {
              where: { student_id: userId },
              select: { id: true },
            }
          : false,
        _count: {
          select: {
            resources: true,
            enrollments: true,
          },
        },
      },
      orderBy: [{ code: 'asc' }, { name: 'asc' }],
      take: filter.limit || 50,
      skip: filter.page && filter.limit ? (filter.page - 1) * filter.limit : 0,
    });

    return subjects.map((s) => {
      const unitsSet = new Set<string>();
      s.resources.forEach((r) => {
        if (r.unit && r.unit.trim().length > 0) {
          unitsSet.add(r.unit.trim());
        }
      });
      const sortedUnits = Array.from(unitsSet).sort();

      const isEnrolled = Array.isArray(s.enrollments) && s.enrollments.length > 0;

      return {
        id: s.id,
        code: s.code,
        name: s.name,
        department: s.department?.name || 'Computer Science & Engineering',
        departmentCode: s.department?.code || undefined,
        departmentId: s.department_id,
        semester: s.semester,
        section: s.section,
        credits: s.credits,
        description: s.description || undefined,
        academicYear: s.academic_year || '2024-2025',
        faculty: {
          id: s.faculty.id,
          name: `${s.faculty.first_name} ${s.faculty.last_name}`.trim(),
          email: s.faculty.email,
          designation: s.faculty.faculty_profile?.designation || 'Associate Professor',
          avatarUrl: s.faculty.avatar_url,
        },
        resourcesCount: s._count.resources,
        unitsCount: sortedUnits.length,
        units: sortedUnits,
        isEnrolled,
      };
    });
  }

  async findSubjectById(subjectId: string, userId?: string): Promise<AcademicSubjectDetailDTO | null> {
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
        enrollments: userId
          ? {
              where: { student_id: userId },
              select: { id: true },
            }
          : false,
      },
    });

    if (!subject) return null;

    const prof = subject.faculty.faculty_profile;
    const isEnrolled = Array.isArray(subject.enrollments) && subject.enrollments.length > 0;

    const allResources: SubjectResourceDTO[] = subject.resources.map((r) => ({
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
    }));

    // Group resources by unit (e.g., "Unit 1", "Unit 2", ..., "General")
    const resourcesByUnit: Record<string, SubjectResourceDTO[]> = {};
    for (const res of allResources) {
      const unitKey = res.unit && res.unit.trim().length > 0 ? res.unit.trim() : 'General Resources';
      if (!resourcesByUnit[unitKey]) {
        resourcesByUnit[unitKey] = [];
      }
      resourcesByUnit[unitKey].push(res);
    }

    return {
      id: subject.id,
      code: subject.code,
      name: subject.name,
      department: subject.department?.name || 'Department of Computer Science & Engineering',
      departmentCode: subject.department?.code || undefined,
      departmentId: subject.department_id,
      semester: subject.semester,
      section: subject.section,
      credits: subject.credits,
      description: subject.description || undefined,
      academicYear: subject.academic_year || '2024-2025',
      faculty: {
        id: subject.faculty.id,
        name: `${subject.faculty.first_name} ${subject.faculty.last_name}`.trim(),
        email: subject.faculty.email,
        designation: prof?.designation || 'Associate Professor',
        qualification: prof?.qualification || 'Ph.D., M.Tech',
        department: subject.department?.name || prof?.department_name || 'Computer Science',
        specialization: prof?.specialization || 'Distributed Systems & Cloud Computing',
        officeRoom: prof?.office_room || 'Room 304, Tech Block',
        officeHours: prof?.office_hours || 'Mon - Thu: 2:00 PM - 4:00 PM',
        bio: prof?.bio || '',
        avatarUrl: subject.faculty.avatar_url,
        expertise: prof?.expertise || ['Cloud Computing', 'Distributed Systems'],
        publications: (prof?.publications as any[]) || [],
      },
      isEnrolled,
      announcements: subject.announcements.map((a) => ({
        id: a.id,
        subjectId: a.subject_id,
        title: a.title,
        content: a.content,
        authorId: a.faculty_id,
        authorName: `${a.faculty.first_name} ${a.faculty.last_name}`.trim(),
        createdAt: a.created_at,
      })),
      resourcesByUnit,
      allResources,
    };
  }

  async enrollStudent(subjectId: string, studentId: string): Promise<boolean> {
    await prisma.subjectEnrollment.upsert({
      where: {
        subject_id_student_id: {
          subject_id: subjectId,
          student_id: studentId,
        },
      },
      update: {},
      create: {
        subject_id: subjectId,
        student_id: studentId,
      },
    });
    return true;
  }

  async unenrollStudent(subjectId: string, studentId: string): Promise<boolean> {
    try {
      await prisma.subjectEnrollment.delete({
        where: {
          subject_id_student_id: {
            subject_id: subjectId,
            student_id: studentId,
          },
        },
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  async findEnrolledSubjects(studentId: string, collegeId?: string): Promise<AcademicSubjectDTO[]> {
    const enrollments = await prisma.subjectEnrollment.findMany({
      where: {
        student_id: studentId,
        ...(collegeId && collegeId.length > 10 ? { subject: { college_id: collegeId } } : {}),
      },
      include: {
        subject: {
          include: {
            department: true,
            faculty: {
              include: {
                faculty_profile: true,
              },
            },
            resources: {
              select: { unit: true },
            },
            _count: {
              select: {
                resources: true,
                enrollments: true,
              },
            },
          },
        },
      },
      orderBy: { enrolled_at: 'desc' },
    });

    return enrollments.map((e) => {
      const s = e.subject;
      const unitsSet = new Set<string>();
      s.resources.forEach((r) => {
        if (r.unit) unitsSet.add(r.unit.trim());
      });

      return {
        id: s.id,
        code: s.code,
        name: s.name,
        department: s.department?.name || 'Computer Science & Engineering',
        departmentCode: s.department?.code || undefined,
        departmentId: s.department_id,
        semester: s.semester,
        section: s.section,
        credits: s.credits,
        description: s.description || undefined,
        academicYear: s.academic_year || '2024-2025',
        faculty: {
          id: s.faculty.id,
          name: `${s.faculty.first_name} ${s.faculty.last_name}`.trim(),
          email: s.faculty.email,
          designation: s.faculty.faculty_profile?.designation || 'Associate Professor',
          avatarUrl: s.faculty.avatar_url,
        },
        resourcesCount: s._count.resources,
        unitsCount: unitsSet.size,
        units: Array.from(unitsSet).sort(),
        isEnrolled: true,
      };
    });
  }

  async searchResources(
    filter: SubjectSearchFilter,
    collegeId?: string
  ): Promise<ResourceSearchResultDTO[]> {
    const where: any = {
      visibility: 'PUBLIC',
    };

    if (collegeId && collegeId.length > 10) {
      where.subject = { college_id: collegeId };
    }

    if (filter.departmentId) {
      where.subject = {
        ...where.subject,
        department_id: filter.departmentId,
      };
    }

    if (filter.semester) {
      where.subject = {
        ...where.subject,
        semester: { contains: filter.semester, mode: 'insensitive' },
      };
    }

    if (filter.unit) {
      where.unit = { contains: filter.unit, mode: 'insensitive' };
    }

    if (filter.resourceType) {
      where.resource_type = filter.resourceType.toUpperCase();
    }

    if (filter.search && filter.search.trim().length > 0) {
      const q = filter.search.trim();
      const normQ = this.normalizeCode(q);

      where.OR = [
        { title: { contains: q, mode: 'insensitive' } },
        { topic: { contains: q, mode: 'insensitive' } },
        { description: { contains: q, mode: 'insensitive' } },
        { unit: { contains: q, mode: 'insensitive' } },
        {
          subject: {
            OR: [
              { code: { contains: q, mode: 'insensitive' } },
              { code: { contains: normQ, mode: 'insensitive' } },
              { name: { contains: q, mode: 'insensitive' } },
            ],
          },
        },
        {
          uploaded_by: {
            OR: [
              { first_name: { contains: q, mode: 'insensitive' } },
              { last_name: { contains: q, mode: 'insensitive' } },
            ],
          },
        },
      ];
    }

    const resources = await prisma.subjectResource.findMany({
      where,
      include: {
        subject: {
          include: {
            department: true,
          },
        },
        uploaded_by: true,
      },
      orderBy: [{ download_count: 'desc' }, { created_at: 'desc' }],
      take: filter.limit || 50,
      skip: filter.page && filter.limit ? (filter.page - 1) * filter.limit : 0,
    });

    return resources.map((r) => ({
      id: r.id,
      subjectId: r.subject_id,
      subjectCode: r.subject.code,
      subjectName: r.subject.name,
      departmentName: r.subject.department?.name || 'Engineering',
      facultyName: `${r.uploaded_by.first_name} ${r.uploaded_by.last_name}`.trim(),
      title: r.title,
      description: r.description || undefined,
      fileUrl: r.file_url,
      fileType: r.file_type,
      unit: r.unit,
      topic: r.topic,
      resourceType: r.resource_type,
      visibility: r.visibility,
      downloadCount: r.download_count,
      viewCount: r.view_count,
      createdAt: r.created_at,
    }));
  }

  async incrementResourceView(resourceId: string): Promise<boolean> {
    try {
      await prisma.subjectResource.update({
        where: { id: resourceId },
        data: { view_count: { increment: 1 } },
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  async incrementResourceDownload(resourceId: string): Promise<boolean> {
    try {
      await prisma.subjectResource.update({
        where: { id: resourceId },
        data: { download_count: { increment: 1 } },
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  async findFacultyDirectory(collegeId?: string, search?: string, departmentId?: string): Promise<AcademicFacultyDTO[]> {
    const where: any = {
      role: 'FACULTY',
      status: 'ACTIVE',
    };

    if (collegeId && collegeId.length > 10) {
      where.college_id = collegeId;
    }

    if (departmentId) {
      where.department_id = departmentId;
    }

    if (search && search.trim().length > 0) {
      const q = search.trim();
      where.OR = [
        { first_name: { contains: q, mode: 'insensitive' } },
        { last_name: { contains: q, mode: 'insensitive' } },
        { email: { contains: q, mode: 'insensitive' } },
        {
          faculty_profile: {
            OR: [
              { specialization: { contains: q, mode: 'insensitive' } },
              { designation: { contains: q, mode: 'insensitive' } },
              { bio: { contains: q, mode: 'insensitive' } },
            ],
          },
        },
      ];
    }

    const facultyUsers = await prisma.user.findMany({
      where,
      include: {
        department: true,
        faculty_profile: true,
        faculty_subjects: {
          select: {
            id: true,
            code: true,
            name: true,
            semester: true,
            section: true,
            credits: true,
          },
        },
      },
      orderBy: [{ first_name: 'asc' }, { last_name: 'asc' }],
    });

    return facultyUsers.map((f) => {
      const prof = f.faculty_profile;
      return {
        id: f.id,
        name: `${f.first_name} ${f.last_name}`.trim(),
        email: f.email,
        designation: prof?.designation || 'Associate Professor',
        qualification: prof?.qualification || 'Ph.D., M.Tech',
        department: f.department?.name || prof?.department_name || 'Department of Computer Science',
        specialization: prof?.specialization || 'Distributed Systems & Cloud Computing',
        bio: prof?.bio || '',
        officeRoom: prof?.office_room || 'Room 304, Block B',
        officeHours: prof?.office_hours || 'Mon - Thu: 2:00 PM - 4:00 PM',
        avatarUrl: f.avatar_url,
        expertise: prof?.expertise || [],
        publications: (prof?.publications as any[]) || [],
        subjectsTaught: f.faculty_subjects.map((sub) => ({
          id: sub.id,
          code: sub.code,
          name: sub.name,
          semester: sub.semester,
          section: sub.section,
          credits: sub.credits,
        })),
      };
    });
  }

  async findFacultyById(facultyId: string): Promise<AcademicFacultyDTO | null> {
    const user = await prisma.user.findUnique({
      where: { id: facultyId },
      include: {
        department: true,
        faculty_profile: true,
        faculty_subjects: {
          select: {
            id: true,
            code: true,
            name: true,
            semester: true,
            section: true,
            credits: true,
          },
        },
      },
    });

    if (!user || user.role !== 'FACULTY') return null;

    const prof = user.faculty_profile;
    return {
      id: user.id,
      name: `${user.first_name} ${user.last_name}`.trim(),
      email: user.email,
      designation: prof?.designation || 'Associate Professor',
      qualification: prof?.qualification || 'Ph.D., M.Tech',
      department: user.department?.name || prof?.department_name || 'Computer Science',
      specialization: prof?.specialization || 'Distributed Systems & Cloud Computing',
      bio: prof?.bio || '',
      officeRoom: prof?.office_room || 'Room 304, Block B',
      officeHours: prof?.office_hours || 'Mon - Thu: 2:00 PM - 4:00 PM',
      avatarUrl: user.avatar_url,
      expertise: prof?.expertise || [],
      publications: (prof?.publications as any[]) || [],
      subjectsTaught: user.faculty_subjects.map((sub) => ({
        id: sub.id,
        code: sub.code,
        name: sub.name,
        semester: sub.semester,
        section: sub.section,
        credits: sub.credits,
      })),
    };
  }
}
