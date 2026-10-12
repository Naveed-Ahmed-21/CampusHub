import { Role, ClubStatus, ApplicationStatus, UserStatus } from '@prisma/client';

export interface QueryAdminUsersDto {
  role?: Role;
  departmentId?: string;
  search?: string;
  page?: number;
  limit?: number;
}

export interface UpdateUserRoleDto {
  userId: string;
  newRole: Role;
}

export interface UpdateUserStatusDto {
  userId: string;
  isActive?: boolean;
  status?: UserStatus;
}

export interface CreateUserDto {
  email: string;
  firstName?: string;
  lastName?: string;
  role: Role;
  departmentId?: string;
  rollNumber?: string;
  registrationNumber?: string;
  phone?: string;
  password?: string;
  admissionYear?: number;
  batchName?: string;
  batchId?: string;
  section?: string;
  currentYear?: number;
  year?: string;
  programId?: string;
  designation?: string;
  officeRoom?: string;
  status?: UserStatus;
  isPasswordConfigured?: boolean;
  isProfileCompleted?: boolean;
}

export interface UpdateUserDto {
  firstName?: string;
  lastName?: string;
  email?: string;
  phone?: string;
  departmentId?: string | null;
  rollNumber?: string;
  registrationNumber?: string;
  role?: Role;
  status?: UserStatus;
  admissionYear?: number;
  batchName?: string;
  batchId?: string;
  section?: string;
  currentYear?: number;
  year?: string;
  designation?: string;
  officeRoom?: string;
}

export interface DepartmentOverviewDto {
  department: any;
  totalStudents: number;
  totalFaculty: number;
  studentsByYear: {
    firstYear: number;
    secondYear: number;
    thirdYear: number;
    fourthYear: number;
    graduated: number;
  };
}

export interface QueryDepartmentStudentsDto {
  year?: string | number;
  page?: number;
  limit?: number;
  search?: string;
}

export interface QueryDepartmentFacultyDto {
  page?: number;
  limit?: number;
  search?: string;
}

export interface CreateDepartmentDto {
  name: string;
  code: string;
  description?: string;
  hodName?: string;
}

export interface UpdateDepartmentDto {
  name?: string;
  code?: string;
  description?: string;
  isActive?: boolean;
  is_active?: boolean;
}

export interface SystemAnalyticsDto {
  totalUsers: number;
  activeStudents: number;
  facultyCount: number;
  totalDepartments: number;
  approvedClubs: number;
  pendingClubs: number;
  totalEvents: number;
  totalPlacementDrives: number;
  totalPlacementsCount: number;
  averagePackageLpa: number;
}

export interface SystemReportItem {
  id: string;
  timestamp: Date;
  actorName: string;
  action: string;
  category: string;
  details: string;
  ipAddress?: string;
}

export interface CreateAcademicYearDto {
  yearName: string;
  startDate: string;
  endDate: string;
  isActive?: boolean;
}

export interface UpdateAcademicYearDto {
  yearName?: string;
  startDate?: string;
  endDate?: string;
  isActive?: boolean;
}

export interface CreateAcademicTermDto {
  academicYearId: string;
  name: string;
  termType?: string;
  semesterNumber: number;
  startDate: string;
  endDate: string;
  status?: string;
}

export interface UpdateAcademicTermDto {
  name?: string;
  termType?: string;
  semesterNumber?: number;
  startDate?: string;
  endDate?: string;
  status?: string;
}

export interface CreateAcademicProgramDto {
  departmentId: string;
  name: string;
  code: string;
  degreeType?: string;
  totalSemesters?: number;
  isActive?: boolean;
}

export interface UpdateAcademicProgramDto {
  departmentId?: string;
  name?: string;
  code?: string;
  degreeType?: string;
  totalSemesters?: number;
  isActive?: boolean;
}

export interface CreateBatchDto {
  departmentId?: string;
  programId?: string;
  name: string;
  admissionYear: number;
  graduationYear: number;
  status?: string;
}

