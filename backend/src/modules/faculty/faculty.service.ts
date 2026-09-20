import { FacultyRepository } from './faculty.repository';
import {
  CreateSubjectDTO,
  UpdateSubjectDTO,
  CreateSubjectResourceDTO,
  CreateSubjectAnnouncementDTO,
  FacultyDashboardDTO,
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
} from './faculty.types';
import { NotFoundError, ForbiddenError } from '../../shared/utils/custom-error.util';
import { NotificationsRepository } from '../notifications/notifications.repository';
import { NotificationsService } from '../notifications/notifications.service';
import { prisma } from '../../config/database';

export class FacultyService {
  private readonly notificationsService: NotificationsService;

  constructor(
    private readonly repository: FacultyRepository = new FacultyRepository(),
    notificationsService?: NotificationsService,
  ) {
    this.notificationsService = notificationsService ?? new NotificationsService(new NotificationsRepository());
  }

  private isElevatedRole(role: string): boolean {
    return ['ADMIN', 'COLLEGE_ADMIN', 'SUPER_ADMIN'].includes(role);
  }

  async getDashboard(facultyId: string, collegeId: string): Promise<FacultyDashboardDTO> {
    const [facultyInfo, subjects, mentees, announcements, todaySchedule] = await Promise.all([
      this.repository.getFacultyUserInfo(facultyId),
      this.repository.findSubjectsByFaculty(facultyId, collegeId),
      this.repository.getMentees(facultyId, collegeId),
      this.repository.getRecentAnnouncements(facultyId, collegeId),
      this.repository.getScheduleSlots(facultyId, collegeId),
    ]);

    return {
      faculty: facultyInfo || {
        id: facultyId,
        name: 'Faculty Member',
        email: 'faculty@campushub.edu',
        designation: 'Associate Professor',
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

  async updateSubject(
    facultyId: string,
    subjectId: string,
    dto: UpdateSubjectDTO,
    userRole: string
  ): Promise<SubjectDTO> {
    const subject = await this.getSubjectDetails(subjectId, facultyId, userRole);
    if (subject.facultyId !== facultyId && !this.isElevatedRole(userRole)) {
      throw new ForbiddenError('You are not authorized to update this subject');
    }
    return await this.repository.updateSubject(subjectId, dto);
  }

  async deleteSubject(
    facultyId: string,
    subjectId: string,
    userRole: string
  ): Promise<{ success: boolean; message: string }> {
    const subject = await this.getSubjectDetails(subjectId, facultyId, userRole);
    if (subject.facultyId !== facultyId && !this.isElevatedRole(userRole)) {
      throw new ForbiddenError('You are not authorized to delete this subject');
    }
    await this.repository.deleteSubject(subjectId);
    return { success: true, message: 'Subject and all associated resources deleted successfully' };
  }

  async getSubjectDetails(
    subjectId: string,
    userId: string,
    userRole: string
  ): Promise<
    SubjectDTO & {
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
    }
  > {
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

  async updateSubjectResource(
    facultyId: string,
    subjectId: string,
    resourceId: string,
    dto: Partial<CreateSubjectResourceDTO>,
    userRole: string
  ): Promise<SubjectResourceDTO> {
    const subject = await this.getSubjectDetails(subjectId, facultyId, userRole);
    if (subject.facultyId !== facultyId && !this.isElevatedRole(userRole)) {
      throw new ForbiddenError('You are not authorized to modify resources for this subject');
    }

    const updated = await this.repository.updateSubjectResource(resourceId, dto);
    if (!updated) {
      throw new NotFoundError(`Resource with ID ${resourceId} not found`);
    }
    return updated;
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

    const announcement = await this.repository.createSubjectAnnouncement(facultyId, subjectId, dto);

    try {
      const enrollments = await prisma.subjectEnrollment.findMany({
        where: { subject_id: subjectId },
        select: { student_id: true },
      });
      for (const enr of enrollments) {
        await this.notificationsService.sendNotification({
          user_id: enr.student_id,
          title: `[${subject.code}] ${dto.title}`,
          body: dto.content.length > 120 ? `${dto.content.substring(0, 117)}...` : dto.content,
          type: 'ANNOUNCEMENT',
          category: 'Academics',
          deep_link: `/academics/subjects/${subjectId}`,
        });
      }
    } catch (_) {}

    return announcement;
  }

  async getTodaySchedule(facultyId: string, collegeId?: string): Promise<ClassScheduleSlotDTO[]> {
    return await this.repository.getScheduleSlots(facultyId, collegeId);
  }

  async createScheduleSlot(facultyId: string, dto: CreateScheduleSlotDTO): Promise<ClassScheduleSlotDTO> {
    return await this.repository.createScheduleSlot(facultyId, dto);
  }

  async updateScheduleSlot(facultyId: string, slotId: string, dto: UpdateScheduleSlotDTO): Promise<ClassScheduleSlotDTO> {
    return await this.repository.updateScheduleSlot(facultyId, slotId, dto);
  }

  async deleteScheduleSlot(facultyId: string, slotId: string): Promise<void> {
    await this.repository.deleteScheduleSlot(facultyId, slotId);
  }

  async getMentees(facultyId: string, collegeId: string): Promise<MenteeStudentDTO[]> {
    return await this.repository.getMentees(facultyId, collegeId);
  }

  async getFacultyProfile(facultyId: string): Promise<FacultyProfileDTO> {
    const profile = await this.repository.getFacultyProfile(facultyId);
    if (!profile) {
      throw new NotFoundError(`Faculty profile for ID ${facultyId} not found`);
    }
    return profile;
  }

  async updateFacultyProfile(facultyId: string, dto: UpdateFacultyProfileDTO): Promise<FacultyProfileDTO> {
    return await this.repository.updateFacultyProfile(facultyId, dto);
  }

  async createAssignment(
    facultyId: string,
    subjectId: string,
    dto: CreateAssignmentDTO,
    userRole: string
  ): Promise<SubjectAssignmentDTO> {
    const subject = await this.getSubjectDetails(subjectId, facultyId, userRole);
    if (subject.facultyId !== facultyId && !this.isElevatedRole(userRole)) {
      throw new ForbiddenError('You are not authorized to create assignments for this subject');
    }
    const assignment = await this.repository.createAssignment(facultyId, subjectId, dto);

    try {
      const enrollments = await prisma.subjectEnrollment.findMany({
        where: { subject_id: subjectId },
        select: { student_id: true },
      });
      for (const enr of enrollments) {
        await this.notificationsService.sendNotification({
          user_id: enr.student_id,
          title: `New Assignment: ${dto.title}`,
          body: `Subject: ${subject.code} - ${subject.name}. Max marks: ${dto.maxMarks ?? 'N/A'}. Due: ${dto.dueAt ? new Date(dto.dueAt).toLocaleDateString() : 'TBD'}`,
          type: 'SYSTEM',
          category: 'Academics',
          deep_link: `/academics/subjects/${subjectId}`,
        });
      }
    } catch (_) {}

    return assignment;
  }

  async getSubjectAssignments(
    facultyId: string,
    subjectId: string,
    userRole: string
  ): Promise<SubjectAssignmentDTO[]> {
    await this.getSubjectDetails(subjectId, facultyId, userRole);
    return await this.repository.findAssignmentsBySubject(subjectId);
  }

  async getAssignmentSubmissions(
    facultyId: string,
    assignmentId: string,
    userRole: string
  ): Promise<AssignmentSubmissionDTO[]> {
    return await this.repository.findSubmissionsByAssignment(assignmentId);
  }

  async gradeAssignmentSubmission(
    facultyId: string,
    assignmentId: string,
    submissionId: string,
    dto: GradeSubmissionDTO,
    userRole: string
  ): Promise<AssignmentSubmissionDTO> {
    const graded = await this.repository.gradeSubmission(facultyId, assignmentId, submissionId, dto);

    try {
      const submission = await prisma.assignmentSubmission.findUnique({
        where: { id: submissionId },
        include: { assignment: { include: { subject: true } } },
      });
      if (submission) {
        await this.notificationsService.sendNotification({
          user_id: submission.student_id,
          title: `Assignment Graded: ${submission.assignment.title}`,
          body: `Marks: ${dto.marks}/${submission.assignment.max_marks || '100'}. ${dto.feedback ? `Feedback: ${dto.feedback}` : ''}`.trim(),
          type: 'SYSTEM',
          category: 'Academics',
          deep_link: `/academics/subjects/${submission.assignment.subject_id}`,
        });
      }
    } catch (_) {}

    return graded;
  }

  async recordAttendance(
    facultyId: string,
    subjectId: string,
    dto: RecordAttendanceDTO,
    userRole: string
  ): Promise<AttendanceSessionDTO> {
    const subject = await this.getSubjectDetails(subjectId, facultyId, userRole);
    if (subject.facultyId !== facultyId && !this.isElevatedRole(userRole)) {
      throw new ForbiddenError('You are not authorized to record attendance for this subject');
    }
    return await this.repository.recordAttendance(facultyId, subjectId, dto);
  }

  async getAttendanceSessions(
    facultyId: string,
    subjectId: string,
    userRole: string
  ): Promise<AttendanceSessionDTO[]> {
    await this.getSubjectDetails(subjectId, facultyId, userRole);
    return await this.repository.findAttendanceSessionsBySubject(subjectId);
  }

  async createAssessment(
    facultyId: string,
    subjectId: string,
    dto: CreateSubjectAssessmentDTO,
    userRole: string
  ): Promise<SubjectAssessmentDTO> {
    const subject = await this.getSubjectDetails(subjectId, facultyId, userRole);
    if (subject.facultyId !== facultyId && !this.isElevatedRole(userRole)) {
      throw new ForbiddenError('You are not authorized to create assessments for this subject');
    }
    return await this.repository.createAssessment(facultyId, subjectId, dto);
  }

  async getSubjectAssessments(
    facultyId: string,
    subjectId: string,
    userRole: string
  ): Promise<SubjectAssessmentDTO[]> {
    await this.getSubjectDetails(subjectId, facultyId, userRole);
    return await this.repository.findAssessmentsBySubject(subjectId);
  }

  async getAssessmentResults(
    facultyId: string,
    assessmentId: string,
    userRole: string
  ): Promise<StudentAssessmentResultDTO[]> {
    const assessment = await this.repository.findAssessmentById(assessmentId);
    if (!assessment) {
      throw new NotFoundError(`Assessment with ID ${assessmentId} not found`);
    }
    await this.getSubjectDetails(assessment.subjectId, facultyId, userRole);
    return await this.repository.findAssessmentResults(assessmentId);
  }

  async recordAssessmentMarks(
    facultyId: string,
    assessmentId: string,
    dto: BatchRecordAssessmentMarksDTO,
    userRole: string
  ): Promise<StudentAssessmentResultDTO[]> {
    const assessment = await this.repository.findAssessmentById(assessmentId);
    if (!assessment) {
      throw new NotFoundError(`Assessment with ID ${assessmentId} not found`);
    }
    const subject = await this.getSubjectDetails(assessment.subjectId, facultyId, userRole);
    if (subject.facultyId !== facultyId && !this.isElevatedRole(userRole)) {
      throw new ForbiddenError('You are not authorized to grade this assessment');
    }
    const results = await this.repository.batchRecordAssessmentMarks(facultyId, assessmentId, dto);

    try {
      if (dto.results && Array.isArray(dto.results)) {
        for (const item of dto.results) {
          await this.notificationsService.sendNotification({
            user_id: item.studentId,
            title: `Marks Published: ${assessment.title}`,
            body: `Scored ${item.marksObtained ?? 0}/${assessment.totalMarks} in ${subject.code} - ${subject.name}`,
            type: 'SYSTEM',
            category: 'Academics',
            deep_link: `/academics/subjects/${subject.id}`,
          });
        }
      }
    } catch (_) {}

    return results;
  }

  async getAcademicContext(
    facultyId: string,
    collegeId: string,
    targetDate?: Date
  ): Promise<FacultyAcademicContextDTO> {
    return await this.repository.findFacultyAcademicContext(facultyId, collegeId, targetDate);
  }

  async getSessionAttendance(
    facultyId: string,
    sessionId: string,
    userRole: string
  ): Promise<SessionAttendanceDetailDTO> {
    return await this.repository.findSessionAttendance(sessionId, facultyId);
  }

  async bulkRecordAttendance(
    facultyId: string,
    dto: BulkAttendanceDTO,
    userRole: string
  ): Promise<SessionAttendanceDetailDTO> {
    const sessionDetail = await this.repository.bulkRecordAttendance(facultyId, dto);

    try {
      const session = await prisma.subjectAttendanceSession.findUnique({
        where: { id: dto.sessionId },
        include: { subject: true },
      });
      if (session) {
        const sDate = session.session_date ? new Date(session.session_date).toLocaleDateString() : 'Class';
        for (const item of dto.records) {
          await this.notificationsService.sendNotification({
            user_id: item.studentId,
            title: `Attendance Marked: ${session.subject.code}`,
            body: `Status: ${item.status} for ${session.topic || 'Class Session'} on ${sDate}`,
            type: 'SYSTEM',
            category: 'Academics',
            deep_link: `/academics/subjects/${session.subject_id}`,
          });
        }
      }
    } catch (_) {}

    return sessionDetail;
  }

  async updateAttendanceRecord(
    facultyId: string,
    recordId: string,
    status: string,
    remarks?: string
  ) {
    return await this.repository.updateAttendanceRecordStatus(facultyId, recordId, status, remarks);
  }

  async toggleSessionLock(facultyId: string, sessionId: string, lock: boolean) {
    return await this.repository.toggleSessionLock(facultyId, sessionId, lock);
  }
}

