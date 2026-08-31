import { FacultyRepository } from './faculty.repository';
import {
  CreateSubjectDTO,
  CreateSubjectResourceDTO,
  CreateSubjectAnnouncementDTO,
  FacultyDashboardDTO,
  SubjectDTO,
  SubjectResourceDTO,
  SubjectAnnouncementDTO,
  ClassScheduleSlotDTO,
  MenteeStudentDTO,
} from './faculty.types';
import { NotFoundError, ForbiddenError } from '../../shared/utils/custom-error.util';

export class FacultyService {
  constructor(private readonly repository: FacultyRepository = new FacultyRepository()) {}

  private isElevatedRole(role: string): boolean {
    return ['ADMIN', 'COLLEGE_ADMIN', 'SUPER_ADMIN'].includes(role);
  }

  async getDashboard(facultyId: string, collegeId: string): Promise<FacultyDashboardDTO> {
    const [facultyInfo, subjects, mentees, announcements] = await Promise.all([
      this.repository.getFacultyUserInfo(facultyId),
      this.repository.findSubjectsByFaculty(facultyId, collegeId),
      this.repository.getMentees(facultyId, collegeId),
      this.repository.getRecentAnnouncements(facultyId, collegeId),
    ]);

    const todaySchedule = this.generateScheduleSlotsFromSubjects(subjects);

    return {
      faculty: facultyInfo || {
        id: facultyId,
        name: 'Faculty Member',
        email: 'faculty@campushub.edu',
        designation: 'Faculty Member',
        department: 'Academic Department',
      },
      stats: {
        totalSubjects: subjects.length,
        totalMentees: mentees.length,
        todayClassesCount: todaySchedule.length,
        upcomingEventsCount: 0,
        publishedAnnouncementsCount: announcements.length,
      },
      todaySchedule,
      recentAnnouncements: announcements,
      upcomingEvents: [],
    };
  }

  async getSubjects(facultyId: string, collegeId: string): Promise<SubjectDTO[]> {
    return await this.repository.findSubjectsByFaculty(facultyId, collegeId);
  }

  async createSubject(facultyId: string, collegeId: string, dto: CreateSubjectDTO): Promise<SubjectDTO> {
    return await this.repository.createSubject(facultyId, collegeId, dto);
  }

  async getSubjectDetails(
    subjectId: string,
    userId: string,
    userRole: string
  ): Promise<SubjectDTO & { facultyId: string; resources: SubjectResourceDTO[]; announcements: SubjectAnnouncementDTO[] }> {
    const subject = await this.repository.findSubjectById(subjectId);
    if (!subject) {
      throw new NotFoundError(`Subject with ID ${subjectId} not found`);
    }
    return subject;
  }

  async addSubjectResource(
    facultyId: string,
    subjectId: string,
    dto: CreateSubjectResourceDTO,
    userRole: string
  ): Promise<SubjectResourceDTO> {
    const subject = await this.getSubjectDetails(subjectId, facultyId, userRole);
    if (subject.facultyId !== facultyId && !this.isElevatedRole(userRole)) {
      throw new ForbiddenError('You are not authorized to upload resources to this subject');
    }

    return await this.repository.createSubjectResource(facultyId, subjectId, dto);
  }

  async deleteSubjectResource(
    facultyId: string,
    subjectId: string,
    resourceId: string,
    userRole: string
  ): Promise<{ success: boolean; message: string }> {
    const subject = await this.getSubjectDetails(subjectId, facultyId, userRole);
    if (subject.facultyId !== facultyId && !this.isElevatedRole(userRole)) {
      throw new ForbiddenError('You are not authorized to modify resources for this subject');
    }

    await this.repository.deleteSubjectResource(resourceId);
    return { success: true, message: 'Resource removed successfully' };
  }

  async addSubjectAnnouncement(
    facultyId: string,
    subjectId: string,
    dto: CreateSubjectAnnouncementDTO,
    userRole: string
  ): Promise<SubjectAnnouncementDTO> {
    const subject = await this.getSubjectDetails(subjectId, facultyId, userRole);
    if (subject.facultyId !== facultyId && !this.isElevatedRole(userRole)) {
      throw new ForbiddenError('You are not authorized to post announcements for this subject');
    }

    return await this.repository.createSubjectAnnouncement(facultyId, subjectId, dto);
  }

  async getTodaySchedule(facultyId: string, collegeId?: string): Promise<ClassScheduleSlotDTO[]> {
    try {
      const subjects = await this.repository.findSubjectsByFaculty(facultyId, collegeId || '');
      return this.generateScheduleSlotsFromSubjects(subjects);
    } catch {
      return [];
    }
  }

  async getMentees(facultyId: string, collegeId: string): Promise<MenteeStudentDTO[]> {
    return await this.repository.getMentees(facultyId, collegeId);
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
}
