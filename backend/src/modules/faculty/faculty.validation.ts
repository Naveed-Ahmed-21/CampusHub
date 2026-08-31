import { z } from 'zod';

export const createSubjectSchema = z.object({
  body: z.object({
    code: z.string().min(2, 'Subject code must be at least 2 characters'),
    name: z.string().min(3, 'Subject name must be at least 3 characters'),
    departmentId: z.string().optional(),
    departmentName: z.string().optional(),
    semester: z.string().min(1, 'Semester is required'),
    section: z.string().optional().default('A'),
    credits: z.number().int().positive().optional().default(3),
    description: z.string().optional(),
  }),
});

export const createSubjectResourceSchema = z.object({
  params: z.object({
    id: z.string().optional(),
    subjectId: z.string().optional(),
  }).optional(),
  body: z.object({
    title: z.string().min(2, 'Resource title must be at least 2 characters'),
    description: z.string().optional(),
    fileUrl: z.string().min(1, 'File URL is required'),
    fileType: z.string().min(1, 'File type is required'),
  }),
});

export const createSubjectAnnouncementSchema = z.object({
  params: z.object({
    id: z.string().optional(),
    subjectId: z.string().optional(),
  }).optional(),
  body: z.object({
    title: z.string().min(2, 'Announcement title must be at least 2 characters'),
    content: z.string().min(5, 'Announcement content must be at least 5 characters'),
  }),
});

export const createFacultyAnnouncementSchema = z.object({
  body: z.object({
    title: z.string().min(2, 'Title is required'),
    content: z.string().min(5, 'Content is required'),
    departmentId: z.string().optional(),
    type: z.enum(['GENERAL', 'ANNOUNCEMENT', 'ACADEMIC']).optional().default('ACADEMIC'),
  }),
});
