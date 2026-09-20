import { SubjectResourceDTO, SubjectAnnouncementDTO } from '../faculty/faculty.types';

export interface SubjectSearchFilter {
  search?: string;
  departmentId?: string;
  semester?: string;
  section?: string;
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

export interface StudentAssignmentDTO {
  id: string;
  subjectId: string;
  subjectCode: string;
  subjectName: string;
  facultyName: string;
  title: string;
  description?: string;
  unit?: string;
  topic?: string;
  attachments: any[];
  maxMarks: number;
  dueAt: Date;
  submissionType: string;
  allowLate: boolean;
  submission?: {
    id: string;
    status: string;
    marks?: number | null;
    feedback?: string | null;
    submittedAt: Date;
    fileUrl?: string | null;
    textContent?: string | null;
    linkUrl?: string | null;
  } | null;
}

export interface SubmitAssignmentDTO {
  submissionType?: string;
  fileUrl?: string;
  linkUrl?: string;
  textContent?: string;
}

export interface StudentAttendanceSummaryDTO {
  subjectId: string;
  subjectCode: string;
  subjectName: string;
  facultyName: string;
  totalSessions: number;
  attendedSessions: number;
  percentage: number;
  records: Array<{
    id: string;
    date: string;
    startTime?: string;
    endTime?: string;
    topic?: string;
    status: string;
    remarks?: string;
  }>;
}

export interface StudentTimetableSlotDTO {
  id: string;
  subjectId?: string;
  subjectCode: string;
  subjectName: string;
  facultyId?: string;
  facultyName: string;
  facultyAvatarUrl?: string | null;
  roomOrVenue: string;
  startTime: string;
  endTime: string;
  dayOfWeek: string;
  topic?: string;
  sessionType: string;
  status: string;
}

export interface StudentSubjectAssessmentDTO {
  id: string;
  subjectId: string;
  subjectCode: string;
  subjectName: string;
  facultyName: string;
  title: string;
  description?: string;
  assessmentType: string;
  unit?: string;
  topic?: string;
  totalMarks: number;
  passingMarks: number;
  durationMinutes?: number;
  scheduledAt?: Date | null;
  status: string;
  result?: {
    marksObtained?: number | null;
    grade?: string | null;
    remarks?: string | null;
    status: string;
    evaluatedAt?: Date | null;
  } | null;
}

export interface StudentAssessmentSummaryDTO {
  subjectId: string;
  subjectCode: string;
  subjectName: string;
  totalAssessments: number;
  evaluatedAssessments: number;
  totalScored: number;
  totalMax: number;
  percentage: number;
  assessments: StudentSubjectAssessmentDTO[];
}

export interface StudentAcademicContextDTO {
  academicYear: string;
  academicTerm: string;
  termType: 'ODD' | 'EVEN';
  semester: number;
  semesterRoman: string;
  semesterLabel: string;
  yearOfStudy: number;
  yearRoman: string;
  yearLabel: string;
  admissionYear: number;
  batchName: string;
  department: string;
  departmentName: string;
  program: string;
  section: string;
  class: string;
  academicHeader: string;
  status: string;
  hasOverride: boolean;
  overrideReason?: string;
  subjects: AcademicSubjectDTO[];
}


