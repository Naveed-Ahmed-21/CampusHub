import { AcademicsRepository } from './academics.repository';
import { TermResolutionService } from './term-resolution.service';
import {
  SubjectSearchFilter,
  AcademicSubjectDTO,
  AcademicSubjectDetailDTO,
  ResourceSearchResultDTO,
  AcademicFacultyDTO,
  StudentAssignmentDTO,
  SubmitAssignmentDTO,
  StudentAttendanceSummaryDTO,
  StudentTimetableSlotDTO,
  StudentSubjectAssessmentDTO,
  StudentAssessmentSummaryDTO,
  StudentAcademicContextDTO,
} from './academics.types';
import { NotFoundError } from '../../shared/utils/custom-error.util';

export class AcademicsService {
  constructor(
    private readonly repository: AcademicsRepository = new AcademicsRepository(),
    private readonly termService: TermResolutionService = new TermResolutionService()
  ) {}

  async getCurrentTerm(collegeId: string, targetDate?: Date) {
    return await this.termService.getCurrentTerm(collegeId, targetDate);
  }

  async getStudentAcademicContext(
    studentId: string,
    collegeId: string,
    targetDate?: Date
  ): Promise<StudentAcademicContextDTO> {
    const progression = await this.termService.deriveStudentProgression(studentId, targetDate);
    const currentTerm = await this.termService.getCurrentTerm(collegeId, targetDate);
    await this.termService.ensureCurriculumAndEnrollments(studentId, targetDate);

    const subjects = await this.getMyEnrolledSubjects(studentId, collegeId);

    return {
      academicYear: progression.academicYear,
      academicTerm: progression.academicTerm,
      termType: currentTerm.termType,
      semester: progression.semester,
      semesterRoman: progression.semesterRoman,
      semesterLabel: progression.semesterLabel,
      yearOfStudy: progression.yearOfStudy,
      yearRoman: progression.yearRoman,
      yearLabel: progression.yearLabel,
      admissionYear: progression.admissionYear,
      batchName: progression.batchName,
      department: progression.departmentCode,
      departmentName: progression.departmentName,
      program: progression.programName,
      section: progression.section,
      class: `${progression.yearRoman} ${progression.departmentCode} ${progression.section}`,
      academicHeader: progression.academicHeader,
      status: progression.status,
      hasOverride: progression.hasOverride,
      overrideReason: progression.overrideReason,
      subjects,
    };
  }

  async getSubjects(
    filter: SubjectSearchFilter,
    userId?: string,
    collegeId?: string
  ): Promise<AcademicSubjectDTO[]> {
    return await this.repository.findSubjects(filter, userId, collegeId);
  }

  async getSubjectDetails(subjectId: string, userId?: string): Promise<AcademicSubjectDetailDTO> {
    const subject = await this.repository.findSubjectById(subjectId, userId);
    if (!subject) {
      throw new NotFoundError(`Subject with ID ${subjectId} not found`);
    }
    return subject;
  }

  async enrollInSubject(subjectId: string, studentId: string): Promise<{ success: boolean; message: string }> {
    await this.getSubjectDetails(subjectId, studentId);
    await this.repository.enrollStudent(subjectId, studentId);
    return { success: true, message: 'Successfully enrolled in subject' };
  }

  async unenrollFromSubject(subjectId: string, studentId: string): Promise<{ success: boolean; message: string }> {
    await this.repository.unenrollStudent(subjectId, studentId);
    return { success: true, message: 'Successfully unenrolled from subject' };
  }

  async getMyEnrolledSubjects(studentId: string, collegeId?: string): Promise<AcademicSubjectDTO[]> {
    return await this.repository.findEnrolledSubjects(studentId, collegeId);
  }

  async searchResources(
    filter: SubjectSearchFilter,
    collegeId?: string
  ): Promise<ResourceSearchResultDTO[]> {
    return await this.repository.searchResources(filter, collegeId);
  }

  async recordResourceView(resourceId: string): Promise<{ success: boolean }> {
    const success = await this.repository.incrementResourceView(resourceId);
    return { success };
  }

  async recordResourceDownload(resourceId: string): Promise<{ success: boolean }> {
    const success = await this.repository.incrementResourceDownload(resourceId);
    return { success };
  }

  async getFacultyDirectory(collegeId?: string, search?: string, departmentId?: string): Promise<AcademicFacultyDTO[]> {
    return await this.repository.findFacultyDirectory(collegeId, search, departmentId);
  }

  async getFacultyProfile(facultyId: string): Promise<AcademicFacultyDTO> {
    const faculty = await this.repository.findFacultyById(facultyId);
    if (!faculty) {
      throw new NotFoundError(`Faculty with ID ${facultyId} not found`);
    }
    return faculty;
  }

  async getSubjectAssignments(subjectId: string, studentId: string): Promise<StudentAssignmentDTO[]> {
    return await this.repository.findSubjectAssignments(subjectId, studentId);
  }

  async getPendingAssignments(studentId: string): Promise<StudentAssignmentDTO[]> {
    return await this.repository.findPendingAssignments(studentId);
  }

  async submitAssignment(studentId: string, assignmentId: string, dto: SubmitAssignmentDTO): Promise<any> {
    return await this.repository.submitAssignment(studentId, assignmentId, dto);
  }

  async getSubjectAttendance(subjectId: string, studentId: string): Promise<StudentAttendanceSummaryDTO> {
    return await this.repository.findSubjectAttendance(subjectId, studentId);
  }

  async getOverallAttendanceSummary(studentId: string): Promise<StudentAttendanceSummaryDTO[]> {
    return await this.repository.findOverallAttendanceSummary(studentId);
  }

  async getStudentTimetable(
    studentId: string,
    collegeId?: string,
    todayOnly?: boolean
  ): Promise<StudentTimetableSlotDTO[]> {
    return await this.repository.findStudentTimetable(studentId, collegeId, todayOnly);
  }

  async getSubjectAssessments(subjectId: string, studentId: string): Promise<StudentSubjectAssessmentDTO[]> {
    return await this.repository.findSubjectAssessments(subjectId, studentId);
  }

  async getAssessmentsSummary(studentId: string): Promise<StudentAssessmentSummaryDTO[]> {
    return await this.repository.findOverallAssessmentsSummary(studentId);
  }
}

