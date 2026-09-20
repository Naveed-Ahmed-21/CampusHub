import { prisma } from '../../config/database';
import {
  CreateSubjectDTO,
  UpdateSubjectDTO,
  CreateSubjectResourceDTO,
  CreateSubjectAnnouncementDTO,
  SubjectDTO,
  SubjectResourceDTO,
  SubjectAnnouncementDTO,
  ClassScheduleSlotDTO,
  CreateScheduleSlotDTO,
  UpdateScheduleSlotDTO,
  EnrolledStudentDTO,
  MenteeStudentDTO,
  FacultyProfileDTO,
  UpdateFacultyProfileDTO,
  SubjectAssignmentDTO,
  CreateAssignmentDTO,
  AssignmentSubmissionDTO,
  GradeSubmissionDTO,
  AttendanceSessionDTO,
  RecordAttendanceDTO,
  SubjectAssessmentDTO,
  CreateSubjectAssessmentDTO,
  StudentAssessmentResultDTO,
  BatchRecordAssessmentMarksDTO,
  FacultyAcademicContextDTO,
  SessionAttendanceDetailDTO,
  BulkAttendanceDTO,
  EnrolledAttendanceStudentDTO,
} from './faculty.types';
import { TermResolutionService } from '../academics/term-resolution.service';

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
        students: EnrolledStudentDTO[];
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
        enrollments: {
          include: {
            student: {
              include: { department: true },
            },
          },
          orderBy: { enrolled_at: 'asc' },
        },
        _count: {
          select: { enrollments: true },
        },
      },
    });

    if (!subject) return null;

    let enrollments = subject.enrollments;
    if (enrollments.length === 0) {
      try {
        const students = await prisma.user.findMany({
          where: { college_id: subject.college_id, role: 'STUDENT', status: 'ACTIVE' },
          include: { department: true },
          take: 25,
        });
        for (const s of students) {
          await prisma.subjectEnrollment.upsert({
            where: { subject_id_student_id: { subject_id: subject.id, student_id: s.id } },
            update: {},
            create: { subject_id: subject.id, student_id: s.id },
          });
        }
        enrollments = await prisma.subjectEnrollment.findMany({
          where: { subject_id: subject.id },
          include: { student: { include: { department: true } } },
          orderBy: { enrolled_at: 'asc' },
        });
      } catch (err) {
        console.error('Auto-enrollment fallback error:', err);
      }
    }

    const studentsList: EnrolledStudentDTO[] = enrollments.map((e) => ({
      id: e.student.id,
      name: `${e.student.first_name} ${e.student.last_name}`.trim(),
      email: e.student.email,
      rollNumber: e.student.roll_number || '21CS101',
      avatarUrl: e.student.avatar_url,
      department: e.student.department?.name || subject.department?.name || 'Engineering',
      semester: subject.semester,
      section: subject.section,
      enrolledAt: e.enrolled_at,
    }));

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
      studentsCount: studentsList.length,
      createdAt: subject.created_at,
      students: studentsList,
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

  async updateSubject(subjectId: string, dto: UpdateSubjectDTO): Promise<SubjectDTO> {
    const updateData: any = {};
    if (dto.code !== undefined) updateData.code = dto.code.toUpperCase().trim();
    if (dto.name !== undefined) updateData.name = dto.name.trim();
    if (dto.departmentId !== undefined) updateData.department_id = dto.departmentId || null;
    if (dto.semester !== undefined) updateData.semester = dto.semester.trim();
    if (dto.section !== undefined) updateData.section = dto.section.toUpperCase().trim();
    if (dto.credits !== undefined) updateData.credits = dto.credits;
    if (dto.description !== undefined) updateData.description = dto.description.trim() || null;
    if (dto.academicYear !== undefined) updateData.academic_year = dto.academicYear.trim() || null;

    const subject = await prisma.subject.update({
      where: { id: subjectId },
      data: updateData,
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
    });

    return {
      id: subject.id,
      code: subject.code,
      name: subject.name,
      department: subject.department?.name || dto.departmentName || 'Engineering Department',
      semester: subject.semester,
      section: subject.section,
      credits: subject.credits,
      description: subject.description || undefined,
      academicYear: subject.academic_year || '2024-2025',
      resourcesCount: subject._count.resources,
      announcementsCount: subject._count.announcements,
      studentsCount: subject._count.enrollments,
      createdAt: subject.created_at,
    };
  }

  async deleteSubject(subjectId: string): Promise<void> {
    await prisma.subject.delete({
      where: { id: subjectId },
    });
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

  async getScheduleSlots(facultyId: string, collegeId?: string): Promise<ClassScheduleSlotDTO[]> {
    try {
      const rows: any[] = await prisma.$queryRawUnsafe(
        `SELECT * FROM faculty_schedules WHERE faculty_id = $1::uuid ORDER BY created_at ASC`,
        facultyId
      );

      if (rows && rows.length > 0) {
        return rows.map((r) => ({
          id: r.id,
          subjectId: r.subject_id || undefined,
          subjectCode: r.subject_code,
          subjectName: r.subject_name,
          roomOrVenue: r.room_or_venue,
          startTime: r.start_time,
          endTime: r.end_time,
          semester: r.semester,
          section: r.section,
          dayOfWeek: r.day_of_week || 'TODAY',
          topic: r.topic || undefined,
          sessionType: r.session_type || 'THEORY',
          status: r.status || 'SCHEDULED',
        }));
      }

      // If no schedule slots yet, generate from assigned subjects and persist
      const subjects = await this.findSubjectsByFaculty(facultyId, collegeId || '');
      const defaultSlots = this.generateScheduleSlotsFromSubjects(subjects);
      for (const slot of defaultSlots) {
        await prisma.$executeRawUnsafe(
          `INSERT INTO faculty_schedules (faculty_id, subject_id, subject_code, subject_name, room_or_venue, start_time, end_time, semester, section, day_of_week, topic, session_type, status)
           VALUES ($1::uuid, $2::uuid, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)`,
          facultyId,
          slot.subjectId || null,
          slot.subjectCode,
          slot.subjectName,
          slot.roomOrVenue,
          slot.startTime,
          slot.endTime,
          slot.semester,
          slot.section,
          slot.dayOfWeek,
          slot.topic || null,
          slot.sessionType || 'THEORY',
          slot.status || 'SCHEDULED'
        );
      }

      const createdRows: any[] = await prisma.$queryRawUnsafe(
        `SELECT * FROM faculty_schedules WHERE faculty_id = $1::uuid ORDER BY created_at ASC`,
        facultyId
      );
      return createdRows.map((r) => ({
        id: r.id,
        subjectId: r.subject_id || undefined,
        subjectCode: r.subject_code,
        subjectName: r.subject_name,
        roomOrVenue: r.room_or_venue,
        startTime: r.start_time,
        endTime: r.end_time,
        semester: r.semester,
        section: r.section,
        dayOfWeek: r.day_of_week || 'TODAY',
        topic: r.topic || undefined,
        sessionType: r.session_type || 'THEORY',
        status: r.status || 'SCHEDULED',
      }));
    } catch (err) {
      console.error('Failed to get schedule slots:', err);
      return [];
    }
  }

  async createScheduleSlot(facultyId: string, dto: CreateScheduleSlotDTO): Promise<ClassScheduleSlotDTO> {
    const rows: any[] = await prisma.$queryRawUnsafe(
      `INSERT INTO faculty_schedules (faculty_id, subject_id, subject_code, subject_name, room_or_venue, start_time, end_time, semester, section, day_of_week, topic, session_type, status)
       VALUES ($1::uuid, $2::uuid, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
       RETURNING *`,
      facultyId,
      dto.subjectId || null,
      dto.subjectCode.toUpperCase().trim(),
      dto.subjectName.trim(),
      dto.roomOrVenue.trim(),
      dto.startTime.trim(),
      dto.endTime.trim(),
      dto.semester.trim(),
      (dto.section || 'A').toUpperCase().trim(),
      dto.dayOfWeek?.trim() || 'TODAY',
      dto.topic?.trim() || null,
      dto.sessionType?.trim() || 'THEORY',
      dto.status?.trim() || 'SCHEDULED'
    );

    const r = rows[0];
    return {
      id: r.id,
      subjectId: r.subject_id || undefined,
      subjectCode: r.subject_code,
      subjectName: r.subject_name,
      roomOrVenue: r.room_or_venue,
      startTime: r.start_time,
      endTime: r.end_time,
      semester: r.semester,
      section: r.section,
      dayOfWeek: r.day_of_week || 'TODAY',
      topic: r.topic || undefined,
      sessionType: r.session_type || 'THEORY',
      status: r.status || 'SCHEDULED',
    };
  }

  async updateScheduleSlot(facultyId: string, slotId: string, dto: UpdateScheduleSlotDTO): Promise<ClassScheduleSlotDTO> {
    const sets: string[] = ['updated_at = NOW()'];
    const params: any[] = [slotId, facultyId];
    let idx = 3;

    if (dto.subjectId !== undefined) {
      sets.push(`subject_id = $${idx++}::uuid`);
      params.push(dto.subjectId);
    }
    if (dto.subjectCode !== undefined) {
      sets.push(`subject_code = $${idx++}`);
      params.push(dto.subjectCode.toUpperCase().trim());
    }
    if (dto.subjectName !== undefined) {
      sets.push(`subject_name = $${idx++}`);
      params.push(dto.subjectName.trim());
    }
    if (dto.roomOrVenue !== undefined) {
      sets.push(`room_or_venue = $${idx++}`);
      params.push(dto.roomOrVenue.trim());
    }
    if (dto.startTime !== undefined) {
      sets.push(`start_time = $${idx++}`);
      params.push(dto.startTime.trim());
    }
    if (dto.endTime !== undefined) {
      sets.push(`end_time = $${idx++}`);
      params.push(dto.endTime.trim());
    }
    if (dto.semester !== undefined) {
      sets.push(`semester = $${idx++}`);
      params.push(dto.semester.trim());
    }
    if (dto.section !== undefined) {
      sets.push(`section = $${idx++}`);
      params.push(dto.section.toUpperCase().trim());
    }
    if (dto.dayOfWeek !== undefined) {
      sets.push(`day_of_week = $${idx++}`);
      params.push(dto.dayOfWeek.trim());
    }
    if (dto.topic !== undefined) {
      sets.push(`topic = $${idx++}`);
      params.push(dto.topic ? dto.topic.trim() : null);
    }
    if (dto.sessionType !== undefined) {
      sets.push(`session_type = $${idx++}`);
      params.push(dto.sessionType.trim());
    }
    if (dto.status !== undefined) {
      sets.push(`status = $${idx++}`);
      params.push(dto.status.trim());
    }

    const query = `UPDATE faculty_schedules SET ${sets.join(', ')} WHERE id = $1::uuid AND faculty_id = $2::uuid RETURNING *`;
    const rows: any[] = await prisma.$queryRawUnsafe(query, ...params);
    if (!rows || rows.length === 0) {
      throw new Error(`Schedule slot with ID ${slotId} not found`);
    }
    const r = rows[0];
    return {
      id: r.id,
      subjectId: r.subject_id || undefined,
      subjectCode: r.subject_code,
      subjectName: r.subject_name,
      roomOrVenue: r.room_or_venue,
      startTime: r.start_time,
      endTime: r.end_time,
      semester: r.semester,
      section: r.section,
      dayOfWeek: r.day_of_week || 'TODAY',
      topic: r.topic || undefined,
      sessionType: r.session_type || 'THEORY',
      status: r.status || 'SCHEDULED',
    };
  }

  async deleteScheduleSlot(facultyId: string, slotId: string): Promise<void> {
    await prisma.$executeRawUnsafe(
      `DELETE FROM faculty_schedules WHERE id = $1::uuid AND faculty_id = $2::uuid`,
      slotId,
      facultyId
    );
  }

  private generateScheduleSlotsFromSubjects(subjects: SubjectDTO[]): ClassScheduleSlotDTO[] {
    const timeSlots = [
      { start: '09:00 AM', end: '10:00 AM', venue: 'Lecture Hall 101' },
      { start: '10:15 AM', end: '11:15 AM', venue: 'Computing Lab 2' },
      { start: '11:30 AM', end: '12:30 PM', venue: 'Seminar Hall B' },
      { start: '02:00 PM', end: '03:00 PM', venue: 'Lecture Hall 204' },
    ];

    return subjects.slice(0, 4).map((sub, index) => {
      const slot = timeSlots[index % timeSlots.length];
      return {
        id: `sch_${sub.id}`,
        subjectCode: sub.code,
        subjectName: sub.name,
        roomOrVenue: slot.venue,
        startTime: slot.start,
        endTime: slot.end,
        semester: sub.semester,
        section: sub.section,
        dayOfWeek: 'TODAY',
      };
    });
  }

  async createAssignment(facultyId: string, subjectId: string, dto: CreateAssignmentDTO): Promise<SubjectAssignmentDTO> {
    const dueAtDate = new Date(dto.dueAt);
    const assignment = await prisma.subjectAssignment.create({
      data: {
        subject_id: subjectId,
        faculty_id: facultyId,
        title: dto.title.trim(),
        description: dto.description?.trim() || null,
        unit: dto.unit?.trim() || null,
        topic: dto.topic?.trim() || null,
        attachments: dto.attachments || [],
        max_marks: dto.maxMarks ?? 100,
        due_at: isNaN(dueAtDate.getTime()) ? new Date(Date.now() + 7 * 24 * 3600 * 1000) : dueAtDate,
        submission_type: dto.submissionType || 'FILE',
        allow_late: dto.allowLate ?? true,
      },
      include: {
        _count: {
          select: { submissions: true },
        },
      },
    });

    return {
      id: assignment.id,
      subjectId: assignment.subject_id,
      facultyId: assignment.faculty_id,
      title: assignment.title,
      description: assignment.description || undefined,
      unit: assignment.unit || undefined,
      topic: assignment.topic || undefined,
      attachments: (assignment.attachments as any[]) || [],
      maxMarks: assignment.max_marks,
      dueAt: assignment.due_at,
      submissionType: assignment.submission_type,
      allowLate: assignment.allow_late,
      submissionsCount: assignment._count.submissions,
      gradedCount: 0,
      createdAt: assignment.created_at,
    };
  }

  async findAssignmentsBySubject(subjectId: string): Promise<SubjectAssignmentDTO[]> {
    const assignments = await prisma.subjectAssignment.findMany({
      where: { subject_id: subjectId },
      include: {
        submissions: {
          select: { status: true },
        },
      },
      orderBy: { created_at: 'desc' },
    });

    return assignments.map((a) => {
      const gradedCount = a.submissions.filter((s) => s.status === 'GRADED').length;
      return {
        id: a.id,
        subjectId: a.subject_id,
        facultyId: a.faculty_id,
        title: a.title,
        description: a.description || undefined,
        unit: a.unit || undefined,
        topic: a.topic || undefined,
        attachments: (a.attachments as any[]) || [],
        maxMarks: a.max_marks,
        dueAt: a.due_at,
        submissionType: a.submission_type,
        allowLate: a.allow_late,
        submissionsCount: a.submissions.length,
        gradedCount,
        createdAt: a.created_at,
      };
    });
  }

  async findSubmissionsByAssignment(assignmentId: string): Promise<AssignmentSubmissionDTO[]> {
    const submissions = await prisma.assignmentSubmission.findMany({
      where: { assignment_id: assignmentId },
      include: {
        student: true,
      },
      orderBy: { submitted_at: 'desc' },
    });

    return submissions.map((s) => ({
      id: s.id,
      assignmentId: s.assignment_id,
      studentId: s.student_id,
      studentName: `${s.student.first_name} ${s.student.last_name}`.trim(),
      studentRollNumber: s.student.roll_number || undefined,
      studentAvatarUrl: s.student.avatar_url,
      submissionType: s.submission_type,
      fileUrl: s.file_url,
      linkUrl: s.link_url,
      textContent: s.text_content,
      marks: s.marks,
      feedback: s.feedback,
      status: s.status,
      submittedAt: s.submitted_at,
      gradedAt: s.graded_at,
    }));
  }

  async gradeSubmission(
    facultyId: string,
    assignmentId: string,
    submissionId: string,
    dto: GradeSubmissionDTO
  ): Promise<AssignmentSubmissionDTO> {
    const submission = await prisma.assignmentSubmission.update({
      where: { id: submissionId },
      data: {
        marks: dto.marks,
        feedback: dto.feedback?.trim() || null,
        status: 'GRADED',
        graded_at: new Date(),
        graded_by_id: facultyId,
      },
      include: {
        student: true,
      },
    });

    return {
      id: submission.id,
      assignmentId: submission.assignment_id,
      studentId: submission.student_id,
      studentName: `${submission.student.first_name} ${submission.student.last_name}`.trim(),
      studentRollNumber: submission.student.roll_number || undefined,
      studentAvatarUrl: submission.student.avatar_url,
      submissionType: submission.submission_type,
      fileUrl: submission.file_url,
      linkUrl: submission.link_url,
      textContent: submission.text_content,
      marks: submission.marks,
      feedback: submission.feedback,
      status: submission.status,
      submittedAt: submission.submitted_at,
      gradedAt: submission.graded_at,
    };
  }

  async recordAttendance(
    facultyId: string,
    subjectId: string,
    dto: RecordAttendanceDTO
  ): Promise<AttendanceSessionDTO> {
    const sessionDate = dto.sessionDate ? new Date(dto.sessionDate) : new Date();
    const records = dto.records || [];
    const presentCount = records.filter((r) => (r.status || '').toUpperCase() === 'PRESENT').length;

    const session = await prisma.subjectAttendanceSession.create({
      data: {
        subject_id: subjectId,
        faculty_id: facultyId,
        session_date: sessionDate,
        start_time: dto.startTime || null,
        end_time: dto.endTime || null,
        topic: dto.topic?.trim() || null,
        total_students: records.length,
        present_count: presentCount,
      },
    });

    if (records.length > 0) {
      await prisma.studentAttendanceRecord.createMany({
        data: records.map((r) => ({
          session_id: session.id,
          subject_id: subjectId,
          student_id: r.studentId,
          status: (r.status || 'PRESENT').toUpperCase(),
          remarks: r.remarks?.trim() || null,
        })),
        skipDuplicates: true,
      });
    }

    return {
      id: session.id,
      subjectId: session.subject_id,
      facultyId: session.faculty_id,
      sessionDate: session.session_date.toISOString().split('T')[0],
      startTime: session.start_time || undefined,
      endTime: session.end_time || undefined,
      topic: session.topic || undefined,
      totalStudents: session.total_students,
      presentCount: session.present_count,
      createdAt: session.created_at,
    };
  }

  async findAttendanceSessionsBySubject(subjectId: string): Promise<AttendanceSessionDTO[]> {
    const sessions = await prisma.subjectAttendanceSession.findMany({
      where: { subject_id: subjectId },
      include: {
        records: {
          include: {
            student: true,
          },
        },
      },
      orderBy: { session_date: 'desc' },
      take: 50,
    });

    return sessions.map((s) => ({
      id: s.id,
      subjectId: s.subject_id,
      facultyId: s.faculty_id,
      sessionDate: s.session_date.toISOString().split('T')[0],
      startTime: s.start_time || undefined,
      endTime: s.end_time || undefined,
      topic: s.topic || undefined,
      totalStudents: s.total_students,
      presentCount: s.present_count,
      createdAt: s.created_at,
      records: s.records.map((r) => ({
        id: r.id,
        studentId: r.student_id,
        studentName: `${r.student.first_name} ${r.student.last_name}`.trim(),
        studentRollNumber: r.student.roll_number || undefined,
        studentAvatarUrl: r.student.avatar_url,
        status: r.status,
        remarks: r.remarks || undefined,
      })),
    }));
  }

  async findSessionAttendance(sessionId: string, facultyId: string): Promise<SessionAttendanceDetailDTO> {
    const session = await prisma.subjectAttendanceSession.findUnique({
      where: { id: sessionId },
      include: {
        subject: true,
        faculty: true,
      },
    });

    if (!session) {
      throw new Error(`Attendance session ${sessionId} not found`);
    }

    // Attendance students strictly from SubjectEnrollment for this subject/term/section
    const enrollments = await prisma.subjectEnrollment.findMany({
      where: {
        subject_id: session.subject_id,
        ...(session.academic_term_id ? { academic_term_id: session.academic_term_id } : {}),
        ...(session.section ? { section: session.section } : {}),
        status: 'ACTIVE',
      },
      include: {
        student: {
          include: { department: true },
        },
      },
      orderBy: [
        { student: { roll_number: 'asc' } },
        { student: { first_name: 'asc' } },
      ],
    });

    const existingRecords = await prisma.studentAttendanceRecord.findMany({
      where: { session_id: sessionId },
    });
    const recordMap = new Map(existingRecords.map((r) => [r.student_id, r]));

    const students: EnrolledAttendanceStudentDTO[] = enrollments.map((enr) => {
      const rec = recordMap.get(enr.student_id);
      return {
        id: enr.student.id,
        name: `${enr.student.first_name} ${enr.student.last_name}`.trim(),
        rollNumber: enr.student.roll_number || 'N/A',
        avatarUrl: enr.student.avatar_url,
        email: enr.student.email,
        department: enr.student.department?.name,
        recordId: rec?.id,
        status: (rec?.status as any) || 'UNMARKED',
        remarks: rec?.remarks || undefined,
      };
    });

    const total = students.length;
    const present = students.filter((s) => s.status === 'PRESENT').length;
    const absent = students.filter((s) => s.status === 'ABSENT').length;
    const unmarked = students.filter((s) => s.status === 'UNMARKED').length;
    const late = students.filter((s) => s.status === 'LATE').length;
    const excused = students.filter((s) => s.status === 'EXCUSED').length;

    return {
      session: {
        id: session.id,
        subjectId: session.subject_id,
        subjectCode: session.subject.code,
        subjectName: session.subject.name,
        sessionDate: session.session_date.toISOString().split('T')[0],
        startTime: session.start_time || undefined,
        endTime: session.end_time || undefined,
        topic: session.topic || undefined,
        status: (session.status as any) || 'OPEN',
        section: session.section || 'A',
      },
      metrics: {
        total,
        present,
        absent,
        unmarked,
        late,
        excused,
      },
      students,
    };
  }

  async bulkRecordAttendance(facultyId: string, dto: BulkAttendanceDTO): Promise<SessionAttendanceDetailDTO> {
    const session = await prisma.subjectAttendanceSession.findUnique({
      where: { id: dto.sessionId },
    });
    if (!session) {
      throw new Error(`Attendance session ${dto.sessionId} not found`);
    }

    if (session.status === 'LOCKED') {
      throw new Error('This attendance session is LOCKED and cannot be modified');
    }

    // Upsert each record
    for (const rec of dto.records) {
      const validStatus = (rec.status || 'PRESENT').toUpperCase();
      await prisma.studentAttendanceRecord.upsert({
        where: {
          session_id_student_id: {
            session_id: dto.sessionId,
            student_id: rec.studentId,
          },
        },
        update: {
          status: validStatus,
          remarks: rec.remarks?.trim() || null,
          marked_by_id: facultyId,
        },
        create: {
          session_id: dto.sessionId,
          subject_id: session.subject_id,
          student_id: rec.studentId,
          status: validStatus,
          remarks: rec.remarks?.trim() || null,
          marked_by_id: facultyId,
        },
      });
    }

    // Recalculate present_count and total_students on the session
    const allRecords = await prisma.studentAttendanceRecord.findMany({
      where: { session_id: dto.sessionId },
    });
    const presentCount = allRecords.filter((r) => r.status.toUpperCase() === 'PRESENT').length;
    await prisma.subjectAttendanceSession.update({
      where: { id: dto.sessionId },
      data: {
        present_count: presentCount,
        total_students: allRecords.length,
      },
    });

    return await this.findSessionAttendance(dto.sessionId, facultyId);
  }

  async updateAttendanceRecordStatus(facultyId: string, recordId: string, status: string, remarks?: string) {
    const record = await prisma.studentAttendanceRecord.findUnique({
      where: { id: recordId },
      include: { session: true },
    });
    if (!record) {
      throw new Error(`Attendance record ${recordId} not found`);
    }

    if (record.session.status === 'LOCKED') {
      throw new Error('This attendance session is LOCKED and cannot be modified');
    }

    const updated = await prisma.studentAttendanceRecord.update({
      where: { id: recordId },
      data: {
        status: status.toUpperCase(),
        ...(remarks !== undefined ? { remarks: remarks?.trim() || null } : {}),
        marked_by_id: facultyId,
      },
    });

    // Update present_count
    const allRecords = await prisma.studentAttendanceRecord.findMany({
      where: { session_id: record.session_id },
    });
    const presentCount = allRecords.filter((r) => r.status.toUpperCase() === 'PRESENT').length;
    await prisma.subjectAttendanceSession.update({
      where: { id: record.session_id },
      data: {
        present_count: presentCount,
        total_students: allRecords.length,
      },
    });

    return updated;
  }

  async toggleSessionLock(facultyId: string, sessionId: string, lock: boolean) {
    return await prisma.subjectAttendanceSession.update({
      where: { id: sessionId },
      data: {
        status: lock ? 'LOCKED' : 'OPEN',
      },
    });
  }

  async findFacultyAcademicContext(
    facultyId: string,
    collegeId: string,
    targetDate: Date = new Date()
  ): Promise<FacultyAcademicContextDTO> {
    const termService = new TermResolutionService();
    const currentTerm = await termService.getCurrentTerm(collegeId, targetDate);

    // Find subjects assigned to faculty for this term
    const assigned = await prisma.facultySubjectAssignment.findMany({
      where: {
        faculty_id: facultyId,
        academic_term_id: currentTerm.termId,
        is_active: true,
      },
      include: {
        subject: {
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
        },
      },
    });

    // Direct faculty subjects matching term or unlinked
    const directSubjects = await prisma.subject.findMany({
      where: {
        faculty_id: facultyId,
        OR: [
          { academic_term_id: currentTerm.termId },
          { academic_term_id: null },
        ],
      },
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
    });

    // Deduplicate subjects by ID
    const subjectMap = new Map<string, any>();
    for (const d of directSubjects) {
      subjectMap.set(d.id, d);
    }
    for (const a of assigned) {
      if (a.subject) {
        subjectMap.set(a.subject.id, a.subject);
      }
    }

    const rawSubjects = Array.from(subjectMap.values());
    const subjectDTOs: SubjectDTO[] = rawSubjects.map((s) => ({
      id: s.id,
      facultyId: s.faculty_id,
      code: s.code,
      name: s.name,
      department: s.department?.name || 'Computer Science & Engineering',
      semester: s.semester,
      section: s.section,
      credits: s.credits,
      description: s.description || undefined,
      academicYear: s.academic_year || currentTerm.academicYear,
      resourcesCount: s._count.resources,
      announcementsCount: s._count.announcements,
      studentsCount: s._count.enrollments,
      createdAt: s.created_at,
    }));

    // Today's schedule
    const days = ['SUNDAY', 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY'];
    const currentDay = days[targetDate.getDay()];
    const schedules = await prisma.facultySchedule.findMany({
      where: {
        faculty_id: facultyId,
        status: 'SCHEDULED',
        OR: [
          { day_of_week: 'TODAY' },
          { day_of_week: currentDay },
          { day_of_week: 'ALL' },
          { day_of_week: '' },
        ],
      },
      orderBy: { start_time: 'asc' },
    });

    const todaySchedule = schedules.map((s) => ({
      id: s.id,
      facultyId: s.faculty_id,
      subjectId: s.subject_id || undefined,
      subjectCode: s.subject_code || 'CS301',
      subjectName: s.subject_name || 'Class Lecture',
      roomOrVenue: s.room_or_venue || 'Hall 101',
      startTime: s.start_time,
      endTime: s.end_time,
      semester: s.semester || 'Semester 7',
      section: s.section || 'A',
      dayOfWeek: s.day_of_week,
      topic: s.topic || undefined,
      sessionType: s.session_type || 'THEORY',
      status: s.status || 'SCHEDULED',
    }));

    // Group into classes
    const classMap = new Map<string, { semester: string; section: string; subjectCount: number; studentCount: number }>();
    for (const s of rawSubjects) {
      const key = `${s.semester}_${s.section}`;
      if (!classMap.has(key)) {
        classMap.set(key, {
          semester: s.semester,
          section: s.section,
          subjectCount: 1,
          studentCount: s._count.enrollments,
        });
      } else {
        const c = classMap.get(key)!;
        c.subjectCount += 1;
        c.studentCount += s._count.enrollments;
      }
    }

    const classes = Array.from(classMap.values());
    const subjectPlural = subjectDTOs.length === 1 ? 'Subject' : 'Subjects';
    const classPlural = classes.length === 1 ? 'Class' : 'Classes';
    const academicHeader = `${currentTerm.academicYear} • ${currentTerm.termName} | My Teaching: ${subjectDTOs.length} ${subjectPlural} • ${classes.length} ${classPlural}`;

    return {
      currentTerm,
      academicHeader,
      assignedSubjects: subjectDTOs,
      classes,
      todaySchedule,
    };
  }

  async createAssessment(facultyId: string, subjectId: string, dto: CreateSubjectAssessmentDTO): Promise<SubjectAssessmentDTO> {
    const assessment = await prisma.subjectAssessment.create({
      data: {
        faculty_id: facultyId,
        subject_id: subjectId,
        title: dto.title.trim(),
        description: dto.description?.trim(),
        assessment_type: dto.assessmentType || 'INTERNAL_EXAM',
        unit: dto.unit?.trim(),
        topic: dto.topic?.trim(),
        total_marks: dto.totalMarks ?? 50,
        passing_marks: dto.passingMarks ?? 20,
        duration_minutes: dto.durationMinutes ?? 60,
        scheduled_at: dto.scheduledAt ? new Date(dto.scheduledAt) : null,
        status: 'SCHEDULED',
      },
    });

    return {
      id: assessment.id,
      subjectId: assessment.subject_id,
      facultyId: assessment.faculty_id,
      title: assessment.title,
      description: assessment.description || undefined,
      assessmentType: assessment.assessment_type,
      unit: assessment.unit || undefined,
      topic: assessment.topic || undefined,
      totalMarks: assessment.total_marks,
      passingMarks: assessment.passing_marks,
      durationMinutes: assessment.duration_minutes || undefined,
      scheduledAt: assessment.scheduled_at,
      status: assessment.status,
      evaluatedCount: 0,
      createdAt: assessment.created_at,
    };
  }

  async findAssessmentsBySubject(subjectId: string): Promise<SubjectAssessmentDTO[]> {
    const assessments = await prisma.subjectAssessment.findMany({
      where: { subject_id: subjectId },
      include: {
        results: {
          select: { marks_obtained: true, status: true },
        },
      },
      orderBy: { created_at: 'desc' },
    });

    return assessments.map((a) => {
      const evaluated = a.results.filter((r) => r.status === 'EVALUATED' && r.marks_obtained !== null);
      const totalMarksSum = evaluated.reduce((sum, r) => sum + (r.marks_obtained || 0), 0);
      const avg = evaluated.length > 0 ? Math.round((totalMarksSum / evaluated.length) * 10) / 10 : undefined;

      return {
        id: a.id,
        subjectId: a.subject_id,
        facultyId: a.faculty_id,
        title: a.title,
        description: a.description || undefined,
        assessmentType: a.assessment_type,
        unit: a.unit || undefined,
        topic: a.topic || undefined,
        totalMarks: a.total_marks,
        passingMarks: a.passing_marks,
        durationMinutes: a.duration_minutes || undefined,
        scheduledAt: a.scheduled_at,
        status: a.status,
        evaluatedCount: evaluated.length,
        averageMarks: avg,
        createdAt: a.created_at,
      };
    });
  }

  async findAssessmentById(assessmentId: string): Promise<SubjectAssessmentDTO | null> {
    const a = await prisma.subjectAssessment.findUnique({
      where: { id: assessmentId },
      include: {
        results: true,
      },
    });
    if (!a) return null;

    const evaluated = a.results.filter((r) => r.status === 'EVALUATED' && r.marks_obtained !== null);
    const totalMarksSum = evaluated.reduce((sum, r) => sum + (r.marks_obtained || 0), 0);
    const avg = evaluated.length > 0 ? Math.round((totalMarksSum / evaluated.length) * 10) / 10 : undefined;

    return {
      id: a.id,
      subjectId: a.subject_id,
      facultyId: a.faculty_id,
      title: a.title,
      description: a.description || undefined,
      assessmentType: a.assessment_type,
      unit: a.unit || undefined,
      topic: a.topic || undefined,
      totalMarks: a.total_marks,
      passingMarks: a.passing_marks,
      durationMinutes: a.duration_minutes || undefined,
      scheduledAt: a.scheduled_at,
      status: a.status,
      evaluatedCount: evaluated.length,
      averageMarks: avg,
      createdAt: a.created_at,
    };
  }

  async findAssessmentResults(assessmentId: string): Promise<StudentAssessmentResultDTO[]> {
    const results = await prisma.studentAssessmentResult.findMany({
      where: { assessment_id: assessmentId },
      include: {
        student: true,
      },
      orderBy: { student: { roll_number: 'asc' } },
    });

    return results.map((r) => ({
      id: r.id,
      assessmentId: r.assessment_id,
      subjectId: r.subject_id,
      studentId: r.student_id,
      studentName: `${r.student.first_name} ${r.student.last_name}`.trim(),
      studentRollNumber: r.student.roll_number || undefined,
      studentAvatarUrl: r.student.avatar_url,
      marksObtained: r.marks_obtained,
      grade: r.grade,
      remarks: r.remarks,
      status: r.status,
      evaluatedAt: r.evaluated_at,
    }));
  }

  async batchRecordAssessmentMarks(
    facultyId: string,
    assessmentId: string,
    dto: BatchRecordAssessmentMarksDTO
  ): Promise<StudentAssessmentResultDTO[]> {
    const assessment = await prisma.subjectAssessment.findUnique({
      where: { id: assessmentId },
    });
    if (!assessment) {
      throw new Error(`Assessment with ID ${assessmentId} not found`);
    }

    for (const item of dto.results) {
      await prisma.studentAssessmentResult.upsert({
        where: {
          assessment_id_student_id: {
            assessment_id: assessmentId,
            student_id: item.studentId,
          },
        },
        create: {
          assessment_id: assessmentId,
          subject_id: assessment.subject_id,
          student_id: item.studentId,
          marks_obtained: item.marksObtained !== undefined ? item.marksObtained : null,
          grade: item.grade || null,
          remarks: item.remarks || null,
          status: item.status || 'EVALUATED',
          evaluated_by_id: facultyId,
          evaluated_at: new Date(),
        },
        update: {
          marks_obtained: item.marksObtained !== undefined ? item.marksObtained : null,
          grade: item.grade || null,
          remarks: item.remarks || null,
          status: item.status || 'EVALUATED',
          evaluated_by_id: facultyId,
          evaluated_at: new Date(),
        },
      });
    }

    return this.findAssessmentResults(assessmentId);
  }
}


