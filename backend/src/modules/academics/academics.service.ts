import { AcademicsRepository } from './academics.repository';
import {
  SubjectSearchFilter,
  AcademicSubjectDTO,
  AcademicSubjectDetailDTO,
  ResourceSearchResultDTO,
  AcademicFacultyDTO,
} from './academics.types';
import { NotFoundError } from '../../shared/utils/custom-error.util';

export class AcademicsService {
  constructor(private readonly repository: AcademicsRepository = new AcademicsRepository()) {}

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
}
