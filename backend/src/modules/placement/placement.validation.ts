import { z } from 'zod';
import { ApplicationStatus, DriveStatus } from '@prisma/client';

export const createDriveSchema = z.object({
  body: z.object({
    company_name: z.string().min(2, 'Company name is required').max(255),
    role_title: z.string().min(2, 'Role title is required').max(255),
    package_ctc: z.string().optional(),
    location: z.string().optional(),
    eligibility: z.string().optional(),
    min_cgpa: z.number().min(0).max(10).optional(),
    allowed_departments: z.array(z.string()).optional(),
    max_backlogs: z.number().int().min(0).optional(),
    job_description: z.string().optional(),
    deadline: z.string().datetime('Invalid deadline date format'),
    status: z.nativeEnum(DriveStatus).optional(),
  }),
});

export const applyDriveSchema = z.object({
  body: z.object({
    drive_id: z.string().uuid('Invalid drive ID'),
    resume_url: z.string().url('Invalid resume URL').optional().or(z.literal('')),
  }),
});

export const updateApplicationStatusSchema = z.object({
  body: z.object({
    status: z.nativeEnum(ApplicationStatus),
    offer_ctc: z.string().optional(),
  }),
});

export const scheduleInterviewSchema = z.object({
  body: z.object({
    application_id: z.string().uuid('Invalid application ID'),
    round_name: z.string().min(2, 'Round name is required'),
    scheduled_at: z.string().datetime('Invalid interview schedule date format'),
    location_or_link: z.string().optional(),
    notes: z.string().optional(),
  }),
});

export const respondOfferSchema = z.object({
  body: z.object({
    offer_status: z.enum(['ACCEPTED', 'DECLINED']),
  }),
});
