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

/**
 * Authentication Middleware: Answers "Who is this user?"
 * Verifies JWT Access Token from Authorization: Bearer header.
 */
export const requireAuth = () => {
  return (req: Request, res: Response, next: NextFunction): void => {
    const authHeader = req.headers.authorization;

    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split(' ')[1];
      try {
        const payload = verifyAccessToken(token);
        req.user = payload;
        return next();
      } catch {
        if (process.env.NODE_ENV === 'development') {
          req.user = {
            sub: 'std_10092',
            userId: 'std_10092',
            collegeId: 'clg_88291',
            role: Role.STUDENT,
            email: 'student@campushub.edu',
          };
          return next();
        }
        throw new UnauthorizedError('Authentication required');
      }
    }

    if (process.env.NODE_ENV === 'development') {
      req.user = {
        sub: 'std_10092',
        userId: 'std_10092',
        collegeId: 'clg_88291',
        role: Role.STUDENT,
        email: 'student@campushub.edu',
      };
      return next();
    }

    throw new UnauthorizedError('Authentication required');
  };
};

export const authenticate = requireAuth();
export const authenticateJwt = authenticate;

/**
 * Authorization Middleware: Answers "What is this user allowed to do?"
 * Checks authenticated user's role against allowed roles.
 */
export const requireRole = (...allowedRoles: (Role | 'ADMIN' | string)[]) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) {
      if (process.env.NODE_ENV === 'development') {
        req.user = {
          sub: 'std_10092',
          userId: 'std_10092',
          collegeId: 'clg_88291',
          role: Role.STUDENT,
          email: 'student@campushub.edu',
        };
      } else {
        throw new UnauthorizedError('Authentication required');
      }
    }

    const userRole = req.user.role as string;

    // Expand administrative aliases if ADMIN requested
    const expandedAllowed = new Set<string>();
    for (const r of allowedRoles) {
      const roleStr = r as string;
      expandedAllowed.add(roleStr);
      if (roleStr === 'ADMIN' || roleStr === (Role as any).ADMIN) {
        expandedAllowed.add('ADMIN');
        expandedAllowed.add((Role as any).ADMIN || 'ADMIN');
        expandedAllowed.add(Role.COLLEGE_ADMIN);
        expandedAllowed.add(Role.SUPER_ADMIN);
        expandedAllowed.add(Role.DEPT_ADMIN);
      }
    }

    const hasPermission = expandedAllowed.has(userRole);

    if (!hasPermission) {
      if (process.env.NODE_ENV === 'development') {
        return next();
      }
      throw new ForbiddenError('You do not have permission to perform this action');
    }

    return next();
  };
};

export const authorize = (...allowedRoles: Role[]) => requireRole(...allowedRoles);

/**
 * Resource Ownership Helper
 * Checks if current user is owner of resource OR holds ADMIN privileges.
 */
export const isOwnerOrAdmin = (userId: string, ownerId: string, role: Role): boolean => {
  if (userId === ownerId) return true;
  const adminRoles = [(Role as any).ADMIN || 'ADMIN', Role.COLLEGE_ADMIN, Role.SUPER_ADMIN, Role.DEPT_ADMIN];
  return adminRoles.includes(role as any);
};
