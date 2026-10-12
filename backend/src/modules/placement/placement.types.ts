import { ApplicationStatus, DriveStatus } from '@prisma/client';

export interface CreateDriveDto {
  company_name: string;
  company_id?: string;
  role_title: string;
  package_ctc?: string;
  location?: string;
  eligibility?: string;
  min_cgpa?: number;
  allowed_departments?: string[];
  max_backlogs?: number;
  job_description?: string;
  deadline: string;
  status?: DriveStatus;
  target_year?: number;
  target_batch?: string;
  employment_type?: string;
  work_mode?: string;
  required_skills?: string[];
  drive_date?: string;
  test_date?: string;
  interview_date?: string;
  venue_or_link?: string;
  banner_url?: string;
}

export interface UpdateDriveDto {
  company_name?: string;
  company_id?: string;
  role_title?: string;
  package_ctc?: string;
  location?: string;
  eligibility?: string;
  min_cgpa?: number;
  allowed_departments?: string[];
  max_backlogs?: number;
  job_description?: string;
  deadline?: string;
  status?: DriveStatus;
  target_year?: number;
  target_batch?: string;
  employment_type?: string;
  work_mode?: string;
  required_skills?: string[];
  drive_date?: string;
  test_date?: string;
  interview_date?: string;
  venue_or_link?: string;
  banner_url?: string;
}

export interface ApplyDriveDto {
  drive_id: string;
  resume_url?: string;
}

export interface UpdateApplicationStatusDto {
  status: ApplicationStatus;
  offer_ctc?: string;
}

export interface BulkUpdateStatusDto {
  application_ids: string[];
  status: ApplicationStatus;
  offer_ctc?: string;
}

export interface ScheduleInterviewDto {
  application_id: string;
  round_name: string;
  scheduled_at: string;
  location_or_link?: string;
  notes?: string;
}

export interface RespondOfferDto {
  offer_status: 'ACCEPTED' | 'DECLINED';
}

export interface DriveQueryDto {
  status?: DriveStatus;
  search?: string;
  department_id?: string;
  target_year?: number;
  employment_type?: string;
  page?: number;
  limit?: number;
}

export interface CreateCompanyDto {
  name: string;
  website?: string;
  logo_url?: string;
  cover_image_url?: string;
  industry?: string;
  about?: string;
  linkedin_url?: string;
}

export interface UpdateCompanyDto {
  name?: string;
  website?: string;
  logo_url?: string;
  cover_image_url?: string;
  industry?: string;
  about?: string;
  linkedin_url?: string;
}

export interface CompanyLookupResult {
  name: string;
  domain: string;
  website: string;
  logo_url: string;
  cover_image_url: string;
  industry: string;
  about: string;
  linkedin_url?: string;
  location?: string;
}

export interface CreateResourceDto {
  title: string;
  description?: string;
  category: string; // APTITUDE, TECHNICAL, HR, COMPANY_SPECIFIC
  resource_type: string; // PDF, VIDEO, YOUTUBE_PLAYLIST, EXTERNAL_LINK, MOCK_TEST, NOTES
  file_url?: string;
  external_url?: string;
  thumbnail_url?: string;
  tags?: string[];
  target_departments?: string[];
  target_year?: number;
  target_batch?: string;
  company_id?: string;
  drive_id?: string;
}

export interface ResourceQueryDto {
  category?: string;
  resource_type?: string;
  company_id?: string;
  drive_id?: string;
  search?: string;
  page?: number;
  limit?: number;
}

export interface StudentPlacementQueryDto {
  search?: string;
  department_id?: string;
  year?: number;
  status?: 'PLACED' | 'ELIGIBLE' | 'IN_PROCESS' | 'ALL';
  min_cgpa?: number;
  page?: number;
  limit?: number;
}

export interface ApplicationQueryDto {
  drive_id?: string;
  status?: ApplicationStatus;
  department_id?: string;
  search?: string;
  page?: number;
  limit?: number;
}

export interface InterviewQueryDto {
  status?: string;
  drive_id?: string;
  page?: number;
  limit?: number;
}

