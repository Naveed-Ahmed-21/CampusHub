import { z } from 'zod';

export const registerSchema = z.object({
  body: z.object({
    collegeId: z.string().min(1, 'College ID is required'),
    email: z.string().email('Invalid email address'),
    password: z.string().min(8, 'Password must be at least 8 characters'),
    firstName: z.string().min(2, 'First name is required'),
    lastName: z.string().min(2, 'Last name is required'),
    rollNumber: z.string().optional(),
    role: z.enum(['STUDENT', 'FACULTY']).default('STUDENT'),
  }),
});

export const loginSchema = z.object({
  body: z.object({
    email: z.string().min(1, 'Email or username is required'),
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

export const checkStatusSchema = z.object({
  body: z.object({
    email: z.string().email('Invalid email address'),
  }),
});

export const setupPasswordSchema = z.object({
  body: z.object({
    email: z.string().email('Invalid email address'),
    newPassword: z.string().min(8, 'Password must be at least 8 characters'),
    token: z.string().optional(),
    otp: z.string().optional(),
  }),
});

export const sendFirstLoginOtpSchema = z.object({
  body: z.object({
    email: z.string().email('Invalid email address'),
  }),
});

export const verifyFirstLoginOtpSchema = z.object({
  body: z.object({
    email: z.string().email('Invalid email address'),
    otp: z.string().min(4, 'OTP code is required'),
  }),
});

export const verifyForgotPasswordOtpSchema = z.object({
  body: z.object({
    email: z.string().email('Invalid email address'),
    otp: z.string().min(4, 'OTP code is required'),
  }),
});

export const changePasswordSchema = z.object({
  body: z.object({
    currentPassword: z.string().min(1, 'Current password is required'),
    newPassword: z.string().min(6, 'New password must be at least 6 characters'),
  }),
});


