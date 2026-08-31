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
}

export interface SubjectResourceDTO {
  id: string;
  subjectId: string;
  title: string;
  description?: string;
  fileUrl: string;
  fileType: string;
  uploadedById: string;
  uploadedByName: string;
  createdAt: Date;
}

export interface CreateSubjectResourceDTO {
  title: string;
  description?: string;
  fileUrl: string;
  fileType: string;
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
  subjectCode: string;
  subjectName: string;
  roomOrVenue: string;
  startTime: string;
  endTime: string;
  semester: string;
  section: string;
  dayOfWeek: string;
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
