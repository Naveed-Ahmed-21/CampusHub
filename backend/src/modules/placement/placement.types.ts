import { ApplicationStatus, DriveStatus } from '@prisma/client';

export interface CreateDriveDto {
  company_name: string;
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
}

export interface ApplyDriveDto {
  drive_id: string;
  resume_url?: string;
}

export interface UpdateApplicationStatusDto {
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
  page?: number;
  limit?: number;
}
