import { z } from 'zod';

export const createEventSchema = z.object({
  body: z.object({
    title: z.string().min(3, 'Title must be at least 3 characters').max(255),
    description: z.string().optional(),
    scope: z.enum(['COLLEGE', 'DEPARTMENT', 'CLUB']),
    department_id: z.string().uuid().optional(),
    club_id: z.string().uuid().optional(),
    category: z.string().optional(),
    venue: z.string().optional(),
    start_time: z.string().datetime('Invalid start_time format ISO 8601'),
    end_time: z.string().datetime('Invalid end_time format ISO 8601'),
    banner_url: z.string().url().optional().or(z.literal('')),
    max_capacity: z.number().int().positive().optional(),
    registration_deadline: z.string().datetime().optional(),
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
