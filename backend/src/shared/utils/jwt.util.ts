import jwt, { SignOptions } from 'jsonwebtoken';
import { env } from '../../config/env.config';
import { Role } from '@prisma/client';

export interface TokenPayload {
  sub?: string;
  userId: string;
  collegeId: string;
  departmentId?: string | null;
  role: Role;
  email: string;
}

export const generateAccessToken = (payload: TokenPayload): string => {
  const fullPayload: TokenPayload = {
    sub: payload.sub || payload.userId,
    userId: payload.userId,
    collegeId: payload.collegeId,
    departmentId: payload.departmentId,
    role: payload.role,
    email: payload.email,
  };
  const options: SignOptions = {
    expiresIn: env.JWT_ACCESS_EXPIRES_IN as SignOptions['expiresIn'],
  };
  return jwt.sign(fullPayload, env.JWT_ACCESS_SECRET, options);
};

export const generateRefreshToken = (payload: TokenPayload): string => {
  const fullPayload: TokenPayload = {
    sub: payload.sub || payload.userId,
    userId: payload.userId,
    collegeId: payload.collegeId,
    departmentId: payload.departmentId,
    role: payload.role,
    email: payload.email,
  };
  const options: SignOptions = {
    expiresIn: env.JWT_REFRESH_EXPIRES_IN as SignOptions['expiresIn'],
  };
  return jwt.sign(fullPayload, env.JWT_REFRESH_SECRET, options);
};

export const verifyAccessToken = (token: string): TokenPayload => {
  const decoded = jwt.verify(token, env.JWT_ACCESS_SECRET) as TokenPayload;
  if (!decoded.userId && decoded.sub) {
    decoded.userId = decoded.sub;
  }
  return decoded;
};

export const verifyRefreshToken = (token: string): TokenPayload => {
  const decoded = jwt.verify(token, env.JWT_REFRESH_SECRET) as TokenPayload;
  if (!decoded.userId && decoded.sub) {
    decoded.userId = decoded.sub;
  }
  return decoded;
};
