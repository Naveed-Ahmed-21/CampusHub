import { z } from 'zod';
import { registerSchema, loginSchema, refreshTokenSchema, forgotPasswordSchema, resetPasswordSchema, checkStatusSchema, setupPasswordSchema, sendFirstLoginOtpSchema, verifyFirstLoginOtpSchema, verifyForgotPasswordOtpSchema } from './auth.validation';
import { Role } from '@prisma/client';

export type RegisterDTO = z.infer<typeof registerSchema>['body'];
export type LoginDTO = z.infer<typeof loginSchema>['body'];
export type RefreshTokenDTO = z.infer<typeof refreshTokenSchema>['body'];
export type ForgotPasswordDTO = z.infer<typeof forgotPasswordSchema>['body'];
export type ResetPasswordDTO = z.infer<typeof resetPasswordSchema>['body'];
export type CheckStatusDTO = z.infer<typeof checkStatusSchema>['body'];
export type SetupPasswordDTO = z.infer<typeof setupPasswordSchema>['body'];
export type SendFirstLoginOtpDTO = z.infer<typeof sendFirstLoginOtpSchema>['body'];
export type VerifyFirstLoginOtpDTO = z.infer<typeof verifyFirstLoginOtpSchema>['body'];
export type VerifyForgotPasswordOtpDTO = z.infer<typeof verifyForgotPasswordOtpSchema>['body'];

export interface AccountStatusResponseDTO {
  exists: boolean;
  email?: string;
  role?: string;
  isPasswordConfigured?: boolean;
  isProfileCompleted?: boolean;
  firstLoginCompleted?: boolean;
  status?: string;
}


export interface AuthTokensDTO {
  accessToken: string;
  refreshToken: string;
}

export interface UserResponseDTO {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  role: Role;
  collegeId: string;
  departmentId?: string | null;
  rollNumber?: string | null;
  avatarUrl?: string | null;
  phone?: string | null;
  lastSeen?: Date | null;
  createdAt?: Date | null;
  updatedAt?: Date | null;
  isPasswordConfigured?: boolean;
  isProfileCompleted?: boolean;
  firstLoginCompleted?: boolean;
  status?: string;
}
