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
    academicYear: z.string().optional(),
  }),
});

export const createSubjectResourceSchema = z.object({
  params: z
    .object({
      id: z.string().optional(),
      subjectId: z.string().optional(),
    })
    .optional(),
  body: z.object({
    title: z.string().min(2, 'Resource title must be at least 2 characters'),
    description: z.string().optional(),
    fileUrl: z.string().min(1, 'File URL is required'),
    fileType: z.string().min(1, 'File type is required'),
    unit: z.string().optional(),
    topic: z.string().optional(),
    resourceType: z.string().optional().default('NOTES'),
    visibility: z.enum(['PUBLIC', 'ENROLLED_ONLY', 'COLLEGE_ONLY']).optional().default('PUBLIC'),
    thumbnailUrl: z.string().optional(),
    academicYear: z.string().optional(),
  }),
});

export const updateSubjectResourceSchema = z.object({
  params: z.object({
    id: z.string(),
    resourceId: z.string(),
  }),
  body: z.object({
    title: z.string().min(2).optional(),
    description: z.string().optional(),
    fileUrl: z.string().optional(),
    fileType: z.string().optional(),
    unit: z.string().optional(),
    topic: z.string().optional(),
    resourceType: z.string().optional(),
    visibility: z.enum(['PUBLIC', 'ENROLLED_ONLY', 'COLLEGE_ONLY']).optional(),
    thumbnailUrl: z.string().optional(),
  }),
});

export const createSubjectAnnouncementSchema = z.object({
  params: z
    .object({
      id: z.string().optional(),
      subjectId: z.string().optional(),
    })
    .optional(),
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

export const updateFacultyProfileSchema = z.object({
  body: z.object({
    designation: z.string().optional(),
    qualification: z.string().optional(),
    departmentName: z.string().optional(),
    specialization: z.string().optional(),
    bio: z.string().optional(),
    officeRoom: z.string().optional(),
    officeHours: z.string().optional(),
    expertise: z.array(z.string()).optional(),
    publications: z
      .array(
        z.object({
          title: z.string(),
          venue: z.string(),
          link: z.string().optional(),
        })
      )
      .optional(),
    avatarUrl: z.string().optional(),
    linkedinUrl: z.string().optional(),
    googleScholar: z.string().optional(),
  }),
});
