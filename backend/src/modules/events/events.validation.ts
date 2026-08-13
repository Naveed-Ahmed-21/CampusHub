import { z } from 'zod';

export const createEventSchema = z.object({
  body: z.object({
    title: z.string().min(3, 'Title must be at least 3 characters').max(255),
    description: z.string().optional().nullable(),
    scope: z.enum(['COLLEGE', 'DEPARTMENT', 'CLUB']),
    department_id: z.string().uuid().optional().nullable(),
    club_id: z.string().uuid().optional().nullable(),
    category: z.string().optional().nullable(),
    venue: z.string().optional().nullable(),
    start_time: z.string().refine((val) => !isNaN(Date.parse(val)), 'Invalid start_time format'),
    end_time: z.string().refine((val) => !isNaN(Date.parse(val)), 'Invalid end_time format'),
    banner_url: z.string().optional().nullable(),
    max_capacity: z.number().int().positive().optional().nullable(),
    registration_deadline: z.string().optional().nullable(),
  }),
});

export const queryEventsSchema = z.object({
  query: z.object({
    scope: z.enum(['COLLEGE', 'DEPARTMENT', 'CLUB']).optional(),
    department_id: z.string().uuid().optional(),
    club_id: z.string().uuid().optional(),
    category: z.string().optional(),
    search: z.string().optional(),
    page: z.string().transform((v) => parseInt(v, 10)).optional(),
    limit: z.string().transform((v) => parseInt(v, 10)).optional(),
  }),
});

export const markQRAttendanceSchema = z.object({
  body: z.object({
    ticket_code: z.string().min(1, 'Ticket code is required'),
  }),
});