export interface UpdateBatchDto {
  departmentId?: string;
  programId?: string;
  name?: string;
  admissionYear?: number;
  graduationYear?: number;
  status?: string;
}

export interface CreateSubjectDto {
  departmentId?: string;
  facultyId: string;
  code: string;
  name: string;
  semester: string;
  section?: string;
  credits?: number;
  description?: string;
  subjectType?: string;
  hoursPerWeek?: number;
  academicYear?: string;
  academicTermId?: string;
}

export interface UpdateSubjectDto {
  departmentId?: string;
  facultyId?: string;
  code?: string;
  name?: string;
  semester?: string;
  section?: string;
  credits?: number;
  description?: string;
  subjectType?: string;
  hoursPerWeek?: number;
  academicYear?: string;
  academicTermId?: string;
}

export interface CreateCurriculumSubjectDto {
  programId: string;
  subjectId: string;
  batchYear: number;
  semesterNumber: number;
  subjectType?: string;
  credits?: number;
  hoursPerWeek?: number;
  version?: string;
}

export interface CreateAcademicClassDto {
  departmentId: string;
  programId?: string;
  name: string;
  yearOfStudy: number;
  semester: number;
  section?: string;
  classAdvisorId?: string;
  roomId?: string;
}

export interface UpdateAcademicClassDto {
  departmentId?: string;
  programId?: string;
  name?: string;
  yearOfStudy?: number;
  semester?: number;
  section?: string;
  classAdvisorId?: string;
  roomId?: string;
}

export interface CreateRoomDto {
  code: string;
  name: string;
  building?: string;
  floor?: number;
  capacity?: number;
  roomType?: string;
}

export interface UpdateRoomDto {
  code?: string;
  name?: string;
  building?: string;
  floor?: number;
  capacity?: number;
  roomType?: string;
  isActive?: boolean;
}

export interface CreateFacultyAssignmentDto {
  facultyId: string;
  subjectId: string;
  academicTermId: string;
  section?: string;
  role?: string;
  isPrimary?: boolean;
}

export interface CreateScheduleDto {
  facultyId: string;
  subjectId?: string;
  academicTermId?: string;
  classId?: string;
  roomId?: string;
  dayOfWeek: string;
  startTime: string;
  endTime: string;
  semester?: string;
  section?: string;
  topic?: string;
  sessionType?: string;
  status?: string;
  batchGroup?: string;
  effectiveFrom?: string;
  effectiveUntil?: string;
}

export interface UpdateScheduleDto {
  facultyId?: string;
  subjectId?: string;
  academicTermId?: string;
  classId?: string;
  roomId?: string;
  dayOfWeek?: string;
  startTime?: string;
  endTime?: string;
  semester?: string;
  section?: string;
  topic?: string;
  sessionType?: string;
  status?: string;
  batchGroup?: string;
  effectiveFrom?: string;
  effectiveUntil?: string;
}

export interface AcademicMonitoringMetrics {
  totalAttendanceSessions: number;
  averageAttendanceRate: number;
  totalAssignments: number;
  totalSubmissions: number;
  totalAssessments: number;
  averageAssessmentScore: number;
}

export interface QueryAcademicMonitoringDto {
  departmentId?: string;
  subjectId?: string;
  academicTermId?: string;
  facultyId?: string;
  startDate?: string;
  endDate?: string;
}

export interface SendBroadcastNotificationDto {
  title: string;
  body: string;
  category?: string;
  targetAudience: 'ALL' | 'STUDENTS' | 'FACULTY' | 'DEPARTMENT';
  departmentId?: string;
}

export interface QueryAuditLogsDto {
  action?: string;
  category?: string;
  entityType?: string;
  actorUserId?: string;
  startDate?: string;
  endDate?: string;
  limit?: number;
}

export interface UpdateCollegeDto {
  name?: string;
  domain?: string;
  logoUrl?: string;
  address?: string;
}



