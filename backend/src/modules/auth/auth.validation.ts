import { z } from 'zod';

export const registerSchema = z.object({
  body: z.object({
    collegeId: z.string().min(1, 'College ID is required'),
    email: z.string().email('Invalid email address'),
    password: z.string().min(8, 'Password must be at least 8 characters'),
    firstName: z.string().min(2, 'First name is required'),
    lastName: z.string().min(2, 'Last name is required'),
    rollNumber: z.string().optional(),
    role: z.enum(['STUDENT', 'FACULTY', 'DEPT_ADMIN', 'COLLEGE_ADMIN', 'PLACEMENT_OFFICER', 'CLUB_COORDINATOR']).default('STUDENT'),
  }),
});

export const loginSchema = z.object({
  body: z.object({
    email: z.string().email('Invalid email address'),
    password: z.string().min(1, 'Password is required'),
  }),
});

export const refreshTokenSchema = z.object({
  body: z.object({
    refreshToken: z.string().optional(),
    refresh_token: z.string().optional(),
  }),
});

export const forgotPasswordSchema = z.object({
  body: z.object({
    email: z.string().email('Invalid email address'),
  }),
});

export const resetPasswordSchema = z.object({
  body: z.object({
    token: z.string().min(1, 'Reset token is required'),
    newPassword: z.string().min(8, 'New password must be at least 8 characters'),
  }),
});
