import { z } from 'zod';
import { ApplicationStatus, DriveStatus } from '@prisma/client';

const dateStringSchema = z
  .string()
  .refine((val) => !isNaN(Date.parse(val)), { message: 'Invalid date/time format' });

const optionalDateSchema = z
  .string()
  .refine((val) => !isNaN(Date.parse(val)), { message: 'Invalid date/time format' })
  .optional()
  .nullable()
  .or(z.literal(''));

export const createDriveSchema = z.object({
  body: z.object({
    company_name: z.string().min(2, 'Company name is required').max(255),
    company_id: z.string().uuid().optional(),
    role_title: z.string().min(2, 'Role title is required').max(255),
    package_ctc: z.string().optional(),
    location: z.string().optional(),
    eligibility: z.string().optional(),
    min_cgpa: z.number().min(0).max(10).optional(),
    allowed_departments: z.array(z.string()).optional(),
    max_backlogs: z.number().int().min(0).optional(),
    job_description: z.string().optional(),
    deadline: dateStringSchema,
    status: z.nativeEnum(DriveStatus).optional(),
    target_year: z.number().int().min(1).max(5).optional(),
    target_batch: z.string().optional(),
    employment_type: z.string().optional(),
    work_mode: z.string().optional(),
    required_skills: z.array(z.string()).optional(),
    drive_date: optionalDateSchema,
    test_date: optionalDateSchema,
    interview_date: optionalDateSchema,
    venue_or_link: z.string().optional(),
    banner_url: z.string().optional(),
  }),
});

export const updateDriveSchema = z.object({
  body: z.object({
    company_name: z.string().min(2).max(255).optional(),
    company_id: z.string().uuid().optional(),
    role_title: z.string().min(2).max(255).optional(),
    package_ctc: z.string().optional(),
    location: z.string().optional(),
    eligibility: z.string().optional(),
    min_cgpa: z.number().min(0).max(10).optional(),
    allowed_departments: z.array(z.string()).optional(),
    max_backlogs: z.number().int().min(0).optional(),
    job_description: z.string().optional(),
    deadline: optionalDateSchema,
    status: z.nativeEnum(DriveStatus).optional(),
    target_year: z.number().int().min(1).max(5).optional(),
    target_batch: z.string().optional(),
    employment_type: z.string().optional(),
    work_mode: z.string().optional(),
    required_skills: z.array(z.string()).optional(),
    drive_date: optionalDateSchema,
    test_date: optionalDateSchema,
    interview_date: optionalDateSchema,
    venue_or_link: z.string().optional(),
    banner_url: z.string().optional(),
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

export const bulkUpdateStatusSchema = z.object({
  body: z.object({
    application_ids: z.array(z.string().uuid('Invalid application ID')).min(1, 'At least one application required'),
    status: z.nativeEnum(ApplicationStatus),
    offer_ctc: z.string().optional(),
  }),
});

export const scheduleInterviewSchema = z.object({
  body: z.object({
    application_id: z.string().uuid('Invalid application ID'),
    round_name: z.string().min(2, 'Round name is required'),
    scheduled_at: dateStringSchema,
    location_or_link: z.string().optional(),
    notes: z.string().optional(),
  }),
});

export const respondOfferSchema = z.object({
  body: z.object({
    offer_status: z.enum(['ACCEPTED', 'DECLINED']),
  }),
});

export const createCompanySchema = z.object({
  body: z.object({
    name: z.string().min(2, 'Company name is required').max(255),
    website: z.string().url('Invalid website URL').optional().or(z.literal('')),
    logo_url: z.string().url('Invalid logo URL').optional().or(z.literal('')),
    cover_image_url: z.string().url('Invalid cover image URL').optional().or(z.literal('')),
    industry: z.string().max(100).optional(),
    about: z.string().optional(),
    linkedin_url: z.string().url('Invalid LinkedIn URL').optional().or(z.literal('')),
  }),
});

export const updateCompanySchema = z.object({
  body: z.object({
    name: z.string().min(2).max(255).optional(),
    website: z.string().url('Invalid website URL').optional().or(z.literal('')),
    logo_url: z.string().url('Invalid logo URL').optional().or(z.literal('')),
    cover_image_url: z.string().url('Invalid cover image URL').optional().or(z.literal('')),
    industry: z.string().max(100).optional(),
    about: z.string().optional(),
    linkedin_url: z.string().url('Invalid LinkedIn URL').optional().or(z.literal('')),
  }),
});

export const createResourceSchema = z.object({
  body: z.object({
    title: z.string().min(2, 'Title is required').max(255),
    description: z.string().optional(),
    category: z.enum(['APTITUDE', 'TECHNICAL', 'HR', 'COMPANY_SPECIFIC']),
    resource_type: z.enum(['PDF', 'VIDEO', 'YOUTUBE_PLAYLIST', 'EXTERNAL_LINK', 'MOCK_TEST', 'NOTES']),
    file_url: z.string().optional(),
    external_url: z.string().optional(),
    thumbnail_url: z.string().optional(),
    tags: z.array(z.string()).optional(),
    target_departments: z.array(z.string()).optional(),
    target_year: z.number().int().min(1).max(5).optional(),
    target_batch: z.string().optional(),
    company_id: z.string().uuid().optional(),
    drive_id: z.string().uuid().optional(),
  }),
});
