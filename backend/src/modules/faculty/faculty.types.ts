export interface FacultyDashboardDTO {
  faculty: {
    id: string;
    name: string;
    email: string;
    designation: string;
    department: string;
    avatarUrl?: string | null;
  };
  stats: {
    totalSubjects: number;
    totalMentees: number;
    todayClassesCount: number;
    upcomingEventsCount: number;
    publishedAnnouncementsCount: number;
  };
  todaySchedule: ClassScheduleSlotDTO[];
  recentAnnouncements: SubjectAnnouncementDTO[];
  upcomingEvents: Array<{
    id: string;
    title: string;
    startTime: string;
    venue: string;
    scope: string;
  }>;
}

export interface SubjectDTO {
  id: string;
  facultyId?: string;
  code: string;
  name: string;
  department: string;
  semester: string;
  section: string;
  credits: number;
  description?: string;
  academicYear?: string;
  resourcesCount: number;
  announcementsCount: number;
  studentsCount: number;
  createdAt: Date;
}

export interface CreateSubjectDTO {
  code: string;
  name: string;
  departmentId?: string;
  departmentName?: string;
  semester: string;
  section?: string;
  credits?: number;
  description?: string;
  academicYear?: string;
}

export interface UpdateSubjectDTO {
  code?: string;
  name?: string;
  departmentId?: string;
  departmentName?: string;
  semester?: string;
  section?: string;
  credits?: number;
  description?: string;
  academicYear?: string;
}

export interface SubjectResourceDTO {
  id: string;
  subjectId: string;
  title: string;
  description?: string;
  fileUrl: string;
  fileType: string;
  unit?: string | null;
  topic?: string | null;
  resourceType: string;
  visibility: string;
  thumbnailUrl?: string | null;
  academicYear?: string | null;
  downloadCount: number;
  viewCount: number;
  uploadedById: string;
  uploadedByName: string;
  createdAt: Date;
  updatedAt?: Date;
}

export interface CreateSubjectResourceDTO {
  title: string;
  description?: string;
  fileUrl: string;
  fileType: string;
  unit?: string;
  topic?: string;
  resourceType?: string;
  visibility?: string;
  thumbnailUrl?: string;
  academicYear?: string;
}

export interface SubjectAnnouncementDTO {
  id: string;
  subjectId?: string;
  subjectName?: string;
  title: string;
  content: string;
  authorId: string;
  authorName: string;
  createdAt: Date;
}

export interface CreateSubjectAnnouncementDTO {
  title: string;
  content: string;
}

export interface ClassScheduleSlotDTO {
  id: string;
  subjectId?: string;
  subjectCode: string;
  subjectName: string;
  roomOrVenue: string;
  startTime: string;
  endTime: string;
  semester: string;
  section: string;
  dayOfWeek: string;
  topic?: string;
  sessionType?: string;
  status?: string;
}

export interface CreateScheduleSlotDTO {
  subjectId?: string;
  subjectCode: string;
  subjectName: string;
  roomOrVenue: string;
  startTime: string;
  endTime: string;
  semester: string;
  section?: string;
  dayOfWeek?: string;
  topic?: string;
  sessionType?: string;
  status?: string;
}

export interface UpdateScheduleSlotDTO {
  subjectId?: string;
  subjectCode?: string;
  subjectName?: string;
  roomOrVenue?: string;
  startTime?: string;
  endTime?: string;
  semester?: string;
  section?: string;
  dayOfWeek?: string;
  topic?: string;
  sessionType?: string;
  status?: string;
}

export interface EnrolledStudentDTO {
  id: string;
  name: string;
  email: string;
  rollNumber: string;
  avatarUrl?: string | null;
  department: string;
  semester?: string;
  section?: string;
  enrolledAt: Date;
}

export interface MenteeStudentDTO {
  id: string;
  name: string;
  rollNumber: string;
  department: string;
  semester: string;
  cgpa: number;
  email: string;
  avatarUrl?: string | null;
  hasPortfolio: boolean;
}

export interface FacultyProfileDTO {
  id: string;
  userId: string;
  name: string;
  email: string;
  avatarUrl?: string | null;
  designation: string;
  qualification: string;
  department: string;
  specialization: string;
  bio: string;
  officeRoom: string;
  officeHours: string;
  expertise: string[];
  publications: Array<{
    title: string;
    venue: string;
    link?: string;
  }>;
  linkedinUrl?: string | null;
  googleScholar?: string | null;
  subjectsCount: number;
  menteesCount: number;
}

export interface UpdateFacultyProfileDTO {
  designation?: string;
  qualification?: string;
  departmentName?: string;
  specialization?: string;
  bio?: string;
  officeRoom?: string;
  officeHours?: string;
  expertise?: string[];
  publications?: Array<{
    title: string;
    venue: string;
    link?: string;
  }>;
  avatarUrl?: string;
  linkedinUrl?: string;
  googleScholar?: string;
}

