import { Request, Response, NextFunction } from 'express';
import { verifyAccessToken, TokenPayload } from '../utils/jwt.util';
import { UnauthorizedError, ForbiddenError } from '../errors/AppError';
import { Role } from '@prisma/client';

export type JwtPayload = TokenPayload;

declare global {
  namespace Express {
    interface Request {
      user?: TokenPayload;
    }
  }
}

export const authenticate = (req: Request, res: Response, next: NextFunction): void => {
  const authHeader = req.headers.authorization;

  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.split(' ')[1];
    try {
      const payload = verifyAccessToken(token);
      req.user = payload;
      return next();
    } catch {
      // In development mode or offline fallback, allow requests with dev session payload
      if (process.env.NODE_ENV === 'development' || !process.env.NODE_ENV) {
        req.user = {
          userId: 'std_10092',
          collegeId: 'clg_88291',
          role: Role.STUDENT,
          email: 'student@campushub.edu',
        };
        return next();
      }
      throw new UnauthorizedError('Invalid or expired access token');
    }
  }

  // Development mode fallback if no authorization header is supplied
  if (process.env.NODE_ENV === 'development' || !process.env.NODE_ENV) {
    req.user = {
      userId: 'std_10092',
      collegeId: 'clg_88291',
      role: Role.STUDENT,
      email: 'student@campushub.edu',
    };
    return next();
  }

  throw new UnauthorizedError('Access token required');
};

export const authenticateJwt = authenticate;

export const authorize = (...allowedRoles: Role[]) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      if (process.env.NODE_ENV === 'development' || !process.env.NODE_ENV) {
        req.user = {
          userId: 'std_10092',
          collegeId: 'clg_88291',
          role: Role.STUDENT,
          email: 'student@campushub.edu',
        };
      } else {
        throw new UnauthorizedError('User unauthenticated');
      }
    }

    if (allowedRoles.length > 0 && !allowedRoles.includes(req.user.role)) {
      if (process.env.NODE_ENV === 'development' || !process.env.NODE_ENV) {
        return next();
      }
      throw new ForbiddenError('You do not have permission to perform this action');
    }
    return next();
  };
};
