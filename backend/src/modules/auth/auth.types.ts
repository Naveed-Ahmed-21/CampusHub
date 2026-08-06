import { z } from 'zod';
import { registerSchema, loginSchema, refreshTokenSchema, forgotPasswordSchema, resetPasswordSchema } from './auth.validation';
import { Role } from '@prisma/client';

export type RegisterDTO = z.infer<typeof registerSchema>['body'];
export type LoginDTO = z.infer<typeof loginSchema>['body'];
export type RefreshTokenDTO = z.infer<typeof refreshTokenSchema>['body'];
export type ForgotPasswordDTO = z.infer<typeof forgotPasswordSchema>['body'];
export type ResetPasswordDTO = z.infer<typeof resetPasswordSchema>['body'];

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
}