export interface SubjectAssignmentDTO {
  id: string;
  subjectId: string;
  facultyId: string;
  title: string;
  description?: string;
  unit?: string;
  topic?: string;
  attachments: any[];
  maxMarks: number;
  dueAt: Date;
  submissionType: string;
  allowLate: boolean;
  submissionsCount: number;
  gradedCount: number;
  createdAt: Date;
}

export interface CreateAssignmentDTO {
  title: string;
  description?: string;
  unit?: string;
  topic?: string;
  attachments?: any[];
  maxMarks?: number;
  dueAt: string;
  submissionType?: string;
  allowLate?: boolean;
}

export interface AssignmentSubmissionDTO {
  id: string;
  assignmentId: string;
  studentId: string;
  studentName: string;
  studentRollNumber?: string;
  studentAvatarUrl?: string | null;
  submissionType: string;
  fileUrl?: string | null;
  linkUrl?: string | null;
  textContent?: string | null;
  marks?: number | null;
  feedback?: string | null;
  status: string;
  submittedAt: Date;
  gradedAt?: Date | null;
}

export interface GradeSubmissionDTO {
  marks: number;
  feedback?: string;
}

export interface AttendanceSessionDTO {
  id: string;
  subjectId: string;
  facultyId: string;
  sessionDate: string;
  startTime?: string;
  endTime?: string;
  topic?: string;
  totalStudents: number;
  presentCount: number;
  createdAt: Date;
  records?: StudentAttendanceRecordDTO[];
}

export interface StudentAttendanceRecordDTO {
  id?: string;
  studentId: string;
  studentName?: string;
  studentRollNumber?: string;
  studentAvatarUrl?: string | null;
  status: string;
  remarks?: string;
}

export interface RecordAttendanceDTO {
  sessionDate?: string;
  startTime?: string;
  endTime?: string;
  topic?: string;
  records: Array<{
    studentId: string;
    status: string;
    remarks?: string;
  }>;
}

export interface SubjectAssessmentDTO {
  id: string;
  subjectId: string;
  facultyId: string;
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
  evaluatedCount?: number;
  averageMarks?: number;
  createdAt: Date;
}

export interface CreateSubjectAssessmentDTO {
  title: string;
  description?: string;
  assessmentType?: string;
  unit?: string;
  topic?: string;
  totalMarks?: number;
  passingMarks?: number;
  durationMinutes?: number;
  scheduledAt?: string;
}

export interface StudentAssessmentResultDTO {
  id?: string;
  assessmentId: string;
  subjectId: string;
  studentId: string;
  studentName?: string;
  studentRollNumber?: string;
  studentAvatarUrl?: string | null;
  marksObtained?: number | null;
  grade?: string | null;
  remarks?: string | null;
  status: string;
  evaluatedAt?: Date | null;
}

export interface BatchRecordAssessmentMarksDTO {
  results: Array<{
    studentId: string;
    marksObtained?: number;
    grade?: string;
    remarks?: string;
    status?: string;
  }>;
}

export interface FacultyAcademicContextDTO {
  currentTerm: {
    academicYearId: string;
    academicYear: string;
    termId: string;
    termName: string;
    termType: 'ODD' | 'EVEN';
    startDate: string;
    endDate: string;
    status: string;
  };
  academicHeader: string;
  assignedSubjects: SubjectDTO[];
  classes: Array<{
    semester: string;
    section: string;
    subjectCount: number;
    studentCount: number;
  }>;
  todaySchedule: ClassScheduleSlotDTO[];
}

export interface EnrolledAttendanceStudentDTO {
  id: string;
  name: string;
  rollNumber: string;
  avatarUrl?: string | null;
  email?: string;
  department?: string;
  recordId?: string;
  status: 'UNMARKED' | 'PRESENT' | 'ABSENT' | 'LATE' | 'EXCUSED';
  remarks?: string;
}

export interface SessionAttendanceDetailDTO {
  session: {
    id: string;
    subjectId: string;
    subjectCode: string;
    subjectName: string;
    sessionDate: string;
    startTime?: string;
    endTime?: string;
    topic?: string;
    status: 'OPEN' | 'LOCKED';
    section: string;
  };
  metrics: {
    total: number;
    present: number;
    absent: number;
    unmarked: number;
    late: number;
    excused: number;
  };
  students: EnrolledAttendanceStudentDTO[];
}

export interface BulkAttendanceRecordItemDTO {
  studentId: string;
  status: string;
  remarks?: string;
}

export interface BulkAttendanceDTO {
  sessionId: string;
  records: BulkAttendanceRecordItemDTO[];
}


