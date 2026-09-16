import { SubjectResourceDTO, SubjectAnnouncementDTO } from '../faculty/faculty.types';

export interface SubjectSearchFilter {
  search?: string;
  departmentId?: string;
  semester?: string;
  academicYear?: string;
  unit?: string;
  resourceType?: string;
  page?: number;
  limit?: number;
}

export interface AcademicSubjectDTO {
  id: string;
  code: string;
  name: string;
  department: string;
  departmentCode?: string;
  departmentId?: string | null;
  semester: string;
  section: string;
  credits: number;
  description?: string;
  academicYear: string;
  faculty: {
    id: string;
    name: string;
    email: string;
    designation: string;
    avatarUrl?: string | null;
  };
  resourcesCount: number;
  unitsCount: number;
  units: string[];
  isEnrolled: boolean;
}

export interface AcademicSubjectDetailDTO {
  id: string;
  code: string;
  name: string;
  department: string;
  departmentCode?: string;
  departmentId?: string | null;
  semester: string;
  section: string;
  credits: number;
  description?: string;
  academicYear: string;
  faculty: {
    id: string;
    name: string;
    email: string;
    designation: string;
    qualification: string;
    department: string;
    specialization: string;
    officeRoom: string;
    officeHours: string;
    bio: string;
    avatarUrl?: string | null;
    expertise: string[];
    publications: Array<{
      title: string;
      venue: string;
      link?: string;
    }>;
  };
  isEnrolled: boolean;
  announcements: SubjectAnnouncementDTO[];
  resourcesByUnit: Record<string, SubjectResourceDTO[]>;
  allResources: SubjectResourceDTO[];
}

export interface ResourceSearchResultDTO {
  id: string;
  subjectId: string;
  subjectCode: string;
  subjectName: string;
  departmentName: string;
  facultyName: string;
  title: string;
  description?: string;
  fileUrl: string;
  fileType: string;
  unit?: string | null;
  topic?: string | null;
  resourceType: string;
  visibility: string;
  downloadCount: number;
  viewCount: number;
  createdAt: Date;
}

export interface AcademicFacultyDTO {
  id: string;
  name: string;
  email: string;
  designation: string;
  qualification: string;
  department: string;
  specialization: string;
  bio: string;
  officeRoom: string;
  officeHours: string;
  avatarUrl?: string | null;
  expertise: string[];
  publications: Array<{
    title: string;
    venue: string;
    link?: string;
  }>;
  subjectsTaught: Array<{
    id: string;
    code: string;
    name: string;
    semester: string;
    section: string;
    credits: number;
  }>;
}
